from typing import Dict, Tuple
import time
import cv2
import numpy as np

from ..domain.services import (
    l2_normalize,
    average_embedding,
    rank_by_distance,
    decide_match,
    TemporalVoter,
)
from ..infrastructure.io_utils import load_images, save_event_snapshot


def build_templates(gallery_dir: str, detector) -> Tuple[Dict[str, np.ndarray], Dict[str, int]]:
    templates: Dict[str, np.ndarray] = {}
    counts: Dict[str, int] = {}
    import os

    subdirs = sorted([d for d in os.listdir(gallery_dir) if os.path.isdir(os.path.join(gallery_dir, d))])
    if not subdirs:
        print(f"[BLACKLIST] No folders found in {gallery_dir}")
    for person in subdirs:
        folder = os.path.join(gallery_dir, person)
        imgs = load_images(folder)
        per_embs = []
        for img in imgs:
            boxes, encs = detector.detect_and_encode(img)
            if len(encs) > 0:
                per_embs.append(encs[0])
        avg = average_embedding(per_embs)
        if avg is not None:
            templates[person] = avg.astype(np.float32)
            counts[person] = len(per_embs)
            print(f"[BLACKLIST] {person}: {len(per_embs)} samples → OK")
        else:
            print(f"[BLACKLIST] {person}: no valid samples (check images)")
    if not templates:
        print("[BLACKLIST] Empty: no embeddings loaded.")
    return templates, counts


def run_loop(cam, detector, templates: Dict[str, np.ndarray],
             threshold: float, margin: float, detect_every_n: int,
             cooldown_s: int, use_temporal_voting: bool, window_size: int,
             min_votes: int, downscale: float, save_events: bool, skip_draw: bool) -> None:
    last_report: Dict[str, float] = {}
    voter = TemporalVoter(window_size, min_votes)
    print("[INFO] Press ESC to exit.")
    frame_id = 0

    fail_count = 0
    while True:
        ok, frame_bgr_full = cam.read()
        if not ok or frame_bgr_full is None:
            fail_count += 1
            if fail_count % 30 == 0:
                print("Frame not available (retrying)...")
            if fail_count > 300:
                print("Frame not available persistently. Aborting.")
                break
            time.sleep(0.03)
            continue
        else:
            fail_count = 0

        if downscale != 1.0:
            frame_bgr = cv2.resize(frame_bgr_full, None, fx=downscale, fy=downscale, interpolation=cv2.INTER_LINEAR)
        else:
            frame_bgr = frame_bgr_full

        rgb = cv2.cvtColor(frame_bgr, cv2.COLOR_BGR2RGB)

        do_detect = (detect_every_n <= 1) or (frame_id % detect_every_n == 0)
        if do_detect:
            boxes, encs = detector.detect_and_encode(rgb)
        else:
            boxes, encs = [], []

        labels_shown = []
        for (top, right, bottom, left), enc in zip(boxes, encs):
            enc = l2_normalize(enc)
            ranked = rank_by_distance(enc, templates) if templates else []
            label, d1, d2 = decide_match(ranked, threshold=threshold, margin=margin)

            final_label = label
            if use_temporal_voting:
                confirmed, voted = voter.vote(label)
                final_label = voted if confirmed else label

            is_match = (final_label != "UNKNOWN")
            if not skip_draw:
                color = (0, 200, 80) if is_match else (70, 70, 220)
                cv2.rectangle(frame_bgr, (left, top), (right, bottom), color, 2)
                tag = f"{final_label}  d1={d1:.2f}  thr={threshold}  Δ={max(0.0, (d2-d1)):.2f}"
                cv2.putText(frame_bgr, tag, (left, max(top-10, 15)),
                            cv2.FONT_HERSHEY_SIMPLEX, 0.55, color, 2)

            if is_match and save_events:
                now = time.time()
                if final_label not in last_report or (now - last_report[final_label]) > cooldown_s:
                    y1, y2 = max(0, top-10), min(frame_bgr.shape[0], bottom+10)
                    x1, x2 = max(0, left-10), min(frame_bgr.shape[1], right+10)
                    crop = frame_bgr[y1:y2, x1:x2].copy()
                    save_event_snapshot(crop, final_label, d1, d2, base="events")
                    last_report[final_label] = now
                    if not skip_draw:
                        cv2.circle(frame_bgr, (left, top), 6, (0, 255, 255), -1)

            labels_shown.append(final_label)

        shown = frame_bgr
        if downscale != 1.0:
            shown = cv2.resize(frame_bgr, (frame_bgr_full.shape[1], frame_bgr_full.shape[0]))
        if not skip_draw:
            cv2.imshow("FaceSim (Blacklist, Webcam)", shown)

        frame_id += 1
        if (cv2.waitKey(1) & 0xFF) == 27:
            break






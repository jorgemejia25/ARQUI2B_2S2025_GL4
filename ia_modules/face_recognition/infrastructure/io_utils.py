import os, glob, csv, time
from pathlib import Path
from typing import List
import numpy as np
import cv2


def imread_any(path: str):
    data = np.fromfile(path, dtype=np.uint8)
    img = cv2.imdecode(data, cv2.IMREAD_COLOR)
    return img


def load_images(folder: str) -> List[np.ndarray]:
    exts = ("*.jpg", "*.jpeg", "*.png", "*.bmp")
    paths: List[str] = []
    for e in exts:
        paths.extend(glob.glob(os.path.join(folder, e)))
    imgs: List[np.ndarray] = []
    for p in paths:
        img = imread_any(p)
        if img is not None:
            imgs.append(cv2.cvtColor(img, cv2.COLOR_BGR2RGB))
    return imgs


def ensure_events_dir(base="events"):
    Path(base).mkdir(parents=True, exist_ok=True)
    csv_path = Path(base) / "events.csv"
    if not csv_path.exists():
        with open(csv_path, "w", newline="", encoding="utf-8") as f:
            writer = csv.writer(f)
            writer.writerow(["timestamp", "label", "d_best", "d_second", "file"])
    return str(csv_path)


def save_event_snapshot(frame_bgr, label: str, d1: float, d2: float, base="events") -> None:
    ensure_events_dir(base)
    ts = int(time.time())
    fname = f"{ts}_{label.replace(' ', '_')}_{d1:.3f}.jpg"
    path = str(Path(base) / fname)
    cv2.imwrite(path, frame_bgr)
    with open(Path(base) / "events.csv", "a", newline="", encoding="utf-8") as f:
        csv.writer(f).writerow([ts, label, f"{d1:.4f}", f"{d2:.4f}", fname])






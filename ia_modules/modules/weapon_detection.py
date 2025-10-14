"""
Weapon Detection Module using Ultralytics YOLOv8
Detects cold weapons (armas blancas) in frames
"""
from typing import Dict, Any, List, Tuple
import os
import time
import numpy as np
import cv2
from datetime import datetime

try:
    from ..core.module_base import BaseModule
except ImportError:
    from core.module_base import BaseModule


class WeaponDetectionModule(BaseModule):
    """YOLOv8-based weapon detection module"""

    def __init__(self, config: Dict[str, Any]):
        super().__init__("weapon_detection")

        # Configuration
        self.weights_path: str = config.get("weights_path", "models/weapons/best.pt")
        self.conf: float = float(config.get("conf", 0.25))
        self.imgsz: int = int(config.get("imgsz", 416))
        self.detect_every: int = int(config.get("detect_every", 1))
        # Top printing configuration
        self.gap: int = int(config.get("gap", 3))
        self.update_interval: float = float(config.get("update_interval", 2.0))
        self.real_width_cm = config.get("real_width_cm", None)
        self.assume_first_dist_cm = config.get("assume_first_dist_cm", None)
        # API configuration
        self.api_url = config.get("api_url", "http://localhost:8001/api/v1/weapon-detections")
        self.cooldown = config.get("cooldown", 5)  # seconds between detections for same weapon
        self.camera_location = config.get("camera_location", "Main Camera")
        # Global focal and calibration like top_events
        self._focal_px = None
        if config.get("focal_px") is not None:
            try:
                self._focal_px = float(config.get("focal_px"))
            except Exception:
                self._focal_px = None
        else:
            px_ref = config.get("pixel_ref", None)
            dist_ref_cm = config.get("ref_dist_cm", None)
            if px_ref is not None and dist_ref_cm is not None and self.real_width_cm is not None:
                try:
                    self._focal_px = self._compute_focal_px_from_ref(float(px_ref), float(dist_ref_cm), float(self.real_width_cm))
                except Exception:
                    self._focal_px = None

        # State
        self._model = None
        self._class_names: List[str] = []
        # Top state
        self._state: Dict[str, int] = {}
        self._counts: Dict[str, int] = {}
        self._last_seen: Dict[str, Tuple[float, Any]] = {}
        self._occurrences: Dict[str, List[Tuple[int, float, Any]]] = {}
        self._focal_per_class: Dict[str, float] = {}
        self._last_print: float = 0.0
        # API state
        self._last_api_call: Dict[str, float] = {}

    def _resolve_weights_path(self) -> str:
        """Resolve weights path trying a few common locations"""
        # If absolute or relative path exists as given
        if os.path.exists(self.weights_path):
            return self.weights_path

        # Try relative to ia_modules root
        here = os.path.dirname(os.path.abspath(__file__))
        ia_root = os.path.abspath(os.path.join(here, os.pardir))  # ia_modules
        candidate = os.path.join(ia_root, self.weights_path)
        if os.path.exists(candidate):
            return candidate

        # Try original training folder in ARQUI2B_IA-main
        repo_root = os.path.abspath(os.path.join(ia_root, os.pardir))
        alt = os.path.join(repo_root, "ARQUI2B_IA-main", "runs", "weapons_merged_v2", "weights", "best.pt")
        if os.path.exists(alt):
            return alt

        return self.weights_path  # return as-is (ultralytics can still resolve hub names)

    def setup(self) -> bool:
        """Load YOLO model"""
        try:
            from ultralytics import YOLO  # lazy import to avoid hard dependency if unused
        except Exception as e:
            print(f"[weapon_detection] ultralytics not available: {e}")
            return False

        try:
            weights = self._resolve_weights_path()
            if not os.path.exists(weights):
                print(f"[weapon_detection] Weights not found at {weights}. Trying to use default yolov8n.pt")
                self._model = YOLO("yolov8n.pt")
            else:
                print(f"[weapon_detection] Loading weights: {weights}")
                self._model = YOLO(weights)

            # Collect class names if available
            try:
                self._class_names = list(self._model.names.values()) if hasattr(self._model, "names") else []
            except Exception:
                self._class_names = []

            print(f"[weapon_detection] Model ready (imgsz={self.imgsz}, conf={self.conf})")
            return True
        except Exception as e:
            print(f"[weapon_detection] Setup failed: {e}")
            return False

    def process(self, frame: np.ndarray, frame_id: int) -> Dict[str, Any]:
        """Run detection on a frame"""
        results: Dict[str, Any] = {"detections": [], "frame_id": frame_id}

        if frame_id % self.detect_every != 0 or self._model is None:
            return results

        try:
            pred_list = self._model.predict(
                source=frame,
                imgsz=self.imgsz,
                conf=self.conf,
                verbose=False,
                device="cpu",
                max_det=50,
            )

            # pred_list is a list with one Results object
            if not pred_list:
                return results

            r = pred_list[0]
            boxes = r.boxes  # Boxes object

            # Collect detections and also compute per-class max width for top stats
            detected_max_width: Dict[str, float] = {}

            for i in range(len(boxes)):
                b = boxes[i]
                # xyxy as numpy
                xyxy = b.xyxy[0].cpu().numpy().astype(int)
                x1, y1, x2, y2 = [int(v) for v in xyxy]
                conf = float(b.conf[0].item()) if b.conf is not None else 0.0
                cls_id = int(b.cls[0].item()) if b.cls is not None else -1
                cls_name = self._class_names[cls_id] if 0 <= cls_id < len(self._class_names) else f"cls_{cls_id}"

                results["detections"].append({
                    "bbox": (x1, y1, x2, y2),
                    "class_id": cls_id,
                    "class_name": cls_name,
                    "confidence": conf,
                })

                width_px = float(max(0, x2 - x1))
                prev = detected_max_width.get(cls_name)
                if prev is None or width_px > prev:
                    detected_max_width[cls_name] = width_px

            # Update and maybe print top
            self._update_and_maybe_print_top(detected_max_width)

        except Exception as e:
            print(f"[weapon_detection] Processing error: {e}")
            results["error"] = str(e)

        return results

    def _compute_focal_px_from_ref(self, pixel_ref: float, dist_ref_cm: float, real_width_cm: float) -> float:
        return (pixel_ref * dist_ref_cm) / real_width_cm

    def _estimate_distance_cm(self, pixel_width: float, real_width_cm: float, focal_px: float):
        if pixel_width is None or pixel_width <= 0:
            return None
        return (real_width_cm * focal_px) / pixel_width

    def _update_and_maybe_print_top(self, detected: Dict[str, float]):
        """Replicate top_events summary: track counts and print top3 periodically"""
        now = time.time()

        # Update states (gap for previously present classes)
        for cls in list(self._state.keys()):
            if cls not in detected:
                self._state[cls] += 1
                if self._state[cls] > self.gap:
                    self._state.pop(cls, None)
            else:
                self._state[cls] = 0

        # Handle current detections
        for cls, width_px in detected.items():
            dist = None
            # Priority like top_events: use global focal_px if available, else per-class focal, else px
            if self._focal_px is not None and self.real_width_cm is not None and width_px is not None:
                dist = self._estimate_distance_cm(width_px, float(self.real_width_cm), float(self._focal_px))
            elif self.real_width_cm is not None and cls in self._focal_per_class and width_px is not None:
                dist = self._estimate_distance_cm(width_px, float(self.real_width_cm), float(self._focal_per_class[cls]))
            else:
                dist = width_px

            new_event = False
            if cls not in self._state:
                self._state[cls] = 0
                self._counts[cls] = self._counts.get(cls, 0) + 1
                new_event = True
            else:
                self._state[cls] = 0

            self._last_seen[cls] = (now, dist)
            if new_event:
                occ_num = self._counts[cls]
                self._occurrences.setdefault(cls, []).append((occ_num, now, dist))
                # If assume_first_dist_cm, calibrate focal per class and override first record distance
                if (self.assume_first_dist_cm is not None) and (self.real_width_cm is not None) and (detected.get(cls) is not None) and (cls not in self._focal_per_class):
                    try:
                        self._focal_per_class[cls] = self._compute_focal_px_from_ref(float(detected[cls]), float(self.assume_first_dist_cm), float(self.real_width_cm))
                        self._occurrences[cls][-1] = (occ_num, now, float(self.assume_first_dist_cm))
                        self._last_seen[cls] = (now, float(self.assume_first_dist_cm))
                    except Exception:
                        pass

                # Send to API for new detection
                if cls not in self._last_api_call or (now - self._last_api_call[cls]) >= self.cooldown:
                    if self._send_to_api(cls, dist):
                        self._last_api_call[cls] = now
                        print(f"[weapon_detection] Detection sent to API: {cls} (dist={dist})")

        # Commented out: Original printing logic
        # if (now - self._last_print) < self.update_interval:
        #     return
        # self._last_print = now
        # ... rest of printing code ...

        # Commented out: Original printing logic
        # if (now - self._last_print) < self.update_interval:
        #     return
        # self._last_print = now
        #
        # # Build ranking by counts desc
        # ranked = sorted(self._counts.items(), key=lambda x: x[1], reverse=True)
        # lines: List[str] = []
        # for i in range(3):
        #     if i < len(ranked):
        #         cls, cnt = ranked[i]
        #         ts, val = self._last_seen.get(cls, (None, None))
        #         dt = datetime.fromtimestamp(ts).strftime('%H:%M:%S') if ts else 'NA'
        #         if val is None:
        #             dist_str = 'NA'
        #         else:
        #             # If calibrated (cm) else px
        #             if (self._focal_px is not None and self.real_width_cm is not None) or (self.real_width_cm is not None and cls in self._focal_per_class):
        #                 try:
        #                     dist_str = f"{float(val):.1f}cm"
        #                 except Exception:
        #                     dist_str = 'NA'
        #             else:
        #                 try:
        #                     dist_str = f"{int(val)}px"
        #                 except Exception:
        #                     dist_str = 'NA'
        #         lines.append(f"Top{i+1}: {cls} ({dt} - {dist_str} - {cnt})")
        #     else:
        #         lines.append(f"Top{i+1}: -")
        #
        # # Build full top block including recent history per class (as in top_events.py)
        # out_lines: List[str] = []
        # for idx in range(len(lines)):
        #     l = lines[idx]
        #     if l.strip().endswith('-'):
        #         out_lines.append(l)
        #         continue
        #     try:
        #         _header, rest = l.split(':', 1)
        #         cls_name = rest.strip().split('(')[0].strip()
        #     except Exception:
        #         out_lines.append(l)
        #         continue
        #     cnt = self._counts.get(cls_name, 0)
        #     hist = self._occurrences.get(cls_name, [])
        #     hist = list(reversed(hist))  # most recent first
        #     hist_strs: List[str] = []
        #     for occ in hist:
        #         occ_num, occ_ts, occ_dist = occ
        #         occ_dt = datetime.fromtimestamp(occ_ts).strftime('%H:%M:%S')
        #         if occ_dist is None:
        #             dist_s = 'NA'
        #         else:
        #             if (self.real_width_cm is not None) and (cls_name in self._focal_per_class):
        #                 try:
        #                     dist_s = f"{float(occ_dist):.1f}cm"
        #                 except Exception:
        #                     dist_s = 'NA'
        #             else:
        #                 try:
        #                     dist_s = f"{int(occ_dist)}px"
        #                 except Exception:
        #                     dist_s = 'NA'
        #         hist_strs.append(f"({occ_num} - {occ_dt} - {dist_s})")
        #     history_list_repr = repr(hist_strs)
        #     out_lines.append(f"Top{idx+1}: {cls_name} cantidad: {cnt} {history_list_repr}")
        #
        # print("\n".join(out_lines))

    def _send_to_api(self, weapon_name: str, distance: float) -> bool:
        """Send weapon detection event to API"""
        try:
            import requests  # lazy import
            payload = {
                "name": weapon_name,
                "distance": float(distance),
                "camera_location": self.camera_location
            }

            response = requests.post(self.api_url, json=payload, timeout=2)

            if response.status_code == 201:
                return True
            else:
                print(f"[weapon_detection] API error: {response.status_code}")
                return False

        except Exception as e:
            print(f"[weapon_detection] API request failed: {e}")
            return False

    def draw(self, frame: np.ndarray, results: Dict[str, Any]) -> np.ndarray:
        if not results or "detections" not in results:
            return frame

        for det in results["detections"]:
            x1, y1, x2, y2 = det["bbox"]
            label = f"{det['class_name']} {det['confidence']:.2f}"
            color = (0, 140, 255)  # orange-ish
            cv2.rectangle(frame, (x1, y1), (x2, y2), color, 2)
            cv2.putText(frame, label, (x1, max(20, y1 - 10)), cv2.FONT_HERSHEY_SIMPLEX, 0.6, color, 2)

        return frame

    def get_info(self) -> Dict[str, Any]:
        info = super().get_info()
        info.update({
            "weights_path": self.weights_path,
            "conf": self.conf,
            "imgsz": self.imgsz,
            "classes": self._class_names,
        })
        return info

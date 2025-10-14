"""
Plate Detection Module
Detects vehicle license plates and sends events to the API
"""

import cv2
import time
import base64
import requests
from datetime import datetime
from typing import Dict, Any
from ultralytics import YOLO
import easyocr
import numpy as np

from core import trigger_state




try:
    from ..core.module_base import BaseModule
except ImportError:
    from core.module_base import BaseModule


class PlateDetectionModule(BaseModule):
    """Module for detecting vehicle license plates using YOLO + OCR"""

    def __init__(self, config: Dict[str, Any]):
        super().__init__("plate_detection")
        self.api_url = config.get("api_url", "http://localhost:8001/api/v1/plate-events")
        self.conf_threshold = config.get("conf_threshold", 0.4)
        self.cooldown = config.get("cooldown", 5)
        self.camera_location = config.get("camera_location", "Main Entrance")

        self.last_detection_time = 0
        self.reader = easyocr.Reader(['en'])
        self.model = YOLO("yolov8n.pt")

    def setup(self) -> bool:
        """Initialize YOLO and OCR models"""
        try:
            _ = self.model.names
            print(f"[{self.name}] YOLO model loaded successfully.")
            return True
        except Exception as e:
            print(f"[{self.name}] Setup error: {e}")
            return False

    print(f"[DEBUG] capture_next_plate={trigger_state.capture_next_plate}")

    def process(self, frame: np.ndarray, frame_id: int) -> Dict[str, Any]:
        """Process a video frame for plate detection"""
        results = {"detections": [], "frame_id": frame_id}
        current_time = time.time()

        # Avoid spam detections
        if current_time - self.last_detection_time < self.cooldown:
            return results

        try:
            detections = self.model(frame)
            for det in detections:
                for box in det.boxes:
                    conf = float(box.conf[0])
                    if conf < self.conf_threshold:
                        continue

                    x1, y1, x2, y2 = map(int, box.xyxy[0])
                    roi = frame[y1:y2, x1:x2]
                    ocr_results = self.reader.readtext(roi)

                    for (_, text, conf_text) in ocr_results:
                        if len(text) >= 5 and conf_text > 0.5:
                            plate_text = text.strip()
                            results["detections"].append({
                                "plate_text": plate_text,
                                "confidence": conf_text,
                                "bbox": (x1, y1, x2, y2)
                            })

                        if trigger_state.capture_next_plate:
                            print(f"[{self.name}]  Trigger activo — enviando a API.")
                            self._send_to_api(plate_text, conf_text, roi)
                            self.last_detection_time = current_time
                            trigger_state.capture_next_plate = False
                        else:
                            print(f"[{self.name}] Trigger inactivo (capture_next_plate={trigger_state.capture_next_plate})")


        except Exception as e:
            print(f"[{self.name}] Processing error: {e}")
            results["error"] = str(e)

        return results

    def _send_to_api(self, plate_text: str, confidence: float, roi: np.ndarray):
        """Send detection event to API"""
        location = getattr(trigger_state, "last_location", self.camera_location)
        try:
            _, buffer = cv2.imencode(".jpg", roi)
            encoded_image = base64.b64encode(buffer).decode("utf-8")

            payload = {
                "plate_text": plate_text,
                "confidence": float(confidence),
                "camera_location": location,
                "image_base64": encoded_image
            }

            response = requests.post(self.api_url, json=payload, timeout=5)
            if response.status_code == 201:
                print(f"[{self.name}] Event sent successfully to API.")
            else:
                print(f"[{self.name}] API error {response.status_code}: {response.text}")

        except Exception as e:
            print(f"[{self.name}] Error sending to API: {e}")

    def draw(self, frame: np.ndarray, results: Dict[str, Any]) -> np.ndarray:
        """Draw bounding boxes and labels on frame"""
        if "detections" not in results:
            return frame

        for det in results["detections"]:
            x1, y1, x2, y2 = det["bbox"]
            plate_text = det["plate_text"]
            conf = det["confidence"]

            cv2.rectangle(frame, (x1, y1), (x2, y2), (0, 200, 80), 2)
            cv2.putText(frame, f"{plate_text} ({conf:.2f})",
                        (x1, y1 - 10), cv2.FONT_HERSHEY_SIMPLEX, 0.6,
                        (0, 200, 80), 2)

        return frame

    def get_info(self) -> Dict[str, Any]:
        info = super().get_info()
        info.update({
            "api_url": self.api_url,
            "conf_threshold": self.conf_threshold,
            "cooldown": self.cooldown,
            "camera_location": self.camera_location
        })
        return info

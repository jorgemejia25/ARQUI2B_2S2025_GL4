"""
Detects license plate text directly using OCR (EasyOCR)
"""

import cv2
import time
import base64
import requests
from typing import Dict, Any
import numpy as np
import easyocr

from core import trigger_state

try:
    from ..core.module_base import BaseModule
except ImportError:
    from core.module_base import BaseModule


class PlateDetectionModule(BaseModule):
    """Simplified text-based plate detection module"""

    def __init__(self, config: Dict[str, Any]):
        super().__init__("plate_detection")
        self.api_url_primary = config.get("api_url_primary", "http://localhost:8001/api/v1/plate-events")
        self.api_url_secondary = config.get("api_url_secondary", "")
        self.use_dual_apis = config.get("use_dual_apis", False)
        self.conf_threshold = config.get("conf_threshold", 0.45)
        self.cooldown = config.get("cooldown", 5)
        self.camera_location = config.get("camera_location", "Entrada Principal")
        self.last_detection_time = 0

        # Initialize OCR reader with SSL workaround
        self.reader = None
        self._init_ocr_reader()

    def _init_ocr_reader(self):
        """Initialize OCR reader with SSL certificate workaround"""
        try:
            import ssl
            import urllib.request
            
            # Create SSL context that doesn't verify certificates
            ssl_context = ssl.create_default_context()
            ssl_context.check_hostname = False
            ssl_context.verify_mode = ssl.CERT_NONE
            
            # Monkey patch urllib to use our SSL context
            original_urlopen = urllib.request.urlopen
            def patched_urlopen(*args, **kwargs):
                if 'context' not in kwargs:
                    kwargs['context'] = ssl_context
                return original_urlopen(*args, **kwargs)
            urllib.request.urlopen = patched_urlopen
            
            # Now try to initialize EasyOCR
            self.reader = easyocr.Reader(['en'])
            print(f"[{self.name}] EasyOCR initialized successfully")
            
        except Exception as e:
            print(f"[{self.name}] Warning: Failed to initialize EasyOCR: {e}")
            print(f"[{self.name}] Plate detection will be disabled")
            self.reader = None

    def setup(self) -> bool:
        """Setup OCR"""
        if self.reader is not None:
            print(f"[{self.name}] EasyOCR initialized successfully")
            return True
        else:
            print(f"[{self.name}] EasyOCR not available - plate detection disabled")
            return False

    def process(self, frame: np.ndarray, frame_id: int) -> Dict[str, Any]:
        """Detect any readable text as a plate"""
        results = {"detections": [], "frame_id": frame_id}
        
        # If OCR reader is not available, return empty results
        if self.reader is None:
            return results
            
        current_time = time.time()

        # Cooldown: avoid flooding the API
        if current_time - self.last_detection_time < self.cooldown:
            return results

        try:
            ocr_results = self.reader.readtext(frame)

            for (bbox, text, conf) in ocr_results:
                text = text.strip()
                if len(text) >= 4 and conf >= self.conf_threshold:
                    x1, y1 = map(int, bbox[0])
                    x2, y2 = map(int, bbox[2])
                    h, w, _ = frame.shape
                    padding_x = int((x2 - x1) * 1.5)   
                    padding_y = int((y2 - y1) * 2.0)
                    x1_exp = max(0, x1 - padding_x)
                    y1_exp = max(0, y1 - padding_y)
                    x2_exp = min(w, x2 + padding_x)
                    y2_exp = min(h, y2 + padding_y)
                    roi = frame[y1_exp:y2_exp, x1_exp:x2_exp]
                    results["detections"].append({
                        "plate_text": text,
                        "confidence": conf,
                        "bbox": (x1, y1, x2, y2)
                    })

                    if trigger_state.capture_next_plate:
                        print(f"[{self.name}] Texto detectado como placa: {text} ({conf:.2f})")
                        self._send_to_api(text, conf, roi)
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

            # Send to primary API
            success_primary = self._send_to_single_api(self.api_url_primary, payload, "Primary")
            
            # Send to secondary API if configured
            success_secondary = True  # Default to True if no secondary API
            if self.use_dual_apis and self.api_url_secondary:
                success_secondary = self._send_to_single_api(self.api_url_secondary, payload, "Secondary")
            
            if success_primary:
                print(f"[{self.name}] Evento enviado correctamente a la API ({plate_text}).")

        except Exception as e:
            print(f"[{self.name}] Error sending to API: {e}")
    
    def _send_to_single_api(self, api_url: str, payload: Dict[str, Any], api_name: str) -> bool:
        """Send payload to a single API endpoint"""
        try:
            response = requests.post(api_url, json=payload, timeout=5)
            if response.status_code == 201:
                print(f"[{self.name}] {api_name} API success: {payload['plate_text']}")
                return True
            else:
                print(f"[{self.name}] {api_name} API error {response.status_code}: {response.text}")
                return False
        except Exception as e:
            print(f"[{self.name}] {api_name} API request failed: {e}")
            return False

    def draw(self, frame: np.ndarray, results: Dict[str, Any]) -> np.ndarray:
        """Draw bounding boxes around detected text"""
        if "detections" not in results:
            return frame

        for det in results["detections"]:
            x1, y1, x2, y2 = det["bbox"]
            plate_text = det["plate_text"]
            conf = det["confidence"]

            cv2.rectangle(frame, (x1, y1), (x2, y2), (0, 200, 255), 2)
            cv2.putText(frame, f"{plate_text} ({conf:.2f})",
                        (x1, y1 - 10), cv2.FONT_HERSHEY_SIMPLEX, 0.6,
                        (0, 200, 255), 2)

        return frame

    def get_info(self) -> Dict[str, Any]:
        info = super().get_info()
        info.update({
            "api_url_primary": self.api_url_primary,
            "api_url_secondary": self.api_url_secondary,
            "use_dual_apis": self.use_dual_apis,
            "conf_threshold": self.conf_threshold,
            "cooldown": self.cooldown,
            "camera_location": self.camera_location,
            "model_type": "OCR-only"
        })
        return info

"""
Face Recognition Module
Detects and recognizes faces from a blacklist gallery
"""
import os
import time
import glob
import cv2
import numpy as np
import face_recognition as fr
import requests
from typing import Dict, Any, List, Tuple, Optional

try:
    from ..core.module_base import BaseModule
except ImportError:
    from core.module_base import BaseModule


class FaceRecognitionModule(BaseModule):
    """Face recognition and blacklist detection module"""
    
    def __init__(self, config: Dict[str, Any]):
        super().__init__("face_recognition")
        
        # Configuration
        self.gallery_dir = config.get("gallery_dir", "gallery")
        self.api_url_primary = config.get("api_url_primary", "http://localhost:8001/api/v1/blacklist-events")
        self.api_url_secondary = config.get("api_url_secondary", "")
        self.use_dual_apis = config.get("use_dual_apis", False)
        self.threshold = config.get("threshold", 0.50)
        self.detect_every = config.get("detect_every", 3)
        self.cooldown = config.get("cooldown", 8)
        self.camera_location = config.get("camera_location", "Main Camera")
        
        # State
        self.templates: Dict[str, np.ndarray] = {}
        self.last_detection_time: Dict[str, float] = {}
        self.last_api_call: Dict[str, float] = {}
        
    def setup(self) -> bool:
        """Initialize module and load face templates"""
        try:
            self.templates = self._load_templates()
            if not self.templates:
                print(f"[{self.name}] No templates loaded from {self.gallery_dir}")
                return False
            
            print(f"[{self.name}] Loaded {len(self.templates)} templates: {list(self.templates.keys())}")
            return True
            
        except Exception as e:
            print(f"[{self.name}] Setup failed: {e}")
            return False
    
    def _load_templates(self) -> Dict[str, np.ndarray]:
        """Load face encodings from gallery directory"""
        templates = {}
        
        if not os.path.exists(self.gallery_dir):
            print(f"[{self.name}] Gallery not found: {self.gallery_dir}")
            return templates
        
        # Iterate through person folders
        for person_dir in os.listdir(self.gallery_dir):
            person_path = os.path.join(self.gallery_dir, person_dir)
            
            if not os.path.isdir(person_path):
                continue
            
            # Load images for this person
            encodings = []
            image_files = []
            
            for ext in ['*.jpg', '*.jpeg', '*.png']:
                image_files.extend(glob.glob(os.path.join(person_path, ext)))
            
            for img_path in image_files:
                img = cv2.imread(img_path)
                if img is None:
                    continue
                
                rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
                face_encodings = fr.face_encodings(rgb)
                
                if face_encodings:
                    encodings.append(face_encodings[0])
            
            # Create averaged template
            if encodings:
                avg_encoding = np.mean(encodings, axis=0)
                avg_encoding = avg_encoding / np.linalg.norm(avg_encoding)  # Normalize
                templates[person_dir] = avg_encoding
                print(f"[{self.name}] {person_dir}: {len(encodings)} samples loaded")
        
        return templates
    
    def process(self, frame: np.ndarray, frame_id: int) -> Dict[str, Any]:
        """Process frame for face detection and recognition"""
        results = {
            "detections": [],
            "frame_id": frame_id
        }
        
        # Skip frames for performance
        if frame_id % self.detect_every != 0:
            return results
        
        try:
            # Convert to RGB
            rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            
            # Detect faces
            face_locations = fr.face_locations(rgb, model="hog")
            face_encodings = fr.face_encodings(rgb, face_locations)
            
            current_time = time.time()
            
            # Process each face
            for (top, right, bottom, left), encoding in zip(face_locations, face_encodings):
                # Normalize encoding
                encoding = encoding / np.linalg.norm(encoding)
                
                # Match against templates
                person_name, distance = self._match_face(encoding)
                
                detection = {
                    "bbox": (left, top, right, bottom),
                    "person": person_name,
                    "distance": float(distance),
                    "confidence": float(1.0 - distance),
                    "is_match": person_name != "UNKNOWN"
                }
                
                results["detections"].append(detection)
                
                # Handle API calls for matches
                if person_name != "UNKNOWN":
                    self._handle_detection(person_name, distance, current_time)
            
        except Exception as e:
            print(f"[{self.name}] Processing error: {e}")
            results["error"] = str(e)
        
        return results
    
    def _match_face(self, encoding: np.ndarray) -> Tuple[str, float]:
        """
        Match face encoding against templates
        
        Returns:
            (person_name, distance) tuple
        """
        if not self.templates:
            return "UNKNOWN", 1.0
        
        # Calculate distances to all templates
        distances = []
        names = []
        
        for name, template in self.templates.items():
            dist = np.linalg.norm(encoding - template)
            distances.append(dist)
            names.append(name)
        
        # Find best match
        min_idx = np.argmin(distances)
        min_distance = distances[min_idx]
        
        # Check if distance is below threshold
        if min_distance < self.threshold:
            return names[min_idx], min_distance
        
        return "UNKNOWN", min_distance
    
    def _handle_detection(self, person_name: str, distance: float, current_time: float):
        """Handle a successful face match"""
        # Check cooldown
        if person_name in self.last_api_call:
            if current_time - self.last_api_call[person_name] < self.cooldown:
                return  # Still in cooldown
        
        # Send to API
        if self._send_to_api(person_name, distance):
            self.last_api_call[person_name] = current_time
            print(f"[{self.name}] Detection: {person_name} (dist={distance:.3f})")
    
    def _send_to_api(self, person_name: str, distance: float) -> bool:
        """Send detection event to API(s)"""
        payload = {
            "person_name": person_name,
            "confidence": float(1.0 - distance),
            "distance": float(distance),
            "camera_location": self.camera_location
        }
        
        success_primary = self._send_to_single_api(self.api_url_primary, payload, "Primary")
        
        # Send to secondary API if configured
        success_secondary = True  # Default to True if no secondary API
        if self.use_dual_apis and self.api_url_secondary:
            success_secondary = self._send_to_single_api(self.api_url_secondary, payload, "Secondary")
        
        # Return True if at least primary API succeeds
        return success_primary
    
    def _send_to_single_api(self, api_url: str, payload: Dict[str, Any], api_name: str) -> bool:
        """Send payload to a single API endpoint"""
        try:
            response = requests.post(api_url, json=payload, timeout=2)
            
            if response.status_code == 201:
                print(f"[{self.name}] {api_name} API success: {payload['person_name']}")
                return True
            else:
                print(f"[{self.name}] {api_name} API error: {response.status_code}")
                return False
                
        except Exception as e:
            print(f"[{self.name}] {api_name} API request failed: {e}")
            return False
    
    def draw(self, frame: np.ndarray, results: Dict[str, Any]) -> np.ndarray:
        """Draw detection results on frame"""
        if "detections" not in results:
            return frame
        
        for detection in results["detections"]:
            left, top, right, bottom = detection["bbox"]
            person = detection["person"]
            confidence = detection["confidence"]
            is_match = detection["is_match"]
            
            # Choose color based on match
            color = (0, 200, 80) if is_match else (70, 70, 220)
            
            # Draw bounding box
            cv2.rectangle(frame, (left, top), (right, bottom), color, 2)
            
            # Draw label
            label = f"{person} ({confidence:.2f})"
            cv2.putText(frame, label, (left, top - 10),
                       cv2.FONT_HERSHEY_SIMPLEX, 0.6, color, 2)
            
            # Draw indicator for matches
            if is_match:
                cv2.circle(frame, (left, top), 6, (0, 255, 255), -1)
        
        return frame
    
    def get_info(self) -> Dict[str, Any]:
        """Get module information"""
        info = super().get_info()
        info.update({
            "templates_count": len(self.templates),
            "template_names": list(self.templates.keys()),
            "threshold": self.threshold,
            "cooldown": self.cooldown,
            "api_url_primary": self.api_url_primary,
            "api_url_secondary": self.api_url_secondary,
            "use_dual_apis": self.use_dual_apis
        })
        return info


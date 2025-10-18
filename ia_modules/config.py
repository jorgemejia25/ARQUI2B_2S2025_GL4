"""
Configuration file for AI Modules System
"""
import os


class Config:
    """System configuration"""
    
    # Base directories
    BASE_DIR = os.path.dirname(os.path.abspath(__file__))
    GALLERY_DIR = os.path.join(BASE_DIR, "gallery")
    
    # API endpoints - Primary and Secondary support
    API_PRIMARY_URL = os.getenv("API_PRIMARY_URL", "http://69.164.244.224:8001")
    API_SECONDARY_URL = os.getenv("API_SECONDARY_URL", "")  # Optional secondary API
    USE_DUAL_APIS = os.getenv("USE_DUAL_APIS", "false").lower() == "true"
    
    # Primary API endpoints
    BLACKLIST_ENDPOINT_PRIMARY = f"{API_PRIMARY_URL}/api/v1/blacklist-events"
    WEAPON_ENDPOINT_PRIMARY = f"{API_PRIMARY_URL}/api/v1/weapon-detections"
    PLATE_ENDPOINT_PRIMARY = f"{API_PRIMARY_URL}/api/v1/plate-events"
    
    # Secondary API endpoints (if configured)
    BLACKLIST_ENDPOINT_SECONDARY = f"{API_SECONDARY_URL}/api/v1/blacklist-events" if API_SECONDARY_URL else ""
    WEAPON_ENDPOINT_SECONDARY = f"{API_SECONDARY_URL}/api/v1/weapon-detections" if API_SECONDARY_URL else ""
    PLATE_ENDPOINT_SECONDARY = f"{API_SECONDARY_URL}/api/v1/plate-events" if API_SECONDARY_URL else ""
    
    # Camera defaults
    DEFAULT_CAMERA_ID = 0
    DEFAULT_FPS = 30
    DEFAULT_WIDTH = 640
    DEFAULT_HEIGHT = 480
    
    # Face recognition defaults
    FACE_THRESHOLD = 0.50
    FACE_COOLDOWN = 8  # seconds
    FACE_DETECT_EVERY = 3  # process every N frames
    
    @classmethod
    def get_face_recognition_config(cls, **overrides):
        """Get face recognition module configuration with optional overrides"""
        config = {
            "gallery_dir": cls.GALLERY_DIR,
            "api_url_primary": cls.BLACKLIST_ENDPOINT_PRIMARY,
            "api_url_secondary": cls.BLACKLIST_ENDPOINT_SECONDARY,
            "use_dual_apis": cls.USE_DUAL_APIS and bool(cls.API_SECONDARY_URL),
            "threshold": cls.FACE_THRESHOLD,
            "cooldown": cls.FACE_COOLDOWN,
            "detect_every": cls.FACE_DETECT_EVERY,
            "camera_location": "Main Camera"
        }
        config.update(overrides)
        return config
    
    @classmethod
    def get_weapon_detection_config(cls, **overrides):
        """Get weapon detection module configuration with optional overrides"""
        config = {
            "api_url_primary": cls.WEAPON_ENDPOINT_PRIMARY,
            "api_url_secondary": cls.WEAPON_ENDPOINT_SECONDARY,
            "use_dual_apis": cls.USE_DUAL_APIS and bool(cls.API_SECONDARY_URL),
            "cooldown": 5,
            "camera_location": "Main Camera"
        }
        config.update(overrides)
        return config
    
    @classmethod
    def get_plate_detection_config(cls, **overrides):
        """Get plate detection module configuration with optional overrides"""
        config = {
            "api_url_primary": cls.PLATE_ENDPOINT_PRIMARY,
            "api_url_secondary": cls.PLATE_ENDPOINT_SECONDARY,
            "use_dual_apis": cls.USE_DUAL_APIS and bool(cls.API_SECONDARY_URL),
            "confidence_threshold": 0.45,
            "camera_location": "Entrada Principal",
            "events_dir": "events",
            "cooldown": 6
        }
        config.update(overrides)
        return config
    
    @classmethod
    def get_camera_config(cls, **overrides):
        """Get camera configuration with optional overrides"""
        config = {
            "camera_id": cls.DEFAULT_CAMERA_ID,
            "fps": cls.DEFAULT_FPS,
            "width": cls.DEFAULT_WIDTH,
            "height": cls.DEFAULT_HEIGHT
        }
        config.update(overrides)
        return config

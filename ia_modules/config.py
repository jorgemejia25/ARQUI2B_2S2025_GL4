"""
Configuration file for AI Modules System
"""
import os


class Config:
    """System configuration"""
    
    # Base directories
    BASE_DIR = os.path.dirname(os.path.abspath(__file__))
    GALLERY_DIR = os.path.join(BASE_DIR, "gallery")
    
    # API endpoints
    API_BASE_URL = os.getenv("API_BASE_URL", "http://localhost:8001")
    BLACKLIST_ENDPOINT = f"{API_BASE_URL}/api/v1/blacklist-events"
    
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
            "api_url": cls.BLACKLIST_ENDPOINT,
            "threshold": cls.FACE_THRESHOLD,
            "cooldown": cls.FACE_COOLDOWN,
            "detect_every": cls.FACE_DETECT_EVERY,
            "camera_location": "Main Camera"
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

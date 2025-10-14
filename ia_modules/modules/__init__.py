"""
AI Processing Modules
"""
try:
    from .face_recognition import FaceRecognitionModule
    from .plate_detection import PlateDetectionModule
except ImportError:
    from face_recognition import FaceRecognitionModule
    from .plate_detection import PlateDetectionModule    

__all__ = ["FaceRecognitionModule", "PlateDetectionModule"]

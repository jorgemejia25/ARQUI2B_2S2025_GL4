"""
AI Processing Modules
"""
try:
    from .face_recognition import FaceRecognitionModule
    from .weapon_detection import WeaponDetectionModule
except ImportError:
    from face_recognition import FaceRecognitionModule
    from weapon_detection import WeaponDetectionModule

__all__ = ['FaceRecognitionModule', 'WeaponDetectionModule']

"""
AI Processing Modules
"""
try:
    from .face_recognition import FaceRecognitionModule
except ImportError:
    from face_recognition import FaceRecognitionModule

__all__ = ['FaceRecognitionModule']

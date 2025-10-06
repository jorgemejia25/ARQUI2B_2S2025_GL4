from typing import List, Tuple
import numpy as np
import face_recognition


class FaceRecognitionDetector:
    def __init__(self, model: str = "hog", upsample: int = 0) -> None:
        self.model = model
        self.upsample = int(max(0, upsample))

    def detect_and_encode(self, rgb_image: np.ndarray) -> Tuple[List[Tuple[int, int, int, int]], List[np.ndarray]]:
        boxes = face_recognition.face_locations(
            rgb_image,
            number_of_times_to_upsample=self.upsample,
            model=self.model,
        )
        encodings = face_recognition.face_encodings(rgb_image, boxes)
        return boxes, encodings






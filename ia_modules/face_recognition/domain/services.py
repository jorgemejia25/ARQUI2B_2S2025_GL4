from typing import Dict, List, Tuple, Optional
import numpy as np


def l2_normalize(vector: np.ndarray) -> np.ndarray:
    norm = np.linalg.norm(vector) + 1e-12
    return vector / norm


def average_embedding(embeddings: List[np.ndarray]) -> Optional[np.ndarray]:
    if not embeddings:
        return None
    stacked = np.stack(embeddings, axis=0)
    return l2_normalize(np.mean(stacked, axis=0))


def rank_by_distance(embedding: np.ndarray, templates: Dict[str, np.ndarray]) -> List[Tuple[str, float]]:
    embedding = l2_normalize(embedding)
    items: List[Tuple[str, float]] = []
    for name, centroid in templates.items():
        distance = float(np.linalg.norm(embedding - centroid))
        items.append((name, distance))
    items.sort(key=lambda x: x[1])
    return items


def decide_match(sorted_distances: List[Tuple[str, float]], threshold: float, margin: float) -> Tuple[str, float, float]:
    if not sorted_distances:
        return "UNKNOWN", 9.99, 9.99
    name1, d1 = sorted_distances[0]
    name2, d2 = (("—", 9.99) if len(sorted_distances) < 2 else sorted_distances[1])
    if d1 < threshold and (d2 - d1) >= margin:
        return name1, d1, d2
    return "UNKNOWN", d1, d2


class TemporalVoter:
    def __init__(self, window_size: int = 5, min_votes: int = 3) -> None:
        self.window_size = window_size
        self.min_votes = min_votes
        self.buffer: List[str] = []

    def vote(self, label: str) -> Tuple[bool, str]:
        self.buffer.append(label)
        if len(self.buffer) > self.window_size:
            self.buffer.pop(0)
        unique_labels = set(self.buffer)
        best_label, best_count = None, 0
        for candidate in unique_labels:
            count = self.buffer.count(candidate)
            if count > best_count:
                best_label, best_count = candidate, count
        confirmed = (
            best_label is not None
            and best_label != "UNKNOWN"
            and best_count >= self.min_votes
        )
        return confirmed, best_label if confirmed else label






from typing import Optional, Tuple
import cv2
import threading
import time


class ThreadedCapture:
    """Threaded camera reader keeping only the latest frame to reduce latency."""

    def __init__(self, index: int, fps: int = 30, width: int = None, height: int = None, force_mjpg: bool = True) -> None:
        self.cap = cv2.VideoCapture(index)
        if not self.cap.isOpened():
            raise RuntimeError("Unable to open camera")
        try:
            self.cap.set(cv2.CAP_PROP_FPS, float(fps))
        except Exception:
            pass
        try:
            self.cap.set(cv2.CAP_PROP_BUFFERSIZE, 1)
        except Exception:
            pass
        if force_mjpg:
            try:
                fourcc = cv2.VideoWriter_fourcc(*"MJPG")
                self.cap.set(cv2.CAP_PROP_FOURCC, fourcc)
            except Exception:
                pass
        if width is not None:
            try:
                self.cap.set(cv2.CAP_PROP_FRAME_WIDTH, float(width))
            except Exception:
                pass
        if height is not None:
            try:
                self.cap.set(cv2.CAP_PROP_FRAME_HEIGHT, float(height))
            except Exception:
                pass

        self.ok = False
        self.latest = None
        self.stopped = False
        self.lock = threading.Lock()
        self.thread = threading.Thread(target=self._loop, daemon=True)

    def start(self) -> "ThreadedCapture":
        self.thread.start()
        # Warm up to acquire first frame
        for _ in range(100):
            ok, frame = self.read()
            if ok and frame is not None:
                break
            time.sleep(0.05)
        return self

    def _loop(self) -> None:
        while not self.stopped:
            ok, frame = self.cap.read()
            with self.lock:
                self.ok = ok
                self.latest = None if not ok else frame
            time.sleep(0.001)

    def read(self) -> Tuple[bool, Optional["cv2.typing.MatLike"]]:
        with self.lock:
            return self.ok, None if self.latest is None else self.latest.copy()

    def stop(self) -> None:
        self.stopped = True
        try:
            self.thread.join(timeout=0.5)
        except Exception:
            pass
        self.cap.release()






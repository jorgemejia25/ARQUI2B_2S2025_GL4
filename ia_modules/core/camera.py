"""
Shared camera manager for thread-safe video capture
"""
import cv2
import threading
import time
from typing import Optional
import numpy as np


class SharedCamera:
    """Thread-safe camera manager that provides frames to multiple consumers"""
    
    def __init__(self, camera_id: int = 0, fps: int = 30, width: int = 640, height: int = 480):
        self.camera_id = camera_id
        self.fps = fps
        self.width = width
        self.height = height
        
        self._cap: Optional[cv2.VideoCapture] = None
        self._frame: Optional[np.ndarray] = None
        self._lock = threading.Lock()
        self._thread: Optional[threading.Thread] = None
        self._running = False
        self._frame_count = 0
        
    def start(self) -> bool:
        """Start camera capture thread"""
        if self._running:
            return True
            
        self._cap = cv2.VideoCapture(self.camera_id)
        if not self._cap.isOpened():
            print(f"[Camera] Failed to open camera {self.camera_id}")
            return False
            
        # Configure camera
        self._cap.set(cv2.CAP_PROP_FRAME_WIDTH, self.width)
        self._cap.set(cv2.CAP_PROP_FRAME_HEIGHT, self.height)
        self._cap.set(cv2.CAP_PROP_FPS, self.fps)
        
        self._running = True
        self._thread = threading.Thread(target=self._capture_loop, daemon=True)
        self._thread.start()
        
        print(f"[Camera] Started: {self.width}x{self.height} @ {self.fps}fps")
        return True
    
    def stop(self):
        """Stop camera capture"""
        self._running = False
        if self._thread:
            self._thread.join(timeout=2.0)
        if self._cap:
            self._cap.release()
            self._cap = None
        print("[Camera] Stopped")
    
    def _capture_loop(self):
        """Main capture loop - runs in separate thread"""
        frame_delay = 1.0 / self.fps
        
        while self._running:
            start = time.time()
            
            if self._cap and self._cap.isOpened():
                ret, frame = self._cap.read()
                if ret and frame is not None:
                    with self._lock:
                        self._frame = frame.copy()
                        self._frame_count += 1
                else:
                    time.sleep(0.05)
                    continue
            
            # Maintain target FPS
            elapsed = time.time() - start
            sleep_time = max(0, frame_delay - elapsed)
            if sleep_time > 0:
                time.sleep(sleep_time)
    
    def read(self) -> tuple[bool, Optional[np.ndarray]]:
        """Read the latest frame (thread-safe)"""
        with self._lock:
            if self._frame is not None:
                return True, self._frame.copy()
            return False, None
    
    @property
    def is_running(self) -> bool:
        """Check if camera is running"""
        return self._running
    
    @property
    def frame_count(self) -> int:
        """Get total frames captured"""
        return self._frame_count


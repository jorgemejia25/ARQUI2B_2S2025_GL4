"""
Base module interface for AI processing modules
"""
from abc import ABC, abstractmethod
from typing import Dict, Any, Optional
import numpy as np


class BaseModule(ABC):
    """Base class for all AI modules"""
    
    def __init__(self, name: str, enabled: bool = True):
        self.name = name
        self.enabled = enabled
        self.initialized = False
    
    @abstractmethod
    def setup(self) -> bool:
        """
        Initialize module resources
        Returns True if successful
        """
        pass
    
    @abstractmethod
    def process(self, frame: np.ndarray, frame_id: int) -> Dict[str, Any]:
        """
        Process a single frame
        
        Args:
            frame: Input frame (BGR format)
            frame_id: Frame sequence number
            
        Returns:
            Dictionary with processing results
        """
        pass
    
    def shutdown(self):
        """Cleanup module resources (override if needed)"""
        pass
    
    def draw(self, frame: np.ndarray, results: Dict[str, Any]) -> np.ndarray:
        """
        Draw results on frame (optional, override if needed)
        
        Args:
            frame: Frame to draw on
            results: Results from process()
            
        Returns:
            Modified frame
        """
        return frame
    
    def get_info(self) -> Dict[str, Any]:
        """Get module information"""
        return {
            "name": self.name,
            "enabled": self.enabled,
            "initialized": self.initialized
        }


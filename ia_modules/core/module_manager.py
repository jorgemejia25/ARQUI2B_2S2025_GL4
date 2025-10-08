"""
Module manager for coordinating AI modules
"""
import time
from typing import List, Dict, Any
import numpy as np

try:
    from .module_base import BaseModule
    from .camera import SharedCamera
except ImportError:
    from module_base import BaseModule
    from camera import SharedCamera


class ModuleManager:
    """Manages and coordinates multiple AI modules"""
    
    def __init__(self, camera: SharedCamera):
        self.camera = camera
        self.modules: List[BaseModule] = []
        self._running = False
    
    def add_module(self, module: BaseModule) -> bool:
        """
        Add and initialize a new module
        
        Args:
            module: Module instance to add
            
        Returns:
            True if module was added successfully
        """
        if module.setup():
            module.initialized = True
            self.modules.append(module)
            print(f"[ModuleManager] Added module: {module.name}")
            return True
        else:
            print(f"[ModuleManager] Failed to initialize: {module.name}")
            return False
    
    def remove_module(self, module_name: str) -> bool:
        """Remove a module by name"""
        for i, module in enumerate(self.modules):
            if module.name == module_name:
                module.shutdown()
                self.modules.pop(i)
                print(f"[ModuleManager] Removed module: {module_name}")
                return True
        return False
    
    def process_frame(self, frame: np.ndarray, frame_id: int) -> Dict[str, Any]:
        """
        Process frame through all enabled modules
        
        Args:
            frame: Input frame
            frame_id: Frame sequence number
            
        Returns:
            Dictionary mapping module names to their results
        """
        results = {}
        
        for module in self.modules:
            if module.enabled and module.initialized:
                try:
                    module_results = module.process(frame, frame_id)
                    results[module.name] = module_results
                except Exception as e:
                    print(f"[ModuleManager] Error in {module.name}: {e}")
                    results[module.name] = {"error": str(e)}
        
        return results
    
    def draw_results(self, frame: np.ndarray, all_results: Dict[str, Any]) -> np.ndarray:
        """
        Draw all module results on frame
        
        Args:
            frame: Frame to draw on
            all_results: Results from all modules
            
        Returns:
            Frame with overlays
        """
        display_frame = frame.copy()
        
        for module in self.modules:
            if module.enabled and module.name in all_results:
                try:
                    display_frame = module.draw(display_frame, all_results[module.name])
                except Exception as e:
                    print(f"[ModuleManager] Draw error in {module.name}: {e}")
        
        return display_frame
    
    def enable_module(self, module_name: str):
        """Enable a module by name"""
        for module in self.modules:
            if module.name == module_name:
                module.enabled = True
                print(f"[ModuleManager] Enabled: {module_name}")
                return
    
    def disable_module(self, module_name: str):
        """Disable a module by name"""
        for module in self.modules:
            if module.name == module_name:
                module.enabled = False
                print(f"[ModuleManager] Disabled: {module_name}")
                return
    
    def get_status(self) -> Dict[str, Any]:
        """Get status of all modules"""
        return {
            "total_modules": len(self.modules),
            "camera_running": self.camera.is_running,
            "frame_count": self.camera.frame_count,
            "modules": [m.get_info() for m in self.modules]
        }
    
    def print_status(self):
        """Print formatted status"""
        status = self.get_status()
        print("\n" + "="*60)
        print("MODULE MANAGER STATUS")
        print("="*60)
        print(f"Camera: {'Running' if status['camera_running'] else 'Stopped'}")
        print(f"Total Frames: {status['frame_count']}")
        print(f"Modules: {status['total_modules']}")
        
        for module_info in status['modules']:
            state = "ENABLED" if module_info['enabled'] else "DISABLED"
            init = "READY" if module_info['initialized'] else "NOT READY"
            print(f"  - {module_info['name']}: {state} | {init}")
        
        print("="*60 + "\n")
    
    def shutdown_all(self):
        """Shutdown all modules"""
        for module in self.modules:
            try:
                module.shutdown()
            except Exception as e:
                print(f"[ModuleManager] Shutdown error in {module.name}: {e}")
        
        self.modules.clear()
        print("[ModuleManager] All modules shut down")

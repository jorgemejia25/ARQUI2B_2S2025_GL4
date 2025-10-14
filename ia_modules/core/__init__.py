"""
Core components for the AI Modules System
"""
try:
    from .camera import SharedCamera
    from .module_base import BaseModule
    from .module_manager import ModuleManager
except ImportError:
    from camera import SharedCamera
    from module_base import BaseModule
    from module_manager import ModuleManager

__all__ = ['SharedCamera', 'BaseModule', 'ModuleManager']

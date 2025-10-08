"""
AI Modules System
A modular framework for AI processing with shared camera access
"""
__version__ = "1.0.0"
__author__ = "USAC Arqui2 Team"

from .core import SharedCamera, BaseModule, ModuleManager

__all__ = ['SharedCamera', 'BaseModule', 'ModuleManager']


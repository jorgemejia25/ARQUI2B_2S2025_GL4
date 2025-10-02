"""
Logging configuration
"""

import logging
import sys
from app.core.config import app_settings


def setup_logging() -> None:
    """Configure application logging"""
    
    logging.basicConfig(
        level=getattr(logging, app_settings.LOG_LEVEL),
        format=app_settings.LOG_FORMAT,
        handlers=[
            logging.StreamHandler(sys.stdout)
        ]
    )


def get_logger(name: str) -> logging.Logger:
    """Get a logger instance"""
    return logging.getLogger(name)


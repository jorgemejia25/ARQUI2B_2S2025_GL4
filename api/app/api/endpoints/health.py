"""
Health check endpoints
"""

from fastapi import APIRouter, Depends
from typing import Dict

from app.core.config import settings
from app.api.dependencies import get_mqtt_service, get_websocket_service

router = APIRouter()


@router.get("/health", tags=["health"])
async def health_check() -> Dict:
    """Basic health check endpoint"""
    return {
        "status": "healthy",
        "app_name": settings.APP_NAME,
        "version": settings.APP_VERSION
    }


@router.get("/health/detailed", tags=["health"])
async def detailed_health_check(
    mqtt_service=Depends(get_mqtt_service),
    websocket_service=Depends(get_websocket_service)
) -> Dict:
    """Detailed health check with service status"""
    return {
        "status": "healthy",
        "app_name": settings.APP_NAME,
        "version": settings.APP_VERSION,
        "services": {
            "mqtt": {
                "connected": mqtt_service.is_connected(),
                "broker": settings.MQTT_BROKER,
                "port": settings.MQTT_PORT
            },
            "websocket": {
                "connections": websocket_service.get_stats()
            },
            "database": {
                "path": settings.DATABASE_PATH
            }
        }
    }





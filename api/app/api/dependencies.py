"""
Dependency injection for API endpoints
Provides shared instances of services and repositories
"""

from typing import Generator
from app.db.connection import DatabaseConnection
from app.db.repositories.alert_repository import AlertRepository
from app.db.repositories.dashboard_repository import DashboardRepository
from app.services.mqtt_service import MQTTService
from app.services.websocket_service import WebSocketService

# Global service instances
_mqtt_service = None
_websocket_service = None


def get_mqtt_service() -> MQTTService:
    """Get MQTT service instance"""
    global _mqtt_service
    if _mqtt_service is None:
        _mqtt_service = MQTTService()
    return _mqtt_service


def get_websocket_service() -> WebSocketService:
    """Get WebSocket service instance"""
    global _websocket_service
    if _websocket_service is None:
        _websocket_service = WebSocketService()
    return _websocket_service


def get_db_connection() -> Generator[DatabaseConnection, None, None]:
    """Get database connection"""
    db = DatabaseConnection()
    db.connect()
    try:
        yield db
    finally:
        db.disconnect()


def get_alert_repository() -> Generator[AlertRepository, None, None]:
    """Get alert repository"""
    db = DatabaseConnection()
    db.connect()
    try:
        yield AlertRepository(db)
    finally:
        db.disconnect()


def get_dashboard_repository() -> Generator[DashboardRepository, None, None]:
    """Get dashboard repository"""
    db = DatabaseConnection()
    db.connect()
    try:
        yield DashboardRepository(db)
    finally:
        db.disconnect()


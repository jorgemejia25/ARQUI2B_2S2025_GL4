"""
Rutas del API IoT - Puente MQTT
"""

from fastapi import APIRouter
from typing import Dict, Any

router = APIRouter()

@router.get("/")
def read_root():
    """Endpoint raíz del API"""
    return {
        "mensaje": "API IoT - Puente MQTT funcionando",
        "status": "conectado",
        "version": "1.0.0"
    }

@router.get("/status")
def get_status():
    """Endpoint para verificar el estado general del API"""
    from main import mqtt_handler
    
    return {
        "mqtt_connected": mqtt_handler.is_connected(),
        "broker": f"{mqtt_handler.broker}:{mqtt_handler.port}",
        "topics_count": len(mqtt_handler.topics),
        "topics": mqtt_handler.topics
    }

@router.get("/debug/received")
def get_received_data():
    """Endpoint para debugging - muestra los últimos datos recibidos por MQTT"""
    from main import mqtt_handler
    
    return {
        "total_received": mqtt_handler.get_total_received(),
        "last_10_messages": mqtt_handler.get_last_messages(10)
    }

@router.get("/debug/mqtt-test")
def test_mqtt_connection():
    """Endpoint para probar la conexión MQTT"""
    from main import mqtt_handler
    
    return {
        "mqtt_connected": mqtt_handler.is_connected(),
        "broker": f"{mqtt_handler.broker}:{mqtt_handler.port}",
        "client_id": mqtt_handler.get_client_id(),
        "topics_subscribed": mqtt_handler.topics,
        "connection_status": "Connected" if mqtt_handler.is_connected() else "Disconnected"
    }

@router.post("/debug/clear")
def clear_received_data():
    """Endpoint para limpiar el historial de eventos recibidos"""
    from main import mqtt_handler
    
    mqtt_handler.clear_received_data()
    
    return {
        "mensaje": "Historial de eventos limpiado",
        "total_received": mqtt_handler.get_total_received()
    }

@router.get("/debug/database-stats")
def get_database_stats():
    """Endpoint para obtener estadísticas de la base de datos"""
    from main import mqtt_handler
    
    stats = mqtt_handler.get_database_stats()
    return stats

@router.get("/debug/websocket-stats")
def get_websocket_stats():
    """Endpoint para obtener estadísticas de WebSocket"""
    from main import websocket_manager
    
    return {
        "total_connections": websocket_manager.get_total_connections(),
        "connections_by_type": websocket_manager.get_connection_count()
    }


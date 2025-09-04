"""
Utilidades del API IoT - Puente MQTT
"""

import json
import time
from typing import Dict, Any, Optional
from datetime import datetime

def format_timestamp(timestamp: float) -> str:
    """Formatear timestamp a string legible"""
    return datetime.fromtimestamp(timestamp).strftime('%Y-%m-%d %H:%M:%S')

def validate_json_payload(payload: str) -> Optional[Dict[str, Any]]:
    """Validar y parsear payload JSON"""
    try:
        return json.loads(payload)
    except json.JSONDecodeError:
        return None

def create_response(success: bool, message: str, data: Any = None) -> Dict[str, Any]:
    """Crear respuesta estandarizada del API"""
    response = {
        "success": success,
        "message": message,
        "timestamp": time.time()
    }
    
    if data is not None:
        response["data"] = data
        
    return response

def sanitize_topic(topic: str) -> str:
    """Sanitizar tópico MQTT para uso seguro"""
    # Remover caracteres peligrosos
    dangerous_chars = ['<', '>', '"', "'", '&']
    sanitized = topic
    for char in dangerous_chars:
        sanitized = sanitized.replace(char, '')
    
    return sanitized

def parse_mqtt_topic(topic: str) -> Dict[str, str]:
    """Parsear tópico MQTT para extraer información"""
    parts = topic.split('/')
    
    if topic == "arduino/data":
        return {
            "device_type": "arduino",
            "data_type": "sensor_data"
        }
    elif topic.startswith("iot/bus/"):
        if len(parts) >= 4:
            return {
                "device_type": "bus",
                "bus_id": parts[2],
                "data_type": parts[3]
            }
    elif topic.startswith("iot/sensor/"):
        if len(parts) >= 4:
            return {
                "device_type": "sensor",
                "sensor_type": parts[2],
                "data_type": parts[3]
            }
    
    return {
        "device_type": "unknown",
        "data_type": "unknown"
    }

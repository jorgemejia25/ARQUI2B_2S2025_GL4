"""
Configuración del API IoT - Puente MQTT
"""

SERVER_HOST = "0.0.0.0"
SERVER_PORT = 8001

MQTT_BROKER = "192.168.1.181"
MQTT_PORT = 1883
MQTT_TOPICS = [
    "arduino/data",
]

LOG_LEVEL = "INFO"
LOG_FORMAT = "%(asctime)s - %(name)s - %(levelname)s - %(message)s"

CORS_ORIGINS = ["*"]
CORS_CREDENTIALS = True
CORS_METHODS = ["*"]
CORS_HEADERS = ["*"]

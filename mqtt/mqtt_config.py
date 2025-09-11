"""
Configuración centralizada para MQTT usando variables de entorno.
Este archivo puede ser importado por todos los módulos que necesiten configuración MQTT.
"""

import os
from dotenv import load_dotenv

# Cargar variables de entorno desde .env
load_dotenv()

# Configuración MQTT
MQTT_BROKER = os.getenv("MQTT_BROKER", "localhost")
MQTT_PORT = int(os.getenv("MQTT_PORT", "1883"))
MQTT_USERNAME = os.getenv("MQTT_USERNAME", "")
MQTT_PASSWORD = os.getenv("MQTT_PASSWORD", "")
MQTT_TOPIC = os.getenv("MQTT_TOPIC", "arduino/data")

# Configuración adicional
MQTT_CLIENT_ID_PREFIX = os.getenv("MQTT_CLIENT_ID_PREFIX", "arduino")
MQTT_KEEPALIVE = int(os.getenv("MQTT_KEEPALIVE", "60"))
MQTT_QOS = int(os.getenv("MQTT_QOS", "0"))

def get_mqtt_config():
    """
    Retorna un diccionario con toda la configuración MQTT.
    
    Returns:
        dict: Configuración MQTT completa
    """
    return {
        "broker": MQTT_BROKER,
        "port": MQTT_PORT,
        "username": MQTT_USERNAME,
        "password": MQTT_PASSWORD,
        "topic": MQTT_TOPIC,
        "client_id_prefix": MQTT_CLIENT_ID_PREFIX,
        "keepalive": MQTT_KEEPALIVE,
        "qos": MQTT_QOS
    }

def print_mqtt_config():
    """
    Imprime la configuración MQTT actual (sin mostrar contraseñas).
    """
    config = get_mqtt_config()
    print("=== Configuración MQTT ===")
    print(f"Broker: {config['broker']}")
    print(f"Puerto: {config['port']}")
    print(f"Usuario: {config['username'] if config['username'] else 'No configurado'}")
    print(f"Contraseña: {'***' if config['password'] else 'No configurada'}")
    print(f"Tópico: {config['topic']}")
    print(f"Prefijo Cliente: {config['client_id_prefix']}")
    print(f"Keepalive: {config['keepalive']} segundos")
    print(f"QoS: {config['qos']}")
    print("=========================")

if __name__ == "__main__":
    # Si se ejecuta directamente, mostrar la configuración
    print_mqtt_config()

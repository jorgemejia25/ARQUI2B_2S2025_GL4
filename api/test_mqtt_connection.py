#!/usr/bin/env python3
"""
Script de prueba para verificar la conexión MQTT del API
"""

import sys
import os
import time
import json
import logging

# Agregar el directorio actual al path para importar módulos
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from config import MQTT_BROKER, MQTT_PORT, MQTT_USERNAME, MQTT_PASSWORD, MQTT_TOPICS
from mqtt_handler import MQTTHandler

# Configurar logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

def test_mqtt_connection():
    """Probar la conexión MQTT del API"""
    print("=== PRUEBA DE CONEXIÓN MQTT DEL API ===")
    print(f"Broker: {MQTT_BROKER}")
    print(f"Puerto: {MQTT_PORT}")
    print(f"Usuario: {MQTT_USERNAME}")
    print(f"Contraseña: {'***' if MQTT_PASSWORD else 'No configurada'}")
    print(f"Tópicos: {MQTT_TOPICS}")
    print("=" * 50)
    
    # Crear instancia del manejador MQTT
    mqtt_handler = MQTTHandler(MQTT_BROKER, MQTT_PORT, MQTT_TOPICS)
    
    try:
        # Intentar conectar
        print("Intentando conectar al broker MQTT...")
        success = mqtt_handler.connect()
        
        if success:
            print("✓ Conexión MQTT exitosa!")
            print(f"✓ Cliente ID: {mqtt_handler.get_client_id()}")
            print(f"✓ Estado de conexión: {mqtt_handler.is_connected()}")
            
            # Esperar un poco para recibir mensajes
            print("\nEsperando mensajes por 10 segundos...")
            print("(Envía datos desde el Arduino o usa el simulador)")
            
            start_time = time.time()
            initial_count = mqtt_handler.get_total_received()
            
            while time.time() - start_time < 10:
                current_count = mqtt_handler.get_total_received()
                if current_count > initial_count:
                    print(f"✓ Mensaje recibido! Total: {current_count}")
                    # Mostrar el último mensaje
                    last_messages = mqtt_handler.get_last_messages(1)
                    if last_messages:
                        msg = last_messages[0]
                        print(f"  Tópico: {msg['topic']}")
                        print(f"  Timestamp: {msg['timestamp']}")
                        print(f"  Datos: {json.dumps(msg['payload'], indent=2)}")
                time.sleep(1)
            
            final_count = mqtt_handler.get_total_received()
            print(f"\nTotal de mensajes recibidos: {final_count}")
            
            if final_count == 0:
                print("⚠ No se recibieron mensajes. Verifica que:")
                print("  - El broker MQTT esté funcionando")
                print("  - Las credenciales sean correctas")
                print("  - Haya datos siendo publicados en el tópico")
            
        else:
            print("✗ Error al conectar al broker MQTT")
            print("Verifica:")
            print("  - La dirección del broker")
            print("  - El puerto")
            print("  - Las credenciales de autenticación")
            print("  - La conectividad de red")
            
    except Exception as e:
        print(f"✗ Error durante la prueba: {e}")
        logger.error(f"Error en la prueba de conexión: {e}")
        
    finally:
        # Desconectar
        print("\nDesconectando...")
        mqtt_handler.disconnect()
        print("✓ Desconexión completada")

def test_configuration():
    """Probar la configuración cargada"""
    print("\n=== VERIFICACIÓN DE CONFIGURACIÓN ===")
    print(f"MQTT_BROKER: {MQTT_BROKER}")
    print(f"MQTT_PORT: {MQTT_PORT}")
    print(f"MQTT_USERNAME: {MQTT_USERNAME}")
    print(f"MQTT_PASSWORD: {'Configurada' if MQTT_PASSWORD else 'No configurada'}")
    print(f"MQTT_TOPICS: {MQTT_TOPICS}")
    
    # Verificar que las variables estén configuradas
    if not MQTT_BROKER:
        print("⚠ MQTT_BROKER no está configurado")
    if not MQTT_PORT:
        print("⚠ MQTT_PORT no está configurado")
    if not MQTT_USERNAME:
        print("⚠ MQTT_USERNAME no está configurado")
    if not MQTT_PASSWORD:
        print("⚠ MQTT_PASSWORD no está configurado")
    
    print("=" * 50)

if __name__ == "__main__":
    test_configuration()
    test_mqtt_connection()

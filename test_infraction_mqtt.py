#!/usr/bin/env python3
"""
Script de prueba para verificar que las infracciones lleguen del MQTT Python al API.
"""

import paho.mqtt.client as mqtt
import json
import time

# Configuración MQTT (misma que usa el API)
MQTT_BROKER = "trolley.proxy.rlwy.net"
MQTT_PORT = 55424
MQTT_USERNAME = "jorge"
MQTT_PASSWORD = "34eikykmbd8w5igpjiebialeisx0yu02"

def test_infraction_publishing():
    """Probar publicación de infracción simulada"""
    
    # Crear cliente MQTT
    client = mqtt.Client()
    client.username_pw_set(MQTT_USERNAME, MQTT_PASSWORD)
    
    try:
        print(f"Conectando a {MQTT_BROKER}:{MQTT_PORT}...")
        client.connect(MQTT_BROKER, MQTT_PORT, 60)
        
        # Datos de infracción simulada (igual formato que mqtt/main.py)
        infraction_data = {
            "timestamp": time.time(),
            "alert_type": "INFRACCION",
            "sensor_id": "SD1",
            "semaforo_id": "S3",
            "distancia_cm": 5.2,
            "severity": 4
        }
        
        # Publicar en el tópico de infracciones
        topic = "arduino/data/infracciones"
        message = json.dumps(infraction_data, indent=2)
        
        print(f"\n🚨 PUBLICANDO INFRACCIÓN DE PRUEBA:")
        print(f"Tópico: {topic}")
        print(f"Datos: {infraction_data}")
        
        result = client.publish(topic, message)
        
        if result.rc == mqtt.MQTT_ERR_SUCCESS:
            print("✅ Infracción publicada exitosamente")
        else:
            print(f"❌ Error publicando: {result.rc}")
            
        # También publicar en tópico principal para comparar
        topic_main = "arduino/data"
        main_data = {
            "ts": str(int(time.time())),
            "semaforos": {"S1": "VERDE", "S2": "ROJO", "S3": "ROJO"},
            "infracciones": ["S3"],  # Array como en Arduino
            "_protocol_version": "1.1"
        }
        
        print(f"\n📡 PUBLICANDO DATOS PRINCIPALES:")
        print(f"Tópico: {topic_main}")
        print(f"Infracciones en array: {main_data['infracciones']}")
        
        result2 = client.publish(topic_main, json.dumps(main_data, indent=2))
        
        if result2.rc == mqtt.MQTT_ERR_SUCCESS:
            print("✅ Datos principales publicados exitosamente")
        else:
            print(f"❌ Error publicando datos principales: {result2.rc}")
        
        time.sleep(2)
        client.disconnect()
        
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    print("=== PRUEBA DE INFRACCIONES MQTT ===")
    test_infraction_publishing()
    print("\n=== PRUEBA COMPLETADA ===")
    print("\nVerifica los logs del API para confirmar recepción:")
    print("- Debe aparecer: '🚨🚨🚨 INFRACCIÓN RECIBIDA EN API 🚨🚨🚨'")
    print("- Debe aparecer: '🚨 CAMPO INFRACCIONES ENCONTRADO: [\"S3\"]'")

#!/usr/bin/env python3
"""
Cliente MQTT simple para probar la funcionalidad del broker Mosquitto.
"""

import paho.mqtt.client as mqtt
import time
import json

# Configuración MQTT
MQTT_BROKER = "localhost"
MQTT_PORT = 1883
MQTT_TOPIC = "arduino/data"
MQTT_CLIENT_ID = "test_client"

def on_connect(client, userdata, flags, rc):
    """Callback cuando se conecta al broker."""
    if rc == 0:
        print(f"Conectado exitosamente al broker MQTT")
        # Suscribirse al tópico
        client.subscribe(MQTT_TOPIC)
        print(f"Suscrito al tópico: {MQTT_TOPIC}")
    else:
        print(f"Error al conectar, código: {rc}")

def on_message(client, userdata, msg):
    """Callback cuando se recibe un mensaje."""
    print(f"Mensaje recibido en {msg.topic}: {msg.payload.decode()}")

def on_disconnect(client, userdata, rc):
    """Callback cuando se desconecta del broker."""
    print("Desconectado del broker MQTT")

def main():
    """Función principal."""
    print("=== Cliente MQTT de Prueba ===")
    
    # Crear cliente MQTT
    client = mqtt.Client(MQTT_CLIENT_ID)
    
    # Configurar callbacks
    client.on_connect = on_connect
    client.on_message = on_message
    client.on_disconnect = on_disconnect
    
    try:
        # Conectar al broker
        print(f"Conectando a {MQTT_BROKER}:{MQTT_PORT}...")
        client.connect(MQTT_BROKER, MQTT_PORT, 60)
        
        # Iniciar loop en background
        client.loop_start()
        
        # Esperar un poco para la conexión
        time.sleep(2)
        
        # Enviar mensaje de prueba
        test_message = {
            "timestamp": time.time(),
            "type": "test",
            "message": "Hola desde cliente MQTT de prueba"
        }
        
        print(f"Enviando mensaje de prueba...")
        client.publish(MQTT_TOPIC, json.dumps(test_message))
        
        # Mantener ejecutando por 10 segundos
        print("Esperando mensajes por 10 segundos...")
        time.sleep(10)
        
    except KeyboardInterrupt:
        print("\nInterrupción de teclado recibida")
    except Exception as e:
        print(f"Error: {e}")
    finally:
        # Limpiar
        client.loop_stop()
        client.disconnect()
        print("Cliente MQTT cerrado")

if __name__ == "__main__":
    main()

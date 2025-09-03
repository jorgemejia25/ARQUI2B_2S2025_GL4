#!/usr/bin/env python3
"""
Cliente MQTT que publica datos simulados del Arduino.
"""

import paho.mqtt.client as mqtt
import time
import json
import random
from datetime import datetime

# Configuración MQTT
MQTT_BROKER = "localhost"
MQTT_PORT = 1883
MQTT_TOPIC = "arduino/data"
MQTT_CLIENT_ID = "arduino_simulator"

class ArduinoMQTTPublisher:
    """Publicador MQTT para datos simulados del Arduino."""
    
    def __init__(self):
        self.client = mqtt.Client(MQTT_CLIENT_ID)
        self.running = False
        
        # Configurar callbacks
        self.client.on_connect = self.on_connect
        self.client.on_disconnect = self.on_disconnect
        
    def on_connect(self, client, userdata, flags, rc):
        """Callback cuando se conecta al broker."""
        if rc == 0:
            print(f"Conectado exitosamente al broker MQTT")
            print(f"Publicando en tópico: {MQTT_TOPIC}")
        else:
            print(f"Error al conectar, código: {rc}")
    
    def on_disconnect(self, client, userdata, rc):
        """Callback cuando se desconecta del broker."""
        print("Desconectado del broker MQTT")
    
    def connect(self):
        """Conectar al broker MQTT."""
        try:
            print(f"Conectando a {MQTT_BROKER}:{MQTT_PORT}...")
            self.client.connect(MQTT_BROKER, MQTT_PORT, 60)
            self.client.loop_start()
            return True
        except Exception as e:
            print(f"Error al conectar: {e}")
            return False
    
    def disconnect(self):
        """Desconectar del broker MQTT."""
        self.running = False
        self.client.loop_stop()
        self.client.disconnect()
        print("Desconectado del broker MQTT")
    
    def generate_simulated_data(self):
        """Genera datos simulados del Arduino."""
        timestamp = datetime.now().isoformat()
        
        # Simular datos de semáforos
        semaforos = []
        for i in range(random.randint(3, 8)):
            estado = random.choice(["verde", "amarillo", "rojo"])
            semaforos.append({
                "id": f"sem_{i+1}",
                "estado": estado,
                "ubicacion": f"Intersección {i+1}"
            })
        
        # Simular datos de distancias
        distancias = []
        for i in range(random.randint(2, 5)):
            distancias.append({
                "id": f"dist_{i+1}",
                "distancia_cm": random.uniform(5.0, 200.0),
                "zona": f"Zona {i+1}"
            })
        
        # Simular datos de gas
        gas = []
        for i in range(random.randint(1, 3)):
            ppm = random.uniform(100, 800)
            gas.append({
                "zona": f"Zona {i+1}",
                "ppm": round(ppm, 2),
                "is_alto": ppm > 500
            })
        
        # Simular datos de sismo
        tiene_sismo = random.random() < 0.1  # 10% de probabilidad
        sismo = None
        if tiene_sismo:
            sismo = {
                "magnitud": round(random.uniform(2.0, 6.0), 1),
                "origen": random.choice(["Norte", "Sur", "Este", "Oeste", "Centro"])
            }
        
        # Simular datos de botones de pánico
        botones_panico = []
        if random.random() < 0.05:  # 5% de probabilidad
            botones_panico.append({
                "id": f"btn_{random.randint(1, 5)}",
                "ubicacion": f"Ubicación {random.randint(1, 10)}"
            })
        
        # Simular datos de infracciones
        infracciones = []
        if random.random() < 0.15:  # 15% de probabilidad
            tipos = ["Exceso de velocidad", "Semáforo en rojo", "Estacionamiento prohibido"]
            for _ in range(random.randint(1, 3)):
                infracciones.append({
                    "tipo": random.choice(tipos),
                    "timestamp": timestamp,
                    "ubicacion": f"Ubicación {random.randint(1, 20)}"
                })
        
        # Simular datos de ETA
        eta = []
        if random.random() < 0.7:  # 70% de probabilidad
            tipos_transporte = ["Bus", "Metro", "Tren"]
            for i in range(random.randint(1, 4)):
                eta.append({
                    "parada": f"Parada {i+1}",
                    "tipo_transporte": random.choice(tipos_transporte),
                    "tiempo_segundos": random.randint(30, 300),
                    "info": f"FROM=Origen{i+1},TO=Destino{i+1},ROUTE=Ruta{i+1}"
                })
        
        # Construir mensaje completo
        data = {
            "timestamp": timestamp,
            "protocol_version": "1.0",
            "semaforos": semaforos,
            "distancias": distancias,
            "gas": gas,
            "tiene_sismo": tiene_sismo,
            "sismo": sismo,
            "botones_panico_activos": botones_panico,
            "infracciones": infracciones,
            "eta": eta
        }
        
        return data
    
    def publish_data(self, data):
        """Publica datos en el tópico MQTT."""
        try:
            message = json.dumps(data, indent=2)
            result = self.client.publish(MQTT_TOPIC, message)
            
            if result.rc == mqtt.MQTT_ERR_SUCCESS:
                print(f"Datos publicados exitosamente - {data['timestamp']}")
                print(f"  Semáforos: {len(data['semaforos'])} | Distancias: {len(data['distancias'])}")
                print(f"  Gas: {len(data['gas'])} | Sismo: {'SÍ' if data['tiene_sismo'] else 'NO'}")
                print(f"  Infracciones: {len(data['infracciones'])} | ETA: {len(data['eta'])}")
            else:
                print(f"Error al publicar: {result.rc}")
                
        except Exception as e:
            print(f"Error al publicar datos: {e}")
    
    def run(self, interval=5):
        """Ejecuta el publicador MQTT."""
        if not self.connect():
            return
        
        self.running = True
        print(f"Publicando datos cada {interval} segundos...")
        print("Presiona Ctrl+C para detener")
        
        try:
            while self.running:
                # Generar y publicar datos
                data = self.generate_simulated_data()
                self.publish_data(data)
                
                # Esperar antes de la siguiente publicación
                time.sleep(interval)
                
        except KeyboardInterrupt:
            print("\nInterrupción de teclado recibida")
        finally:
            self.disconnect()

def main():
    """Función principal."""
    print("=== Publicador MQTT de Datos Simulados del Arduino ===")
    
    publisher = ArduinoMQTTPublisher()
    
    try:
        publisher.run(interval=5)  # Publicar cada 5 segundos
    except Exception as e:
        print(f"Error en la aplicación: {e}")
        publisher.disconnect()

if __name__ == "__main__":
    main()

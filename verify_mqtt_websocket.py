#!/usr/bin/env python3
"""
Script para verificar que las infracciones lleguen correctamente 
desde MQTT hasta WebSocket y Flutter
"""

import json
import time
import asyncio
import websockets
import paho.mqtt.client as mqtt
from datetime import datetime

# Configuración
MQTT_BROKER = "trolley.proxy.rlwy.net"  # Cambiar por localhost si es local
MQTT_PORT = 55424
MQTT_USERNAME = "jorge"
MQTT_PASSWORD = "34eikykmbd8w5igpjiebialeisx0yu02"
MQTT_TOPIC = "arduino/data/infracciones"

API_HOST = "localhost"  # Cambiar por IP de Raspberry Pi
API_PORT = 8001
WEBSOCKET_URL = f"ws://{API_HOST}:{API_PORT}/ws/alerts"

class MQTTWebSocketVerifier:
    def __init__(self):
        self.mqtt_client = None
        self.websocket = None
        self.mqtt_connected = False
        self.websocket_connected = False
        self.test_results = []
        
    def setup_mqtt(self):
        """Configura cliente MQTT"""
        print("📡 Configurando cliente MQTT...")
        
        self.mqtt_client = mqtt.Client()
        self.mqtt_client.username_pw_set(MQTT_USERNAME, MQTT_PASSWORD)
        
        def on_connect(client, userdata, flags, rc):
            if rc == 0:
                self.mqtt_connected = True
                print("✅ MQTT conectado exitosamente")
            else:
                print(f"❌ Error MQTT: {rc}")
        
        def on_disconnect(client, userdata, rc):
            self.mqtt_connected = False
            print(f"⚠️ MQTT desconectado: {rc}")
        
        self.mqtt_client.on_connect = on_connect
        self.mqtt_client.on_disconnect = on_disconnect
        
        try:
            self.mqtt_client.connect(MQTT_BROKER, MQTT_PORT, 60)
            self.mqtt_client.loop_start()
            
            # Esperar conexión
            timeout = 10
            while not self.mqtt_connected and timeout > 0:
                time.sleep(0.5)
                timeout -= 0.5
            
            return self.mqtt_connected
        except Exception as e:
            print(f"❌ Error conectando MQTT: {e}")
            return False
    
    async def setup_websocket(self):
        """Configura conexión WebSocket"""
        print(f"🔌 Conectando a WebSocket: {WEBSOCKET_URL}")
        
        try:
            self.websocket = await websockets.connect(WEBSOCKET_URL)
            self.websocket_connected = True
            print("✅ WebSocket conectado exitosamente")
            return True
        except Exception as e:
            print(f"❌ Error conectando WebSocket: {e}")
            return False
    
    def send_test_infraction(self, semaforo_id="S3", sensor_id="SD2"):
        """Envía una infracción de prueba por MQTT"""
        if not self.mqtt_connected:
            print("❌ MQTT no conectado")
            return False
        
        test_data = {
            "timestamp": time.time(),
            "alert_type": "INFRACCION",
            "sensor_id": sensor_id,
            "semaforo_id": semaforo_id,
            "distancia_cm": 6.1,
            "severity": 4,
            "signal_color": "red",
            "violation_type": "red_light",
            "origen": f"TEST - Sensor {sensor_id} - Infracción semáforo {semaforo_id}"
        }
        
        try:
            message = json.dumps(test_data, indent=2)
            result = self.mqtt_client.publish(MQTT_TOPIC, message)
            
            if result.rc == mqtt.MQTT_ERR_SUCCESS:
                print(f"📤 Infracción de prueba enviada: {semaforo_id}")
                print(f"   Datos: {json.dumps(test_data, indent=2)}")
                return True
            else:
                print(f"❌ Error enviando infracción: {result.rc}")
                return False
        except Exception as e:
            print(f"❌ Error enviando infracción: {e}")
            return False
    
    async def listen_websocket(self, duration=30):
        """Escucha mensajes del WebSocket"""
        if not self.websocket_connected:
            print("❌ WebSocket no conectado")
            return []
        
        print(f"👂 Escuchando WebSocket por {duration} segundos...")
        received_messages = []
        
        try:
            start_time = time.time()
            while time.time() - start_time < duration:
                try:
                    # Esperar mensaje con timeout
                    message = await asyncio.wait_for(
                        self.websocket.recv(), 
                        timeout=1.0
                    )
                    
                    # Parsear mensaje
                    try:
                        data = json.loads(message)
                        received_messages.append({
                            "timestamp": time.time(),
                            "data": data
                        })
                        
                        print(f"📥 Mensaje WebSocket recibido:")
                        print(f"   Tipo: {data.get('alert_type', 'unknown')}")
                        print(f"   Semáforo: {data.get('signal_id', 'unknown')}")
                        print(f"   Datos: {json.dumps(data, indent=2)}")
                        
                        # Verificar si es infracción
                        if data.get('alert_type') == 'INFRACCION':
                            print("✅ ¡INFRACCIÓN RECIBIDA EN WEBSOCKET!")
                        
                    except json.JSONDecodeError:
                        print(f"⚠️ Mensaje no JSON: {message}")
                        
                except asyncio.TimeoutError:
                    # Timeout normal, continuar
                    continue
                    
        except Exception as e:
            print(f"❌ Error escuchando WebSocket: {e}")
        
        return received_messages
    
    async def run_test(self):
        """Ejecuta prueba completa"""
        print("🧪 VERIFICACIÓN MQTT → WebSocket → Flutter")
        print("=" * 50)
        
        # 1. Configurar MQTT
        if not self.setup_mqtt():
            print("❌ Falló configuración MQTT")
            return False
        
        # 2. Configurar WebSocket
        if not await self.setup_websocket():
            print("❌ Falló configuración WebSocket")
            return False
        
        # 3. Iniciar escucha de WebSocket en background
        listen_task = asyncio.create_task(self.listen_websocket(20))
        
        # 4. Esperar un momento para estabilizar conexiones
        await asyncio.sleep(2)
        
        # 5. Enviar infracciones de prueba
        print("\n📤 Enviando infracciones de prueba...")
        
        test_infractions = [
            {"semaforo_id": "S3", "sensor_id": "SD2"},
            {"semaforo_id": "S7", "sensor_id": "SD4"},
            {"semaforo_id": "S1", "sensor_id": "SD1"}
        ]
        
        for i, infraction in enumerate(test_infractions, 1):
            print(f"\n🧪 Test {i}/3: {infraction['semaforo_id']} ← {infraction['sensor_id']}")
            success = self.send_test_infraction(**infraction)
            if success:
                print(f"   ✅ Enviado exitosamente")
            else:
                print(f"   ❌ Error enviando")
            
            # Esperar entre envíos
            await asyncio.sleep(3)
        
        # 6. Esperar a que termine la escucha
        print("\n👂 Esperando mensajes WebSocket...")
        received_messages = await listen_task
        
        # 7. Análisis de resultados
        print("\n" + "=" * 50)
        print("📊 RESULTADOS")
        print("=" * 50)
        
        print(f"📤 Infracciones enviadas por MQTT: {len(test_infractions)}")
        print(f"📥 Mensajes recibidos por WebSocket: {len(received_messages)}")
        
        # Analizar mensajes recibidos
        infractions_received = 0
        for msg in received_messages:
            data = msg["data"]
            if data.get("alert_type") == "INFRACCION":
                infractions_received += 1
                print(f"   ✅ Infracción: {data.get('signal_id', 'unknown')}")
        
        print(f"🎯 Infracciones recibidas en WebSocket: {infractions_received}")
        
        # Veredicto
        if infractions_received >= len(test_infractions):
            print("\n✅ PRUEBA EXITOSA: Las infracciones llegan correctamente a WebSocket")
            print("   Flutter debería recibirlas sin problemas")
        elif infractions_received > 0:
            print(f"\n⚠️ PRUEBA PARCIAL: Solo {infractions_received}/{len(test_infractions)} infracciones llegaron")
            print("   Verificar configuración o conectividad")
        else:
            print("\n❌ PRUEBA FALLIDA: No llegaron infracciones a WebSocket")
            print("   Verificar:")
            print("   1. API corriendo en puerto 8001")
            print("   2. MQTT handler procesando correctamente")
            print("   3. WebSocket manager funcionando")
        
        return infractions_received >= len(test_infractions)
    
    async def cleanup(self):
        """Limpia conexiones"""
        if self.websocket and self.websocket_connected:
            await self.websocket.close()
        
        if self.mqtt_client and self.mqtt_connected:
            self.mqtt_client.loop_stop()
            self.mqtt_client.disconnect()

async def main():
    """Función principal"""
    verifier = MQTTWebSocketVerifier()
    
    try:
        success = await verifier.run_test()
        
        if success:
            print("\n🎉 ¡Verificación completada exitosamente!")
        else:
            print("\n🔧 Se requieren ajustes en el sistema")
            
    except KeyboardInterrupt:
        print("\n⏹️ Prueba interrumpida por el usuario")
    except Exception as e:
        print(f"\n❌ Error en la verificación: {e}")
    finally:
        await verifier.cleanup()

if __name__ == "__main__":
    asyncio.run(main())

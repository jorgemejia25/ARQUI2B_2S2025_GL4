#!/usr/bin/env python3
"""
Script de diagnóstico para verificar la comunicación Arduino-MQTT
Útil para debuggear problemas en Raspberry Pi
"""

import serial
import serial.tools.list_ports
import time
import json
import sys
import paho.mqtt.client as mqtt
from datetime import datetime

# Configuraciones a probar
POSSIBLE_PORTS = ['/dev/ttyUSB0', '/dev/ttyACM0', '/dev/ttyAMA0', '/dev/serial0']
BAUDRATE = 115200
TIMEOUT = 2.0

# Configuración MQTT (ajustar según tu setup)
MQTT_BROKER = "localhost"  # Para Raspberry Pi local
MQTT_PORT = 1883
MQTT_TOPIC = "arduino/data"

class ArduinoMQTTDebugger:
    def __init__(self):
        self.serial_conn = None
        self.mqtt_client = None
        self.found_port = None
        self.data_count = 0
        self.infractions_count = 0
        
    def find_arduino_port(self):
        """Encuentra el puerto del Arduino"""
        print("🔍 Buscando puertos disponibles...")
        
        # Listar todos los puertos
        ports = serial.tools.list_ports.comports()
        print(f"Puertos encontrados: {len(ports)}")
        
        for port in ports:
            print(f"  - {port.device}: {port.description}")
        
        # Probar puertos comunes
        for port in POSSIBLE_PORTS:
            try:
                print(f"\n🔌 Probando puerto: {port}")
                ser = serial.Serial(port, BAUDRATE, timeout=TIMEOUT)
                time.sleep(2)  # Esperar reinicio de Arduino
                
                # Leer algunas líneas para verificar
                test_lines = []
                for _ in range(5):
                    if ser.in_waiting:
                        line = ser.readline().decode('utf-8', errors='ignore').strip()
                        if line:
                            test_lines.append(line)
                            print(f"  📄 Línea recibida: {line[:100]}...")
                
                if test_lines:
                    print(f"✅ Puerto {port} funciona - recibidas {len(test_lines)} líneas")
                    self.found_port = port
                    ser.close()
                    return port
                else:
                    print(f"⚠️ Puerto {port} abierto pero sin datos")
                    ser.close()
                    
            except serial.SerialException as e:
                print(f"❌ Error en {port}: {e}")
            except Exception as e:
                print(f"❌ Error inesperado en {port}: {e}")
        
        return None
    
    def connect_serial(self):
        """Conecta al puerto serial del Arduino"""
        if not self.found_port:
            port = self.find_arduino_port()
            if not port:
                print("❌ No se encontró Arduino en ningún puerto")
                return False
        
        try:
            print(f"\n🔌 Conectando a Arduino en {self.found_port}...")
            self.serial_conn = serial.Serial(self.found_port, BAUDRATE, timeout=TIMEOUT)
            time.sleep(3)  # Esperar reinicio
            
            # Limpiar buffers
            self.serial_conn.reset_input_buffer()
            self.serial_conn.reset_output_buffer()
            
            print("✅ Conexión serial establecida")
            return True
            
        except Exception as e:
            print(f"❌ Error conectando serial: {e}")
            return False
    
    def setup_mqtt(self):
        """Configura conexión MQTT"""
        try:
            print(f"\n📡 Configurando MQTT: {MQTT_BROKER}:{MQTT_PORT}")
            self.mqtt_client = mqtt.Client()
            
            def on_connect(client, userdata, flags, rc):
                if rc == 0:
                    print("✅ MQTT conectado exitosamente")
                else:
                    print(f"❌ Error MQTT: {rc}")
            
            def on_disconnect(client, userdata, rc):
                print(f"⚠️ MQTT desconectado: {rc}")
            
            self.mqtt_client.on_connect = on_connect
            self.mqtt_client.on_disconnect = on_disconnect
            
            self.mqtt_client.connect(MQTT_BROKER, MQTT_PORT, 60)
            self.mqtt_client.loop_start()
            
            time.sleep(2)  # Esperar conexión
            return True
            
        except Exception as e:
            print(f"❌ Error configurando MQTT: {e}")
            return False
    
    def publish_mqtt(self, data, topic_suffix=""):
        """Publica datos en MQTT"""
        if not self.mqtt_client:
            return False
        
        try:
            topic = MQTT_TOPIC + topic_suffix
            message = json.dumps(data, ensure_ascii=False)
            result = self.mqtt_client.publish(topic, message)
            
            if result.rc == mqtt.MQTT_ERR_SUCCESS:
                print(f"📤 MQTT enviado a {topic}")
                return True
            else:
                print(f"❌ Error MQTT publish: {result.rc}")
                return False
                
        except Exception as e:
            print(f"❌ Error publicando MQTT: {e}")
            return False
    
    def process_infraction_line(self, line):
        """Procesa líneas de infracción inmediata"""
        try:
            # Parsear: "INFRACCION ROJO SD1 -> Semaforo S3, cm=5.2"
            import re
            match = re.match(r'INFRACCION ROJO SD(\d+) -> Semaforo S(\d+), cm=([0-9.]+)', line)
            if match:
                sd_num = int(match.group(1))
                semaforo_id = f"S{match.group(2)}"
                distancia = float(match.group(3))
                
                print(f"\n🚨 INFRACCIÓN DETECTADA:")
                print(f"   Sensor: SD{sd_num}")
                print(f"   Semáforo: {semaforo_id}")
                print(f"   Distancia: {distancia}cm")
                
                # Crear datos de infracción para MQTT
                infraction_data = {
                    "timestamp": time.time(),
                    "alert_type": "INFRACCION",
                    "sensor_id": f"SD{sd_num}",
                    "semaforo_id": semaforo_id,
                    "distancia_cm": distancia,
                    "severity": 4,
                    "signal_color": "red",
                    "violation_type": "red_light",
                    "origen": f"Sensor SD{sd_num} - Infracción semáforo {semaforo_id}"
                }
                
                # Publicar inmediatamente
                self.publish_mqtt(infraction_data, "/infracciones")
                self.infractions_count += 1
                
                return True
        except Exception as e:
            print(f"❌ Error procesando infracción: {e}")
        
        return False
    
    def process_json_data(self, json_str):
        """Procesa datos JSON del Arduino"""
        try:
            data = json.loads(json_str)
            self.data_count += 1
            
            print(f"\n📊 DATOS JSON #{self.data_count}:")
            print(f"   Timestamp: {data.get('ts', 'N/A')}")
            print(f"   Semáforos: {len(data.get('semaforos', {}))}")
            print(f"   Distancias: {len(data.get('dist_cm', {}))}")
            print(f"   Gas: {len(data.get('gas_ppm', {}))}")
            print(f"   Infracciones: {len(data.get('infracciones', []))}")
            
            # Mostrar infracciones en JSON
            if data.get('infracciones'):
                print(f"   🚨 Infracciones en JSON: {data['infracciones']}")
            
            # Mostrar estados de semáforos
            semaforos = data.get('semaforos', {})
            if semaforos:
                rojos = [s for s, estado in semaforos.items() if estado == 'ROJO']
                if rojos:
                    print(f"   🔴 Semáforos en ROJO: {rojos}")
            
            # Publicar datos completos
            self.publish_mqtt(data)
            
            return True
            
        except json.JSONDecodeError as e:
            print(f"❌ Error JSON: {e}")
            return False
        except Exception as e:
            print(f"❌ Error procesando JSON: {e}")
            return False
    
    def monitor_arduino(self, duration=60):
        """Monitorea Arduino por un tiempo determinado"""
        if not self.serial_conn:
            print("❌ Sin conexión serial")
            return
        
        print(f"\n👀 Monitoreando Arduino por {duration} segundos...")
        print("Presiona Ctrl+C para detener\n")
        
        start_time = time.time()
        line_count = 0
        json_count = 0
        infraction_lines = 0
        
        try:
            while time.time() - start_time < duration:
                if self.serial_conn.in_waiting:
                    try:
                        raw_line = self.serial_conn.readline()
                        line = raw_line.decode('utf-8', errors='ignore').strip()
                        
                        if not line:
                            continue
                        
                        line_count += 1
                        
                        # Procesar líneas de infracción
                        if line.startswith('INFRACCION ROJO'):
                            infraction_lines += 1
                            self.process_infraction_line(line)
                            continue
                        
                        # Procesar JSON
                        if line.startswith('{'):
                            json_count += 1
                            self.process_json_data(line)
                            continue
                        
                        # Otras líneas (debug, etc.)
                        if line_count % 10 == 0:  # Mostrar cada 10 líneas
                            print(f"📄 Línea #{line_count}: {line[:80]}...")
                    
                    except Exception as e:
                        print(f"❌ Error leyendo línea: {e}")
                
                time.sleep(0.1)
        
        except KeyboardInterrupt:
            print("\n⏹️ Monitoreo interrumpido por el usuario")
        
        print(f"\n📈 RESUMEN DEL MONITOREO:")
        print(f"   Duración: {time.time() - start_time:.1f} segundos")
        print(f"   Líneas totales: {line_count}")
        print(f"   JSONs procesados: {json_count}")
        print(f"   Líneas de infracción: {infraction_lines}")
        print(f"   Infracciones enviadas por MQTT: {self.infractions_count}")
        print(f"   Datos JSON enviados por MQTT: {self.data_count}")
    
    def run_diagnosis(self):
        """Ejecuta diagnóstico completo"""
        print("🔧 DIAGNÓSTICO ARDUINO-MQTT")
        print("=" * 50)
        
        # 1. Encontrar y conectar Arduino
        if not self.connect_serial():
            return False
        
        # 2. Configurar MQTT
        if not self.setup_mqtt():
            print("⚠️ Continuando sin MQTT...")
        
        # 3. Monitorear por 30 segundos
        self.monitor_arduino(30)
        
        # 4. Cleanup
        if self.serial_conn:
            self.serial_conn.close()
        
        if self.mqtt_client:
            self.mqtt_client.loop_stop()
            self.mqtt_client.disconnect()
        
        print("\n✅ Diagnóstico completado")
        return True

def main():
    """Función principal"""
    if len(sys.argv) > 1:
        if sys.argv[1] == '--help':
            print("Uso: python test_arduino_mqtt_debug.py [--local|--railway]")
            print("  --local: Usar broker MQTT local (localhost:1883)")
            print("  --railway: Usar broker MQTT de Railway")
            return
        elif sys.argv[1] == '--railway':
            global MQTT_BROKER, MQTT_PORT
            MQTT_BROKER = "trolley.proxy.rlwy.net"
            MQTT_PORT = 55424
            print("🚂 Usando broker MQTT de Railway")
    
    debugger = ArduinoMQTTDebugger()
    debugger.run_diagnosis()

if __name__ == "__main__":
    main()

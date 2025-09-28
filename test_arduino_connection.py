#!/usr/bin/env python3
"""
Script de prueba para verificar la conexión con Arduino y el envío de infracciones.
"""

import time
import serial
import json
import sys
import os

# Agregar el directorio mqtt al path
sys.path.append(os.path.join(os.path.dirname(__file__), 'mqtt'))

from serial_receiver import ArduinoSerialReceiver, SerialConfig
from arduino_data_parser import parse_arduino_json

def test_serial_connection():
    """Prueba la conexión serial directa con Arduino."""
    print("=== PRUEBA DE CONEXIÓN SERIAL ===")
    
    # Configuración
    config = SerialConfig(
        port='/dev/ttyACM0',
        baudrate=115200,
        timeout=1.0
    )
    
    try:
        # Intentar conectar directamente
        ser = serial.Serial(
            port=config.port,
            baudrate=config.baudrate,
            timeout=config.timeout
        )
        
        print(f"✅ Conectado a {config.port} a {config.baudrate} baudios")
        
        # Leer datos por 10 segundos
        print("Leyendo datos por 10 segundos...")
        start_time = time.time()
        
        while time.time() - start_time < 10:
            if ser.in_waiting > 0:
                line = ser.readline().decode('utf-8', errors='ignore').strip()
                if line:
                    print(f"[{time.time():.2f}] {line}")
                    
                    # Verificar si es una infracción
                    if line.startswith('INFRACCION ROJO'):
                        print(f"🚨 INFRACCION DETECTADA: {line}")
                    
                    # Verificar si es JSON
                    if line.startswith('{'):
                        try:
                            data = json.loads(line)
                            if 'infracciones' in data and data['infracciones']:
                                print(f"🚨 INFRACCIONES EN JSON: {data['infracciones']}")
                        except json.JSONDecodeError:
                            pass
            
            time.sleep(0.1)
        
        ser.close()
        print("✅ Prueba de conexión serial completada")
        
    except serial.SerialException as e:
        print(f"❌ Error de conexión serial: {e}")
        print("Verifica que:")
        print("1. El Arduino esté conectado")
        print("2. El puerto /dev/ttyACM0 exista")
        print("3. No haya otro programa usando el puerto")
        return False
    
    return True

def test_arduino_receiver():
    """Prueba el receptor de Arduino con callbacks."""
    print("\n=== PRUEBA DEL RECEPTOR ARDUINO ===")
    
    config = SerialConfig(
        port='/dev/ttyACM0',
        baudrate=115200,
        timeout=1.0
    )
    
    receiver = ArduinoSerialReceiver(config)
    
    # Contadores para estadísticas
    json_count = 0
    infraction_count = 0
    error_count = 0
    
    def on_data_received(data):
        nonlocal json_count
        json_count += 1
        print(f"📊 JSON #{json_count} recibido - {data.timestamp}")
        
        if data.tiene_infracciones:
            print(f"🚨 INFRACCIONES EN JSON: {data.infracciones}")
    
    def on_infraction_detected(sd_num, semaforo_id, distancia):
        nonlocal infraction_count
        infraction_count += 1
        print(f"🚨 INFRACCIÓN #{infraction_count} EN TIEMPO REAL:")
        print(f"   Sensor: SD{sd_num}")
        print(f"   Semáforo: S{semaforo_id}")
        print(f"   Distancia: {distancia}cm")
    
    def on_parse_error(error_msg, raw_data):
        nonlocal error_count
        error_count += 1
        print(f"❌ Error #{error_count}: {error_msg}")
        print(f"   Datos: {raw_data[:100]}...")
    
    # Configurar callbacks
    receiver.set_data_callback(on_data_received)
    receiver.set_infraction_callback(on_infraction_detected)
    receiver.set_error_callback(on_parse_error)
    
    try:
        # Conectar y recibir por 15 segundos
        if receiver.connect():
            print("✅ Receptor conectado exitosamente")
            receiver.start_receiving()
            
            print("Recibiendo datos por 15 segundos...")
            time.sleep(15)
            
            receiver.stop_receiving()
            receiver.disconnect()
            
            print(f"\n📊 ESTADÍSTICAS:")
            print(f"   JSONs recibidos: {json_count}")
            print(f"   Infracciones en tiempo real: {infraction_count}")
            print(f"   Errores de parsing: {error_count}")
            
        else:
            print("❌ No se pudo conectar el receptor")
            return False
            
    except Exception as e:
        print(f"❌ Error en receptor: {e}")
        return False
    
    return True

def test_mqtt_publication():
    """Prueba la publicación en MQTT."""
    print("\n=== PRUEBA DE PUBLICACIÓN MQTT ===")
    
    try:
        from main import ArduinoMainController
        
        controller = ArduinoMainController(simulation_mode=False)
        controller.initialize()
        
        if controller.mqtt_connected:
            print("✅ MQTT conectado exitosamente")
            
            # Probar publicación de infracción
            test_infraction = {
                "timestamp": time.time(),
                "alert_type": "INFRACCION",
                "sensor_id": "SD1",
                "semaforo_id": "S1",
                "distancia_cm": 5.0,
                "severity": 4,
                "signal_color": "red",
                "violation_type": "red_light",
                "origen": "Prueba de conexión"
            }
            
            controller._publish_individual_infraction("S1")
            print("✅ Infracción de prueba publicada en MQTT")
            
        else:
            print("❌ MQTT no conectado")
            return False
            
    except Exception as e:
        print(f"❌ Error en MQTT: {e}")
        return False
    
    return True

def main():
    """Función principal de pruebas."""
    print("🔧 DIAGNÓSTICO DE CONEXIÓN ARDUINO-MQTT-FLUTTER")
    print("=" * 60)
    
    # Prueba 1: Conexión serial directa
    if not test_serial_connection():
        print("\n❌ FALLO EN CONEXIÓN SERIAL - No se pueden continuar las pruebas")
        return
    
    # Prueba 2: Receptor Arduino
    if not test_arduino_receiver():
        print("\n❌ FALLO EN RECEPTOR ARDUINO")
        return
    
    # Prueba 3: MQTT
    if not test_mqtt_publication():
        print("\n❌ FALLO EN MQTT")
        return
    
    print("\n✅ TODAS LAS PRUEBAS COMPLETADAS EXITOSAMENTE")
    print("\nSi las infracciones no llegan a Flutter, el problema puede estar en:")
    print("1. La API no está procesando correctamente los mensajes MQTT")
    print("2. El WebSocket no está enviando las infracciones")
    print("3. Flutter no está conectado al WebSocket correcto")

if __name__ == "__main__":
    main()

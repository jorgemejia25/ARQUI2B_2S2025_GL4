#!/usr/bin/env python3
"""
Simulador interactivo de eventos MQTT para el sistema de seguridad de tráfico.
Permite enviar eventos desde el teclado para probar el sistema.
"""

import json
import time
import random
import threading
import paho.mqtt.client as mqtt
from typing import Dict, Any, List
import sys
import os

# Configuración del simulador
MQTT_BROKER = "localhost"
MQTT_PORT = 1883
MQTT_USERNAME = "jorge"
MQTT_PASSWORD = "jorge123"

class InteractiveMQTTSimulator:
    """
    Simulador interactivo que permite enviar eventos MQTT desde el teclado.
    """
    
    def __init__(self):
        self.client = mqtt.Client()
        self.connected = False
        self.simulation_time = 0
        self.phase = 0  # Fase del semáforo (0-3)
        self.phase_start_time = 0
        
        # Estados de simulación
        self.sensor_states = {
            'TM1': {'below': False, 'stable': False, 'start_time': 0},
            'TM2': {'below': False, 'stable': False, 'start_time': 0},
            'TU3': {'below': False, 'stable': False, 'start_time': 0},
            'TU4': {'below': False, 'stable': False, 'start_time': 0}
        }
        
        # Estados de botones de pánico
        self.panic_button_states = {
            'PB1': {'active': False, 'until': 0},
            'PB2': {'active': False, 'until': 0},
            'PB3': {'active': False, 'until': 0},
            'PB4': {'active': False, 'until': 0}
        }
        
        # Estado del sismo
        self.earthquake_state = {
            'active': False,
            'until': 0,
            'magnitude': 0.0
        }
        
        # Infracciones activas
        self.active_violations = set()
        
        # ETA activos
        self.active_eta = {}
        
        # Control manual de alertas
        self.manual_alert_duration = 10.0  # Duración de alertas manuales en segundos
        
        # Configurar MQTT
        self.setup_mqtt()
    
    def setup_mqtt(self):
        """Configurar conexión MQTT"""
        try:
            # Configurar autenticación si se proporcionan credenciales
            if MQTT_USERNAME and MQTT_PASSWORD:
                print(f"Configurando autenticación MQTT para usuario: {MQTT_USERNAME}")
                self.client.username_pw_set(MQTT_USERNAME, MQTT_PASSWORD)
            
            # Configurar callbacks
            self.client.on_connect = self.on_connect
            self.client.on_disconnect = self.on_disconnect
            
            # Conectar al broker
            self.client.connect(MQTT_BROKER, MQTT_PORT, 60)
            self.client.loop_start()
            
            # Esperar un momento para la conexión
            time.sleep(1)
            
            if self.connected:
                print(f"Conectado a MQTT broker {MQTT_BROKER}:{MQTT_PORT}")
            else:
                print(f"Error conectando a MQTT broker {MQTT_BROKER}:{MQTT_PORT}")
                
        except Exception as e:
            print(f"Error configurando MQTT: {e}")
    
    def on_connect(self, client, userdata, flags, rc):
        """Callback cuando se conecta al broker MQTT"""
        if rc == 0:
            self.connected = True
            print(f"Conectado a MQTT broker con código: {rc}")
        else:
            self.connected = False
            print(f"Error conectando a MQTT broker con código: {rc}")
    
    def on_disconnect(self, client, userdata, rc):
        """Callback cuando se desconecta del broker MQTT"""
        self.connected = False
        print(f"Desconectado del broker MQTT con código: {rc}")
    
    def send_mqtt_message(self, topic: str, payload: Dict[str, Any]):
        """Envía un mensaje MQTT"""
        if not self.connected:
            print("No conectado al broker MQTT")
            return False
        
        try:
            message = json.dumps(payload, ensure_ascii=False)
            result = self.client.publish(topic, message)
            
            if result.rc == mqtt.MQTT_ERR_SUCCESS:
                print(f"Mensaje enviado a {topic}")
                print(f"Payload: {json.dumps(payload, indent=2, ensure_ascii=False)}")
                return True
            else:
                print(f"Error enviando mensaje a {topic}: {result.rc}")
                return False
                
        except Exception as e:
            print(f"Error enviando mensaje MQTT: {e}")
            return False
    
    def send_normal_data(self):
        """Envía datos normales del sistema"""
        # Generar estados de semáforos
        semaforos = {}
        for i in range(1, 11):
            semaphore_id = f"S{i}"
            # Simular estados aleatorios
            states = ["VERDE", "AMARILLO", "ROJO"]
            semaforos[semaphore_id] = random.choice(states)
        
        # Generar datos de gas
        gas_data = [
            {"zona": "Z1", "ppm": random.randint(150, 250), "is_alto": False},
            {"zona": "Z2", "ppm": random.randint(150, 250), "is_alto": False}
        ]
        
        # Generar distancias
        distancias = {}
        for i in range(1, 7):
            distancias[f"P{i}"] = random.uniform(20.0, 100.0)
        
        # Generar botones de pánico
        botones_panico = []
        for i in range(1, 5):
            botones_panico.append({
                "id": f"PB{i}",
                "activo": False,
                "button_id": str(i),
                "ubicacion": f"Parada {i}"
            })
        
        payload = {
            "timestamp": time.time(),
            "semaforos": semaforos,
            "dist_cm": distancias,
            "gas": gas_data,
            "botones_panico_activos": botones_panico,
            "tiene_sismo": False,
            "sismo": {"magnitud": 0.0, "origen": ""},
            "infracciones": []
        }
        
        return self.send_mqtt_message("arduino/data", payload)
    
    def send_earthquake_alert(self, magnitude: float = 5.5):
        """Envía alerta de sismo"""
        payload = {
            "timestamp": time.time(),
            "alert_type": "SISMO",
            "severity": 4,
            "seismic_intensity": magnitude,
            "threshold_g": 2.0,
            "tiene_sismo": True,
            "origen": "Centro Histórico"
        }
        
        print(f"Enviando alerta de sismo - Magnitud: {magnitude}")
        return self.send_mqtt_message("arduino/data", payload)
    
    def send_panic_button_alert(self, button_id: str = "PB1"):
        """Envía alerta de botón de pánico"""
        payload = {
            "timestamp": time.time(),
            "alert_type": "PANICO",
            "severity": 5,
            "stop_id": button_id,
            "button_id": button_id.replace('PB', ''),
            "origen": f"Parada {button_id.replace('PB', '')}"
        }
        
        print(f"Enviando alerta de botón de pánico - {button_id}")
        return self.send_mqtt_message("arduino/data", payload)
    
    def send_traffic_violation(self, semaphore_id: str = "S1"):
        """Envía infracción de tráfico"""
        payload = {
            "timestamp": time.time(),
            "alert_type": "INFRACCION",
            "severity": 4,
            "signal_id": semaphore_id,
            "signal_color": "red",
            "origen": f"Infracción semáforo {semaphore_id}"
        }
        
        print(f"Enviando infracción de tráfico - Semáforo: {semaphore_id}")
        return self.send_mqtt_message("arduino/data/infracciones", payload)
    
    def send_gas_alert(self, zone: str = "Z1", ppm: int = 300):
        """Envía alerta de gas alto"""
        payload = {
            "timestamp": time.time(),
            "alert_type": "GAS",
            "severity": 3,
            "gas_ppm": ppm,
            "threshold_ppm": 275.0,
            "zona": zone,
            "origen": zone
        }
        
        print(f"Enviando alerta de gas - Zona: {zone}, PPM: {ppm}")
        return self.send_mqtt_message("arduino/data", payload)
    
    def send_eta_update(self, parada: str = "P1", tipo: str = "Transurbano", tiempo: int = 120):
        """Envía actualización de ETA"""
        zonas_tu = ['Centro', 'Zona Norte', 'Zona Sur', 'Universidad']
        estaciones_tm = ['Estación Central', 'Estación Norte', 'Estación Sur']
        
        if tipo == "Transurbano":
            origen = random.choice(zonas_tu)
        else:
            origen = random.choice(estaciones_tm)
        
        payload = {
            "timestamp": time.time(),
            "alert_type": "ETA_UPDATE",
            "stop_id": parada,
            "tipo_transporte": tipo,
            "tiempo_segundos": tiempo,
            "origen": origen,
            "severity": 1
        }
        
        print(f"Enviando actualización de ETA - {parada}: {tipo} en {tiempo}s desde {origen}")
        return self.send_mqtt_message("arduino/data", payload)
    
    def show_menu(self):
        """Muestra el menú interactivo"""
        print("\n" + "="*60)
        print("SIMULADOR INTERACTIVO DE EVENTOS MQTT")
        print("="*60)
        print("Estado de conexión MQTT:", "Conectado" if self.connected else "Desconectado")
        print("\nOPCIONES DISPONIBLES:")
        print("1.  Enviar datos normales del sistema")
        print("2.  Enviar alerta de sismo")
        print("3.  Enviar alerta de botón de pánico")
        print("4.  Enviar infracción de tráfico")
        print("5.  Enviar alerta de gas alto")
        print("6.  Enviar actualización de ETA")
        print("7.  Limpiar todas las alertas")
        print("8.  Enviar datos continuos (5 segundos)")
        print("0.  Salir")
        print("="*60)
    
    def run_interactive(self):
        """Ejecuta el simulador interactivo"""
        print("Iniciando simulador interactivo de eventos MQTT...")
        
        while True:
            try:
                self.show_menu()
                choice = input("\nSelecciona una opción (0-8): ").strip()
                
                if choice == "0":
                    print("Hasta luego!")
                    break
                elif choice == "1":
                    self.send_normal_data()
                elif choice == "2":
                    magnitude = input("Ingresa la magnitud del sismo (por defecto 5.5): ").strip()
                    try:
                        magnitude = float(magnitude) if magnitude else 5.5
                    except ValueError:
                        magnitude = 5.5
                    self.send_earthquake_alert(magnitude)
                elif choice == "3":
                    button = input("Ingresa el ID del botón (PB1-PB4, por defecto PB1): ").strip().upper()
                    if not button or button not in ['PB1', 'PB2', 'PB3', 'PB4']:
                        button = 'PB1'
                    self.send_panic_button_alert(button)
                elif choice == "4":
                    semaphore = input("Ingresa el ID del semáforo (S1-S10, por defecto S1): ").strip().upper()
                    if not semaphore or not semaphore.startswith('S'):
                        semaphore = 'S1'
                    self.send_traffic_violation(semaphore)
                elif choice == "5":
                    zone = input("Ingresa la zona (Z1 o Z2, por defecto Z1): ").strip().upper()
                    if zone not in ['Z1', 'Z2']:
                        zone = 'Z1'
                    ppm = input("Ingresa el nivel de PPM (por defecto 300): ").strip()
                    try:
                        ppm = int(ppm) if ppm else 300
                    except ValueError:
                        ppm = 300
                    self.send_gas_alert(zone, ppm)
                elif choice == "6":
                    parada = input("Ingresa la parada (P1-P4, por defecto P1): ").strip().upper()
                    if parada not in ['P1', 'P2', 'P3', 'P4']:
                        parada = 'P1'
                    tipo = input("Ingresa el tipo (Transurbano/Transmetro, por defecto Transurbano): ").strip()
                    if tipo not in ['Transurbano', 'Transmetro']:
                        tipo = 'Transurbano'
                    tiempo = input("Ingresa el tiempo en segundos (por defecto 120): ").strip()
                    try:
                        tiempo = int(tiempo) if tiempo else 120
                    except ValueError:
                        tiempo = 120
                    self.send_eta_update(parada, tipo, tiempo)
                elif choice == "7":
                    print("Todas las alertas limpiadas")
                elif choice == "8":
                    duration = input("Ingresa la duración en segundos (por defecto 5): ").strip()
                    try:
                        duration = int(duration) if duration else 5
                    except ValueError:
                        duration = 5
                    print(f"Enviando datos continuos por {duration} segundos...")
                    for i in range(duration):
                        self.send_normal_data()
                        time.sleep(1)
                    print("Envío continuo finalizado")
                else:
                    print("Opción no válida. Intenta de nuevo.")
                
                input("\nPresiona Enter para continuar...")
                
            except KeyboardInterrupt:
                print("\nHasta luego!")
                break
            except Exception as e:
                print(f"Error: {e}")
                input("Presiona Enter para continuar...")
        
        # Cerrar conexión MQTT
        if self.connected:
            self.client.loop_stop()
            self.client.disconnect()
            print("Conexión MQTT cerrada")

def main():
    """Función principal"""
    print("Iniciando Simulador Interactivo de Eventos MQTT")
    print("Sistema de Seguridad de Tráfico - Arquitectura de Software 2")
    
    simulator = InteractiveMQTTSimulator()
    
    if not simulator.connected:
        print("No se pudo conectar al broker MQTT. Verifica que esté ejecutándose.")
        print("Ejecuta: ./start_mosquitto.sh")
        return
    
    simulator.run_interactive()

if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""
Archivo principal del módulo MQTT para comunicación serial con Arduino.
Utiliza todas las funcionalidades del módulo: comunicación serial, parser de datos,
y manejo completo de la información del Arduino.
"""

import time
import signal
import sys
import argparse
import json
import paho.mqtt.client as mqtt
from paho.mqtt.client import CallbackAPIVersion
from datetime import datetime

# Imports directos para ejecutar desde el directorio mqtt
from serial_receiver import ArduinoSerialReceiver, SerialConfig
from arduino_data_parser import ArduinoDataParser, parse_arduino_json
from config import SERIAL_CONFIG
from simulation_mode import ArduinoSimulator

# Configuración MQTT
import os
from dotenv import load_dotenv

# Cargar variables de entorno desde .env
load_dotenv()

MQTT_BROKER = os.getenv("MQTT_BROKER", "trolley.proxy.rlwy.net")
MQTT_PORT = int(os.getenv("MQTT_PORT", "55424"))
MQTT_USERNAME = os.getenv("MQTT_USERNAME", "jorge")
MQTT_PASSWORD = os.getenv("MQTT_PASSWORD", "34eikykmbd8w5igpjiebialeisx0yu02")
MQTT_TOPIC = os.getenv("MQTT_TOPIC", "arduino/data")
MQTT_CLIENT_ID = "arduino_main_controller"


class ArduinoMainController:
    """
    Controlador principal que maneja la comunicación con Arduino
    y procesa todos los datos recibidos.
    """
    
    def __init__(self, simulation_mode: bool = False):
        self.receiver: ArduinoSerialReceiver = None
        self.simulator: ArduinoSimulator = None
        self.data_count = 0
        self.last_data: ArduinoDataParser = None
        self.alertas_activas = set()
        self.running = False
        self.simulation_mode = simulation_mode
        
        # Cliente MQTT
        self.mqtt_client = mqtt.Client(CallbackAPIVersion.VERSION1, client_id=MQTT_CLIENT_ID)
        self.mqtt_connected = False
        
        # Configurar manejo de señales para cierre limpio
        signal.signal(signal.SIGINT, self._signal_handler)
        signal.signal(signal.SIGTERM, self._signal_handler)
    
    def _signal_handler(self, signum, frame):
        """Maneja señales de interrupción para cierre limpio."""
        print(f"\n\nSeñal {signum} recibida. Cerrando aplicación...")
        self.stop()
        sys.exit(0)
    
    def _init_mqtt(self):
        """Inicializa la conexión MQTT."""
        try:
            print("Configurando cliente MQTT...")
            
            # Configurar callbacks MQTT
            self.mqtt_client.on_connect = self._on_mqtt_connect
            self.mqtt_client.on_disconnect = self._on_mqtt_disconnect
            
            # Configurar autenticación si se proporcionan credenciales
            if MQTT_USERNAME and MQTT_PASSWORD:
                print(f"Configurando autenticación MQTT para usuario: {MQTT_USERNAME}")
                self.mqtt_client.username_pw_set(MQTT_USERNAME, MQTT_PASSWORD)
            
            # Conectar al broker
            print(f"Conectando a broker MQTT: {MQTT_BROKER}:{MQTT_PORT}")
            self.mqtt_client.connect(MQTT_BROKER, MQTT_PORT, 60)
            
            # Iniciar loop en background
            self.mqtt_client.loop_start()
            
            # Esperar conexión
            timeout = 10
            while not self.mqtt_connected and timeout > 0:
                time.sleep(0.5)
                timeout -= 0.5
            
            if self.mqtt_connected:
                print("Cliente MQTT conectado exitosamente")
                return True
            else:
                print("Error: Timeout al conectar MQTT")
                return False
                
        except Exception as e:
            print(f"Error al inicializar MQTT: {e}")
            return False
    
    def _on_mqtt_connect(self, client, userdata, flags, rc):
        """Callback cuando se conecta al broker MQTT."""
        if rc == 0:
            self.mqtt_connected = True
            print(f"Conectado al broker MQTT (código: {rc})")
        else:
            print(f"Error al conectar MQTT (código: {rc})")
    
    def _on_mqtt_disconnect(self, client, userdata, rc):
        """Callback cuando se desconecta del broker MQTT."""
        self.mqtt_connected = False
        print("Desconectado del broker MQTT")
    
    def _publish_mqtt(self, data: ArduinoDataParser):
        """Publica datos en el tópico MQTT."""
        if not self.mqtt_connected:
            print("⚠️ MQTT no conectado - datos no publicados")
            return
        
        try:
            # Convertir datos a formato JSON
            mqtt_data = self._convert_to_mqtt_format(data)
            message = json.dumps(mqtt_data, indent=2)
            
            # Publicar
            result = self.mqtt_client.publish(MQTT_TOPIC, message)
            
            if result.rc == mqtt.MQTT_ERR_SUCCESS:
                eta_count = len(data.eta)
                gas_alerts = len([g for g in data.gas if g.ppm >= 260])
                print(f"✓ MQTT publicado - {data.timestamp} | ETAs: {eta_count} | Gas alto: {gas_alerts}")
            else:
                print(f"✗ Error al publicar MQTT (código: {result.rc})")
                
        except Exception as e:
            print(f"Error al publicar en MQTT: {e}")
    
    def _convert_to_mqtt_format(self, data: ArduinoDataParser) -> dict:
        """Convierte los datos del Arduino al formato MQTT."""
        return {
            "timestamp": data.timestamp,
            "protocol_version": getattr(data, '_protocol_version', '1.0'),
            "semaforos": [
                {
                    "id": sem.id,
                    "estado": sem.estado
                } for sem in data.semaforos
            ],
            "distancias": [
                {
                    "id": dist.id,
                    "distancia_cm": dist.distancia_cm
                } for dist in data.distancias
            ],
            "gas": [
                {
                    "zona": gas.zona,
                    "ppm": gas.ppm,
                    "is_alto": gas.is_alto
                } for gas in data.gas
            ],
            "tiene_sismo": data.tiene_sismo,
            "sismo": {
                "magnitud": data.sismo.magnitud,
                "origen": data.sismo.origen
            } if data.tiene_sismo else None,
            "botones_panico_activos": [
                {
                    "id": btn.id,
                    "activo": btn.activo,
                    "timestamp": btn.timestamp,
                    "button_id": btn.button_id
                } for btn in data.botones_panico_activos
            ],
            "infracciones": data.infracciones,  # Las infracciones son strings simples
            "eta": [
                {
                    "parada": eta.parada,
                    "tipo_transporte": eta.tipo_transporte,
                    "tiempo_segundos": eta.tiempo_segundos,
                    "info": eta.info
                } for eta in data.eta
            ]
        }
    
    def initialize(self):
        """Inicializa el controlador y establece la conexión."""
        # Inicializar MQTT primero
        if not self._init_mqtt():
            print("Advertencia: No se pudo inicializar MQTT, continuando sin él...")
        
        if self.simulation_mode:
            print("=== Módulo MQTT - MODO SIMULACIÓN ===")
            print("Generando datos simulados del Arduino")
            
            # Crear simulador
            self.simulator = ArduinoSimulator()
            
            # Configurar callbacks para datos simulados
            print("Simulador configurado")
            print("Inicialización completada")
        else:
            print("=== Módulo MQTT - Comunicación Serial con Arduino ===")
            print(f"Configurando conexión en puerto: {SERIAL_CONFIG['port']}")
            print(f"Baudrate: {SERIAL_CONFIG['baudrate']}")
            
            # Crear configuración
            config = SerialConfig(
                port=SERIAL_CONFIG['port'],
                baudrate=SERIAL_CONFIG['baudrate'],
                timeout=SERIAL_CONFIG['timeout']
            )
            
            # Crear receptor
            self.receiver = ArduinoSerialReceiver(config)
            
            # Configurar callbacks
            self.receiver.set_data_callback(self._on_data_received)
            self.receiver.set_error_callback(self._on_parse_error)
            self.receiver.set_infraction_callback(self._on_infraction_detected)
            
            print("Callbacks configurados")
            print("Inicialización completada")
    
    def start(self):
        """Inicia la comunicación con Arduino o simulación."""
        if self.simulation_mode:
            print("\nIniciando modo simulación...")
            self.running = True
            print("Simulación iniciada - Generando datos...")
            print("Presiona Ctrl+C para detener")
            return True
        else:
            if not self.receiver:
                print("Error: Receptor no inicializado")
                return False
            
            print("\nIniciando comunicación con Arduino...")
            
            # Conectar
            if not self.receiver.connect():
                print("Error: No se pudo conectar con Arduino")
                return False
            
            print("Conectado exitosamente con Arduino")
            
            # Iniciar recepción
            self.receiver.start_receiving()
            self.running = True
            
            print("Receptor iniciado - Esperando datos...")
            print("Presiona Ctrl+C para detener")
            
            return True
    
    def stop(self):
        """Detiene la comunicación y limpia recursos."""
        if self.simulation_mode:
            if self.running:
                print("\nDeteniendo simulación...")
                self.running = False
                print("Simulación detenida")
        else:
            if self.receiver and self.running:
                print("\nDeteniendo receptor...")
                self.receiver.stop_receiving()
                self.receiver.disconnect()
                self.running = False
                print("Receptor detenido y desconectado")
        
        # Detener MQTT
        if self.mqtt_connected:
            print("Deteniendo cliente MQTT...")
            self.mqtt_client.loop_stop()
            self.mqtt_client.disconnect()
            self.mqtt_connected = False
            print("Cliente MQTT detenido")
    
    def run(self):
        """Bucle principal de ejecución."""
        if not self.start():
            return
        
        try:
            if self.simulation_mode:
                # Bucle de simulación
                self._run_simulation()
            else:
                # Bucle normal de comunicación
                while self.running:
                    time.sleep(1)
                    
                    # Mostrar resumen cada 10 segundos
                    if self.data_count > 0 and self.data_count % 10 == 0:
                        self._show_status_summary()
                        
        except KeyboardInterrupt:
            print("\nInterrupción de teclado recibida")
        finally:
            self.stop()
    
    def _run_simulation(self):
        """Ejecuta el bucle de simulación."""
        print("Generando datos simulados cada 2 segundos...")
        
        while self.running:
            try:
                # Generar datos simulados
                json_data = self.simulator.generate_json_data()
                
                # Simular recepción de datos
                self._on_data_received_simulated(json_data)
                
                # Actualizar tiempo de simulación
                self.simulator.update_simulation_time(2.0)
                
                # Esperar 2 segundos
                time.sleep(2)
                
            except KeyboardInterrupt:
                break
    
    def _on_data_received(self, data: ArduinoDataParser):
        """
        Callback principal para datos recibidos del Arduino.
        
        Args:
            data: Objeto ArduinoDataParser con todos los datos estructurados
        """
        self.data_count += 1
        self.last_data = data
        
        # Procesar todos los tipos de datos
        self._process_semaforos(data)
        self._process_distancias(data)
        self._process_gas(data)
        self._process_sismo(data)
        self._process_panic_buttons(data)
        self._process_infracciones(data)
        self._process_eta(data)
        
        # Publicar en MQTT
        self._publish_mqtt(data)
        
        # Mostrar resumen cada 5 datos
        if self.data_count % 5 == 0:
            self._show_data_summary(data)
    
    def _on_data_received_simulated(self, json_data: str):
        """
        Maneja datos simulados del Arduino.
        
        Args:
            json_data: String JSON con datos simulados
        """
        try:
            # Parsear el JSON simulado
            data = parse_arduino_json(json_data)
            if data:
                # Usar el mismo procesamiento que los datos reales
                self._on_data_received(data)
            else:
                print("Error al parsear datos simulados")
        except Exception as e:
            print(f"Error procesando datos simulados: {e}")
    
    def _on_parse_error(self, error_msg: str, raw_data: str):
        """
        Callback para errores de parsing.
        
        Args:
            error_msg: Mensaje de error
            raw_data: Datos crudos que causaron el error
        """
        print(f"\nError de parsing: {error_msg}")
        print(f"Datos crudos: {raw_data[:100]}...")
    
    def _on_infraction_detected(self, sd_num: int, semaforo_id: str, distancia: float):
        """
        Callback para infracciones detectadas en tiempo real.
        
        Args:
            sd_num: Número del sensor SD (1-5)
            semaforo_id: ID del semáforo infringido (S1-S10)
            distancia: Distancia del vehículo en cm
        """
        print(f"\n🚨 INFRACCIÓN EN TIEMPO REAL:")
        print(f"   Sensor: SD{sd_num}")
        print(f"   Semáforo: {semaforo_id}")
        print(f"   Distancia: {distancia}cm")
        print(f"   Timestamp: {datetime.now().strftime('%H:%M:%S')}")
        
        # Crear datos simulados para MQTT
        infraction_data = {
            "timestamp": time.time(),
            "alert_type": "INFRACCION",
            "sensor_id": f"SD{sd_num}",
            "semaforo_id": semaforo_id,
            "distancia_cm": distancia,
            "severity": 3  # Alta severidad
        }
        
        # Publicar infracción inmediatamente por MQTT
        if self.mqtt_connected:
            try:
                message = json.dumps(infraction_data, indent=2)
                result = self.mqtt_client.publish(MQTT_TOPIC + "/infracciones", message)
                if result.rc == mqtt.MQTT_ERR_SUCCESS:
                    print(f"   ✓ Infracción publicada en MQTT")
                else:
                    print(f"   ✗ Error publicando infracción: {result.rc}")
            except Exception as e:
                print(f"   ✗ Error en MQTT infracción: {e}")
        else:
            print(f"   ⚠️ MQTT no conectado - infracción no publicada")
    
    def _process_semaforos(self, data: ArduinoDataParser):
        """Procesa información de semáforos con debug."""
        # Contar por estado
        verdes = len(data.semaforos_verdes)
        rojos = len(data.semaforos_rojos)
        amarillos = len(data.semaforos_amarillos)
        
        # Debug periódico del estado de semáforos
        if not hasattr(self, 'semaforo_debug_counter'):
            self.semaforo_debug_counter = 0
        self.semaforo_debug_counter += 1
        
        if self.semaforo_debug_counter % 25 == 0:  # Cada 25 lecturas
            print(f"🚦 ESTADO SEMÁFOROS: Verde={verdes}, Amarillo={amarillos}, Rojo={rojos}")
            # Mostrar algunos ejemplos
            if data.semaforos_verdes:
                ejemplos_verdes = [s.id for s in data.semaforos_verdes[:3]]
                print(f"   Verdes: {', '.join(ejemplos_verdes)}")
            if data.semaforos_rojos:
                ejemplos_rojos = [s.id for s in data.semaforos_rojos[:3]]
                print(f"   Rojos: {', '.join(ejemplos_rojos)}")
        
        # Alerta si hay muchos semáforos en rojo
        if rojos >= 5:
            alerta_id = "muchos_semaforos_rojos"
            if alerta_id not in self.alertas_activas:
                print(f"🚨 CONGESTIÓN: {rojos}/10 semáforos en ROJO!")
                self.alertas_activas.add(alerta_id)
        else:
            # Remover alerta si ya no hay muchos rojos
            alerta_id = "muchos_semaforos_rojos"
            if alerta_id in self.alertas_activas:
                print(f"✅ TRÁFICO MEJORADO: {rojos}/10 semáforos en rojo")
                self.alertas_activas.remove(alerta_id)
    
    def _process_distancias(self, data: ArduinoDataParser):
        """Procesa información de distancias con detección de paradas."""
        # Mapeo de sensores: P1=TU3, P2=TU4, P3=TM1, P4=TM2, P5/P6=sin sensor real
        paradas_importantes = ['P1', 'P2', 'P3', 'P4']  # Solo las que tienen sensores reales
        
        for dist in data.distancias:
            if dist.id in paradas_importantes:
                alerta_id = f"vehiculo_parada_{dist.id}"
                
                # Umbral de detección de vehículos (más sensible para detectar mejor)
                if dist.distancia_cm < 15.0:  # Vehículo presente
                    if alerta_id not in self.alertas_activas:
                        print(f"🚌 VEHÍCULO DETECTADO: {dist.id} - {dist.distancia_cm:.1f} cm")
                        self.alertas_activas.add(alerta_id)
                else:  # Vehículo ausente
                    if alerta_id in self.alertas_activas:
                        print(f"🚌 VEHÍCULO SALIÓ: {dist.id} - {dist.distancia_cm:.1f} cm")
                        self.alertas_activas.remove(alerta_id)
            
            # Debug: mostrar todas las distancias cada 10 lecturas
            if hasattr(self, 'debug_counter'):
                self.debug_counter += 1
            else:
                self.debug_counter = 1
                
            if self.debug_counter % 50 == 0:  # Cada 50 lecturas (aprox cada 100 segundos)
                print(f"📊 DEBUG DISTANCIAS: {dist.id}={dist.distancia_cm:.1f}cm", end=" ")
                if dist.id == 'P6':  # Último sensor, nueva línea
                    print()
    
    def _process_gas(self, data: ArduinoDataParser):
        """Procesa información de sensores de gas con histéresis y debug."""
        # Debug periódico de valores de gas
        if not hasattr(self, 'gas_debug_counter'):
            self.gas_debug_counter = 0
        self.gas_debug_counter += 1
        
        if self.gas_debug_counter % 30 == 0:  # Cada 30 lecturas
            valores_gas = [f"{gas.zona}={gas.ppm}ppm" for gas in data.gas]
            print(f"🔥 VALORES GAS: {', '.join(valores_gas)}")
        
        for gas in data.gas:
            alerta_id = f"gas_alto_{gas.zona}"
            
            # Histéresis mejorada: solo alertar por humo real, no fluctuaciones normales
            umbral_activacion = 275  # Solo si realmente hay humo (Arduino HUMO_UMBRAL=500 → ~275ppm)
            umbral_desactivacion = 250  # Volver a valores normales
            
            if alerta_id not in self.alertas_activas:
                # Solo activar si supera el umbral de activación (humo detectado)
                if gas.ppm >= umbral_activacion:
                    print(f"🔥 HUMO DETECTADO: Zona {gas.zona} ({gas.ppm} ppm)")
                    self.alertas_activas.add(alerta_id)
            else:
                # Solo desactivar si baja del umbral de desactivación
                if gas.ppm < umbral_desactivacion:
                    print(f"✅ HUMO ELIMINADO: Zona {gas.zona} ({gas.ppm} ppm)")
                    self.alertas_activas.remove(alerta_id)
    
    def _process_sismo(self, data: ArduinoDataParser):
        """Procesa información del sensor de sismo."""
        if data.tiene_sismo:
            alerta_id = "sismo_activo"
            if alerta_id not in self.alertas_activas:
                print(f"SISMO ACTIVO! Magnitud: {data.sismo.magnitud}")
                print(f"   Origen: {data.sismo.origen}")
                self.alertas_activas.add(alerta_id)
        else:
            # Remover alerta si ya no hay sismo
            alerta_id = "sismo_activo"
            if alerta_id in self.alertas_activas:
                self.alertas_activas.remove(alerta_id)
    
    def _process_panic_buttons(self, data: ArduinoDataParser):
        """Procesa información de botones de pánico."""
        if data.botones_panico_activos:
            for btn in data.botones_panico_activos:
                alerta_id = f"panic_button_{btn.id}"
                if alerta_id not in self.alertas_activas:
                    print(f"ALERTA: Botón de pánico {btn.id} activado!")
                    self.alertas_activas.add(alerta_id)
        else:
            # Remover alertas de botones de pánico
            for alerta in list(self.alertas_activas):
                if alerta.startswith("panic_button_"):
                    self.alertas_activas.remove(alerta)
    
    def _process_infracciones(self, data: ArduinoDataParser):
        """Procesa información de infracciones."""
        if data.tiene_infracciones:
            alerta_id = "infracciones_activas"
            if alerta_id not in self.alertas_activas:
                print(f"ALERTA: {len(data.infracciones)} infracciones activas")
                for infraccion in data.infracciones:
                    print(f"   - {infraccion}")
                self.alertas_activas.add(alerta_id)
        else:
            # Remover alerta si ya no hay infracciones
            alerta_id = "infracciones_activas"
            if alerta_id in self.alertas_activas:
                self.alertas_activas.remove(alerta_id)
    
    def _process_eta(self, data: ArduinoDataParser):
        """Procesa información de ETA."""
        if data.eta:
            print(f"\n--- Información de Transporte ({len(data.eta)} ETAs activos) ---")
            
            for eta in data.eta:
                tiempo = eta.tiempo_segundos
                tiempo_str = f"{tiempo}s" if tiempo else "N/A"
                
                # Determinar estado del transporte
                if tiempo and tiempo < 60:
                    estado = "LLEGANDO PRONTO"
                elif tiempo and tiempo < 120:
                    estado = "EN CAMINO"
                else:
                    estado = "PROGRAMADO"
                
                print(f"  {eta.parada}: {eta.tipo_transporte} - {tiempo_str} ({estado})")
                
                # Mostrar información adicional del ETA
                if eta.info:
                    # Extraer información adicional del string del ETA
                    if "FROM=" in eta.info and "TO=" in eta.info:
                        from_part = eta.info.split("FROM=")[1].split(",")[0] if "FROM=" in eta.info else "N/A"
                        to_part = eta.info.split("TO=")[1].split(",")[0] if "TO=" in eta.info else "N/A"
                        print(f"    Ruta: {from_part} → {to_part}")
        else:
            print("\n--- Información de Transporte ---")
            print("  No hay ETAs activos en este momento")
    
    def _show_data_summary(self, data: ArduinoDataParser):
        """Muestra un resumen de los datos recibidos."""
        print(f"\nDatos #{self.data_count} - {data.timestamp}")
        print(f"   Semáforos: {len(data.semaforos)} | Distancias: {len(data.distancias)}")
        print(f"   Gas: {len(data.gas)} | Sismo: {'SÍ' if data.tiene_sismo else 'NO'}")
        print(f"   Infracciones: {len(data.infracciones)} | Transporte: {len(data.eta)} ETAs")
        
        # Mostrar resumen rápido del transporte si hay ETAs
        if data.eta:
            transportes = {}
            for eta in data.eta:
                tipo = eta.tipo_transporte
                if tipo not in transportes:
                    transportes[tipo] = 0
                transportes[tipo] += 1
            
            transport_info = []
            for tipo, count in transportes.items():
                transport_info.append(f"{tipo}: {count}")
            
            if transport_info:
                print(f"   Transportes: {' | '.join(transport_info)}")
    
    def _show_status_summary(self):
        """Muestra un resumen del estado del sistema."""
        if not self.last_data:
            return
        
        print(f"\nRESUMEN DEL SISTEMA (Datos: {self.data_count})")
        print(f"   Timestamp: {self.last_data.timestamp}")
        print(f"   Semáforos en rojo: {len(self.last_data.semaforos_rojos)}")
        print(f"   Tiene sismo: {'SÍ' if self.last_data.tiene_sismo else 'NO'}")
        print(f"   Infracciones activas: {len(self.last_data.infracciones)}")
        print(f"   Botones de pánico: {len(self.last_data.botones_panico_activos)}")
        print(f"   Transporte activo: {len(self.last_data.eta)} ETAs")
        print(f"   Alertas activas: {len(self.alertas_activas)}")
        
        # Mostrar información del transporte
        if self.last_data.eta:
            print("   Transportes activos:")
            for eta in self.last_data.eta:
                tiempo = eta.tiempo_segundos
                tiempo_str = f"{tiempo}s" if tiempo else "N/A"
                print(f"     - {eta.parada}: {eta.tipo_transporte} en {tiempo_str}")
        
        if self.alertas_activas:
            print("   Alertas:")
            for alerta in sorted(self.alertas_activas):
                print(f"     - {alerta}")
    
    def get_system_status(self) -> dict:
        """Obtiene el estado completo del sistema."""
        if not self.last_data:
            return {"status": "No hay datos disponibles"}
        
        return {
            "status": "running",
            "data_count": self.data_count,
            "last_timestamp": self.last_data.timestamp,
            "protocol_version": getattr(self.last_data, '_protocol_version', '1.0'),
            "semaforos": {
                "total": len(self.last_data.semaforos),
                "verdes": len(self.last_data.semaforos_verdes),
                "amarillos": len(self.last_data.semaforos_amarillos),
                "rojos": len(self.last_data.semaforos_rojos)
            },
            "distancias": len(self.last_data.distancias),
            "gas_sensores": len(self.last_data.gas),
            "sismo": {
                "activo": self.last_data.tiene_sismo,
                "magnitud": self.last_data.sismo.magnitud if self.last_data.tiene_sismo else 0
            },
            "panic_buttons": len(self.last_data.botones_panico_activos),
            "infracciones": len(self.last_data.infracciones),
            "eta_count": len(self.last_data.eta),
            "eta_details": [
                {
                    "parada": eta.parada,
                    "tipo": eta.tipo_transporte,
                    "tiempo": eta.tiempo_segundos,
                    "info": eta.info
                } for eta in self.last_data.eta
            ],
            "alertas_activas": list(self.alertas_activas)
        }


def main():
    """Función principal de la aplicación."""
    # Configurar argumentos de línea de comandos
    parser = argparse.ArgumentParser(description='Módulo MQTT para comunicación con Arduino')
    parser.add_argument('--simulation', '-s', action='store_true', 
                       help='Ejecutar en modo simulación (sin hardware)')
    parser.add_argument('--duration', '-d', type=int, default=60,
                       help='Duración de la simulación en segundos (por defecto: 60)')
    
    args = parser.parse_args()
    
    if args.simulation:
        print("Iniciando módulo MQTT en modo simulación...")
        controller = ArduinoMainController(simulation_mode=True)
    else:
        print("Iniciando módulo MQTT para Arduino...")
        controller = ArduinoMainController(simulation_mode=False)
    
    try:
        # Inicializar
        controller.initialize()
        
        # Ejecutar
        controller.run()
        
    except Exception as e:
        print(f"Error en la aplicación: {e}")
        controller.stop()
        sys.exit(1)
    
    print("Aplicación finalizada correctamente")


if __name__ == "__main__":
    main()

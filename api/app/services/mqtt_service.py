"""
MQTT Service
Handles MQTT broker communication and message processing
"""

import json
import time
from typing import List, Dict, Any, Optional
import paho.mqtt.client as mqtt

from app.core.config import settings
from app.core.logging import get_logger
from app.db.connection import DatabaseConnection
from app.db.repositories.mqtt_repository import MQTTRepository

logger = get_logger(__name__)


class MQTTService:
    """Service for MQTT operations"""
    
    def __init__(self, websocket_manager=None):
        self.broker = settings.MQTT_BROKER
        self.port = settings.MQTT_PORT
        self.topics = settings.MQTT_TOPICS
        self.client = mqtt.Client()
        try:
            self.client.enable_logger(logger)
        except Exception:
            pass
        try:
            self.client.reconnect_delay_set(min_delay=1, max_delay=30)
        except Exception:
            pass
        self.received_data = []
        self.websocket_manager = websocket_manager
        
        # Initialize database connection and repository
        self.db_connection = DatabaseConnection()
        self.mqtt_repository = MQTTRepository(self.db_connection)
        
        # Configure MQTT callbacks
        self.client.on_connect = self.on_connect
        self.client.on_message = self.on_message
        self.client.on_disconnect = self.on_disconnect
    
    def on_connect(self, client, userdata, flags, rc):
        """Callback when connected to MQTT broker"""
        logger.info(f"Connected to MQTT broker: code={rc}")
        
        # Print visible de conexión exitosa
        print("\n" + "+"*80)
        print("API CONECTADO AL BROKER MQTT")
        print("+"*80)
        print(f"Broker: {self.broker}:{self.port}")
        print(f"Codigo de conexion: {rc}")
        
        # Subscribe to all topics
        for topic in self.topics:
            client.subscribe(topic)
            print(f"  - Suscrito a: {topic}")
            logger.info(f"Subscribed to topic: {topic}")
        
        # Subscribe to new sensor topic
        client.subscribe("arduino/data/sensors")
        print(f"  - Suscrito a: arduino/data/sensors")
        logger.info(f"Subscribed to topic: arduino/data/sensors")
        
        # Subscribe to panic button topic
        client.subscribe("arduino/data/panic")
        print(f"  - Suscrito a: arduino/data/panic")
        logger.info(f"Subscribed to topic: arduino/data/panic")
        
        print("+"*80 + "\n")
    
    def on_message(self, client, userdata, msg):
        """Callback when message is received"""
        try:
            # Decode JSON payload
            payload = json.loads(msg.payload.decode('utf-8'))
            topic = msg.topic
            
            # Create data structure
            data_received = {
                "timestamp": time.time(),
                "topic": topic,
                "payload": payload
            }
            
            # Add to received data list
            self.received_data.append(data_received)
            
            # Print JSON recibido en consola de forma visible
            print("\n" + "="*80)
            print("JSON RECIBIDO DESDE MQTT")
            print("="*80)
            print(f"Topico: {topic}")
            print(f"Timestamp: {data_received['timestamp']:.2f}")
            print(f"JSON Payload:")
            print(json.dumps(payload, indent=2, ensure_ascii=False))
            
            # Destacar si hay infracciones en el JSON principal
            if topic == "arduino/data" and "infracciones" in payload:
                infracciones = payload.get("infracciones", [])
                if infracciones:
                    print(f"\n>>> INFRACCIONES DETECTADAS EN JSON: {infracciones} <<<")
            
            print("="*80 + "\n")
            
            # Log received data
            logger.info(f"MQTT data received - Topic: {topic}")
            logger.debug(f"Payload: {json.dumps(payload, indent=2, ensure_ascii=False)}")
            
            # Save to database
            try:
                success = self.mqtt_repository.save_mqtt_data(topic, payload)
                if success:
                    logger.info(f"Data saved to database: {topic}")
                else:
                    logger.warning(f"Failed to save data: {topic}")
            except Exception as e:
                logger.error(f"Database save error: {e}")

            # Detectar infracción y notificar a la IA
            if topic == "arduino/data/infracciones":
                from datetime import datetime
                import requests

                # Print destacado para infracciones
                print("\n" + "!"*80)
                print("INFRACCION DETECTADA")
                print("!"*80)
                print(f"Signal ID: {payload.get('signal_id', 'Desconocido')}")
                print(f"Severidad: {payload.get('severity', 'N/A')}")
                print(f"Tipo de alerta: {payload.get('alert_type', 'INFRACCION')}")
                print(f"Origen: {payload.get('origen', 'N/A')}")
                print("!"*80 + "\n")

                DETECTOR_URL = "http://localhost:5001/api/deteccion"
                
                signal_id = payload.get("signal_id", "Desconocido")
                payload_trigger = {
                    "tipo_evento": "infraccion_detectada",
                    "ubicacion": signal_id,
                    "timestamp": datetime.now().isoformat()
                }


                try:
                    logger.info("Infracción detectada — enviando evento al servicio de detección de placas...")
                    response = requests.post(DETECTOR_URL, json=payload_trigger, timeout=5)
                    logger.info(f"Respuesta IA ({response.status_code}): {response.text}")
                except Exception as e:
                    logger.error(f"Error enviando evento a detección de placas: {e}")
            
            # Detectar botón de pánico
            elif topic == "arduino/data/panic":
                # Print destacado para botones de pánico
                print("\n" + "@"*80)
                print("ALERTA DE BOTON DE PANICO ACTIVADO")
                print("@"*80)
                print(f"Button ID: {payload.get('button_id', 'Desconocido')}")
                print(f"Ubicacion: {payload.get('location', 'N/A')}")
                print(f"Severidad: {payload.get('severity', 'N/A')}")
                print(f"Tipo de alerta: {payload.get('alert_type', 'PANIC_BUTTON')}")
                print(f"Origen: {payload.get('origen', 'N/A')}")
                print(f"Timestamp: {payload.get('timestamp', 'N/A')}")
                print("@"*80 + "\n")
                
                logger.warning(f"PANIC BUTTON ALERT: {payload.get('button_id')} at {payload.get('location')}")
            
            # Detectar alertas de SISMO y GAS en el topic principal
            elif topic == "arduino/data":
                alert_type = payload.get("alert_type", "")
                
                if alert_type == "SISMO":
                    # Print destacado para sismo
                    print("\n" + "~"*80)
                    print("ALERTA DE SISMO DETECTADO")
                    print("~"*80)
                    print(f"Magnitud: {payload.get('seismic_intensity', 'N/A')}")
                    print(f"Umbral: {payload.get('threshold_g', 'N/A')} G")
                    print(f"Origen: {payload.get('origen', 'N/A')}")
                    print(f"Severidad: {payload.get('severity', 'N/A')}")
                    print("~"*80 + "\n")
                    
                    logger.warning(f"SEISMIC ALERT: magnitude={payload.get('seismic_intensity')} from {payload.get('origen')}")
                
                elif alert_type == "GAS":
                    # Print destacado para gas/humo
                    print("\n" + "#"*80)
                    print("ALERTA DE GAS/HUMO DETECTADO")
                    print("#"*80)
                    print(f"Zona: {payload.get('zona', 'N/A')}")
                    print(f"PPM: {payload.get('gas_ppm', 'N/A')}")
                    print(f"Umbral: {payload.get('threshold_ppm', 'N/A')}")
                    print(f"Origen: {payload.get('origen', 'N/A')}")
                    print(f"Severidad: {payload.get('severity', 'N/A')}")
                    print("#"*80 + "\n")
                    
                    logger.warning(f"GAS ALERT: zone={payload.get('zona')}, ppm={payload.get('gas_ppm')}")

            
            # Emit via WebSocket if manager is available
            if self.websocket_manager:
                try:
                    import asyncio
                    # Try to get existing loop, create new one if needed
                    try:
                        loop = asyncio.get_event_loop()
                        if loop.is_running():
                            # Schedule coroutine in existing loop
                            asyncio.run_coroutine_threadsafe(
                                self._process_websocket_emission(topic, payload), 
                                loop
                            )
                        else:
                            # Run in new thread
                            asyncio.run(self._process_websocket_emission(topic, payload))
                    except RuntimeError:
                        # No event loop, create new one
                        asyncio.run(self._process_websocket_emission(topic, payload))
                except Exception as e:
                    logger.error(f"WebSocket emission error: {e}")
            
        except json.JSONDecodeError as e:
            logger.error(f"JSON decode error for topic {msg.topic}: {e}")
        except Exception as e:
            logger.error(f"Message processing error: {e}")
    
    def on_disconnect(self, client, userdata, rc):
        """Callback when disconnected from broker"""
        logger.warning(f"Disconnected from MQTT broker: code={rc}")
        if rc != 0:
            logger.info("Attempting reconnection...")
            try:
                client.reconnect()
            except Exception as e:
                logger.error(f"Reconnection failed: {e}")
    
    def connect(self) -> bool:
        """Connect to MQTT broker"""
        try:
            # Configure authentication if provided
            if settings.MQTT_USERNAME and settings.MQTT_PASSWORD:
                logger.info(f"Configuring MQTT authentication: {settings.MQTT_USERNAME}")
                self.client.username_pw_set(settings.MQTT_USERNAME, settings.MQTT_PASSWORD)
            
            # Optional LWT
            try:
                self.client.will_set(
                    topic="service/status",
                    payload=json.dumps({"status": "offline"}, ensure_ascii=False),
                    qos=1,
                    retain=True,
                )
            except Exception:
                pass

            keepalive = getattr(settings, "MQTT_KEEPALIVE", 60)
            self.client.connect(self.broker, self.port, keepalive)
            self.client.loop_start()
            logger.info(f"Connected to MQTT broker: {self.broker}:{self.port}")
            return True
        except Exception as e:
            logger.error(f"MQTT connection error: {e}")
            return False
    
    def disconnect(self) -> bool:
        """Disconnect from MQTT broker"""
        try:
            self.client.loop_stop()
            self.client.disconnect()
            logger.info("MQTT connection closed")
            return True
        except Exception as e:
            logger.error(f"MQTT disconnect error: {e}")
            return False
    
    def is_connected(self) -> bool:
        """Check if connected to broker"""
        return self.client.is_connected()
    
    def get_received_data(self) -> List[Dict[str, Any]]:
        """Get received data"""
        return self.received_data
    
    def get_last_messages(self, count: int = 10) -> List[Dict[str, Any]]:
        """Get last N messages"""
        return self.received_data[-count:] if self.received_data else []
    
    def clear_received_data(self):
        """Clear received data history"""
        self.received_data.clear()
        logger.info("Received data history cleared")
    
    async def _process_websocket_emission(self, topic: str, payload: Dict[str, Any]):
        """Process and emit data via WebSocket"""
        try:
            # Process infractions from dedicated topic
            if topic == "arduino/data/infracciones":
                # Emit infraction alert with proper Flutter format
                alert_data = {
                    "type": "infraction",
                    "timestamp": time.time(),
                    "data": {
                        "alert_type": payload.get("alert_type", "INFRACCION"),
                        "severity": payload.get("severity", 4),
                        "signal_id": payload.get("signal_id", "unknown"),
                        "signal_color": payload.get("signal_color", "red"),
                        "origen": payload.get("origen", f"Infraccion semaforo {payload.get('signal_id', 'unknown')}"),
                    }
                }
                await self.websocket_manager.emit_alert(alert_data)
                logger.info(f"Infraction alert emitted via WebSocket: {payload.get('signal_id')}")
            
            # Process different types of data for WebSocket emission
            elif "alert_type" in payload:
                # Emit alert
                alert_data = {
                    "timestamp": time.time(),
                    "alert_type": payload.get("alert_type"),
                    "severity": payload.get("severity", 2),
                    "data": payload
                }
                await self.websocket_manager.emit_alert(alert_data)
                logger.info(f"Alert emitted via WebSocket: {payload.get('alert_type')}")
            
            elif topic == "arduino/data":
                # Process seismic alerts
                if "seismic_intensity" in payload:
                    intensity = payload.get("seismic_intensity", 0.0)
                    threshold = payload.get("threshold_g", 2.0)
                    
                    if intensity > threshold:
                        alert_data = {
                            "timestamp": time.time(),
                            "alert_type": "SISMO",
                            "severity": 4,
                            "data": {
                                "alert_type": "SISMO",
                                "severity": 4,
                                "seismic_intensity": intensity,
                                "threshold_g": threshold,
                                "tiene_sismo": True,
                                "origen": "Sensor sísmico - Centro Histórico"
                            }
                        }
                        await self.websocket_manager.emit_alert(alert_data)
                        logger.info(f"Seismic alert emitted via WebSocket: {intensity} G")
                    else:
                        logger.debug(f"Seismic intensity {intensity} G below threshold {threshold} G")
                
                # Process Arduino data for WebSocket emission
                if "semaforos" in payload:
                    semaforos = payload["semaforos"]
                    if isinstance(semaforos, dict):
                        # Emit traffic updates for each semaphore
                        for semaforo_id, estado in semaforos.items():
                            traffic_data = {
                                "timestamp": time.time(),
                                "signal_id": semaforo_id,
                                "signal_color": estado.lower(),
                                "violation_type": "signal_update",
                                "data": payload
                            }
                            await self.websocket_manager.emit_traffic_update(traffic_data)
                    else:
                        logger.debug(f"Semaforos is not a dict: {type(semaforos)}")
                
                if "botones_panico_activos" in payload:
                    botones = payload["botones_panico_activos"]
                    if isinstance(botones, list):
                        # Emit panic button updates
                        for boton in botones:
                            if isinstance(boton, dict) and boton.get("activo", False):
                                stop_data = {
                                    "timestamp": time.time(),
                                    "stop_id": boton["id"],
                                    "event_type": "panic_button",
                                    "data": payload
                                }
                                await self.websocket_manager.emit_stop_update(stop_data)
                    else:
                        logger.debug(f"Botones_panico_activos is not a list: {type(botones)}")
                
                # Process infractions from arduino data
                if "infracciones" in payload:
                    infracciones = payload["infracciones"]
                    if isinstance(infracciones, list) and infracciones:
                        # Emit infraction alerts for each infraction
                        for infraccion in infracciones:
                            signal_id = infraccion if isinstance(infraccion, str) else infraccion.get("signal_id", "unknown")
                            alert_data = {
                                "type": "infraction",
                                "timestamp": time.time(),
                                "data": {
                                    "alert_type": "INFRACCION",
                                    "severity": 4,
                                    "signal_id": signal_id,
                                    "signal_color": "red",
                                    "origen": f"Infraccion semaforo {signal_id}"
                                }
                            }
                            await self.websocket_manager.emit_alert(alert_data)
                            logger.info(f"Infraction from arduino/data emitted via WebSocket: {signal_id}")
                
                # Emit general data update
                general_data = {
                    "timestamp": time.time(),
                    "type": "arduino_data",
                    "data": payload
                }
                await self.websocket_manager.broadcast(general_data, "general")
                
                logger.info("Arduino data processed for WebSocket emission")
            
        except Exception as e:
            logger.error(f"WebSocket emission processing error: {e}")


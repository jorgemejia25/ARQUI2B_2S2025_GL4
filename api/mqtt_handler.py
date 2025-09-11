import json
import time
import logging
import asyncio
from typing import List, Dict, Any
import paho.mqtt.client as mqtt
from database import DatabaseManager
from config import MQTT_USERNAME, MQTT_PASSWORD

logger = logging.getLogger(__name__)

class MQTTHandler:
    def __init__(self, broker: str, port: int, topics: List[str], websocket_manager=None):
        self.broker = broker
        self.port = port
        self.topics = topics
        self.client = mqtt.Client()
        self.received_data = []
        self.db_manager = DatabaseManager()
        self.websocket_manager = websocket_manager
        
        # Configurar callbacks
        self.client.on_connect = self.on_connect
        self.client.on_message = self.on_message
        self.client.on_disconnect = self.on_disconnect
        
    def on_connect(self, client, userdata, flags, rc):
        """Callback cuando se conecta al broker MQTT"""
        logger.info(f"Conectado a MQTT broker con código: {rc}")
        
        # Suscribirse a todos los tópicos
        for topic in self.topics:
            client.subscribe(topic)
            logger.info(f"Suscrito a: {topic}")
    
    def on_message(self, client, userdata, msg):
        """Callback cuando se recibe un mensaje MQTT"""
        try:
            # Decodificar el mensaje JSON
            payload = json.loads(msg.payload.decode('utf-8'))
            topic = msg.topic
            
            # Crear estructura de datos recibida
            data_received = {
                "timestamp": time.time(),
                "topic": topic,
                "payload": payload
            }
            
            # Agregar a la lista de datos recibidos
            self.received_data.append(data_received)
            
            # Imprimir el JSON recibido de manera visible
            print("\n" + "="*60)
            print("DATOS MQTT RECIBIDOS")
            print("="*60)
            print(f"Topico: {topic}")
            print(f"Timestamp: {time.time():.2f}")
            print(f"Datos recibidos:")
            print(json.dumps(payload, indent=2, ensure_ascii=False))
            print("="*60)
            print()
            
            # Loggear para archivos
            logger.info("=== DATO MQTT RECIBIDO ===")
            logger.info(f"Topico: {topic}")
            logger.info(f"Payload: {json.dumps(payload, indent=2, ensure_ascii=False)}")
            logger.info("==========================")
            
            # Guardar en la base de datos
            try:
                success = self.db_manager.save_mqtt_data(topic, payload)
                if success:
                    logger.info(f"Datos guardados exitosamente en BD para topico: {topic}")
                    
                    # Emitir por WebSocket si es relevante
                    if self.websocket_manager:
                        # Usar asyncio.run_coroutine_threadsafe para ejecutar async desde hilo no-async
                        try:
                            loop = asyncio.get_event_loop()
                            if loop.is_running():
                                # Si estamos en el hilo principal, ejecutar directamente
                                asyncio.create_task(self._emit_websocket_data(topic, payload))
                            else:
                                # Si estamos en un hilo separado, usar run_coroutine_threadsafe
                                future = asyncio.run_coroutine_threadsafe(
                                    self._emit_websocket_data(topic, payload), loop
                                )
                        except RuntimeError:
                            # Si no hay event loop, crear uno nuevo
                            asyncio.run(self._emit_websocket_data(topic, payload))
                else:
                    logger.warning(f"Error guardando datos en BD para topico: {topic}")
            except Exception as e:
                logger.error(f"Excepcion guardando datos en BD: {e}")
            
        except json.JSONDecodeError as e:
            error_msg = f"Error decodificando JSON del topico {msg.topic}: {e}"
            print(f"ERROR: {error_msg}")
            logger.error(error_msg)
        except Exception as e:
            error_msg = f"Error procesando mensaje MQTT: {e}"
            print(f"ERROR: {error_msg}")
            logger.error(error_msg)
    
    def on_disconnect(self, client, userdata, rc):
        """Callback cuando se desconecta del broker MQTT"""
        logger.warning(f"Desconectado del broker MQTT con código: {rc}")
        if rc != 0:
            logger.info("Reintentando conexión...")
            client.reconnect()
    
    def connect(self):
        """Conectar al broker MQTT"""
        try:
            # Configurar autenticación si se proporcionan credenciales
            if MQTT_USERNAME and MQTT_PASSWORD:
                logger.info(f"Configurando autenticación MQTT para usuario: {MQTT_USERNAME}")
                self.client.username_pw_set(MQTT_USERNAME, MQTT_PASSWORD)
            
            self.client.connect(self.broker, self.port, 60)
            self.client.loop_start()
            logger.info(f"Conectado a MQTT broker {self.broker}:{self.port}")
            return True
        except Exception as e:
            logger.error(f"Error conectando a MQTT broker: {e}")
            return False
    
    def disconnect(self):
        """Desconectar del broker MQTT"""
        try:
            self.client.loop_stop()
            self.client.disconnect()
            logger.info("Conexión MQTT cerrada")
            return True
        except Exception as e:
            logger.error(f"Error cerrando conexión MQTT: {e}")
            return False
    
    def is_connected(self) -> bool:
        """Verificar si está conectado al broker"""
        return self.client.is_connected()
    
    def get_client_id(self) -> str:
        """Obtener el ID del cliente MQTT"""
        if self.client._client_id:
            return self.client._client_id.decode()
        return "Unknown"
    
    def get_received_data(self) -> List[Dict[str, Any]]:
        """Obtener los datos recibidos"""
        return self.received_data
    
    def get_total_received(self) -> int:
        """Obtener el total de mensajes recibidos"""
        return len(self.received_data)
    
    def get_last_messages(self, count: int = 10) -> List[Dict[str, Any]]:
        """Obtener los últimos N mensajes recibidos"""
        return self.received_data[-count:] if self.received_data else []
    
    def clear_received_data(self):
        """Limpiar el historial de datos recibidos"""
        self.received_data.clear()
        logger.info("Historial de datos MQTT limpiado")
    
    async def _emit_websocket_data(self, topic: str, payload: Dict[str, Any]):
        """Emitir datos por WebSocket según el tipo de información"""
        try:
            logger.info("=== INICIANDO EMISIÓN WEBSOCKET ===")
            logger.info(f"Topico MQTT: {topic}")
            logger.info(f"Tipo de payload: {type(payload)}")
            logger.info(f"Payload: {json.dumps(payload, ensure_ascii=False)}")
            
            # Verificar que el payload sea un diccionario
            if not isinstance(payload, dict):
                logger.error(f"Payload no es un diccionario: {type(payload)} - {payload}")
                return
            
            if topic == "arduino/data":
                # Procesar datos del Arduino
                if "alert_type" in payload:
                    logger.info(f"Procesando alerta tipo: {payload['alert_type']}")
                    
                    # Es una alerta
                    alert_data = {
                        "timestamp": time.time(),
                        "alert_type": payload["alert_type"],
                        "severity": payload.get("severity", 2),
                        "data": payload
                    }
                    
                    # Emitir alerta general
                    logger.info("Emitiendo alerta general por WebSocket...")
                    await self.websocket_manager.emit_alert(alert_data)
                    logger.info("Alerta general emitida exitosamente")
                    
                    # Emitir por tipo específico
                    if payload["alert_type"] == "INFRACCION":
                        logger.info("Procesando infracción de semáforo...")
                        # Actualización de semáforo
                        traffic_data = {
                            "timestamp": time.time(),
                            "signal_id": payload.get("signal_id", "unknown"),
                            "signal_color": payload.get("signal_color", "red"),
                            "violation_type": "red_light",
                            "data": payload
                        }
                        logger.info(f"Emitiendo actualización de semáforo: {traffic_data['signal_id']}")
                        await self.websocket_manager.emit_traffic_update(traffic_data)
                        logger.info("Actualización de semáforo emitida exitosamente")
                        
                    elif payload["alert_type"] == "PANICO":
                        logger.info("Procesando botón de pánico...")
                        # Actualización de parada (botón de pánico)
                        stop_data = {
                            "timestamp": time.time(),
                            "stop_id": payload.get("stop_id", "unknown"),
                            "event_type": "panic_button",
                            "button_id": payload.get("button_id", 1),
                            "data": payload
                        }
                        logger.info(f"Emitiendo actualización de parada: {stop_data['stop_id']}")
                        await self.websocket_manager.emit_stop_update(stop_data)
                        logger.info("Actualización de parada emitida exitosamente")
                        
                elif "gas_ppm" in payload:
                    logger.info(f"Procesando medición de gas: {payload['gas_ppm']} ppm")
                    # Alerta de gas (si supera umbral)
                    threshold = payload.get("threshold_ppm", 100.0)
                    if payload["gas_ppm"] > threshold:
                        logger.info(f"Gas supera umbral ({threshold} ppm), emitiendo alerta...")
                        alert_data = {
                            "timestamp": time.time(),
                            "alert_type": "GAS_ALERT",
                            "severity": 3,
                            "data": payload
                        }
                        await self.websocket_manager.emit_alert(alert_data)
                        logger.info("Alerta de gas emitida exitosamente")
                    else:
                        logger.info(f"Gas no supera umbral ({threshold} ppm), no se emite alerta")
                        
                elif "seismic_intensity" in payload:
                    logger.info(f"Procesando medición sísmica: {payload['seismic_intensity']} g")
                    # Alerta sísmica (si supera umbral)
                    threshold = payload.get("threshold_g", 2.0)
                    if payload["seismic_intensity"] > threshold:
                        alert_data = {
                            "timestamp": time.time(),
                            "alert_type": "SEISMIC_ALERT",
                            "severity": 4,
                            "data": {
                                "seismic_intensity": payload["seismic_intensity"],
                                "threshold_g": threshold,
                                "tiene_sismo": True,
                                "origen": "Centro Histórico",   
                            }
                        }
                        await self.websocket_manager.emit_alert(alert_data)
                        logger.info("Alerta sísmica emitida exitosamente")
                    else:
                        logger.info(f"Sismo no supera umbral ({threshold} g), no se emite alerta")
                else:
                    # Procesar formato de datos del Arduino con múltiples sensores
                    logger.info("Procesando datos del Arduino con formato completo...")
                    
                    # Procesar semáforos
                    if "semaforos" in payload:
                        logger.info(f"Procesando {len(payload['semaforos'])} semáforos...")
                        for semaforo in payload["semaforos"]:
                            estado = semaforo.get("estado", "UNKNOWN")
                            semaforo_id = semaforo["id"]
                            
                            logger.info(f"Semáforo {semaforo_id} en estado {estado} - emitiendo actualización de tráfico")
                            
                            # Mapear estados del Arduino a colores estándar
                            color_mapping = {
                                "VERDE": "green",
                                "AMARILLO": "yellow", 
                                "ROJO": "red"
                            }
                            
                            signal_color = color_mapping.get(estado, estado.lower())
                            
                            # Determinar tipo de violación solo para rojo
                            violation_type = "red_light" if estado == "ROJO" else "signal_update"
                            
                            traffic_data = {
                                "timestamp": time.time(),
                                "signal_id": semaforo_id,
                                "signal_color": signal_color,
                                "violation_type": violation_type,
                                "data": {
                                    "alert_type": "INFRACCION" if estado == "ROJO" else "SIGNAL_UPDATE",
                                    "signal_id": semaforo_id,
                                    "signal_color": signal_color,
                                    "severity": 3 if estado == "ROJO" else 1
                                }
                            }
                            
                            await self.websocket_manager.emit_traffic_update(traffic_data)
                            logger.info(f"Actualización de tráfico emitida para semáforo {semaforo_id} (estado: {estado})")
                    
                    # Procesar datos de ETA (tiempos de llegada de buses)
                    if "eta" in payload and payload["eta"]:
                        eta_data = payload["eta"]
                        logger.info(f"🚌 DATOS ETA RECIBIDOS: {eta_data}")
                        logger.info(f"Procesando {len(eta_data)} ETAs de transporte...")
                        
                        # Definir categorías de paradas correctas (según mapeo del Arduino)
                        PARADAS_TRANSMETRO = ["P3", "P4"]  # TM1, TM2
                        PARADAS_TRANSURBANO = ["P1", "P2"]  # TU3, TU4
                        
                        # El Arduino envía eta como array de objetos con información completa
                        for eta_item in eta_data:
                            parada = eta_item.get("parada", "unknown")
                            tipo_transporte = eta_item.get("tipo_transporte", "unknown")
                            tiempo_segundos = eta_item.get("tiempo_segundos", 0)
                            info = eta_item.get("info", "")
                            
                            # Verificar que la parada sea válida (solo P1, P2, P3, P4)
                            if parada not in PARADAS_TRANSMETRO + PARADAS_TRANSURBANO:
                                logger.warning(f"Parada {parada} no válida - solo se permiten P1, P2, P3, P4")
                                continue
                            
                            # Verificar que el tipo de transporte coincida con la categoría de parada
                            if parada in PARADAS_TRANSMETRO and tipo_transporte != "Transmetro":
                                logger.warning(f"Parada {parada} debe ser Transmetro, pero se recibió {tipo_transporte}")
                                continue
                            elif parada in PARADAS_TRANSURBANO and tipo_transporte != "Transurbano":
                                logger.warning(f"Parada {parada} debe ser Transurbano, pero se recibió {tipo_transporte}")
                                continue
                            
                            logger.info(f"ETA válido detectado en parada {parada}: {tipo_transporte} en {tiempo_segundos}s")
                            
                            # Extraer origen del string de información
                            origen = "Desconocido"
                            try:
                                if "FROM=" in info:
                                    origen_part = info.split("FROM=")[1].split(",")[0]
                                    origen = origen_part
                            except (IndexError, ValueError):
                                logger.warning(f"No se pudo extraer origen de: {info}")
                            
                            # Emitir actualización de parada con información de ETA
                            stop_data = {
                                "timestamp": time.time(),
                                "stop_id": parada,
                                "event_type": "eta_update",
                                "eta_info": {
                                    "tipo_transporte": tipo_transporte,
                                    "tiempo_segundos": tiempo_segundos,
                                    "origen": origen,
                                    "info": info
                                },
                                "data": {
                                    "alert_type": "ETA_UPDATE",
                                    "stop_id": parada,
                                    "tipo_transporte": tipo_transporte,
                                    "tiempo_segundos": tiempo_segundos,
                                    "origen": origen,
                                    "severity": 1
                                }
                            }
                            
                            await self.websocket_manager.emit_stop_update(stop_data)
                            logger.info(f"Actualización de parada emitida para ETA en {parada}: {tipo_transporte} desde {origen} en {tiempo_segundos}s")
                    
                    # Procesar botones de pánico activos
                    if "botones_panico_activos" in payload:
                        logger.info(f"Procesando {len(payload['botones_panico_activos'])} botones de pánico...")
                        for boton in payload["botones_panico_activos"]:
                            if boton.get("activo", False):
                                logger.info(f"Botón de pánico {boton['id']} activo - emitiendo actualización de parada")
                                stop_data = {
                                    "timestamp": time.time(),
                                    "stop_id": boton["id"],
                                    "event_type": "panic_button",
                                    "button_id": boton.get("button_id", boton["id"]),
                                    "data": {
                                        "alert_type": "PANICO",
                                        "stop_id": boton["id"],
                                        "button_id": boton.get("button_id", boton["id"]),
                                        "severity": 3
                                    }
                                }
                                await self.websocket_manager.emit_stop_update(stop_data)
                                # también como ALERTA para /ws/alerts
                                alert_data = {
                                    "timestamp": time.time(),
                                    "alert_type": "PANICO",
                                    "severity": 5,
                                    "stop_id": boton["id"],
                                    "origen": boton.get("ubicacion", f"Parada {boton['id']}"),
                                }
                                await self.websocket_manager.emit_alert(alert_data)
                                logger.info(f"Actualización de parada y alerta emitidas para botón {boton['id']}")

                    # Procesar mediciones de gas
                    if "gas" in payload:
                        logger.info(f"Procesando {len(payload['gas'])} mediciones de gas...")
                        for gas_measurement in payload["gas"]:
                            ppm = gas_measurement.get("ppm", 0)
                            is_alto = gas_measurement.get("is_alto", False)
                            zona = gas_measurement.get("zona", "unknown")
                            
                            if is_alto or ppm > 100:  # Umbral de 100 ppm
                                logger.info(f"Gas alto detectado en {zona}: {ppm} ppm - emitiendo alerta")
                                # Dentro de "Procesar mediciones de gas":
                                alert_data = {
                                    "timestamp": time.time(),
                                    "alert_type": "GAS_ALERT",
                                    "severity": 3,
                                    "data": {
                                        "gas_ppm": ppm,
                                        "threshold_ppm": 100.0,
                                        "zona": zona,
                                        "origen": zona,         
                                        "is_alto": is_alto
                                    }
                                }
                                await self.websocket_manager.emit_alert(alert_data)
                                logger.info(f"Alerta de gas emitida para zona {zona}")
                    
                    # Procesar detección de sismo
                    if "tiene_sismo" in payload and payload["tiene_sismo"]:
                        logger.info("Sismo detectado - emitiendo alerta sísmica")
                        sismo = payload.get("sismo", {}) or {}
                        alert_data = {
                            "timestamp": time.time(),
                            "alert_type": "SEISMIC_ALERT",
                            "severity": 4,
                            "data": {
                                "seismic_intensity": sismo.get("magnitud", 3.0),
                                "threshold_g": 2.0,
                                "tiene_sismo": True,
                                "origen": "Centro Histórico"        
                            }
                        }
                        await self.websocket_manager.emit_alert(alert_data)
                        logger.info("Alerta sísmica emitida exitosamente")
                    
                    # Procesar infracciones
                    if "infracciones" in payload and len(payload["infracciones"]) > 0:
                        logger.info(f"Procesando {len(payload['infracciones'])} infracciones...")
                        for infraccion in payload["infracciones"]:
                            # Aceptar ambos formatos: dict o string ("S9", "SEMAFORO_003", etc.)
                            if isinstance(infraccion, dict):
                                signal_id = (infraccion.get("signal_id")
                                            or infraccion.get("id")
                                            or infraccion.get("semaforo_id")
                                            or "unknown")
                                signal_color = infraccion.get("signal_color", "red")
                                violation_type = infraccion.get("violation_type", "red_light")
                            else:
                                # Es un string (ej. "S9"): asumimos luz roja
                                signal_id = str(infraccion)
                                signal_color = "red"
                                violation_type = "red_light"

                            logger.info(f"Infracción detectada en {signal_id} (color={signal_color})")

                            traffic_data = {
                                "timestamp": time.time(),
                                "signal_id": signal_id,
                                "signal_color": signal_color,
                                "violation_type": violation_type,
                                "data": {
                                    "alert_type": "INFRACCION",
                                    "signal_id": signal_id,
                                    "signal_color": signal_color,
                                    "severity": 5
                                }
                            }

                            # WS: /ws/traffic (para vista de tráfico)
                            await self.websocket_manager.emit_traffic_update(traffic_data)

                            # WS: /ws/alerts (para feed unificado de alertas)
                            alert_data = {
                                "type": "infraction",  # Tipo que reconoce Flutter
                                "timestamp": time.time(),
                                "alert_type": "INFRACCION",
                                "severity": 4,  # Alta severidad
                                "signal_id": signal_id,
                                "signal_color": signal_color,
                                "origen": f"Infracción semáforo {signal_id}",
                                "data": {
                                    "alert_type": "INFRACCION",
                                    "signal_id": signal_id,
                                    "signal_color": signal_color,
                                    "severity": 4
                                }
                            }
                            logger.info(f"🚨 Enviando infracción por WebSocket: {signal_id} - {signal_color}")
                            await self.websocket_manager.emit_alert(alert_data)

                        logger.info("Procesadas todas las infracciones.")


                    
                    logger.info("Procesamiento completo de datos del Arduino finalizado")
                    
            logger.info("=== FINALIZADA EMISIÓN WEBSOCKET ===")
                        
        except Exception as e:
            logger.error(f"Error emitiendo datos por WebSocket: {e}")
            logger.error("=== ERROR EN EMISIÓN WEBSOCKET ===")
    
    def get_database_stats(self) -> Dict[str, Any]:
        """Obtener estadísticas de la base de datos"""
        try:
            # Conectar a la base de datos
            if not self.db_manager.connect():
                return {"error": "No se pudo conectar a la base de datos"}
            
            # Obtener estadísticas básicas
            stats = {
                "database_path": self.db_manager.db_path,
                "connected": self.db_manager.connection is not None
            }
            
            # Obtener conteo de registros en tablas principales
            try:
                # Contar alertas
                alert_count = self.db_manager.execute_query("SELECT COUNT(*) as count FROM Alert")
                if alert_count:
                    stats["total_alerts"] = alert_count[0]["count"]
                
                # Contar posiciones de buses
                bus_pos_count = self.db_manager.execute_query("SELECT COUNT(*) as count FROM BusPosition")
                if bus_pos_count:
                    stats["total_bus_positions"] = bus_pos_count[0]["count"]
                
                # Contar mediciones de gas
                gas_count = self.db_manager.execute_query("SELECT COUNT(*) as count FROM GasMeasurement")
                if gas_count:
                    stats["total_gas_measurements"] = gas_count[0]["count"]
                
                # Contar mediciones sísmicas
                seismic_count = self.db_manager.execute_query("SELECT COUNT(*) as count FROM SeismicMeasurement")
                if seismic_count:
                    stats["total_seismic_measurements"] = seismic_count[0]["count"]
                    
            except Exception as e:
                stats["error"] = f"Error obteniendo estadísticas: {e}"
            
            return stats
            
        except Exception as e:
            return {"error": f"Error general: {e}"}

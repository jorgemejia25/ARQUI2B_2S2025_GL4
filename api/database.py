"""
Gestor de base de datos SQLite para el API IoT
"""

import sqlite3
import logging
from typing import Dict, Any, List, Optional
from datetime import datetime

logger = logging.getLogger(__name__)

class DatabaseManager:
    def __init__(self, db_path: str = None):
        import os
        if db_path is None:
            # En producción, usar un path relativo al contenedor
            self.db_path = os.getenv("DATABASE_PATH", "/app/data/ARQUI_2.db")
        else:
            self.db_path = db_path
        self.connection = None
        
    def connect(self) -> bool:
        """Conectar a la base de datos SQLite"""
        try:
            self.connection = sqlite3.connect(self.db_path)
            self.connection.row_factory = sqlite3.Row
            logger.info(f"Conectado a la base de datos: {self.db_path}")
            return True
        except Exception as e:
            logger.error(f"Error conectando a la base de datos: {e}")
            return False
    
    def disconnect(self):
        """Desconectar de la base de datos"""
        if self.connection:
            self.connection.close()
            self.connection = None
            logger.info("Desconectado de la base de datos")
    
    def execute_query(self, query: str, params: tuple = ()) -> Optional[List[Dict[str, Any]]]:
        """Ejecutar una consulta SQL y retornar resultados"""
        try:
            if not self.connection:
                self.connect()
            
            cursor = self.connection.cursor()
            cursor.execute(query, params)
            
            if query.strip().upper().startswith('SELECT'):
                results = cursor.fetchall()
                return [dict(row) for row in results]
            else:
                self.connection.commit()
                return None
                
        except Exception as e:
            logger.error(f"Error ejecutando consulta: {e}")
            return None
    
    def save_mqtt_data(self, topic: str, payload: Dict[str, Any]) -> bool:
        """Guardar datos recibidos por MQTT en la base de datos"""
        try:
            # Determinar qué tabla usar basado en el tópico
            if topic == "arduino/data":
                return self._save_arduino_data(payload)
            elif topic.startswith("iot/bus/"):
                return self._save_bus_data(topic, payload)
            elif topic.startswith("iot/sensor/"):
                return self._save_sensor_data(topic, payload)
            else:
                logger.warning(f"Topico no reconocido para guardar: {topic}")
                return False
                
        except Exception as e:
            logger.error(f"Error guardando datos MQTT: {e}")
            return False
    
    def _save_arduino_data(self, payload: Dict[str, Any]) -> bool:
        """Guardar datos del Arduino"""
        try:
            saved_something = False
            
            # Procesar datos de gas
            if "gas" in payload and isinstance(payload["gas"], list):
                for gas_data in payload["gas"]:
                    if "ppm" in gas_data:
                        query = """
                        INSERT INTO GasMeasurement (ts, ppm) 
                        VALUES (datetime('now'), ?)
                        """
                        result = self.execute_query(query, (gas_data["ppm"],))
                        if result is not None:
                            logger.info(f"Medición de gas guardada: {gas_data['ppm']} ppm (zona: {gas_data.get('zona', 'N/A')})")
                            saved_something = True
                
            # Procesar datos sísmicos
            if payload.get("tiene_sismo", False) and "sismo" in payload:
                sismo_data = payload["sismo"]
                if "magnitud" in sismo_data:
                    query = """
                    INSERT INTO SeismicMeasurement (ts, intensity_g) 
                    VALUES (datetime('now'), ?)
                    """
                    result = self.execute_query(query, (sismo_data["magnitud"],))
                    if result is not None:
                        logger.info(f"Medición sísmica guardada: {sismo_data['magnitud']} g (origen: {sismo_data.get('origen', 'N/A')})")
                        saved_something = True
            
            # Procesar infracciones de tráfico
            if "infracciones" in payload and isinstance(payload["infracciones"], list):
                for infraccion in payload["infracciones"]:
                    # Obtener el tipo de alerta INFRACCION
                    alert_type_query = "SELECT alert_type_id FROM AlertType WHERE code = 'INFRACCION'"
                    alert_type_result = self.execute_query(alert_type_query)
                    
                    if alert_type_result:
                        alert_type_id = alert_type_result[0]["alert_type_id"]
                        
                        # Insertar la alerta principal
                        alert_query = """
                        INSERT INTO Alert (ts, alert_type_id, severity, bus_id, stop_id) 
                        VALUES (datetime('now'), ?, ?, ?, ?)
                        """
                        # Manejar tanto strings ("S1") como diccionarios
                        if isinstance(infraccion, dict):
                            severity = infraccion.get("severity", 3)
                            signal_id = infraccion.get("signal_id", str(infraccion))
                        else:
                            # Es un string como "S1"
                            severity = 3  # Severidad por defecto
                            signal_id = str(infraccion)
                        
                        result = self.execute_query(alert_query, (alert_type_id, severity, None, None))
                        
                        if result is not None:
                            # Obtener el ID de la alerta insertada
                            alert_id_query = "SELECT last_insert_rowid() as alert_id"
                            alert_id_result = self.execute_query(alert_id_query)
                            
                            if alert_id_result:
                                alert_id = alert_id_result[0]["alert_id"]
                                
                                # Insertar en TrafficInfraction
                                infraction_query = """
                                INSERT INTO TrafficInfraction (alert_id, signal_color) 
                                VALUES (?, ?)
                                """
                                # Usar signal_color de la infracción o por defecto "red"
                                if isinstance(infraccion, dict):
                                    signal_color = infraccion.get("signal_color", "red")
                                else:
                                    signal_color = "red"  # Por defecto para strings como "S1"
                                
                                self.execute_query(infraction_query, (alert_id, signal_color))
                                logger.info(f"Infracción de tráfico guardada: {signal_id} - {signal_color}")
                                saved_something = True
            
            # Procesar botones de pánico activos
            if "botones_panico_activos" in payload and isinstance(payload["botones_panico_activos"], list):
                for boton in payload["botones_panico_activos"]:
                    # Obtener el tipo de alerta PANICO
                    alert_type_query = "SELECT alert_type_id FROM AlertType WHERE code = 'PANICO'"
                    alert_type_result = self.execute_query(alert_type_query)
                    
                    if alert_type_result:
                        alert_type_id = alert_type_result[0]["alert_type_id"]
                        
                        # Insertar la alerta principal
                        alert_query = """
                        INSERT INTO Alert (ts, alert_type_id, severity, bus_id, stop_id) 
                        VALUES (datetime('now'), ?, ?, ?, ?)
                        """
                        severity = boton.get("severity", 1)
                        stop_id = boton.get("stop_id")
                        result = self.execute_query(alert_query, (alert_type_id, severity, None, stop_id))
                        
                        if result is not None:
                            # Obtener el ID de la alerta insertada
                            alert_id_query = "SELECT last_insert_rowid() as alert_id"
                            alert_id_result = self.execute_query(alert_id_query)
                            
                            if alert_id_result:
                                alert_id = alert_id_result[0]["alert_id"]
                                
                                # Insertar en PanicEvent
                                panic_query = """
                                INSERT INTO PanicEvent (alert_id, button_id) 
                                VALUES (?, ?)
                                """
                                button_id = boton.get("button_id", 1)
                                self.execute_query(panic_query, (alert_id, button_id))
                                logger.info(f"Botón de pánico guardado: {button_id}")
                                saved_something = True
            
            # Procesar datos de buses
            if "buses" in payload and isinstance(payload["buses"], list):
                for bus_data in payload["buses"]:
                    bus_code = bus_data.get("bus_code", "")
                    latitude = bus_data.get("latitude")
                    longitude = bus_data.get("longitude")
                    speed_kmh = bus_data.get("speed_kmh")
                    distance_to_next_stop_m = bus_data.get("distance_to_next_stop_m")
                    
                    # Validar que tenemos datos mínimos
                    if not bus_code or latitude is None or longitude is None:
                        logger.warning(f"Datos de bus incompletos: {bus_data}")
                        continue
                    
                    # Obtener bus_id del código
                    bus_query = "SELECT bus_id FROM Bus WHERE code = ?"
                    bus_result = self.execute_query(bus_query, (bus_code,))
                    
                    if not bus_result:
                        logger.warning(f"Bus no encontrado con código: {bus_code}")
                        continue
                    
                    bus_id = bus_result[0]["bus_id"]
                    
                    # Insertar posición del bus
                    position_query = """
                    INSERT INTO BusPosition (bus_id, ts, latitude, longitude, speed_kmh, distance_to_next_stop_m) 
                    VALUES (?, datetime('now'), ?, ?, ?, ?)
                    """
                    
                    result = self.execute_query(position_query, (
                        bus_id,
                        latitude,
                        longitude,
                        speed_kmh,
                        distance_to_next_stop_m
                    ))
                    
                    if result is not None:
                        logger.info(f"Posición de bus guardada: {bus_code} - Lat: {latitude}, Lng: {longitude}")
                        saved_something = True
                    else:
                        logger.error(f"Error insertando posición de bus: {bus_code}")
            
            # Si se guardó algo, retornar True
            if saved_something:
                return True
            
            # Si no se guardó nada específico, es un payload genérico válido
            logger.info(f"Datos genéricos del Arduino procesados (sin datos específicos para guardar)")
            return True
                
        except Exception as e:
            logger.error(f"Error guardando datos del Arduino: {e}")
            return False
    
    def _save_bus_data(self, topic: str, payload: Dict[str, Any]) -> bool:
        """Guardar datos de buses"""
        try:
            logger.info(f"Procesando datos de bus: {topic} - {payload}")
            
            # Extraer datos del payload
            bus_code = payload.get("bus_code", "")
            latitude = payload.get("latitude")
            longitude = payload.get("longitude")
            speed_kmh = payload.get("speed_kmh")
            distance_to_next_stop_m = payload.get("distance_to_next_stop_m")
            
            # Validar que tenemos datos mínimos
            if not bus_code or latitude is None or longitude is None:
                logger.warning(f"Datos de bus incompletos: {payload}")
                return False
            
            # Obtener bus_id del código
            bus_query = "SELECT bus_id FROM Bus WHERE code = ?"
            bus_result = self.execute_query(bus_query, (bus_code,))
            
            if not bus_result:
                logger.warning(f"Bus no encontrado con código: {bus_code}")
                return False
            
            bus_id = bus_result[0]["bus_id"]
            
            # Insertar posición del bus
            position_query = """
            INSERT INTO BusPosition (bus_id, ts, latitude, longitude, speed_kmh, distance_to_next_stop_m) 
            VALUES (?, datetime('now'), ?, ?, ?, ?)
            """
            
            result = self.execute_query(position_query, (
                bus_id,
                latitude,
                longitude,
                speed_kmh,
                distance_to_next_stop_m
            ))
            
            if result is not None:
                logger.info(f"Posición de bus guardada: {bus_code} - Lat: {latitude}, Lng: {longitude}")
                return True
            else:
                logger.error(f"Error insertando posición de bus: {bus_code}")
                return False
                
        except Exception as e:
            logger.error(f"Error guardando datos de bus: {e}")
            return False
    
    def _save_sensor_data(self, topic: str, payload: Dict[str, Any]) -> bool:
        """Guardar datos de sensores"""
        try:
            # Aquí implementarías la lógica específica para guardar datos de sensores
            logger.info(f"Guardando datos de sensor: {topic} - {payload}")
            return True
        except Exception as e:
            logger.error(f"Error guardando datos de sensor: {e}")
            return False
    
    def get_recent_alerts(self, limit: int = 10) -> List[Dict[str, Any]]:
        """Obtener alertas recientes"""
        query = """
        SELECT a.alert_id, a.ts, at.description, a.severity, a.bus_id, a.stop_id
        FROM Alert a
        JOIN AlertType at ON a.alert_type_id = at.alert_type_id
        ORDER BY a.ts DESC
        LIMIT ?
        """
        return self.execute_query(query, (limit,)) or []
    
    def get_bus_positions(self, bus_id: Optional[int] = None) -> List[Dict[str, Any]]:
        """Obtener posiciones de buses"""
        if bus_id:
            query = """
            SELECT bp.*, b.code as bus_code
            FROM BusPosition bp
            JOIN Bus b ON bp.bus_id = b.bus_id
            WHERE bp.bus_id = ?
            ORDER BY bp.ts DESC
            LIMIT 10
            """
            return self.execute_query(query, (bus_id,)) or []
        else:
            query = """
            SELECT bp.*, b.code as bus_code
            FROM BusPosition bp
            JOIN Bus b ON bp.bus_id = b.bus_id
            ORDER BY bp.ts DESC
            LIMIT 20
            """
            return self.execute_query(query) or []
    
    def __enter__(self):
        """Context manager para usar 'with'"""
        self.connect()
        return self
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        """Context manager para usar 'with'"""
        self.disconnect()

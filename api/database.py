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
            # Determinar qué tipo de datos es basado en el payload
            if "gas_ppm" in payload:
                # Es una medición de gas
                query = """
                INSERT INTO GasMeasurement (ts, ppm) 
                VALUES (datetime('now'), ?)
                """
                result = self.execute_query(query, (payload["gas_ppm"],))
                logger.info(f"Medición de gas guardada: {payload['gas_ppm']} ppm")
                return result is not None
                
            elif "seismic_intensity" in payload:
                # Es una medición sísmica
                query = """
                INSERT INTO SeismicMeasurement (ts, intensity_g) 
                VALUES (datetime('now'), ?)
                """
                result = self.execute_query(query, (payload["seismic_intensity"],))
                logger.info(f"Medición sísmica guardada: {payload['seismic_intensity']} g")
                return result is not None
                
            elif "alert_type" in payload:
                # Es una alerta
                # Primero obtener el tipo de alerta
                alert_type_query = "SELECT alert_type_id FROM AlertType WHERE code = ?"
                alert_type_result = self.execute_query(alert_type_query, (payload["alert_type"],))
                
                if alert_type_result:
                    alert_type_id = alert_type_result[0]["alert_type_id"]
                    
                    # Insertar la alerta principal
                    alert_query = """
                    INSERT INTO Alert (ts, alert_type_id, severity, bus_id, stop_id) 
                    VALUES (datetime('now'), ?, ?, ?, ?)
                    """
                    bus_id = payload.get("bus_id")
                    stop_id = payload.get("stop_id")
                    severity = payload.get("severity", 2)
                    
                    result = self.execute_query(alert_query, (alert_type_id, severity, bus_id, stop_id))
                    
                    if result is not None:
                        # Obtener el ID de la alerta insertada
                        alert_id_query = "SELECT last_insert_rowid() as alert_id"
                        alert_id_result = self.execute_query(alert_id_query)
                        
                        if alert_id_result:
                            alert_id = alert_id_result[0]["alert_id"]
                            
                            # Insertar en la tabla específica según el tipo
                            if payload["alert_type"] == "INFRACCION":
                                infraction_query = """
                                INSERT INTO TrafficInfraction (alert_id, signal_color) 
                                VALUES (?, ?)
                                """
                                signal_color = payload.get("signal_color", "red")
                                self.execute_query(infraction_query, (alert_id, signal_color))
                                
                            elif payload["alert_type"] == "PANICO":
                                panic_query = """
                                INSERT INTO PanicEvent (alert_id, button_id) 
                                VALUES (?, ?)
                                """
                                button_id = payload.get("button_id", 1)
                                self.execute_query(panic_query, (alert_id, button_id))
                                
                            elif payload["alert_type"] == "SISMO":
                                seismic_query = """
                                INSERT INTO SeismicEvent (alert_id, intensity_g, duration_ms) 
                                VALUES (?, ?, ?)
                                """
                                intensity = payload.get("intensity_g", 0.0)
                                duration = payload.get("duration_ms", 0)
                                self.execute_query(seismic_query, (alert_id, intensity, duration))
                                
                            elif payload["alert_type"] == "GAS":
                                gas_query = """
                                INSERT INTO GasEvent (alert_id, ppm, threshold_ppm) 
                                VALUES (?, ?, ?)
                                """
                                ppm = payload.get("ppm", 0.0)
                                threshold = payload.get("threshold_ppm", 100.0)
                                self.execute_query(gas_query, (alert_id, ppm, threshold))
                        
                        logger.info(f"Alerta guardada: {payload['alert_type']}")
                        return True
                
                logger.warning(f"Tipo de alerta no reconocido: {payload['alert_type']}")
                return False
                
            else:
                # Datos genéricos del Arduino
                logger.info(f"Datos genéricos del Arduino guardados: {payload}")
                return True
                
        except Exception as e:
            logger.error(f"Error guardando datos del Arduino: {e}")
            return False
    
    def _save_bus_data(self, topic: str, payload: Dict[str, Any]) -> bool:
        """Guardar datos de buses"""
        try:
            # Aquí implementarías la lógica específica para guardar datos de buses
            logger.info(f"Guardando datos de bus: {topic} - {payload}")
            return True
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

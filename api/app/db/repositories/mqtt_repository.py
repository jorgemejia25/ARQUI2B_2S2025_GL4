"""
MQTT data repository
Handles storage of data received from MQTT
"""

from typing import Dict, Any
from app.db.repositories.base import BaseRepository
from app.core.logging import get_logger

logger = get_logger(__name__)


class MQTTRepository(BaseRepository):
    """Repository for MQTT data operations"""
    
    def save_mqtt_data(self, topic: str, payload: Dict[str, Any]) -> bool:
        """
        Save data received from MQTT based on topic
        
        Args:
            topic: MQTT topic
            payload: Message payload
            
        Returns:
            True if data was saved successfully
        """
        try:
            if topic == "arduino/data":
                return self._save_arduino_data(payload)
            elif topic == "arduino/data/infracciones":
                return self._save_infraction_data(payload)
            else:
                logger.warning(f"Unrecognized MQTT topic: {topic}")
                return False
        except Exception as e:
            logger.error(f"Error saving MQTT data: {e}")
            return False
    
    def _save_arduino_data(self, payload: Dict[str, Any]) -> bool:
        """Save general Arduino data"""
        saved_something = False
        
        # Save gas measurements
        if "gas" in payload and isinstance(payload["gas"], list):
            for gas_data in payload["gas"]:
                if "ppm" in gas_data:
                    query = """
                    INSERT INTO GasMeasurement (ts, ppm) 
                    VALUES (datetime('now'), ?)
                    """
                    result = self.execute_query(query, (gas_data["ppm"],))
                    if result is None:
                        logger.info(f"Gas measurement saved: {gas_data['ppm']} ppm")
                        saved_something = True
        
        # Save seismic measurements
        if payload.get("tiene_sismo", False) and "sismo" in payload:
            sismo_data = payload["sismo"]
            if "magnitud" in sismo_data:
                query = """
                INSERT INTO SeismicMeasurement (ts, intensity_g) 
                VALUES (datetime('now'), ?)
                """
                result = self.execute_query(query, (sismo_data["magnitud"],))
                if result is None:
                    logger.info(f"Seismic measurement saved: {sismo_data['magnitud']} g")
                    saved_something = True
        
        # Save infractions
        if "infracciones" in payload and isinstance(payload["infracciones"], list):
            for infraccion in payload["infracciones"]:
                if self._save_traffic_infraction(infraccion):
                    saved_something = True
        
        # Save panic button events
        if "botones_panico_activos" in payload and isinstance(payload["botones_panico_activos"], list):
            for boton in payload["botones_panico_activos"]:
                if boton.get("activo", False):
                    if self._save_panic_event(boton):
                        saved_something = True
        
        # Save general alerts
        if "alert_type" in payload:
            if self._save_general_alert(payload):
                saved_something = True
        
        return saved_something or True  # Return True even if no specific data was saved
    
    def _save_infraction_data(self, payload: Dict[str, Any]) -> bool:
        """Save traffic infraction from dedicated topic"""
        signal_id = payload.get("signal_id", "unknown")
        severity = payload.get("severity", 4)
        
        # Get INFRACCION alert type
        type_query = "SELECT alert_type_id FROM AlertType WHERE code = 'INFRACCION'"
        type_result = self.execute_query(type_query)
        
        if not type_result:
            logger.error("INFRACCION alert type not found")
            return False
        
        alert_type_id = type_result[0]["alert_type_id"]
        
        # Insert alert
        alert_query = """
        INSERT INTO Alert (ts, alert_type_id, severity, bus_id, stop_id)
        VALUES (datetime('now'), ?, ?, NULL, NULL)
        """
        result = self.execute_query(alert_query, (alert_type_id, severity))
        
        if result is None:
            logger.info(f"Infraction saved: {signal_id}, severity={severity}")
            return True
        else:
            logger.error("Failed to save infraction")
            return False
    
    def _save_traffic_infraction(self, infraccion: Any) -> bool:
        """Save a single traffic infraction"""
        # Get alert type
        type_query = "SELECT alert_type_id FROM AlertType WHERE code = 'INFRACCION'"
        type_result = self.execute_query(type_query)
        
        if not type_result:
            return False
        
        alert_type_id = type_result[0]["alert_type_id"]
        
        # Extract signal data
        if isinstance(infraccion, dict):
            severity = infraccion.get("severity", 3)
            signal_id = infraccion.get("signal_id", str(infraccion))
            signal_color = infraccion.get("signal_color", "red")
        else:
            severity = 3
            signal_id = str(infraccion)
            signal_color = "red"
        
        # Insert alert
        alert_query = """
        INSERT INTO Alert (ts, alert_type_id, severity, bus_id, stop_id) 
        VALUES (datetime('now'), ?, ?, ?, ?)
        """
        result = self.execute_query(alert_query, (alert_type_id, severity, None, None))
        
        if result is None:
            # Get last inserted alert ID
            alert_id_query = "SELECT last_insert_rowid() as alert_id"
            alert_id_result = self.execute_query(alert_id_query)
            
            if alert_id_result:
                alert_id = alert_id_result[0]["alert_id"]
                
                # Insert traffic infraction details
                infraction_query = """
                INSERT INTO TrafficInfraction (alert_id, signal_color) 
                VALUES (?, ?)
                """
                self.execute_query(infraction_query, (alert_id, signal_color))
                logger.info(f"Traffic infraction saved: {signal_id} - {signal_color}")
                return True
        
        return False
    
    def _save_panic_event(self, boton: Dict[str, Any]) -> bool:
        """Save a panic button event"""
        # Get alert type
        type_query = "SELECT alert_type_id FROM AlertType WHERE code = 'PANICO'"
        type_result = self.execute_query(type_query)
        
        if not type_result:
            return False
        
        alert_type_id = type_result[0]["alert_type_id"]
        severity = boton.get("severity", 1)
        stop_id = boton.get("stop_id")
        
        # Insert alert
        alert_query = """
        INSERT INTO Alert (ts, alert_type_id, severity, bus_id, stop_id) 
        VALUES (datetime('now'), ?, ?, ?, ?)
        """
        result = self.execute_query(alert_query, (alert_type_id, severity, None, stop_id))
        
        if result is None:
            # Get last inserted alert ID
            alert_id_query = "SELECT last_insert_rowid() as alert_id"
            alert_id_result = self.execute_query(alert_id_query)
            
            if alert_id_result:
                alert_id = alert_id_result[0]["alert_id"]
                button_id = boton.get("button_id", 1)
                
                # Insert panic event details
                panic_query = """
                INSERT INTO PanicEvent (alert_id, button_id) 
                VALUES (?, ?)
                """
                self.execute_query(panic_query, (alert_id, button_id))
                logger.info(f"Panic button event saved: {button_id}")
                return True
        
        return False
    
    def _save_general_alert(self, payload: Dict[str, Any]) -> bool:
        """Save a general alert"""
        alert_type = payload.get("alert_type")
        severity = payload.get("severity", 2)
        
        # Get alert type ID
        type_query = "SELECT alert_type_id FROM AlertType WHERE code = ?"
        type_result = self.execute_query(type_query, (alert_type,))
        
        if not type_result:
            logger.warning(f"Alert type not found: {alert_type}")
            return False
        
        alert_type_id = type_result[0]["alert_type_id"]
        
        # Insert alert
        alert_query = """
        INSERT INTO Alert (ts, alert_type_id, severity, bus_id, stop_id)
        VALUES (datetime('now'), ?, ?, NULL, NULL)
        """
        result = self.execute_query(alert_query, (alert_type_id, severity))
        
        if result is None:
            logger.info(f"General alert saved: {alert_type}, severity={severity}")
            return True
        
        return False





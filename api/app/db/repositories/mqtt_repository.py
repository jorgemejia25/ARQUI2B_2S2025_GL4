"""
MQTT data repository
Handles storage of data received from MQTT
"""

from typing import Dict, Any, Optional
from app.db.repositories.base import BaseRepository
from app.core.logging import get_logger

logger = get_logger(__name__)

# Secuencias esperadas de sensores para validación de BusPosition
METRO_SEQUENCE = ["PM1", "S2", "S1", "PM2", "S5"]
URBAN_SEQUENCE = ["PU1", "S4", "S3", "PU2", "S3", "S4"]


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
            elif topic == "arduino/data/sensors":
                return self._save_active_sensor_data(payload)
            elif topic == "arduino/data/panic":
                return self._save_panic_alert(payload)
            else:
                logger.warning(f"Unrecognized MQTT topic: {topic}")
                return False
        except Exception as e:
            logger.error(f"Error saving MQTT data: {e}")
            return False
    
    def _save_arduino_data(self, payload: Dict[str, Any]) -> bool:
        """Save general Arduino data"""
        saved_something = False
        
        # Detectar alertas específicas en el topic principal
        alert_type = payload.get("alert_type", "")
        
        if alert_type == "SISMO":
            # Guardar alerta de sismo
            return self._save_seismic_alert(payload)
        
        elif alert_type == "GAS":
            # Guardar alerta de gas/humo
            return self._save_gas_alert(payload)
        
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
        origen = payload.get("origen", f"Infracción {signal_id}")
        
        logger.info(f"Guardando infracción: {signal_id} - {origen}")
        
        # Get INFRACCION alert type
        type_query = "SELECT alert_type_id FROM AlertType WHERE code = 'INFRACCION'"
        type_result = self.execute_query(type_query)
        
        if not type_result:
            logger.error("INFRACCION alert type not found in database")
            return False
        
        alert_type_id = type_result[0]["alert_type_id"]
        
        # Insert alert
        alert_query = """
        INSERT INTO Alert (ts, alert_type_id, severity, bus_id, stop_id)
        VALUES (datetime('now'), ?, ?, NULL, NULL)
        """
        result = self.execute_query(alert_query, (alert_type_id, severity))
        
        if result is None:
            logger.info(f"Infracción guardada exitosamente: {signal_id} (severity={severity})")
            print(f"[DB] Infracción guardada: {signal_id}")
            return True
        else:
            logger.error(f"Error al guardar infracción: {signal_id}")
            return False
    
    def _save_panic_alert(self, payload: Dict[str, Any]) -> bool:
        """Save panic button alert from dedicated topic"""
        button_id = payload.get("button_id", "unknown")
        location = payload.get("location", "unknown")
        severity = payload.get("severity", 5)
        
        logger.info(f"Guardando alerta de pánico: {button_id} en {location}")
        
        # Get PANIC_BUTTON alert type (intentar varios códigos posibles)
        type_query = """
        SELECT alert_type_id FROM AlertType 
        WHERE code IN ('PANIC_BUTTON', 'BOTON_PANICO', 'PANICO')
        LIMIT 1
        """
        type_result = self.execute_query(type_query)
        
        if not type_result:
            logger.error("PANIC_BUTTON alert type not found in database")
            # Intentar con INCENDIO como fallback
            fallback_query = "SELECT alert_type_id FROM AlertType WHERE code = 'INCENDIO'"
            type_result = self.execute_query(fallback_query)
            if not type_result:
                logger.error("No suitable alert type found for panic button")
                return False
        
        alert_type_id = type_result[0]["alert_type_id"]
        
        # Insert alert
        alert_query = """
        INSERT INTO Alert (ts, alert_type_id, severity, bus_id, stop_id)
        VALUES (datetime('now'), ?, ?, NULL, NULL)
        """
        result = self.execute_query(alert_query, (alert_type_id, severity))
        
        if result is None:
            logger.info(f"Panic button alert saved: {button_id} at {location}, severity={severity}")
            return True
        else:
            logger.error("Failed to save panic button alert")
            return False
    
    def _save_seismic_alert(self, payload: Dict[str, Any]) -> bool:
        """Save seismic alert"""
        magnitude = payload.get("seismic_intensity", 0.0)
        origen = payload.get("origen", "Sensor sísmico")
        severity = payload.get("severity", 4)
        
        logger.info(f"Guardando alerta de sismo: magnitud={magnitude}, origen={origen}")
        
        # Get SISMO alert type
        type_query = """
        SELECT alert_type_id FROM AlertType 
        WHERE code IN ('SISMO', 'SEISMIC', 'TERREMOTO')
        LIMIT 1
        """
        type_result = self.execute_query(type_query)
        
        if not type_result:
            logger.error("SISMO alert type not found in database")
            return False
        
        alert_type_id = type_result[0]["alert_type_id"]
        
        # Insert alert
        alert_query = """
        INSERT INTO Alert (ts, alert_type_id, severity, bus_id, stop_id)
        VALUES (datetime('now'), ?, ?, NULL, NULL)
        """
        result = self.execute_query(alert_query, (alert_type_id, severity))
        
        if result is None:
            logger.info(f"Alerta de sismo guardada: magnitud={magnitude}")
            print(f"[DB] Alerta de sismo guardada: magnitud={magnitude}")
            return True
        else:
            logger.error("Failed to save seismic alert")
            return False
    
    def _save_gas_alert(self, payload: Dict[str, Any]) -> bool:
        """Save gas/smoke alert"""
        zone = payload.get("zona", "unknown")
        gas_ppm = payload.get("gas_ppm", 0)
        severity = payload.get("severity", 3)
        
        logger.info(f"Guardando alerta de gas: zona={zone}, ppm={gas_ppm}")
        
        # Get INCENDIO/GAS alert type
        type_query = """
        SELECT alert_type_id FROM AlertType 
        WHERE code IN ('INCENDIO', 'GAS', 'HUMO', 'FIRE')
        LIMIT 1
        """
        type_result = self.execute_query(type_query)
        
        if not type_result:
            logger.error("GAS/INCENDIO alert type not found in database")
            return False
        
        alert_type_id = type_result[0]["alert_type_id"]
        
        # Insert alert
        alert_query = """
        INSERT INTO Alert (ts, alert_type_id, severity, bus_id, stop_id)
        VALUES (datetime('now'), ?, ?, NULL, NULL)
        """
        result = self.execute_query(alert_query, (alert_type_id, severity))
        
        if result is None:
            logger.info(f"Alerta de gas guardada: zona={zone}, ppm={gas_ppm}")
            print(f"[DB] Alerta de gas guardada: zona={zone}, PPM={gas_ppm}")
            return True
        else:
            logger.error("Failed to save gas alert")
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


    def _get_last_bus_position_sensor(self, route_type: str) -> Optional[str]:
        """
        Get the last sensor saved in BusPosition table
        
        Args:
            route_type: "metro" or "urban"
            
        Returns:
            Name of the last sensor (from position column) or None if table is empty
        """
        try:
            if route_type == "metro":
                query = "SELECT position FROM BusPositionMetro ORDER BY ts DESC LIMIT 1"
            else:
                query = "SELECT position FROM BusPositionUrban ORDER BY ts DESC LIMIT 1"
            
            result = self.execute_query(query)
            # execute_query returns list of dicts: [{'position': 'PM1'}]
            if result and len(result) > 0:
                return result[0]['position']
            return None
        except Exception as e:
            logger.error(f"Error getting last bus position sensor: {e}")
            return None

    def _get_last_bus_position_sensors(self, route_type: str, limit: int = 2) -> list[str]:
        """Return a list with the last <limit> sensor names (newest first)."""
        try:
            if route_type == "metro":
                query = "SELECT position FROM BusPositionMetro ORDER BY ts DESC LIMIT ?"
            else:
                query = "SELECT position FROM BusPositionUrban ORDER BY ts DESC LIMIT ?"
            result = self.execute_query(query, (limit,))
            if not result:
                return []
            return [row["position"] for row in result]
        except Exception as e:
            logger.error(f"Error getting last bus position sensors: {e}")
            return []
    
    def _get_next_expected_sensor(self, current_sensor: str, route_type: str) -> str:
        """
        Calculate the next expected sensor in the sequence
        
        Args:
            current_sensor: Last sensor saved in BusPosition
            route_type: "metro" or "urban"
            
        Returns:
            Name of the next expected sensor in the cycle
        """
        sequence = METRO_SEQUENCE if route_type == "metro" else URBAN_SEQUENCE
        
        try:
            current_index = sequence.index(current_sensor)
            next_index = (current_index + 1) % len(sequence)  # Modulo for cycling
            return sequence[next_index]
        except ValueError:
            # If sensor not in sequence, return first sensor
            logger.warning(f"Sensor {current_sensor} not in {route_type} sequence, resetting to first")
            return sequence[0]
    
    def _save_active_sensor_data(self, payload: Dict[str, Any]) -> bool:
        """
        Save active sensor data with sequence validation
        
        Logic:
        1. Always save to ActiveSensorGroup (all sensors)
        2. Only save to BusPosition if sensor follows expected sequence
        3. If BusPosition is empty, accept any sensor as starting point
        
        Args:
            payload: Sensor data with sensor_name and route_type
            
        Returns:
            True if data was saved successfully
        """
        try:
            sensor_name = payload.get("sensor_name")
            route_type = payload.get("route_type", "").lower()
            
            if not sensor_name:
                logger.warning("No sensor_name in payload")
                return False
            
            if route_type not in ["metro", "urban"]:
                logger.warning(f"Unknown route_type: {route_type}")
                return False
            
            # STEP 1: Always save to ActiveSensorGroup (no validation)
            if route_type == "metro":
                query_active = """
                INSERT INTO ActiveSensorGroupMetro (ts, sensor_name)
                VALUES (datetime('now'), ?)
                """
                table_name = "ActiveSensorGroupMetro"
            else:
                query_active = """
                INSERT INTO ActiveSensorGroupUrban (ts, sensor_name)
                VALUES (datetime('now'), ?)
                """
                table_name = "ActiveSensorGroupUrban"
            
            result_active = self.execute_query(query_active, (sensor_name,))
            
            if result_active is not None:
                logger.error(f"Failed to save sensor to {table_name}: {sensor_name}")
                return False
            
            logger.info(f"Sensor saved to {table_name}: {sensor_name}")
            
            # STEP 2: Get last sensor from BusPosition
            last_sensor = self._get_last_bus_position_sensor(route_type)
            
            # STEP 3: Validate sequence
            should_save_to_bus_position = False
            
            if route_type == "urban":
                # Lógica especial con ambigüedad inicial por duplicados (S3, S4)
                sequence = URBAN_SEQUENCE
                if last_sensor is None:
                    # Primer sensor: aceptar siempre y no forzamos índice todavía
                    should_save_to_bus_position = True
                    logger.info(f"🚀 (urban) primer sensor aceptado: {sensor_name}")
                else:
                    last_two = self._get_last_bus_position_sensors("urban", 2)
                    if len(last_two) < 2:
                        # Solo un sensor previo: permitir cualquiera de los siguientes posibles
                        # para todas las ocurrencias del last_sensor en la secuencia
                        candidate_next = set()
                        for i, val in enumerate(sequence):
                            if val == last_sensor:
                                candidate_next.add(sequence[(i + 1) % len(sequence)])
                        if sensor_name in candidate_next:
                            should_save_to_bus_position = True
                            logger.info(
                                f"✅ (urban) sensor válido en fase ambigua: {sensor_name} (posibles={sorted(candidate_next)})"
                            )
                        else:
                            logger.warning(
                                f"❌ (urban) sensor descartado en fase ambigua: {sensor_name} (esperados uno de {sorted(candidate_next)})"
                            )
                    else:
                        # Tenemos al menos dos previos: prev2 -> prev1 ya desambigua
                        prev1 = last_two[0]  # más reciente
                        prev2 = last_two[1]
                        # Encontrar índices donde prev2 -> prev1 es válido
                        matching_indices = []
                        for i, val in enumerate(sequence):
                            if val == prev2 and sequence[(i + 1) % len(sequence)] == prev1:
                                matching_indices.append((i + 1) % len(sequence))
                        if len(matching_indices) == 1:
                            idx_prev1 = matching_indices[0]
                            expected = sequence[(idx_prev1 + 1) % len(sequence)]
                            if sensor_name == expected:
                                should_save_to_bus_position = True
                                logger.info(
                                    f"✅ (urban) sensor válido tras desambiguar: {sensor_name} (expected: {expected})"
                                )
                            else:
                                logger.warning(
                                    f"❌ (urban) sensor inválido: {sensor_name} (expected: {expected})"
                                )
                        else:
                            # Si por algún motivo no se pudo desambiguar (no debería pasar con secuencia actual), 
                            # volvemos a lógica de conjunto de posibles
                            candidate_next = set()
                            for i, val in enumerate(sequence):
                                if val == last_sensor:
                                    candidate_next.add(sequence[(i + 1) % len(sequence)])
                            if sensor_name in candidate_next:
                                should_save_to_bus_position = True
                                logger.info(
                                    f"✅ (urban) sensor válido fallback: {sensor_name} (posibles={sorted(candidate_next)})"
                                )
                            else:
                                logger.warning(
                                    f"❌ (urban) sensor inválido fallback: {sensor_name} (esperados uno de {sorted(candidate_next)})"
                                )
            else:
                # Comportamiento original para metro
                if last_sensor is None:
                    should_save_to_bus_position = True
                    logger.info(f"🚀 First sensor in BusPosition{route_type.capitalize()}: {sensor_name}")
                else:
                    expected_sensor = self._get_next_expected_sensor(last_sensor, route_type)
                    if sensor_name == expected_sensor:
                        should_save_to_bus_position = True
                        logger.info(f"✅ Valid sensor ({route_type}): {sensor_name} (expected: {expected_sensor})")
                    else:
                        logger.warning(f"❌ Invalid sensor ({route_type}): {sensor_name} (expected: {expected_sensor}, skipped for BusPosition)")
            
            # STEP 4: Save to BusPosition only if valid
            # Using default values for simulation: bus_id=1, speed_kmh=50, distance_to_next_stop=100
            # Sensor name is saved in 'position' column
            if should_save_to_bus_position:
                if route_type == "metro":
                    query_bus = """
                    INSERT INTO BusPositionMetro (ts, bus_id, speed_kmh, position, distance_to_next_stop)
                    VALUES (datetime('now'), 1, 50.0, ?, 100.0)
                    """
                    bus_table = "BusPositionMetro"
                else:
                    query_bus = """
                    INSERT INTO BusPositionUrban (ts, bus_id, speed_kmh, position, distance_to_next_stop)
                    VALUES (datetime('now'), 1, 50.0, ?, 100.0)
                    """
                    bus_table = "BusPositionUrban"
                
                result_bus = self.execute_query(query_bus, (sensor_name,))
                
                if result_bus is None:
                    logger.info(f"Sensor saved to {bus_table}: {sensor_name} (bus_id=1, speed=50km/h, distance=100m)")
                else:
                    logger.error(f"Failed to save sensor to {bus_table}: {sensor_name}")
            
            return True
                
        except Exception as e:
            logger.error(f"Error saving active sensor data: {e}")
            return False





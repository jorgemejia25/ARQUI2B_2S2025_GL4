"""
Arduino data parser
Parses JSON data from Arduino serial communication
"""

import json
from typing import Dict, Any, Optional
from app.models.arduino_data import (
    ArduinoData, GasSensor, PanicButton, ETAInfo, SeismicEvent
)
from app.core.logging import get_logger

logger = get_logger(__name__)


class ArduinoDataParser:
    """Parser for Arduino JSON data"""
    
    @staticmethod
    def parse_json(json_str: str) -> Optional[ArduinoData]:
        """
        Parse JSON string from Arduino
        
        Args:
            json_str: JSON string from Arduino
            
        Returns:
            ArduinoData object or None if parsing fails
        """
        try:
            data = json.loads(json_str)
            return ArduinoDataParser.parse_dict(data)
        except json.JSONDecodeError as e:
            # Log a short, sanitized preview to help diagnose malformed inputs
            preview = (json_str or "").replace("\n", " ").replace("\r", " ")
            if len(preview) > 256:
                preview = preview[:256] + "..."
            logger.error(f"JSON decode error: {e}; payload_len={len(json_str) if json_str is not None else 0}; preview='{preview}'")
            return None
        except Exception as e:
            logger.error(f"Parse error: {e}")
            return None
    
    @staticmethod
    def parse_dict(data: Dict[str, Any]) -> ArduinoData:
        """
        Parse dictionary data from Arduino
        
        Args:
            data: Dictionary with Arduino data
            
        Returns:
            ArduinoData object
        """
        # Parse traffic lights
        traffic_lights = data.get("semaforos", {})
        if not isinstance(traffic_lights, dict):
            traffic_lights = {}
        
        # Parse distances
        distances = data.get("dist_cm", {})
        if not isinstance(distances, dict):
            distances = {}
        
        # Parse gas sensors
        gas_sensors = []
        
        # Intentar formato de lista (simulador): [{"zona": "Z1", "ppm": 200, ...}, ...]
        gas_data = data.get("gas", [])
        if isinstance(gas_data, list):
            for gas in gas_data:
                if isinstance(gas, dict):
                    ppm_value = gas.get("ppm", 0)
                    is_high = gas.get("is_alto", False) or ppm_value > 275
                    gas_sensors.append(GasSensor(
                        zone=gas.get("zona", "unknown"),
                        ppm=ppm_value,
                        is_high=is_high
                    ))
        
        # Intentar formato de objeto (Arduino real): {"gas_ppm": {"Z1": 200, "Z2": 200}}
        gas_ppm_data = data.get("gas_ppm", {})
        if isinstance(gas_ppm_data, dict):
            for zone, ppm_value in gas_ppm_data.items():
                if isinstance(ppm_value, (int, float)):
                    is_high = ppm_value > 275
                    if is_high:
                        logger.info(f"Gas alto detectado en {zone}: {ppm_value} PPM")
                    gas_sensors.append(GasSensor(
                        zone=zone,
                        ppm=int(ppm_value),
                        is_high=is_high
                    ))
        
        # Parse panic buttons
        panic_buttons = []
        # Intentar ambos formatos: objeto (Arduino real) y lista (simulador)
        panic_data = data.get("panic_buttons", data.get("botones_panico_activos", []))
        
        if isinstance(panic_data, dict):
            # Formato del Arduino real: {"PB1": {"activo": 1, "ts": "...", "id": "PB1"}, ...}
            for button_key, button_info in panic_data.items():
                if isinstance(button_info, dict):
                    is_active = button_info.get("activo", 0) == 1 or button_info.get("activo", False)
                    if is_active:
                        logger.info(f"Botón de pánico detectado: {button_key} - activo={is_active}")
                    panic_buttons.append(PanicButton(
                        id=button_info.get("id", button_key),
                        active=is_active,
                        button_id=str(button_info.get("id", button_key)),
                        location=button_info.get("ubicacion", f"Zona {button_key}")
                    ))
        elif isinstance(panic_data, list):
            # Formato del simulador: [{"id": "PB1", "activo": true, ...}, ...]
            for button in panic_data:
                if isinstance(button, dict):
                    is_active = button.get("activo", False)
                    if is_active:
                        logger.info(f"Botón de pánico detectado (lista): {button.get('id')} - activo={is_active}")
                    panic_buttons.append(PanicButton(
                        id=button.get("id", "unknown"),
                        active=is_active,
                        button_id=str(button.get("button_id", "")),
                        location=button.get("ubicacion", "")
                    ))
        
        # Parse ETA information
        eta_info = []
        eta_data = data.get("eta", [])
        if isinstance(eta_data, list):
            for eta in eta_data:
                if isinstance(eta, dict):
                    eta_info.append(ETAInfo(
                        stop=eta.get("parada", ""),
                        transport_type=eta.get("tipo_transporte", ""),
                        time_seconds=eta.get("tiempo_segundos", 0),
                        origin=ArduinoDataParser._extract_origin(eta.get("info", "")),
                        info=eta.get("info", "")
                    ))
        
        # Parse infractions
        infractions = data.get("infracciones", [])
        if not isinstance(infractions, list):
            infractions = []
        
        # Log infracciones detectadas
        if infractions:
            logger.info(f"Infracciones parseadas del Arduino: {infractions}")
        
        # Parse seismic data
        has_earthquake = data.get("tiene_sismo", False)
        seismic_event = None
        if has_earthquake or "sismo" in data:
            sismo_data = data.get("sismo", {})
            if isinstance(sismo_data, dict):
                seismic_event = SeismicEvent(
                    active=sismo_data.get("activo", 0) == 1 or has_earthquake,
                    magnitude=float(sismo_data.get("magnitud", 0.0)),
                    origin=sismo_data.get("origen", "")
                )
        
        return ArduinoData(
            timestamp=data.get("ts", str(int(time.time() * 1000))),
            traffic_lights=traffic_lights,
            distances=distances,
            gas_sensors=gas_sensors,
            panic_buttons=panic_buttons,
            eta_info=eta_info,
            infractions=infractions,
            seismic_event=seismic_event,
            has_earthquake=has_earthquake
        )
    
    @staticmethod
    def _extract_origin(info_str: str) -> str:
        """Extract origin from ETA info string"""
        try:
            if "FROM=" in info_str:
                origin_part = info_str.split("FROM=")[1].split(",")[0]
                return origin_part
        except (IndexError, AttributeError):
            pass
        return "Unknown"


import time

def parse_arduino_json(json_str: str) -> Optional[ArduinoData]:
    """
    Convenience function to parse Arduino JSON
    
    Args:
        json_str: JSON string from Arduino
        
    Returns:
        ArduinoData object or None
    """
    return ArduinoDataParser.parse_json(json_str)










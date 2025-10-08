"""
Arduino data models
Structured representation of Arduino sensor data
"""

from typing import Dict, List, Optional, Any
from dataclasses import dataclass, field


@dataclass
class TrafficLight:
    """Traffic light state"""
    id: str
    state: str  # VERDE, AMARILLO, ROJO


@dataclass
class DistanceSensor:
    """Distance sensor reading"""
    sensor_id: str
    distance_cm: float


@dataclass
class GasSensor:
    """Gas sensor reading"""
    zone: str
    ppm: int
    is_high: bool


@dataclass
class PanicButton:
    """Panic button state"""
    id: str
    active: bool
    button_id: str
    location: str


@dataclass
class ETAInfo:
    """Estimated time of arrival information"""
    stop: str
    transport_type: str
    time_seconds: int
    origin: str
    info: str


@dataclass
class SeismicEvent:
    """Seismic event data"""
    active: bool
    magnitude: float
    origin: str


@dataclass
class ArduinoData:
    """Complete Arduino sensor data"""
    
    timestamp: str
    traffic_lights: Dict[str, str] = field(default_factory=dict)
    distances: Dict[str, float] = field(default_factory=dict)
    gas_sensors: List[GasSensor] = field(default_factory=list)
    panic_buttons: List[PanicButton] = field(default_factory=list)
    eta_info: List[ETAInfo] = field(default_factory=list)
    infractions: List[str] = field(default_factory=list)
    seismic_event: Optional[SeismicEvent] = None
    has_earthquake: bool = False
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary for JSON serialization"""
        return {
            "timestamp": self.timestamp,
            "semaforos": self.traffic_lights,
            "dist_cm": self.distances,
            "gas": [
                {
                    "zona": gs.zone,
                    "ppm": gs.ppm,
                    "is_alto": gs.is_high
                }
                for gs in self.gas_sensors
            ],
            "botones_panico_activos": [
                {
                    "id": pb.id,
                    "activo": pb.active,
                    "button_id": pb.button_id,
                    "ubicacion": pb.location
                }
                for pb in self.panic_buttons
            ],
            "eta": [
                {
                    "parada": eta.stop,
                    "tipo_transporte": eta.transport_type,
                    "tiempo_segundos": eta.time_seconds,
                    "info": eta.info
                }
                for eta in self.eta_info
            ],
            "infracciones": self.infractions,
            "tiene_sismo": self.has_earthquake,
            "sismo": {
                "magnitud": self.seismic_event.magnitude if self.seismic_event else 0.0,
                "origen": self.seismic_event.origin if self.seismic_event else ""
            } if self.seismic_event or self.has_earthquake else {}
        }









"""
Clase para parsear y trabajar con datos JSON recibidos desde Arduino.
Proporciona acceso fácil a todos los campos del JSON de estado del Arduino.
"""

import json
from typing import Dict, Any, List, Optional
from dataclasses import dataclass
from datetime import datetime


@dataclass
class SemaforoData:
    """Datos de un semáforo individual."""
    id: str
    estado: str
    
    @property
    def is_verde(self) -> bool:
        return self.estado.upper() == "VERDE"
    
    @property
    def is_amarillo(self) -> bool:
        return self.estado.upper() == "AMARILLO"
    
    @property
    def is_rojo(self) -> bool:
        return self.estado.upper() == "ROJO"


@dataclass
class DistanciaData:
    """Datos de distancia de un sensor."""
    id: str
    distancia_cm: float
    
    @property
    def distancia_m(self) -> float:
        return self.distancia_cm / 100.0


@dataclass
class GasData:
    """Datos de sensores de gas."""
    zona: str
    ppm: int
    
    @property
    def is_alto(self) -> bool:
        return self.ppm > 250
    
    @property
    def is_medio(self) -> bool:
        return 200 <= self.ppm <= 250
    
    @property
    def is_bajo(self) -> bool:
        return self.ppm < 200


@dataclass
class ZumbadorData:
    """Estado de los zumbadores."""
    zona: str
    activo: bool


@dataclass
class SismoData:
    """Datos del sensor de sismo."""
    activo: bool
    magnitud: float
    origen: str
    
    @property
    def is_activo(self) -> bool:
        return self.activo


@dataclass
class PanicButtonData:
    """Datos de un botón de pánico."""
    id: str
    activo: bool
    timestamp: str
    button_id: str
    
    @property
    def is_pressed(self) -> bool:
        return self.activo


@dataclass
class ETAData:
    """Datos de tiempo estimado de llegada."""
    parada: str
    info: str
    
    @property
    def tipo_transporte(self) -> str:
        """Extrae el tipo de transporte del ETA."""
        if "M," in self.info:
            return "Transmetro"
        elif "TU," in self.info:
            return "Transurbano"
        return "Desconocido"
    
    @property
    def tiempo_segundos(self) -> Optional[int]:
        """Extrae el tiempo en segundos del ETA."""
        try:
            if "ETA_S=" in self.info:
                start = self.info.find("ETA_S=") + 6
                end = self.info.find(",", start)
                if end == -1:
                    end = self.info.find("FROM=", start)
                if end == -1:
                    end = len(self.info)
                return int(self.info[start:end])
        except (ValueError, IndexError):
            pass
        return None


class ArduinoDataParser:
    """
    Parser principal para datos JSON del Arduino.
    Proporciona acceso estructurado a todos los campos del JSON.
    """
    
    def __init__(self, json_data: Dict[str, Any]):
        """
        Inicializa el parser con datos JSON.
        
        Args:
            json_data: Diccionario JSON parseado desde Arduino
        """
        self.raw_data = json_data
        self._parse_data()
    
    def _parse_data(self):
        """Parsea todos los campos del JSON."""
        # Timestamp
        self.timestamp = self.raw_data.get("ts", "")
        
        # Semáforos
        self.semaforos = self._parse_semaforos()
        
        # Distancias
        self.distancias = self._parse_distancias()
        
        # Gas
        self.gas = self._parse_gas()
        
        # Zumbadores
        self.zumbadores = self._parse_zumbadores()
        
        # Sismo
        self.sismo = self._parse_sismo()
        
        # Botones de pánico
        self.panic_buttons = self._parse_panic_buttons()
        
        # Infracciones
        self.infracciones = self.raw_data.get("infracciones", [])
        
        # ETA
        self.eta = self._parse_eta()
        
        # Versión del protocolo
        self.protocol_version = self.raw_data.get("_protocol_version", "")
    
    def _parse_semaforos(self) -> List[SemaforoData]:
        """Parsea los datos de semáforos."""
        semaforos = []
        semaforos_raw = self.raw_data.get("semaforos", {})
        
        for sem_id, estado in semaforos_raw.items():
            semaforos.append(SemaforoData(
                id=sem_id,
                estado=str(estado)
            ))
        
        return semaforos
    
    def _parse_distancias(self) -> List[DistanciaData]:
        """Parsea los datos de distancias."""
        distancias = []
        dist_raw = self.raw_data.get("dist_cm", {})
        
        for parada_id, distancia in dist_raw.items():
            distancias.append(DistanciaData(
                id=parada_id,
                distancia_cm=float(distancia)
            ))
        
        return distancias
    
    def _parse_gas(self) -> List[GasData]:
        """Parsea los datos de sensores de gas."""
        gas = []
        gas_raw = self.raw_data.get("gas_ppm", {})
        
        for zona, ppm in gas_raw.items():
            gas.append(GasData(
                zona=zona,
                ppm=int(ppm)
            ))
        
        return gas
    
    def _parse_zumbadores(self) -> List[ZumbadorData]:
        """Parsea los datos de zumbadores."""
        zumbadores = []
        zumb_raw = self.raw_data.get("zumbador", {})
        
        for zona, activo in zumb_raw.items():
            zumbadores.append(ZumbadorData(
                zona=zona,
                activo=bool(activo)
            ))
        
        return zumbadores
    
    def _parse_sismo(self) -> SismoData:
        """Parsea los datos del sismo."""
        sismo_raw = self.raw_data.get("sismo", {})
        
        return SismoData(
            activo=bool(sismo_raw.get("activo", False)),
            magnitud=float(sismo_raw.get("magnitud", 0.0)),
            origen=str(sismo_raw.get("origen", ""))
        )
    
    def _parse_panic_buttons(self) -> List[PanicButtonData]:
        """Parsea los datos de botones de pánico."""
        panic_buttons = []
        panic_raw = self.raw_data.get("panic_buttons", {})
        
        for btn_id, btn_data in panic_raw.items():
            if isinstance(btn_data, dict):
                panic_buttons.append(PanicButtonData(
                    id=btn_id,
                    activo=bool(btn_data.get("activo", False)),
                    timestamp=str(btn_data.get("ts", "")),
                    button_id=str(btn_data.get("id", ""))
                ))
        
        return panic_buttons
    
    def _parse_eta(self) -> List[ETAData]:
        """Parsea los datos de ETA."""
        eta = []
        eta_raw = self.raw_data.get("eta", {})
        
        for parada, info in eta_raw.items():
            eta.append(ETAData(
                parada=parada,
                info=str(info)
            ))
        
        return eta
    
    # Métodos de conveniencia para acceder a datos específicos
    
    def get_semaforo(self, sem_id: str) -> Optional[SemaforoData]:
        """Obtiene un semáforo específico por ID."""
        for sem in self.semaforos:
            if sem.id == sem_id:
                return sem
        return None
    
    def get_distancia(self, parada_id: str) -> Optional[DistanciaData]:
        """Obtiene la distancia de una parada específica."""
        for dist in self.distancias:
            if dist.id == parada_id:
                return dist
        return None
    
    def get_gas_zona(self, zona: str) -> Optional[GasData]:
        """Obtiene los datos de gas de una zona específica."""
        for gas in self.gas:
            if gas.zona == zona:
                return gas
        return None
    
    def get_panic_button(self, btn_id: str) -> Optional[PanicButtonData]:
        """Obtiene un botón de pánico específico."""
        for btn in self.panic_buttons:
            if btn.id == btn_id:
                return btn
        return None
    
    def get_eta_parada(self, parada: str) -> Optional[ETAData]:
        """Obtiene el ETA de una parada específica."""
        for eta in self.eta:
            if eta.parada == parada:
                return eta
        return None
    
    # Propiedades útiles
    
    @property
    def semaforos_verdes(self) -> List[SemaforoData]:
        """Lista de semáforos en verde."""
        return [sem for sem in self.semaforos if sem.is_verde]
    
    @property
    def semaforos_rojos(self) -> List[SemaforoData]:
        """Lista de semáforos en rojo."""
        return [sem for sem in self.semaforos if sem.is_rojo]
    
    @property
    def semaforos_amarillos(self) -> List[SemaforoData]:
        """Lista de semáforos en amarillo."""
        return [sem for sem in self.semaforos if sem.is_amarillo]
    
    @property
    def botones_panico_activos(self) -> List[PanicButtonData]:
        """Lista de botones de pánico activos."""
        return [btn for btn in self.panic_buttons if btn.is_pressed]
    
    @property
    def zonas_gas_alto(self) -> List[GasData]:
        """Lista de zonas con gas alto."""
        return [gas for gas in self.gas if gas.is_alto]
    
    @property
    def tiene_infracciones(self) -> bool:
        """Verifica si hay infracciones activas."""
        return len(self.infracciones) > 0
    
    @property
    def tiene_sismo(self) -> bool:
        """Verifica si hay sismo activo."""
        return self.sismo.is_activo
    
    def to_dict(self) -> Dict[str, Any]:
        """Convierte los datos parseados de vuelta a diccionario."""
        return {
            "timestamp": self.timestamp,
            "semaforos": {sem.id: sem.estado for sem in self.semaforos},
            "distancias": {dist.id: dist.distancia_cm for dist in self.distancias},
            "gas": {gas.zona: gas.ppm for gas in self.gas},
            "zumbadores": {zumb.zona: zumb.activo for zumb in self.zumbadores},
            "sismo": {
                "activo": self.sismo.activo,
                "magnitud": self.sismo.magnitud,
                "origen": self.sismo.origen
            },
            "panic_buttons": {
                btn.id: {
                    "activo": btn.activo,
                    "ts": btn.timestamp,
                    "id": btn.button_id
                } for btn in self.panic_buttons
            },
            "infracciones": self.infracciones,
            "eta": {eta.parada: eta.info for eta in self.eta},
            "_protocol_version": self.protocol_version
        }
    
    def __str__(self) -> str:
        """Representación en string de los datos parseados."""
        return f"ArduinoDataParser(ts={self.timestamp}, " \
               f"semáforos={len(self.semaforos)}, " \
               f"distancias={len(self.distancias)}, " \
               f"sismo={'SÍ' if self.tiene_sismo else 'NO'}, " \
               f"infracciones={len(self.infracciones)})"
    
    def __repr__(self) -> str:
        return self.__str__()


def parse_arduino_json(json_string: str) -> Optional[ArduinoDataParser]:
    """
    Función de conveniencia para parsear JSON desde string.
    
    Args:
        json_string: String JSON del Arduino
        
    Returns:
        ArduinoDataParser si el JSON es válido, None en caso contrario
    """
    try:
        data = json.loads(json_string)
        return ArduinoDataParser(data)
    except (json.JSONDecodeError, KeyError, ValueError) as e:
        print(f"Error al parsear JSON del Arduino: {e}")
        return None

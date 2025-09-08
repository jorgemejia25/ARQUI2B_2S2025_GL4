from fastapi import APIRouter, Query, HTTPException
from typing import Optional, List
from database import DatabaseManager

# GETS para obtener datos de las tablas
router = APIRouter(tags=["Datos de las tablas"])

# -------------------------------
# Datos 
# -------------------------------
# Posición del Bus: 
# ID: 1 CODE: BUS_TRANSMETRO
# ID: 2 CODE: BUS_TRANSURBANO
@router.get("/bus-positions")
def get_bus_positions(bus_id: Optional[int] = None,
                      bus_code: Optional[str] = None,
                      limit: int = Query(20, ge=1, le=500)):
    """GET BusPosition: últimas posiciones.
    Parámetros opcionales: bus_id o bus_code; limit.
    ## ID: 1 CODE: BUS_TRANSMETRO
    ## ID: 2 CODE: BUS_TRANSURBANO
    """
    with DatabaseManager() as db:
        def _resolve_bus_id(bid: Optional[int], bcode: Optional[str]) -> Optional[int]:
            if bid is not None:
                return bid
            if bcode:
                row = db.execute_query("SELECT bus_id FROM Bus WHERE code = ?", (bcode,))
                if row:
                    return row[0]["bus_id"]
            return None

        resolved = _resolve_bus_id(bus_id, bus_code)
        if resolved:
            q = """
            SELECT bp.*, b.code AS bus_code
            FROM BusPosition bp
            JOIN Bus b ON bp.bus_id = b.bus_id
            WHERE bp.bus_id = ?
            ORDER BY bp.ts DESC
            LIMIT ?
            """
            return db.execute_query(q, (resolved, limit)) or []
        else:
            q = """
            SELECT bp.*, b.code AS bus_code
            FROM BusPosition bp
            JOIN Bus b ON bp.bus_id = b.bus_id
            ORDER BY bp.ts DESC
            LIMIT ?
            """
            return db.execute_query(q, (limit,)) or []

# Atajos para buses }
# BUSE 1
@router.get("/bus-positions/bus/1")
def get_bus1_positions(limit: int = Query(20, ge=1, le=500)):
    """GET BusPosition: últimas posiciones del BUS_TRANSMETRO (bus_id=1)."""
    with DatabaseManager() as db:
        q = """
        SELECT bp.*, b.code AS bus_code
        FROM BusPosition bp
        JOIN Bus b ON bp.bus_id = b.bus_id
        WHERE bp.bus_id = ?
        ORDER BY bp.ts DESC
        LIMIT ?
        """
        return db.execute_query(q, (1, limit)) or []

# BUSE 2
@router.get("/bus-positions/bus/2")
def get_bus2_positions(limit: int = Query(20, ge=1, le=500)):
    """GET BusPosition: últimas posiciones del BUS_TRANSURBANO (bus_id=2)."""
    with DatabaseManager() as db:
        q = """
        SELECT bp.*, b.code AS bus_code
        FROM BusPosition bp
        JOIN Bus b ON bp.bus_id = b.bus_id
        WHERE bp.bus_id = ?
        ORDER BY bp.ts DESC
        LIMIT ?
        """
        return db.execute_query(q, (2, limit)) or []

# Obtener Gas Lista
@router.get("/gas-history")
def get_gas(from_ts: Optional[str] = None,
            to_ts: Optional[str] = None,
            limit: int = Query(100, ge=1, le=2000)):
    """GET GasMeasurement: serie histórica de gas (ppm).
    Parámetros opcionales: from_ts, to_ts (YYYY-MM-DD HH:MM:SS), limite (200 - 1).
    """
    with DatabaseManager() as db:
        base = "SELECT * FROM GasMeasurement WHERE 1=1"
        params: List = []
        if from_ts:
            base += " AND ts >= ?"
            params.append(from_ts)
        if to_ts:
            base += " AND ts <= ?"
            params.append(to_ts)
        base += " ORDER BY ts DESC LIMIT ?"
        params.append(limit)
        return db.execute_query(base, tuple(params)) or []

# Gas por origen 1
@router.get("/gas-history/origin/1")
def get_gas_origin_1(from_ts: Optional[str] = None,
                     to_ts: Optional[str] = None,
                     limit: int = Query(100, ge=1, le=2000)):
    """GET GasMeasurement: solo registros con origin=1.
    Parámetros opcionales: from_ts, to_ts (YYYY-MM-DD HH:MM:SS), limit.
    """
    with DatabaseManager() as db:
        base = "SELECT * FROM GasMeasurement WHERE origin = ?"
        params: List = ["1"]  # origin se almacena como TEXT
        if from_ts:
            base += " AND ts >= ?"
            params.append(from_ts)
        if to_ts:
            base += " AND ts <= ?"
            params.append(to_ts)
        base += " ORDER BY ts DESC LIMIT ?"
        params.append(limit)
        return db.execute_query(base, tuple(params)) or []

# Gas por origen 2
@router.get("/gas-history/origin/2")
def get_gas_origin_2(from_ts: Optional[str] = None,
                     to_ts: Optional[str] = None,
                     limit: int = Query(100, ge=1, le=2000)):
    """GET GasMeasurement: solo registros con origin=2.
    Parámetros opcionales: from_ts, to_ts (YYYY-MM-DD HH:MM:SS), limit.
    """
    with DatabaseManager() as db:
        base = "SELECT * FROM GasMeasurement WHERE origin = ?"
        params: List = ["2"]  # origin se almacena como TEXT
        if from_ts:
            base += " AND ts >= ?"
            params.append(from_ts)
        if to_ts:
            base += " AND ts <= ?"
            params.append(to_ts)
        base += " ORDER BY ts DESC LIMIT ?"
        params.append(limit)
        return db.execute_query(base, tuple(params)) or []

# Obtener Simos Lista
@router.get("/seismic-history")
def get_seismic(from_ts: Optional[str] = None,
                to_ts: Optional[str] = None,
                limit: int = Query(100, ge=1, le=2000)):
    """GET SeismicMeasurement: serie histórica sísmica (intensity_g).
    Parámetros opcionales: from_ts, to_ts (YYYY-MM-DD HH:MM:SS), limite (200 - 1).
    """
    with DatabaseManager() as db:
        base = "SELECT * FROM SeismicMeasurement WHERE 1=1"
        params: List = []
        if from_ts:
            base += " AND ts >= ?"
            params.append(from_ts)
        if to_ts:
            base += " AND ts <= ?"
            params.append(to_ts)
        base += " ORDER BY ts DESC LIMIT ?"
        params.append(limit)
        return db.execute_query(base, tuple(params)) or []

# -------------------------------
# Alertas 
# -------------------------------
# Infracciones de trafico
@router.get("/tables/traffic-infractions")
def list_traffic_infractions(alert_id: Optional[int] = None, limit: int = Query(200, ge=1, le=5000)):
    """GET TrafficInfraction: infracciones de semáforo. Parámetros: alert_id?, limit."""
    with DatabaseManager() as db:
        if alert_id:
            return db.execute_query(
                "SELECT * FROM TrafficInfraction WHERE alert_id = ? LIMIT ?",
                (alert_id, limit),
            ) or []
        return db.execute_query("SELECT * FROM TrafficInfraction LIMIT ?", (limit,)) or []

# Eventos de btn de panico
@router.get("/tables/panic-events")
def list_panic_events(alert_id: Optional[int] = None, limit: int = Query(200, ge=1, le=5000)):
    """GET PanicEvent: botones de pánico. Parámetros: alert_id?, limit."""
    with DatabaseManager() as db:
        if alert_id:
            return db.execute_query(
                "SELECT * FROM PanicEvent WHERE alert_id = ? LIMIT ?",
                (alert_id, limit),
            ) or []
        return db.execute_query("SELECT * FROM PanicEvent LIMIT ?", (limit,)) or []

# sismos eventos
@router.get("/tables/seismic-events")
def list_seismic_events(alert_id: Optional[int] = None, limit: int = Query(200, ge=1, le=5000)):
    """GET SeismicEvent: detalles sísmicos. Parámetros: alert_id?, limit."""
    with DatabaseManager() as db:
        if alert_id:
            return db.execute_query(
                "SELECT * FROM SeismicEvent WHERE alert_id = ? LIMIT ?",
                (alert_id, limit),
            ) or []
    return db.execute_query("SELECT * FROM SeismicEvent LIMIT ?", (limit,)) or []

# eventos de gas
@router.get("/tables/gas-events")
def list_gas_events(alert_id: Optional[int] = None, limit: int = Query(200, ge=1, le=5000)):
    """GET GasEvent: detalles de gas. Parámetros: alert_id?, limit."""
    with DatabaseManager() as db:
        if alert_id:
            return db.execute_query(
                "SELECT * FROM GasEvent WHERE alert_id = ? LIMIT ?",
                (alert_id, limit),
            ) or []
        return db.execute_query("SELECT * FROM GasEvent LIMIT ?", (limit,)) or []

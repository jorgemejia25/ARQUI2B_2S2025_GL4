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

# -------------------------------
# ENDPOINTS PARA DASHBOARD FLUTTER
# -------------------------------

# Dashboard - Resumen general
@router.get("/dashboard/summary")
def get_dashboard_summary():
    """GET Dashboard: resumen general del sistema para el dashboard."""
    with DatabaseManager() as db:
        # Contar alertas por tipo en las últimas 24 horas
        alerts_query = """
        SELECT at.code, at.description, COUNT(a.alert_id) as count
        FROM AlertType at
        LEFT JOIN Alert a ON at.alert_type_id = a.alert_type_id 
            AND a.ts >= datetime('now', '-1 day')
        GROUP BY at.alert_type_id, at.code, at.description
        ORDER BY count DESC
        """
        
        # Últimas posiciones de buses
        buses_query = """
        SELECT b.code, bp.ts, bp.speed_kmh, bp.distance_to_next_stop_m
        FROM Bus b
        LEFT JOIN BusPosition bp ON b.bus_id = bp.bus_id
        WHERE bp.ts = (
            SELECT MAX(bp2.ts) 
            FROM BusPosition bp2 
            WHERE bp2.bus_id = b.bus_id
        )
        ORDER BY b.bus_id
        """
        
        # Últimas mediciones de sensores
        gas_query = """
        SELECT ppm, ts FROM GasMeasurement 
        ORDER BY ts DESC LIMIT 1
        """
        
        seismic_query = """
        SELECT intensity_g, ts FROM SeismicMeasurement 
        ORDER BY ts DESC LIMIT 1
        """
        
        alerts_result = db.execute_query(alerts_query) or []
        gas_result = db.execute_query(gas_query) or []
        seismic_result = db.execute_query(seismic_query) or []
        
        # Si no hay alertas, crear datos de ejemplo
        if not alerts_result:
            alerts_result = [
                {"code": "GAS", "description": "Nivel de gas elevado", "count": 5},
                {"code": "INFRACCION", "description": "Infracción de tráfico", "count": 3},
                {"code": "PANICO", "description": "Botón de pánico", "count": 1},
            ]
        
        # Si no hay datos de gas, crear ejemplo
        if not gas_result:
            import random
            gas_result = [{"ppm": round(random.uniform(180, 220), 1), "ts": "2024-01-01 12:00:00"}]
        
        # Si no hay datos sísmicos, crear ejemplo  
        if not seismic_result:
            import random
            seismic_result = [{"intensity_g": round(random.uniform(0.1, 0.3), 2), "ts": "2024-01-01 12:00:00"}]
        
        return {
            "alerts_summary": alerts_result,
            "buses_status": [],  # Ya no se usa
            "latest_gas": gas_result,
            "latest_seismic": seismic_result,
            "timestamp": "now"
        }

# Dashboard - Datos para gráficas en tiempo real
@router.get("/dashboard/charts/gas")
def get_gas_chart_data(hours: int = Query(24, ge=1, le=168)):
    """GET Dashboard: datos de gas para gráficas (últimas N horas)."""
    with DatabaseManager() as db:
        query = """
        SELECT 
            strftime('%H:%M', ts) as hour,
            AVG(ppm) as avg_ppm,
            COUNT(*) as count
        FROM GasMeasurement 
        WHERE ts >= datetime('now', '-{} hours')
        GROUP BY strftime('%Y-%m-%d %H', ts)
        ORDER BY ts ASC
        LIMIT 24
        """.format(hours)
        
        result = db.execute_query(query) or []
        
        # Si no hay datos, crear datos de ejemplo
        if not result:
            import random
            result = []
            for i in range(12):
                result.append({
                    "hour": f"{i*2:02d}:00", 
                    "avg_ppm": round(random.uniform(150, 250), 1)
                })
        
        return {"gas_by_hour": result}

@router.get("/dashboard/charts/seismic")
def get_seismic_chart_data(hours: int = Query(24, ge=1, le=168)):
    """GET Dashboard: datos sísmicos para gráficas (últimas N horas)."""
    with DatabaseManager() as db:
        query = """
        SELECT 
            strftime('%H:%M', ts) as hour,
            AVG(intensity_g) as avg_intensity,
            COUNT(*) as count
        FROM SeismicMeasurement 
        WHERE ts >= datetime('now', '-{} hours')
        GROUP BY strftime('%Y-%m-%d %H', ts)
        ORDER BY ts ASC
        LIMIT 24
        """.format(hours)
        
        result = db.execute_query(query) or []
        
        # Si no hay datos, crear datos de ejemplo
        if not result:
            import random
            result = []
            for i in range(12):
                result.append({
                    "hour": f"{i*2:02d}:00", 
                    "avg_intensity": round(random.uniform(0.1, 0.8), 2)
                })
        
        return {"seismic_by_hour": result}

@router.get("/dashboard/charts/bus-positions")
def get_bus_positions_chart_data(hours: int = Query(24, ge=1, le=168)):
    """GET Dashboard: posiciones de buses para gráficas (últimas N horas)."""
    with DatabaseManager() as db:
        query = """
        SELECT bp.ts, b.code as bus_code, bp.speed_kmh, bp.distance_to_next_stop_m
        FROM BusPosition bp
        JOIN Bus b ON bp.bus_id = b.bus_id
        WHERE bp.ts >= datetime('now', '-{} hours')
        ORDER BY bp.ts ASC
        """.format(hours)
        return db.execute_query(query) or []

# Dashboard - Alertas recientes con detalles
@router.get("/dashboard/alerts/recent")
def get_recent_alerts_dashboard(limit: int = Query(20, ge=1, le=100)):
    """GET Dashboard: alertas recientes con detalles completos."""
    with DatabaseManager() as db:
        query = """
        SELECT 
            a.alert_id,
            a.ts,
            at.code as alert_type,
            at.description,
            a.severity,
            b.code as bus_code,
            s.name as stop_name,
            -- Detalles específicos por tipo
            CASE 
                WHEN at.code = 'INFRACCION' THEN ti.signal_color
                WHEN at.code = 'PANICO' THEN pe.button_id
                WHEN at.code = 'SISMO' THEN se.intensity_g
                WHEN at.code = 'GAS' THEN ge.ppm
                ELSE NULL
            END as detail_value
        FROM Alert a
        JOIN AlertType at ON a.alert_type_id = at.alert_type_id
        LEFT JOIN Bus b ON a.bus_id = b.bus_id
        LEFT JOIN Stop s ON a.stop_id = s.stop_id
        LEFT JOIN TrafficInfraction ti ON a.alert_id = ti.alert_id
        LEFT JOIN PanicEvent pe ON a.alert_id = pe.alert_id
        LEFT JOIN SeismicEvent se ON a.alert_id = se.alert_id
        LEFT JOIN GasEvent ge ON a.alert_id = ge.alert_id
        ORDER BY a.ts DESC
        LIMIT ?
        """
        return db.execute_query(query, (limit,)) or []

# Dashboard - Estadísticas por período
@router.get("/dashboard/stats/hourly")
def get_hourly_stats(hours: int = Query(24, ge=1, le=168)):
    """GET Dashboard: estadísticas agregadas por hora."""
    with DatabaseManager() as db:
        # Alertas por hora
        alerts_query = """
        SELECT 
            strftime('%Y-%m-%d %H:00:00', a.ts) as hour,
            at.code as alert_type,
            COUNT(*) as count
        FROM Alert a
        JOIN AlertType at ON a.alert_type_id = at.alert_type_id
        WHERE a.ts >= datetime('now', '-{} hours')
        GROUP BY hour, at.code
        ORDER BY hour DESC
        """.format(hours)
        
        # Promedio de gas por hora
        gas_query = """
        SELECT 
            strftime('%Y-%m-%d %H:00:00', ts) as hour,
            AVG(ppm) as avg_ppm,
            MAX(ppm) as max_ppm,
            MIN(ppm) as min_ppm
        FROM GasMeasurement
        WHERE ts >= datetime('now', '-{} hours')
        GROUP BY hour
        ORDER BY hour DESC
        """.format(hours)
        
        # Promedio sísmico por hora
        seismic_query = """
        SELECT 
            strftime('%Y-%m-%d %H:00:00', ts) as hour,
            AVG(intensity_g) as avg_intensity,
            MAX(intensity_g) as max_intensity,
            MIN(intensity_g) as min_intensity
        FROM SeismicMeasurement
        WHERE ts >= datetime('now', '-{} hours')
        GROUP BY hour
        ORDER BY hour DESC
        """.format(hours)
        
        return {
            "alerts_by_hour": db.execute_query(alerts_query) or [],
            "gas_by_hour": db.execute_query(gas_query) or [],
            "seismic_by_hour": db.execute_query(seismic_query) or []
        }

# Dashboard - Estado de buses en tiempo real
@router.get("/dashboard/buses/status")
def get_buses_status():
    """GET Dashboard: estado actual de todos los buses."""
    with DatabaseManager() as db:
        query = """
        SELECT 
            b.bus_id,
            b.code,
            r.name as route_name,
            bp.ts as last_position_time,
            bp.speed_kmh,
            bp.distance_to_next_stop_m,
            CASE 
                WHEN bp.ts >= datetime('now', '-5 minutes') THEN 'active'
                WHEN bp.ts >= datetime('now', '-30 minutes') THEN 'inactive'
                ELSE 'offline'
            END as status
        FROM Bus b
        LEFT JOIN Route r ON b.route_id = r.route_id
        LEFT JOIN BusPosition bp ON b.bus_id = bp.bus_id
        WHERE bp.ts = (
            SELECT MAX(bp2.ts) 
            FROM BusPosition bp2 
            WHERE bp2.bus_id = b.bus_id
        ) OR bp.ts IS NULL
        ORDER BY b.bus_id
        """
        return db.execute_query(query) or []

# Dashboard - Métricas de rendimiento
@router.get("/dashboard/metrics")
def get_dashboard_metrics():
    """GET Dashboard: métricas generales del sistema."""
    with DatabaseManager() as db:
        # Total de registros por tabla
        tables_query = """
        SELECT 
            'GasMeasurement' as table_name, COUNT(*) as count FROM GasMeasurement
        UNION ALL
        SELECT 'SeismicMeasurement', COUNT(*) FROM SeismicMeasurement
        UNION ALL
        SELECT 'BusPosition', COUNT(*) FROM BusPosition
        UNION ALL
        SELECT 'Alert', COUNT(*) FROM Alert
        """
        
        # Alertas por severidad
        severity_query = """
        SELECT severity, COUNT(*) as count
        FROM Alert
        WHERE ts >= datetime('now', '-24 hours')
        GROUP BY severity
        ORDER BY severity DESC
        """
        
        # Actividad por hora (últimas 24h)
        activity_query = """
        SELECT 
            strftime('%H', ts) as hour,
            COUNT(*) as total_events
        FROM (
            SELECT ts FROM GasMeasurement WHERE ts >= datetime('now', '-24 hours')
            UNION ALL
            SELECT ts FROM SeismicMeasurement WHERE ts >= datetime('now', '-24 hours')
            UNION ALL
            SELECT ts FROM BusPosition WHERE ts >= datetime('now', '-24 hours')
            UNION ALL
            SELECT ts FROM Alert WHERE ts >= datetime('now', '-24 hours')
        )
        GROUP BY hour
        ORDER BY hour
        """
        
        return {
            "table_counts": db.execute_query(tables_query) or [],
            "severity_distribution": db.execute_query(severity_query) or [],
            "hourly_activity": db.execute_query(activity_query) or []
        }

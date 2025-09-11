#!/usr/bin/env python3
"""
Script para insertar datos de prueba de buses en la base de datos
"""

import sqlite3
import datetime
import random
from database import DatabaseManager

def insert_test_bus_data():
    """Insertar datos de prueba de buses"""
    
    with DatabaseManager() as db:
        # Verificar si existen buses en la tabla Bus
        bus_check_query = "SELECT COUNT(*) as count FROM Bus"
        bus_count_result = db.execute_query(bus_check_query)
        
        if not bus_count_result or bus_count_result[0]["count"] == 0:
            print("No hay buses en la tabla Bus. Insertando buses de prueba...")
            
            # Insertar buses de prueba
            insert_bus_query = """
            INSERT INTO Bus (bus_id, code, route_id) 
            VALUES (1, 'BUS_TRANSMETRO', 1), (2, 'BUS_TRANSURBANO', 2)
            """
            db.execute_query(insert_bus_query)
            print("Buses de prueba insertados.")
        
        # Insertar posiciones de prueba para los últimos 2 días
        print("Insertando posiciones de prueba de buses...")
        
        # Generar datos para los últimos 48 horas (cada 5 minutos)
        now = datetime.datetime.now()
        positions_inserted = 0
        
        for hours_ago in range(48, 0, -1):
            for minutes_offset in range(0, 60, 5):  # Cada 5 minutos
                timestamp = now - datetime.timedelta(hours=hours_ago, minutes=minutes_offset)
                
                # Datos para BUS_TRANSMETRO (bus_id=1)
                lat1 = 14.6349 + random.uniform(-0.01, 0.01)  # Guatemala City area
                lng1 = -90.5069 + random.uniform(-0.01, 0.01)
                speed1 = random.uniform(0, 60)
                distance1 = random.uniform(0, 1000)
                
                insert_query1 = """
                INSERT INTO BusPosition (bus_id, ts, latitude, longitude, speed_kmh, distance_to_next_stop_m)
                VALUES (1, ?, ?, ?, ?, ?)
                """
                db.execute_query(insert_query1, (timestamp.strftime('%Y-%m-%d %H:%M:%S'), lat1, lng1, speed1, distance1))
                positions_inserted += 1
                
                # Datos para BUS_TRANSURBANO (bus_id=2)
                lat2 = 14.6349 + random.uniform(-0.01, 0.01)
                lng2 = -90.5069 + random.uniform(-0.01, 0.01)
                speed2 = random.uniform(0, 60)
                distance2 = random.uniform(0, 1000)
                
                insert_query2 = """
                INSERT INTO BusPosition (bus_id, ts, latitude, longitude, speed_kmh, distance_to_next_stop_m)
                VALUES (2, ?, ?, ?, ?, ?)
                """
                db.execute_query(insert_query2, (timestamp.strftime('%Y-%m-%d %H:%M:%S'), lat2, lng2, speed2, distance2))
                positions_inserted += 1
        
        print(f"Insertadas {positions_inserted} posiciones de prueba de buses.")
        
        # Verificar los datos insertados
        check_query = """
        SELECT 
            b.code,
            COUNT(bp.bus_id) as total_positions,
            MAX(bp.ts) as last_position
        FROM Bus b
        LEFT JOIN BusPosition bp ON b.bus_id = bp.bus_id
        GROUP BY b.bus_id, b.code
        """
        
        results = db.execute_query(check_query)
        if results:
            print("\nDatos de buses en la base de datos:")
            for result in results:
                print(f"- {result['code']}: {result['total_positions']} posiciones, última: {result['last_position']}")
        
        # Verificar el estado actual de los buses
        status_query = """
        SELECT 
            b.bus_id,
            b.code,
            bp.ts as last_position_time,
            bp.speed_kmh,
            bp.distance_to_next_stop_m,
            CASE 
                WHEN bp.ts >= datetime('now', '-5 minutes') THEN 'active'
                WHEN bp.ts >= datetime('now', '-30 minutes') THEN 'inactive'
                ELSE 'offline'
            END as status
        FROM Bus b
        LEFT JOIN BusPosition bp ON b.bus_id = bp.bus_id
        WHERE bp.ts = (
            SELECT MAX(bp2.ts) 
            FROM BusPosition bp2 
            WHERE bp2.bus_id = b.bus_id
        ) OR bp.ts IS NULL
        ORDER BY b.bus_id
        """
        
        status_results = db.execute_query(status_query)
        if status_results:
            print("\nEstado actual de los buses:")
            for result in status_results:
                print(f"- {result['code']}: {result['status']} (última posición: {result['last_position_time']})")

if __name__ == "__main__":
    print("Insertando datos de prueba de buses...")
    insert_test_bus_data()
    print("¡Datos de prueba insertados exitosamente!")

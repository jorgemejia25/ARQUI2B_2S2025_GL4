#!/usr/bin/env python3
"""
Script para inicializar la base de datos con datos básicos necesarios
"""

import sqlite3
import os
from database import DatabaseManager

def init_database():
    """Inicializar la base de datos con datos básicos"""
    
    with DatabaseManager() as db:
        print("Inicializando base de datos...")
        
        # Verificar si existen rutas
        route_check_query = "SELECT COUNT(*) as count FROM Route"
        route_count_result = db.execute_query(route_check_query)
        
        if not route_count_result or route_count_result[0]["count"] == 0:
            print("Insertando rutas de prueba...")
            
            # Insertar rutas de prueba
            insert_route_query = """
            INSERT OR IGNORE INTO Route (route_id, name, description) 
            VALUES 
                (1, 'Ruta Transmetro', 'Línea principal del Transmetro'),
                (2, 'Ruta Transurbano', 'Línea principal del Transurbano')
            """
            db.execute_query(insert_route_query)
            print("Rutas insertadas.")
        
        # Verificar si existen buses
        bus_check_query = "SELECT COUNT(*) as count FROM Bus"
        bus_count_result = db.execute_query(bus_check_query)
        
        if not bus_count_result or bus_count_result[0]["count"] == 0:
            print("Insertando buses de prueba...")
            
            # Insertar buses de prueba
            insert_bus_query = """
            INSERT OR IGNORE INTO Bus (bus_id, code, route_id) 
            VALUES 
                (1, 'BUS_TRANSMETRO', 1), 
                (2, 'BUS_TRANSURBANO', 2)
            """
            db.execute_query(insert_bus_query)
            print("Buses insertados.")
        
        # Verificar si existen tipos de alerta
        alert_type_check_query = "SELECT COUNT(*) as count FROM AlertType"
        alert_type_count_result = db.execute_query(alert_type_check_query)
        
        if not alert_type_count_result or alert_type_count_result[0]["count"] == 0:
            print("Insertando tipos de alerta de prueba...")
            
            # Insertar tipos de alerta
            insert_alert_type_query = """
            INSERT OR IGNORE INTO AlertType (alert_type_id, code, description) 
            VALUES 
                (1, 'INFRACCION', 'Infracción de tráfico'),
                (2, 'PANICO', 'Botón de pánico activado'),
                (3, 'GAS', 'Nivel de gas elevado'),
                (4, 'SISMO', 'Actividad sísmica detectada')
            """
            db.execute_query(insert_alert_type_query)
            print("Tipos de alerta insertados.")
        
        # Verificar los datos insertados
        check_query = """
        SELECT 
            'Bus' as tabla,
            b.bus_id,
            b.code,
            r.name as route_name
        FROM Bus b
        LEFT JOIN Route r ON b.route_id = r.route_id
        """
        
        results = db.execute_query(check_query)
        if results:
            print("\nDatos de buses en la base de datos:")
            for result in results:
                print(f"- {result['code']} (ID: {result['bus_id']}) - Ruta: {result['route_name']}")
        
        # Verificar posiciones existentes
        position_check_query = """
        SELECT 
            b.code,
            COUNT(bp.bus_id) as total_positions,
            MAX(bp.ts) as last_position
        FROM Bus b
        LEFT JOIN BusPosition bp ON b.bus_id = bp.bus_id
        GROUP BY b.bus_id, b.code
        """
        
        position_results = db.execute_query(position_check_query)
        if position_results:
            print("\nPosiciones de buses existentes:")
            for result in position_results:
                print(f"- {result['code']}: {result['total_positions']} posiciones, última: {result['last_position']}")
        
        # Verificar estado actual de los buses
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

def create_test_bus_positions():
    """Crear posiciones de prueba para los buses"""
    import datetime
    import random
    
    with DatabaseManager() as db:
        print("\nInsertando posiciones de prueba para los últimos 30 minutos...")
        
        # Generar datos para los últimos 30 minutos (cada minuto)
        now = datetime.datetime.now()
        positions_inserted = 0
        
        for minutes_ago in range(30, 0, -1):
            timestamp = now - datetime.timedelta(minutes=minutes_ago)
            
            # Datos para BUS_TRANSMETRO (bus_id=1)
            lat1 = 14.6349 + random.uniform(-0.005, 0.005)  # Guatemala City area
            lng1 = -90.5069 + random.uniform(-0.005, 0.005)
            speed1 = random.uniform(10, 50)
            distance1 = random.uniform(50, 800)
            
            insert_query1 = """
            INSERT INTO BusPosition (bus_id, ts, latitude, longitude, speed_kmh, distance_to_next_stop_m)
            VALUES (1, ?, ?, ?, ?, ?)
            """
            db.execute_query(insert_query1, (timestamp.strftime('%Y-%m-%d %H:%M:%S'), lat1, lng1, speed1, distance1))
            positions_inserted += 1
            
            # Datos para BUS_TRANSURBANO (bus_id=2)
            lat2 = 14.6349 + random.uniform(-0.005, 0.005)
            lng2 = -90.5069 + random.uniform(-0.005, 0.005)
            speed2 = random.uniform(10, 50)
            distance2 = random.uniform(50, 800)
            
            insert_query2 = """
            INSERT INTO BusPosition (bus_id, ts, latitude, longitude, speed_kmh, distance_to_next_stop_m)
            VALUES (2, ?, ?, ?, ?, ?)
            """
            db.execute_query(insert_query2, (timestamp.strftime('%Y-%m-%d %H:%M:%S'), lat2, lng2, speed2, distance2))
            positions_inserted += 1
        
        print(f"Insertadas {positions_inserted} posiciones de prueba.")

if __name__ == "__main__":
    print("Inicializando base de datos con datos básicos...")
    init_database()
    
    # Preguntar si se quieren crear posiciones de prueba
    response = input("\n¿Quieres crear posiciones de prueba para los buses? (y/n): ")
    if response.lower() in ['y', 'yes', 's', 'si']:
        create_test_bus_positions()
    
    print("\n¡Inicialización completada!")

#!/usr/bin/env python3
"""
Script para simular datos de buses llegando por MQTT
"""

import json
import time
import random
from database import DatabaseManager

def simulate_bus_data():
    """Simular datos de buses como si llegaran por MQTT"""
    
    # Simular payload de MQTT con datos de buses
    payload = {
        "timestamp": time.time(),
        "buses": [
            {
                "bus_code": "BUS_TRANSMETRO",
                "latitude": 14.6349 + random.uniform(-0.01, 0.01),
                "longitude": -90.5069 + random.uniform(-0.01, 0.01),
                "speed_kmh": random.uniform(20, 60),
                "distance_to_next_stop_m": random.uniform(100, 1000)
            },
            {
                "bus_code": "BUS_TRANSURBANO", 
                "latitude": 14.6349 + random.uniform(-0.01, 0.01),
                "longitude": -90.5069 + random.uniform(-0.01, 0.01),
                "speed_kmh": random.uniform(15, 55),
                "distance_to_next_stop_m": random.uniform(50, 800)
            }
        ],
        "gas": [
            {
                "ppm": random.uniform(150, 250),
                "zona": "Centro"
            }
        ],
        "tiene_sismo": False
    }
    
    print("Simulando datos de buses...")
    print("Payload simulado:")
    print(json.dumps(payload, indent=2, ensure_ascii=False))
    
    # Usar el DatabaseManager para procesar los datos
    with DatabaseManager() as db:
        success = db.save_mqtt_data("arduino/data", payload)
        if success:
            print("\n✅ Datos de buses guardados exitosamente!")
        else:
            print("\n❌ Error guardando datos de buses")
        
        # Verificar el estado actual de los buses
        status_query = """
        SELECT 
            b.bus_id,
            b.code,
            bp.ts as last_position_time,
            bp.latitude,
            bp.longitude,
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
                print(f"- {result['code']}: {result['status']}")
                print(f"  Última posición: {result['last_position_time']}")
                print(f"  Coordenadas: {result['latitude']}, {result['longitude']}")
                print(f"  Velocidad: {result['speed_kmh']} km/h")
                print(f"  Distancia a próxima parada: {result['distance_to_next_stop_m']} m")
                print()

def simulate_multiple_bus_updates(count=5):
    """Simular múltiples actualizaciones de buses"""
    print(f"Simulando {count} actualizaciones de buses...")
    
    for i in range(count):
        print(f"\n--- Actualización {i+1}/{count} ---")
        simulate_bus_data()
        if i < count - 1:  # No esperar en la última iteración
            time.sleep(2)

if __name__ == "__main__":
    print("Simulador de datos de buses")
    print("1. Simular una actualización")
    print("2. Simular 5 actualizaciones")
    print("3. Simular 10 actualizaciones")
    
    choice = input("Elige una opción (1-3): ")
    
    if choice == "1":
        simulate_bus_data()
    elif choice == "2":
        simulate_multiple_bus_updates(5)
    elif choice == "3":
        simulate_multiple_bus_updates(10)
    else:
        print("Opción no válida")
        simulate_bus_data()

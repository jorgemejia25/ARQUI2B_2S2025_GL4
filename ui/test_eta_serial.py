#!/usr/bin/env python3
"""
Script de prueba para simular el envío de datos ETA desde Arduino
Ejecutar: python3 test_eta_serial.py
"""

import json
import time
import random

def generate_eta_data():
    """Genera datos ETA simulados en el formato del Arduino"""
    
    # Simular diferentes estados de paradas
    eta_data = {
        "P1": "TU,ETA_S=45,FROM=Centro,TO=P1",
        "P2": "TU,ETA_S=120,FROM=Zona1,TO=P2", 
        "P3": "M,ETA_S=30,FROM=Estacion1,TO=P3",
        "P4": "M,ETA_S=180,FROM=Estacion2,TO=P4",
        "P5": "TU,ETA_S=90,FROM=Zona2,TO=P5",
        "P6": "M,ETA_S=240,FROM=Estacion3,TO=P6"
    }
    
    return eta_data

def generate_arduino_json():
    """Genera un JSON completo como lo enviaría el Arduino"""
    
    # Simular estados de semáforos
    semaforos = {}
    for i in range(1, 11):
        estados = ["VERDE", "ROJO", "AMARILLO"]
        semaforos[f"S{i}"] = random.choice(estados)
    
    # Simular distancias
    distancias = {}
    for i in range(1, 7):
        distancias[f"P{i}"] = random.randint(20, 500)
    
    # Simular gas
    gas = {
        "Z1": random.randint(150, 300),
        "Z2": random.randint(150, 300)
    }
    
    # Simular sismo
    sismo = {
        "activo": 0,
        "magnitud": 0.0,
        "origen": ""
    }
    
    # Simular botones de pánico
    panic_buttons = {}
    for i in range(1, 5):
        panic_buttons[f"PB{i}"] = {
            "activo": random.choice([0, 1]),
            "ts": str(int(time.time())),
            "id": f"PB{i}"
        }
    
    # Simular infracciones
    infracciones = []
    if random.random() > 0.7:  # 30% de probabilidad de infracción
        infracciones = [f"S{random.randint(1, 10)}"]
    
    # Generar ETA
    eta_data = generate_eta_data()
    
    # JSON completo
    json_data = {
        "ts": time.strftime("%Y-%m-%dT%H:%M:%SZ"),
        "semaforos": semaforos,
        "dist_cm": distancias,
        "gas_ppm": gas,
        "zumbador": {"Z1": 0, "Z2": 0},
        "sismo": sismo,
        "panic_buttons": panic_buttons,
        "infracciones": infracciones,
        "eta": eta_data,
        "_protocol_version": "1.1"
    }
    
    return json_data

def main():
    """Función principal que simula el envío de datos"""
    print("=== Simulador de Datos ETA Arduino ===")
    print("Este script genera datos JSON como los enviaría el Arduino")
    print("Incluye el nuevo campo 'eta' con tiempo de llegada estimado")
    print("Presiona Ctrl+C para detener")
    print()
    
    try:
        while True:
            # Generar datos
            data = generate_arduino_json()
            
            # Imprimir JSON (como lo enviaría Arduino)
            json_str = json.dumps(data, separators=(',', ':'))
            print(json_str)
            
            # Mostrar información de ETA
            print(f"  [ETA] P1: {data['eta']['P1']}")
            print(f"  [ETA] P2: {data['eta']['P2']}")
            print(f"  [ETA] P3: {data['eta']['P3']}")
            print(f"  [ETA] P4: {data['eta']['P4']}")
            print(f"  [ETA] P5: {data['eta']['P5']}")
            print(f"  [ETA] P6: {data['eta']['P6']}")
            print()
            
            # Esperar 2 segundos (como Arduino)
            time.sleep(2)
            
    except KeyboardInterrupt:
        print("\nSimulación detenida")

if __name__ == "__main__":
    main()

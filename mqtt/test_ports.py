#!/usr/bin/env python3
"""
Script para probar y detectar puertos seriales disponibles.
"""

import serial.tools.list_ports
import serial
import time

def list_available_ports():
    """Lista todos los puertos seriales disponibles."""
    print("=== Puertos Seriales Disponibles ===")
    ports = serial.tools.list_ports.comports()
    
    if not ports:
        print("No se encontraron puertos seriales.")
        return []
    
    for i, port in enumerate(ports, 1):
        print(f"{i}. Puerto: {port.device}")
        print(f"   Descripción: {port.description}")
        print(f"   VID:PID: {port.vid}:{port.pid}")
        print(f"   Serial: {port.serial_number}")
        print()
    
    return [port.device for port in ports]

def test_port_connection(port, baudrate=9600):
    """Prueba la conexión a un puerto específico."""
    print(f"Probando conexión en {port} con baudrate {baudrate}...")
    
    try:
        ser = serial.Serial(port, baudrate, timeout=1)
        time.sleep(2)  # Esperar a que Arduino se reinicie
        
        if ser.is_open:
            print(f"✅ Conexión exitosa en {port}")
            
            # Intentar leer algunos datos
            print("Leyendo datos disponibles...")
            for i in range(5):
                if ser.in_waiting:
                    try:
                        data = ser.readline()
                        print(f"Datos recibidos: {data}")
                        try:
                            decoded = data.decode('utf-8').strip()
                            print(f"Decodificado (UTF-8): {decoded}")
                        except UnicodeDecodeError:
                            print(f"No se pudo decodificar como UTF-8: {data}")
                    except Exception as e:
                        print(f"Error al leer datos: {e}")
                else:
                    print("No hay datos disponibles")
                time.sleep(1)
            
            ser.close()
            return True
        else:
            print(f"❌ No se pudo abrir {port}")
            return False
            
    except serial.SerialException as e:
        print(f"❌ Error de conexión en {port}: {e}")
        return False
    except Exception as e:
        print(f"❌ Error inesperado en {port}: {e}")
        return False

def main():
    """Función principal."""
    print("=== Detector de Puertos Arduino ===\n")
    
    # Listar puertos disponibles
    ports = list_available_ports()
    
    if not ports:
        print("No hay puertos disponibles para probar.")
        return
    
    # Probar cada puerto
    print("\n=== Probando Conexiones ===")
    working_ports = []
    
    for port in ports:
        if test_port_connection(port):
            working_ports.append(port)
        print("-" * 50)
    
    # Resumen
    print("\n=== Resumen ===")
    if working_ports:
        print(f"Puertos que funcionan: {', '.join(working_ports)}")
        print(f"\nRecomendación: Usar {working_ports[0]} en la configuración")
    else:
        print("No se encontraron puertos funcionales.")
        print("\nVerifica que:")
        print("1. El Arduino esté conectado por USB")
        print("2. El cable USB funcione correctamente")
        print("3. No haya otros programas usando el puerto")
        print("4. El Arduino tenga un programa cargado")

if __name__ == "__main__":
    main()


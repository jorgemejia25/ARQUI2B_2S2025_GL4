#!/usr/bin/env python3
"""
Script de prueba para verificar datos crudos del Arduino.
Este script lee datos directamente del puerto serial sin procesamiento.
"""

import serial
import time
import sys

def test_serial_raw():
    """Prueba la lectura de datos crudos del Arduino."""
    port = '/dev/ttyACM0'
    baudrate = 115200
    
    print(f"Conectando a {port} con baudrate {baudrate}...")
    
    try:
        # Abrir conexión serial
        ser = serial.Serial(
            port=port,
            baudrate=baudrate,
            timeout=1.0,
            bytesize=serial.EIGHTBITS,
            parity=serial.PARITY_NONE,
            stopbits=serial.STOPBITS_ONE
        )
        
        print("Conexión establecida. Esperando datos...")
        print("Presiona Ctrl+C para detener")
        print("-" * 50)
        
        # Esperar a que Arduino se reinicie
        time.sleep(2)
        
        while True:
            if ser.in_waiting:
                # Leer datos crudos
                raw_data = ser.readline()
                
                if raw_data:
                    print(f"Datos crudos ({len(raw_data)} bytes):")
                    print(f"  Hex: {raw_data.hex()}")
                    print(f"  Bytes: {list(raw_data)}")
                    
                    # Intentar diferentes codificaciones
                    encodings = ['utf-8', 'latin-1', 'ascii', 'cp1252']
                    
                    for encoding in encodings:
                        try:
                            decoded = raw_data.decode(encoding).strip()
                            if decoded:
                                print(f"  {encoding}: '{decoded}'")
                        except UnicodeDecodeError:
                            print(f"  {encoding}: ERROR - No se puede decodificar")
                    
                    # Filtrar solo ASCII imprimible
                    ascii_chars = []
                    for byte in raw_data:
                        if 32 <= byte <= 126:  # ASCII imprimible
                            ascii_chars.append(chr(byte))
                    
                    if ascii_chars:
                        filtered = ''.join(ascii_chars).strip()
                        print(f"  ASCII filtrado: '{filtered}'")
                    
                    print("-" * 30)
            
            time.sleep(0.1)
            
    except serial.SerialException as e:
        print(f"Error de conexión serial: {e}")
        return False
    except KeyboardInterrupt:
        print("\nDeteniendo...")
    except Exception as e:
        print(f"Error inesperado: {e}")
        return False
    finally:
        if 'ser' in locals() and ser.is_open:
            ser.close()
            print("Conexión cerrada")
    
    return True

if __name__ == "__main__":
    test_serial_raw()


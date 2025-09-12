#!/usr/bin/env python3
"""
Script de prueba para el modo simulación con control de teclas.
Ejecuta el simulador MQTT con detección de teclas para activar alertas manualmente.
"""

import sys
import time
from main import ArduinoMainController


def main():
    """Función principal para probar el sistema de simulación con teclas."""
    print("="*70)
    print("🧪 PRUEBA DEL SISTEMA DE SIMULACIÓN CON CONTROL DE TECLAS")
    print("="*70)
    print()
    print("Este script ejecuta el módulo MQTT en modo simulación con")
    print("control de alertas por teclado. Las alertas automáticas están")
    print("desactivadas y solo se activan manualmente con teclas.")
    print()
    print("📋 INSTRUCCIONES:")
    print("1. El sistema generará datos simulados cada 2 segundos")
    print("2. Usa las teclas para activar diferentes tipos de alertas")
    print("3. Presiona 'H' para ver la ayuda completa de teclas")
    print("4. Presiona 'Q' o Ctrl+C para salir")
    print()
    print("🎮 TECLAS PRINCIPALES:")
    print("   E - Sismo moderado    P - Botón pánico PB1")
    print("   V - Infracción S1     G - Gas alto Z1")
    print("   C - Limpiar alertas   H - Ayuda completa")
    print("   Q - Salir")
    print()
    print("="*70)
    
    # Preguntar al usuario si quiere continuar
    try:
        input("Presiona Enter para iniciar la simulación...")
    except KeyboardInterrupt:
        print("\n❌ Simulación cancelada por el usuario")
        return
    
    print("\n🚀 Iniciando simulación...")
    print("="*70)
    
    try:
        # Crear controlador en modo simulación
        controller = ArduinoMainController(simulation_mode=True)
        
        # Inicializar
        controller.initialize()
        
        # Ejecutar
        controller.run()
        
    except KeyboardInterrupt:
        print("\n⚠️ Simulación interrumpida por el usuario")
    except Exception as e:
        print(f"\n❌ Error durante la simulación: {e}")
        import traceback
        traceback.print_exc()
    finally:
        print("\n✅ Simulación finalizada")
        print("="*70)


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""
Script de prueba para verificar que las infracciones se envían correctamente
al WebSocket de alertas para notificaciones en Flutter.
"""

import time
import json
from main import ArduinoMainController


def test_infraction_flow():
    """Prueba el flujo completo de infracciones desde simulación hasta WebSocket."""
    print("="*70)
    print("🧪 PRUEBA DE FLUJO DE INFRACCIONES")
    print("="*70)
    print()
    print("Este script verifica que las infracciones se envíen correctamente:")
    print("1. Simulación → MQTT → API → WebSocket → Flutter")
    print()
    print("📋 PASOS DE LA PRUEBA:")
    print("1. Inicia el modo simulación")
    print("2. Presiona 'V' para activar una infracción")
    print("3. Verifica que se publique en MQTT")
    print("4. Verifica que llegue al WebSocket /ws/alerts")
    print()
    print("🎮 TECLAS PARA PROBAR INFRACCIONES:")
    print("   V        - Infracción en semáforo S1")
    print("   Shift+V  - Infracción en semáforo S5")
    print("   Ctrl+V   - Infracción en semáforo S10")
    print("   C        - Limpiar todas las alertas")
    print("   Q        - Salir")
    print()
    print("📡 TÓPICOS MQTT A VERIFICAR:")
    print(f"   - arduino/data (datos generales)")
    print(f"   - arduino/data/infracciones (infracciones específicas)")
    print()
    print("🌐 WEBSOCKET A VERIFICAR:")
    print(f"   - ws://localhost:8000/ws/alerts (alertas para Flutter)")
    print()
    print("="*70)
    
    try:
        input("Presiona Enter para iniciar la prueba...")
    except KeyboardInterrupt:
        print("\n❌ Prueba cancelada")
        return
    
    print("\n🚀 Iniciando simulación con infracciones...")
    print("="*70)
    
    try:
        # Crear controlador en modo simulación
        controller = ArduinoMainController(simulation_mode=True)
        
        # Configurar callback personalizado para infracciones
        original_process = controller._process_infracciones
        
        def enhanced_process_infracciones(data):
            """Versión mejorada que muestra más información."""
            if data.tiene_infracciones:
                print(f"\n🚨 INFRACCIONES DETECTADAS: {len(data.infracciones)}")
                for i, infraccion in enumerate(data.infracciones, 1):
                    print(f"   {i}. Semáforo: {infraccion}")
                    print(f"      → Se publicará en: arduino/data/infracciones")
                    print(f"      → Llegará a WebSocket: /ws/alerts")
                    print(f"      → Tipo para Flutter: 'infraction'")
                print()
            
            # Llamar al método original
            return original_process(data)
        
        # Reemplazar el método
        controller._process_infracciones = enhanced_process_infracciones
        
        # Inicializar y ejecutar
        controller.initialize()
        controller.run()
        
    except KeyboardInterrupt:
        print("\n⚠️ Prueba interrumpida por el usuario")
    except Exception as e:
        print(f"\n❌ Error durante la prueba: {e}")
        import traceback
        traceback.print_exc()
    finally:
        print("\n✅ Prueba de infracciones finalizada")
        print("="*70)
        print("\n📋 RESUMEN:")
        print("- Las infracciones activadas por teclado se agregan a 'active_violations'")
        print("- Se incluyen en el JSON de datos simulados cada 2 segundos")
        print("- Se procesan en '_process_infracciones'")
        print("- Se publican individualmente en 'arduino/data/infracciones'")
        print("- La API las recibe y las reenvía al WebSocket '/ws/alerts'")
        print("- Flutter las recibe como tipo 'infraction' en notificaciones")
        print()
        print("🔍 PARA VERIFICAR EN LA API:")
        print("- Revisa los logs de la API para ver mensajes de infracciones")
        print("- Conecta un cliente WebSocket a ws://localhost:8000/ws/alerts")
        print("- Verifica que lleguen mensajes con type: 'infraction'")


if __name__ == "__main__":
    test_infraction_flow()

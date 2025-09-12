#!/usr/bin/env python3
"""
Script de debug para verificar el flujo completo de infracciones.
Muestra información detallada sobre cada paso del proceso.
"""

import time
import json
from main import ArduinoMainController


def debug_infraction_flow():
    """Debug completo del flujo de infracciones."""
    print("="*80)
    print("🔍 DEBUG: FLUJO COMPLETO DE INFRACCIONES")
    print("="*80)
    print()
    print("Este script muestra información detallada sobre:")
    print("1. ✅ Activación de infracciones por teclado")
    print("2. ✅ Procesamiento en simulación")
    print("3. ✅ Publicación en MQTT (datos generales)")
    print("4. ✅ Publicación en MQTT (infracciones específicas)")
    print("5. ✅ Recepción en API")
    print("6. ✅ Envío a WebSocket")
    print()
    print("🎮 TECLAS PARA PROBAR:")
    print("   V        - Infracción S1")
    print("   Shift+V  - Infracción S5")
    print("   Ctrl+V   - Infracción S10")
    print("   C        - Limpiar alertas")
    print("   Q        - Salir")
    print()
    print("📋 INFORMACIÓN QUE VERÁS:")
    print("   🔄 - Inicio de proceso")
    print("   📡 - Publicación MQTT")
    print("   ✅ - Éxito")
    print("   ❌ - Error")
    print("   🎯 - Información importante")
    print()
    print("="*80)
    
    try:
        input("Presiona Enter para iniciar el debug...")
    except KeyboardInterrupt:
        print("\n❌ Debug cancelado")
        return
    
    print("\n🚀 Iniciando debug de infracciones...")
    print("="*80)
    
    try:
        # Crear controlador en modo simulación
        controller = ArduinoMainController(simulation_mode=True)
        
        # Interceptar el método de conversión MQTT para mostrar datos
        original_convert = controller._convert_to_mqtt_format
        
        def debug_convert_to_mqtt_format(data):
            """Versión debug que muestra el contenido."""
            mqtt_data = original_convert(data)
            
            # Mostrar infracciones en datos generales
            if "infracciones" in mqtt_data and mqtt_data["infracciones"]:
                print(f"\n🎯 INFRACCIONES EN DATOS GENERALES:")
                for infraccion in mqtt_data["infracciones"]:
                    print(f"   📋 {infraccion}")
                print(f"   📤 Se enviará en tópico: arduino/data")
            
            return mqtt_data
        
        # Interceptar el método de publicación individual
        original_publish_individual = controller._publish_individual_infraction
        
        def debug_publish_individual_infraction(infraccion):
            """Versión debug con más información."""
            print(f"\n🎯 PUBLICACIÓN INDIVIDUAL DE INFRACCIÓN:")
            print(f"   🔸 Semáforo: {infraccion}")
            print(f"   🔸 Formato: Individual (para WebSocket)")
            print(f"   🔸 Tópico: arduino/data/infracciones")
            
            # Llamar al método original
            return original_publish_individual(infraccion)
        
        # Reemplazar métodos
        controller._convert_to_mqtt_format = debug_convert_to_mqtt_format
        controller._publish_individual_infraction = debug_publish_individual_infraction
        
        # Agregar información sobre el estado MQTT
        original_publish_mqtt = controller._publish_mqtt
        
        def debug_publish_mqtt(data):
            """Versión debug que muestra estado MQTT."""
            print(f"\n📡 ESTADO MQTT:")
            print(f"   🔸 Conectado: {'✅ SÍ' if controller.mqtt_connected else '❌ NO'}")
            if controller.mqtt_connected:
                print(f"   🔸 Broker: {controller.mqtt_client._host}")
                print(f"   🔸 Puerto: {controller.mqtt_client._port}")
            
            return original_publish_mqtt(data)
        
        controller._publish_mqtt = debug_publish_mqtt
        
        print(f"\n🎯 CONFIGURACIÓN DEBUG:")
        print(f"   🔸 Modo: Simulación")
        print(f"   🔸 Alertas automáticas: Desactivadas")
        print(f"   🔸 Control: Por teclado")
        print(f"   🔸 Intervalo de datos: 2 segundos")
        print()
        
        # Inicializar y ejecutar
        controller.initialize()
        controller.run()
        
    except KeyboardInterrupt:
        print("\n⚠️ Debug interrumpido por el usuario")
    except Exception as e:
        print(f"\n❌ Error durante el debug: {e}")
        import traceback
        traceback.print_exc()
    finally:
        print("\n✅ Debug de infracciones finalizado")
        print("="*80)
        print("\n📋 RESUMEN DEL FLUJO:")
        print("1. Teclado → keyboard_alert_controller.py")
        print("2. Controlador → simulation_mode.py (active_violations)")
        print("3. Simulación → generate_json_data() (cada 2s)")
        print("4. Datos → _on_data_received() → _process_infracciones()")
        print("5. Procesamiento → _publish_individual_infraction()")
        print("6. MQTT → arduino/data/infracciones")
        print("7. API → mqtt_handler.py")
        print("8. WebSocket → /ws/alerts (type: 'infraction')")
        print("9. Flutter → Notificaciones")
        print()
        print("🔍 VERIFICACIONES:")
        print("- ✅ ¿Se activa la infracción por teclado?")
        print("- ✅ ¿Se agrega a active_violations?")
        print("- ✅ ¿Se incluye en datos generales?")
        print("- ✅ ¿Se publica individualmente?")
        print("- ✅ ¿MQTT está conectado?")
        print("- ❓ ¿La API recibe los datos?")
        print("- ❓ ¿Se envía al WebSocket?")
        print("- ❓ ¿Flutter recibe la notificación?")


if __name__ == "__main__":
    debug_infraction_flow()

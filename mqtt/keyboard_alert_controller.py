#!/usr/bin/env python3
"""
Controlador de alertas por teclado para el modo simulación MQTT.
Permite activar diferentes tipos de alertas usando teclas específicas.
"""

from pynput import keyboard
import threading
import time
from typing import Optional, Callable
from simulation_mode import ArduinoSimulator


class KeyboardAlertController:
    """
    Controlador que detecta teclas del teclado y activa alertas en el simulador.
    """
    
    def __init__(self, simulator: ArduinoSimulator):
        self.simulator = simulator
        self.running = False
        self.thread = None
        
        # Mapeo de teclas a funciones de alerta (usando pynput)
        self.key_mappings = {
            # Alertas de sismo
            (keyboard.KeyCode.from_char('e'), frozenset()): self._activate_earthquake,
            (keyboard.KeyCode.from_char('e'), frozenset([keyboard.Key.shift])): self._activate_strong_earthquake,
            
            # Alertas de botones de pánico
            (keyboard.KeyCode.from_char('p'), frozenset()): self._activate_panic_button_1,
            (keyboard.KeyCode.from_char('p'), frozenset([keyboard.Key.shift])): self._activate_panic_button_2,
            (keyboard.KeyCode.from_char('p'), frozenset([keyboard.Key.ctrl])): self._activate_panic_button_3,
            (keyboard.KeyCode.from_char('p'), frozenset([keyboard.Key.alt])): self._activate_panic_button_4,
            
            # Alertas de infracciones
            (keyboard.KeyCode.from_char('v'), frozenset()): self._activate_violation_1,
            (keyboard.KeyCode.from_char('v'), frozenset([keyboard.Key.shift])): self._activate_violation_2,
            (keyboard.KeyCode.from_char('v'), frozenset([keyboard.Key.ctrl])): self._activate_violation_3,
            
            # Alertas de gas
            (keyboard.KeyCode.from_char('g'), frozenset()): self._activate_gas_zone1,
            (keyboard.KeyCode.from_char('g'), frozenset([keyboard.Key.shift])): self._activate_gas_zone2,
            
            # Control general
            (keyboard.KeyCode.from_char('c'), frozenset()): self._clear_all_alerts,
            (keyboard.KeyCode.from_char('h'), frozenset()): self._show_help,
            (keyboard.KeyCode.from_char('q'), frozenset()): self._quit_controller,
        }
        
        # Listener de teclado
        self.listener = None
        
        # Estado de teclas modificadoras
        self.pressed_modifiers = set()
        
        # Callbacks opcionales
        self.on_alert_callback: Optional[Callable] = None
        self.on_quit_callback: Optional[Callable] = None
    
    def set_alert_callback(self, callback: Callable):
        """Establece un callback que se ejecuta cuando se activa una alerta."""
        self.on_alert_callback = callback
    
    def set_quit_callback(self, callback: Callable):
        """Establece un callback que se ejecuta cuando se presiona 'q' para salir."""
        self.on_quit_callback = callback
    
    def _execute_callback(self, alert_type: str, details: str = ""):
        """Ejecuta el callback de alerta si está definido."""
        if self.on_alert_callback:
            self.on_alert_callback(alert_type, details)
    
    def _activate_earthquake(self):
        """Activa un sismo moderado."""
        self.simulator.activate_earthquake_alert(5.2)
        self._execute_callback("earthquake", "Magnitud 5.2")
    
    def _activate_strong_earthquake(self):
        """Activa un sismo fuerte."""
        self.simulator.activate_earthquake_alert(6.8)
        self._execute_callback("earthquake", "Magnitud 6.8")
    
    def _activate_panic_button_1(self):
        """Activa botón de pánico PB1."""
        self.simulator.activate_panic_button_alert("PB1")
        self._execute_callback("panic_button", "PB1")
    
    def _activate_panic_button_2(self):
        """Activa botón de pánico PB2."""
        self.simulator.activate_panic_button_alert("PB2")
        self._execute_callback("panic_button", "PB2")
    
    def _activate_panic_button_3(self):
        """Activa botón de pánico PB3."""
        self.simulator.activate_panic_button_alert("PB3")
        self._execute_callback("panic_button", "PB3")
    
    def _activate_panic_button_4(self):
        """Activa botón de pánico PB4."""
        self.simulator.activate_panic_button_alert("PB4")
        self._execute_callback("panic_button", "PB4")
    
    def _activate_violation_1(self):
        """Activa infracción en semáforo S1."""
        self.simulator.activate_violation_alert("S1")
        self._execute_callback("violation", "S1")
    
    def _activate_violation_2(self):
        """Activa infracción en semáforo S5."""
        self.simulator.activate_violation_alert("S5")
        self._execute_callback("violation", "S5")
    
    def _activate_violation_3(self):
        """Activa infracción en semáforo S10."""
        self.simulator.activate_violation_alert("S10")
        self._execute_callback("violation", "S10")
    
    def _activate_gas_zone1(self):
        """Activa alerta de gas en zona Z1."""
        self.simulator.activate_gas_alert("Z1", 285)
        self._execute_callback("gas_alert", "Z1 - 285 ppm")
    
    def _activate_gas_zone2(self):
        """Activa alerta de gas en zona Z2."""
        self.simulator.activate_gas_alert("Z2", 290)
        self._execute_callback("gas_alert", "Z2 - 290 ppm")
    
    def _clear_all_alerts(self):
        """Limpia todas las alertas activas."""
        self.simulator.clear_all_alerts()
        self._execute_callback("clear_all", "")
    
    def _show_help(self):
        """Muestra la ayuda de teclas."""
        self._print_help()
    
    def _quit_controller(self):
        """Detiene el controlador."""
        print("\n🛑 Deteniendo controlador de teclas...")
        self.running = False
        if self.on_quit_callback:
            self.on_quit_callback()
    
    def _print_help(self):
        """Imprime la ayuda de teclas disponibles."""
        print("\n" + "="*60)
        print("🎮 CONTROLADOR DE ALERTAS POR TECLADO")
        print("="*60)
        print("📋 TECLAS DISPONIBLES:")
        print()
        print("🌍 SISMOS:")
        print("   E        - Sismo moderado (5.2)")
        print("   Shift+E  - Sismo fuerte (6.8)")
        print()
        print("🚨 BOTONES DE PÁNICO:")
        print("   P        - Botón PB1")
        print("   Shift+P  - Botón PB2")
        print("   Ctrl+P   - Botón PB3")
        print("   Alt+P    - Botón PB4")
        print()
        print("🚗 INFRACCIONES:")
        print("   V        - Infracción S1")
        print("   Shift+V  - Infracción S5")
        print("   Ctrl+V   - Infracción S10")
        print()
        print("🔥 ALERTAS DE GAS:")
        print("   G        - Gas alto Z1 (285 ppm)")
        print("   Shift+G  - Gas alto Z2 (290 ppm)")
        print()
        print("🎛️  CONTROL:")
        print("   C        - Limpiar todas las alertas")
        print("   H        - Mostrar esta ayuda")
        print("   Q        - Salir del controlador")
        print()
        print("="*60)
        print("💡 Presiona cualquier tecla para continuar...")
        print("="*60)
    
    def _on_key_press(self, key):
        """Callback ejecutado cuando se presiona una tecla."""
        try:
            # Actualizar estado de teclas modificadoras
            if key in [keyboard.Key.shift, keyboard.Key.ctrl, keyboard.Key.alt]:
                self.pressed_modifiers.add(key)
                return
            
            # Procesar tecla normal
            if hasattr(key, 'char') and key.char:
                key_code = keyboard.KeyCode.from_char(key.char)
                
                # Crear tupla para buscar en el mapeo
                key_combo = (key_code, frozenset(self.pressed_modifiers))
                
                # Buscar en el mapeo de teclas
                if key_combo in self.key_mappings:
                    function = self.key_mappings[key_combo]
                    function()
                    time.sleep(0.2)  # Evitar múltiples activaciones
                
        except Exception as e:
            print(f"Error procesando tecla: {e}")
    
    def _on_key_release(self, key):
        """Callback ejecutado cuando se suelta una tecla."""
        # Actualizar estado de teclas modificadoras
        if key in [keyboard.Key.shift, keyboard.Key.ctrl, keyboard.Key.alt]:
            self.pressed_modifiers.discard(key)
        
        # Si se presiona Escape, salir
        if key == keyboard.Key.esc:
            self._quit_controller()
            return False  # Detener el listener
    
    def start(self):
        """Inicia el controlador de teclas."""
        if self.running:
            print("⚠️ El controlador ya está ejecutándose")
            return
        
        self.running = True
        
        # Crear listener de pynput
        self.listener = keyboard.Listener(
            on_press=self._on_key_press,
            on_release=self._on_key_release
        )
        
        # Iniciar listener en un hilo separado
        self.listener.start()
        
        print("✅ Controlador de teclas iniciado")
        self._print_help()
    
    def stop(self):
        """Detiene el controlador de teclas."""
        if not self.running:
            return
        
        self.running = False
        
        # Detener listener
        if self.listener:
            self.listener.stop()
            self.listener = None
        
        print("🛑 Controlador de teclas detenido")
    
    def is_running(self) -> bool:
        """Verifica si el controlador está ejecutándose."""
        return self.running


def main():
    """Función principal para probar el controlador."""
    print("=== Controlador de Alertas por Teclado ===")
    print("Creando simulador...")
    
    # Crear simulador
    simulator = ArduinoSimulator()
    
    # Crear controlador
    controller = KeyboardAlertController(simulator)
    
    # Configurar callbacks
    def on_alert(alert_type: str, details: str):
        print(f"🔔 Callback ejecutado: {alert_type} - {details}")
    
    def on_quit():
        print("👋 Callback de salida ejecutado")
    
    controller.set_alert_callback(on_alert)
    controller.set_quit_callback(on_quit)
    
    try:
        # Iniciar controlador
        controller.start()
        
        # Mantener el programa ejecutándose
        while controller.is_running():
            time.sleep(0.1)
            
    except KeyboardInterrupt:
        print("\n⚠️ Interrupción de teclado recibida")
    finally:
        controller.stop()
        print("✅ Programa finalizado")


if __name__ == "__main__":
    main()

"""
Paquete MQTT para comunicación serial con Arduino.

Este paquete proporciona funcionalidades para:
- Recepción de datos desde Arduino por comunicación serial
- Procesamiento de datos en formato JSON estructurado
- Configuración flexible de parámetros de conexión
- Manejo robusto de errores y reconexión automática
- Parser especializado para datos del Arduino
- Modo simulación para pruebas sin hardware
"""

from .serial_receiver import ArduinoSerialReceiver, SerialConfig
from .arduino_data_parser import ArduinoDataParser, parse_arduino_json
from .simulation_mode import ArduinoSimulator

__version__ = "1.0.0"
__author__ = "ARQUI2B_2S2025_GL4"
__all__ = ["ArduinoSerialReceiver", "SerialConfig", "ArduinoDataParser", "parse_arduino_json", "ArduinoSimulator"]

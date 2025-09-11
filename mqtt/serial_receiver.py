"""
Módulo para recibir datos JSON desde Arduino por comunicación serial.
Este módulo establece una conexión serial con Arduino y recibe datos
en formato JSON que pueden ser procesados posteriormente.
"""

import serial
import serial.tools.list_ports
import time
import json
import logging
from typing import Optional, Dict, Any, Callable, List
from dataclasses import dataclass
from threading import Thread, Event
from arduino_data_parser import ArduinoDataParser, parse_arduino_json


@dataclass
class SerialConfig:
    """Configuración para la comunicación serial."""
    port: str = '/dev/ttyUSB0'
    baudrate: int = 9600
    timeout: float = 1.0
    bytesize: int = serial.EIGHTBITS
    parity: str = serial.PARITY_NONE
    stopbits: int = serial.STOPBITS_ONE


class ArduinoSerialReceiver:
    """
    Clase para recibir datos desde Arduino por comunicación serial.
    """
    
    def __init__(self, config: SerialConfig):
        """
        Inicializa el receptor serial.
        
        Args:
            config: Configuración de la comunicación serial
        """
        self.config = config
        self.serial_connection: Optional[serial.Serial] = None
        self.is_running = False
        self.stop_event = Event()
        self.receiver_thread: Optional[Thread] = None
        self.logger = self._setup_logging()
        
        # Callbacks para datos parseados
        self.on_data_parsed: Optional[Callable[[ArduinoDataParser], None]] = None
        self.on_parse_error: Optional[Callable[[str, str], None]] = None
        
    def _setup_logging(self) -> logging.Logger:
        """Configura el sistema de logging."""
        logger = logging.getLogger(__name__)
        logger.setLevel(logging.INFO)
        
        if not logger.handlers:
            handler = logging.StreamHandler()
            formatter = logging.Formatter(
                '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
            )
            handler.setFormatter(formatter)
            logger.addHandler(handler)
            
        return logger
    
    @staticmethod
    def find_arduino_ports() -> List[str]:
        """
        Encuentra puertos que probablemente sean Arduino.
        
        Returns:
            Lista de puertos candidatos
        """
        arduino_ports = []
        ports = serial.tools.list_ports.comports()
        
        for port in ports:
            # Buscar puertos que contengan 'Arduino' en la descripción
            if 'Arduino' in port.description or 'arduino' in port.description.lower():
                arduino_ports.append(port.device)
            # También buscar puertos USB comunes
            elif 'USB' in port.description or 'ACM' in port.device or 'USB' in port.device:
                arduino_ports.append(port.device)
        
        return arduino_ports
    
    def connect(self) -> bool:
        """
        Establece la conexión serial con Arduino.
        
        Returns:
            True si la conexión fue exitosa, False en caso contrario
        """
        # Si el puerto configurado no funciona, intentar encontrar Arduino automáticamente
        ports_to_try = [self.config.port]
        
        # Si el puerto configurado no es el predeterminado, agregar puertos Arduino detectados
        if self.config.port != '/dev/ttyUSB0':
            arduino_ports = self.find_arduino_ports()
            ports_to_try.extend(arduino_ports)
        
        for port in ports_to_try:
            try:
                self.logger.info(f"Intentando conectar en puerto: {port}")
                self.serial_connection = serial.Serial(
                    port=port,
                    baudrate=self.config.baudrate,
                    timeout=self.config.timeout,
                    bytesize=self.config.bytesize,
                    parity=self.config.parity,
                    stopbits=self.config.stopbits
                )
                
                # Esperar a que Arduino se reinicie
                time.sleep(2)
                
                if self.serial_connection.is_open:
                    self.logger.info(f"Conexión serial establecida en {port}")
                    # Actualizar la configuración con el puerto que funcionó
                    self.config.port = port
                    # Limpiar buffer de arranque/bootloader
                    try:
                        self.serial_connection.reset_input_buffer()
                        self.serial_connection.reset_output_buffer()
                    except Exception:
                        pass
                    return True
                else:
                    self.logger.warning(f"No se pudo abrir la conexión en {port}")
                    
            except serial.SerialException as e:
                self.logger.warning(f"Error al conectar en {port}: {e}")
                continue
            except Exception as e:
                self.logger.warning(f"Error inesperado al conectar en {port}: {e}")
                continue
        
        self.logger.error("No se pudo establecer conexión con ningún puerto")
        return False
    
    def disconnect(self):
        """Cierra la conexión serial."""
        if self.serial_connection and self.serial_connection.is_open:
            self.serial_connection.close()
            self.logger.info("Conexión serial cerrada")
    
    def start_receiving(self):
        """Inicia el hilo de recepción de datos."""
        if self.is_running:
            self.logger.warning("El receptor ya está ejecutándose")
            return
            
        if not self.serial_connection or not self.serial_connection.is_open:
            if not self.connect():
                self.logger.error("No se pudo conectar con Arduino")
                return
        
        self.is_running = True
        self.stop_event.clear()
        self.receiver_thread = Thread(target=self._receive_loop, daemon=True)
        self.receiver_thread.start()
        self.logger.info("Iniciado el receptor de datos serial")
    
    def stop_receiving(self):
        """Detiene el hilo de recepción de datos."""
        self.is_running = False
        self.stop_event.set()
        
        if self.receiver_thread and self.receiver_thread.is_alive():
            self.receiver_thread.join(timeout=2.0)
            
        self.logger.info("Receptor de datos serial detenido")
    
    def _receive_loop(self):
        """Bucle principal de recepción de datos."""
        while self.is_running and not self.stop_event.is_set():
            try:
                if self.serial_connection and self.serial_connection.in_waiting:
                    # Leer datos como bytes primero
                    raw_data = self.serial_connection.readline()
                    
                    if raw_data:
                        try:
                            # Intentar decodificar como UTF-8
                            data_line = raw_data.decode('utf-8').strip()
                        except UnicodeDecodeError:
                            # Si falla UTF-8, intentar con latin-1 o ignorar errores
                            try:
                                data_line = raw_data.decode('latin-1').strip()
                                self.logger.warning(f"Datos decodificados con latin-1: {data_line}")
                            except UnicodeDecodeError:
                                # Como último recurso, ignorar caracteres problemáticos
                                data_line = raw_data.decode('utf-8', errors='ignore').strip()
                                self.logger.warning(f"Datos decodificados ignorando errores: {data_line}")
                        
                        if data_line:
                            self._process_data(data_line)
                        
            except serial.SerialException as e:
                self.logger.error(f"Error en la comunicación serial: {e}")
                break
            except Exception as e:
                self.logger.error(f"Error inesperado en la recepción: {e}")
                break
                
            time.sleep(0.1)  # Pequeña pausa para no saturar la CPU
    
    def _process_data(self, data_line: str):
        """
        Procesa los datos JSON recibidos desde Arduino.
        
        Args:
            data_line: Línea de datos JSON recibida
        """
        # Ignorar líneas que no sean JSON (Arduino emite líneas de eventos y depuración)
        stripped = data_line.lstrip()
        if not stripped.startswith('{'):
            return

        try:
            # Usar el parser especializado para Arduino
            parsed_data = parse_arduino_json(data_line)
            
            if parsed_data:
                self.logger.info(f"Datos Arduino parseados: {parsed_data}")
                self._handle_json_data(parsed_data.raw_data)
                
                # Llamar callback si está configurado
                if self.on_data_parsed:
                    self.on_data_parsed(parsed_data)
            else:
                # Fallback al método anterior si el parser falla
                data = json.loads(data_line)
                self.logger.info(f"Datos JSON recibidos: {data}")
                self._handle_json_data(data)
                
        except json.JSONDecodeError as e:
            # Si no es JSON válido, registrar error
            error_msg = f"Error al parsear JSON: {e}"
            self.logger.error(error_msg)
            self.logger.error(f"Datos recibidos: {data_line}")
            
            # Llamar callback de error si está configurado
            if self.on_parse_error:
                self.on_parse_error(error_msg, data_line)
    
    def _handle_json_data(self, data: Dict[str, Any]):
        """
        Maneja datos en formato JSON.
        
        Args:
            data: Datos parseados como diccionario
        """
        # Aquí puedes agregar lógica específica para procesar datos JSON
        # Por ejemplo, validar campos, convertir tipos, etc.
        pass
    

    
    def send_command(self, command: str) -> bool:
        """
        Envía un comando a Arduino.
        
        Args:
            command: Comando a enviar
            
        Returns:
            True si el comando se envió exitosamente, False en caso contrario
        """
        try:
            if self.serial_connection and self.serial_connection.is_open:
                self.serial_connection.write(f"{command}\n".encode('utf-8'))
                self.serial_connection.flush()
                self.logger.info(f"Comando enviado: {command}")
                return True
            else:
                self.logger.error("No hay conexión serial activa")
                return False
        except Exception as e:
            self.logger.error(f"Error al enviar comando: {e}")
            return False
    
    def get_status(self) -> Dict[str, Any]:
        """
        Obtiene el estado actual del receptor.
        
        Returns:
            Diccionario con información del estado
        """
        return {
            'is_connected': self.serial_connection.is_open if self.serial_connection else False,
            'is_running': self.is_running,
            'port': self.config.port,
            'baudrate': self.config.baudrate
        }
    
    def set_data_callback(self, callback: Callable[[ArduinoDataParser], None]):
        """
        Configura el callback para datos parseados exitosamente.
        
        Args:
            callback: Función que recibe un ArduinoDataParser
        """
        self.on_data_parsed = callback
    
    def set_error_callback(self, callback: Callable[[str, str], None]):
        """
        Configura el callback para errores de parsing.
        
        Args:
            callback: Función que recibe (error_msg, raw_data)
        """
        self.on_parse_error = callback


def main():
    """Función principal para pruebas del módulo."""
    # Configuración por defecto
    config = SerialConfig(
        port='/dev/ttyACM0', 
        baudrate=115200
    )
    
    # Crear instancia del receptor
    receiver = ArduinoSerialReceiver(config)
    
    try:
        # Iniciar recepción
        receiver.start_receiving()
        
        # Mantener el programa ejecutándose
        print("Receptor serial iniciado. Presiona Ctrl+C para detener.")
        while True:
            time.sleep(1)
            
    except KeyboardInterrupt:
        print("\nDeteniendo el receptor...")
        receiver.stop_receiving()
        receiver.disconnect()
        print("Receptor detenido.")


if __name__ == "__main__":
    main()

"""
Archivo de configuración para el módulo de comunicación serial con Arduino.
Aquí puedes modificar los parámetros de conexión según tu configuración.
"""

# Configuración de comunicación serial
SERIAL_CONFIG = {
    'port': '/dev/ttyUSB0',  # Linux

    
    # Velocidad de transmisión (debe coincidir con Arduino)
    'baudrate': 9600,
    
    # Timeout para operaciones de lectura
    'timeout': 1.0,
    
    # Configuración de bits de datos
    'bytesize': 8,
    
    # Paridad (NONE, EVEN, ODD)
    'parity': 'NONE',
    
    # Bits de parada
    'stopbits': 1
}

# Configuración de logging
LOGGING_CONFIG = {
    'level': 'INFO',  # DEBUG, INFO, WARNING, ERROR, CRITICAL
    'format': '%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    'file': None  # Ruta al archivo de log (None para consola)
}

# Configuración de procesamiento de datos
DATA_PROCESSING = {
    # Tiempo de espera entre lecturas (segundos)
    'read_interval': 0.1,
    
    # Codificación de caracteres
    'encoding': 'utf-8',
    
    # Delimitador de líneas
    'line_delimiter': '\n',
    
    # Tamaño máximo del buffer de lectura
    'max_buffer_size': 1024
}

# Configuración de reconexión
RECONNECTION = {
    # Intentar reconectar automáticamente
    'auto_reconnect': True,
    
    # Número máximo de intentos de reconexión
    'max_attempts': 5,
    
    # Tiempo de espera entre intentos (segundos)
    'retry_delay': 2.0
}

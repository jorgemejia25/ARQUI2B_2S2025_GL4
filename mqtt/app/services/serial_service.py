"""
Serial communication service
Handles communication with Arduino via serial port
"""

import serial
import time
from typing import Optional, Callable
from app.core.config import serial_settings
from app.core.logging import get_logger

logger = get_logger(__name__)


class SerialService:
    """Service for serial communication with Arduino"""
    
    def __init__(self):
        self.port = serial_settings.SERIAL_PORT
        self.baudrate = serial_settings.SERIAL_BAUDRATE
        self.timeout = serial_settings.SERIAL_TIMEOUT
        self.connection: Optional[serial.Serial] = None
        self.is_connected = False
    
    def connect(self) -> bool:
        """
        Establish serial connection
        
        Returns:
            True if connection successful, False otherwise
        """
        try:
            self.connection = serial.Serial(
                port=self.port,
                baudrate=self.baudrate,
                timeout=self.timeout
            )
            time.sleep(2)  # Wait for Arduino to reset
            self.is_connected = True
            logger.info(f"Serial connection established: {self.port} @ {self.baudrate}")
            return True
        except serial.SerialException as e:
            logger.error(f"Serial connection error: {e}")
            self.is_connected = False
            return False
        except Exception as e:
            logger.error(f"Unexpected error during serial connection: {e}")
            self.is_connected = False
            return False
    
    def disconnect(self) -> None:
        """Close serial connection"""
        if self.connection and self.connection.is_open:
            self.connection.close()
            self.is_connected = False
            logger.info("Serial connection closed")
    
    def read_line(self) -> Optional[str]:
        """
        Read a line from serial connection
        
        Returns:
            Decoded string or None if error/timeout
        """
        if not self.is_connected or not self.connection:
            logger.warning("Attempting to read from disconnected serial port")
            return None
        
        try:
            # readline() bloqueará hasta encontrar \n o timeout
            line = self.connection.readline()
            if line:
                decoded = line.decode('utf-8', errors='ignore').strip()
                if decoded:  # Solo retornar si hay contenido
                    return decoded
            return None
        except serial.SerialException as e:
            logger.error(f"Serial read error: {e}")
            self.is_connected = False
            return None
        except Exception as e:
            logger.error(f"Unexpected error reading serial: {e}")
            return None
    
    def write(self, data: str) -> bool:
        """
        Write data to serial connection
        
        Args:
            data: String to send
            
        Returns:
            True if successful, False otherwise
        """
        if not self.is_connected or not self.connection:
            logger.warning("Attempting to write to disconnected serial port")
            return False
        
        try:
            self.connection.write(data.encode('utf-8'))
            return True
        except serial.SerialException as e:
            logger.error(f"Serial write error: {e}")
            self.is_connected = False
            return False
        except Exception as e:
            logger.error(f"Unexpected error writing serial: {e}")
            return False
    
    def read_until_json(self, timeout: float = 10.0) -> Optional[str]:
        """
        Read from serial until a complete JSON object is received
        
        Args:
            timeout: Maximum time to wait in seconds
            
        Returns:
            JSON string or None if timeout/error
        """
        start_time = time.time()
        buffer = []  # accumulate chunks to avoid repeated string copies
        brace_depth = 0
        in_json = False
        
        while (time.time() - start_time) < timeout:
            line = self.read_line()
            if not line:
                # read_line ya bloqueó con su timeout, no necesitamos sleep extra
                continue
            
            stripped = line.strip()
            if not stripped:
                continue
            
            # Try to detect start of JSON
            # Many Arduinos send extra logs; ignore until '{' appears
            for ch in stripped:
                if ch == '{':
                    in_json = True
                    brace_depth += 1
                    buffer.append('{')
                elif ch == '}' and in_json:
                    brace_depth -= 1
                    buffer.append('}')
                    if brace_depth == 0:
                        json_str = ''.join(buffer).strip()
                        if json_str:
                            return json_str
                        buffer = []
                        in_json = False
                elif in_json:
                    buffer.append(ch)
                else:
                    # ignore noise before JSON starts
                    continue
            
            # Safety: prevent unbounded growth if malformed stream
            if len(buffer) > 5 * 1024:
                logger.warning("Serial buffer exceeded 5KB without closing JSON; resetting buffer")
                buffer = []
                brace_depth = 0
                in_json = False
        
        # Timeout fallback: return best-effort if it looks like JSON
        if buffer and in_json and brace_depth == 0:
            return ''.join(buffer).strip()
        return None
    
    def __enter__(self):
        """Context manager entry"""
        self.connect()
        return self
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        """Context manager exit"""
        self.disconnect()










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
        self.port = serial_settings.PORT
        self.baudrate = serial_settings.BAUDRATE
        self.timeout = serial_settings.TIMEOUT
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
            if self.connection.in_waiting > 0:
                line = self.connection.readline()
                return line.decode('utf-8', errors='ignore').strip()
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
        buffer = ""
        
        while (time.time() - start_time) < timeout:
            line = self.read_line()
            if line:
                buffer += line
                # Check if we have a complete JSON
                if buffer.strip().startswith('{') and buffer.strip().endswith('}'):
                    return buffer.strip()
            time.sleep(0.01)
        
        return None if not buffer else buffer.strip()
    
    def __enter__(self):
        """Context manager entry"""
        self.connect()
        return self
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        """Context manager exit"""
        self.disconnect()


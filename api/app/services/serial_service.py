"""
Serial communication service for the API
Provides a thin wrapper over pyserial to send alerts to Arduino
"""

from typing import Optional

import time
import serial

from app.core.config import settings
from app.core.logging import get_logger


logger = get_logger(__name__)


class APISerialService:
    """Serial communication service used by API endpoints.

    Lazily connects on first write and keeps the connection open for reuse.
    """

    def __init__(self) -> None:
        self.port: str = settings.SERIAL_PORT
        self.baudrate: int = settings.SERIAL_BAUDRATE
        self.timeout: float = settings.SERIAL_TIMEOUT
        self._conn: Optional[serial.Serial] = None

    def _ensure_connected(self) -> bool:
        """Ensure the serial connection is established.

        Returns True when connected, False otherwise.
        """
        if self._conn and self._conn.is_open:
            return True
        try:
            self._conn = serial.Serial(
                port=self.port,
                baudrate=self.baudrate,
                timeout=self.timeout,
            )
            # Give Arduino time to reset on new connection
            time.sleep(2)
            logger.info(f"Serial connected: {self.port} @ {self.baudrate}")
            return True
        except serial.SerialException as exc:
            logger.error(f"Serial connection error: {exc}")
            self._conn = None
            return False
        except Exception as exc:
            logger.error(f"Unexpected serial error: {exc}")
            self._conn = None
            return False

    def send_line(self, line: str) -> bool:
        """Send a line to Arduino, appending a newline if not present.

        Returns True on success, False on failure.
        """
        if not self._ensure_connected():
            return False
        try:
            data = line if line.endswith("\n") else f"{line}\n"
            assert self._conn is not None
            self._conn.write(data.encode("utf-8"))
            logger.info(f"Serial write: {data.strip()}")
            return True
        except serial.SerialException as exc:
            logger.error(f"Serial write error: {exc}")
            self._conn = None
            return False
        except Exception as exc:
            logger.error(f"Unexpected serial write error: {exc}")
            return False




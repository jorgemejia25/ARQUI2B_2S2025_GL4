"""
Repository for PlateEvent operations compatible with DatabaseConnection class
"""
from typing import List, Optional, Dict, Any
from app.core.logging import get_logger

logger = get_logger(__name__)


class PlateRepository:
    def __init__(self, db_connection):
        self.db = db_connection

    def save_plate_event(self, data: Dict[str, Any]) -> Optional[int]:
        """Insert new plate detection event"""
        try:
            insert_query = """
            INSERT INTO PlateEvent (plate_text, confidence, camera_location, ts, image_base64)
            VALUES (?, ?, ?, ?, ?)
            """
            params = (
                data.get("plate_text"),
                data.get("confidence"),
                data.get("camera_location"),
                data.get("timestamp"),
                data.get("image_base64"),
            )

            self.db.execute_query(insert_query, params)

            # Obtener el ID del último registro insertado
            result = self.db.execute_query("SELECT last_insert_rowid() AS id")
            if isinstance(result, list) and len(result) > 0:
                event_id = result[0]["id"] if isinstance(result[0], dict) else result[0][0]
            else:
                event_id = None

            logger.info(f"✅ Plate event saved successfully: {data.get('plate_text')} (id={event_id})")
            return event_id

        except Exception as e:
            logger.error(f"Error saving plate event: {e}")
            return None

    def get_plate_events(self, limit: int, offset: int, plate: Optional[str] = None) -> List[Dict[str, Any]]:
        """Retrieve paginated plate events"""
        try:
            if plate:
                query = """
                SELECT * FROM PlateEvent
                WHERE plate_text LIKE ?
                ORDER BY ts DESC
                LIMIT ? OFFSET ?
                """
                params = (f"%{plate}%", limit, offset)
            else:
                query = """
                SELECT * FROM PlateEvent
                ORDER BY ts DESC
                LIMIT ? OFFSET ?
                """
                params = (limit, offset)

            rows = self.db.execute_query(query, params)
            return rows if rows else []

        except Exception as e:
            logger.error(f"Error retrieving plate events: {e}")
            return []

    def get_total_count(self, plate: Optional[str] = None) -> int:
        """Count total number of plate events"""
        try:
            if plate:
                query = "SELECT COUNT(*) AS total FROM PlateEvent WHERE plate_text LIKE ?"
                params = (f"%{plate}%",)
            else:
                query = "SELECT COUNT(*) AS total FROM PlateEvent"
                params = ()

            result = self.db.execute_query(query, params)
            if isinstance(result, list) and len(result) > 0:
                return result[0]["total"] if isinstance(result[0], dict) else result[0][0]
            return 0

        except Exception as e:
            logger.error(f"Error counting plate events: {e}")
            return 0

"""
Weapon Repository
Database operations for weapon detection events
"""

from typing import List, Dict, Any, Optional
from app.core.logging import get_logger
from app.db.connection import DatabaseConnection

logger = get_logger(__name__)


class WeaponRepository:
    """Repository for weapon detection operations"""

    def __init__(self, db_connection: DatabaseConnection):
        self.db = db_connection

    def save_weapon_detection(self, event_data: Dict[str, Any]) -> Optional[int]:
        """
        Save a new weapon detection event to the database

        Args:
            event_data: Dictionary containing event data

        Returns:
            ID of the created event or None if failed
        """
        try:
            # Ensure connection is active
            if not self.db._connection:
                self.db.connect()

            query = """
                INSERT INTO weaponDetections (
                    name,
                    distance,
                    camera_location
                ) VALUES (?, ?, ?)
            """

            params = (
                event_data.get('name'),
                event_data.get('distance'),
                event_data.get('camera_location')
            )

            cursor = self.db._connection.cursor()
            cursor.execute(query, params)
            self.db._connection.commit()

            # Get the inserted ID
            event_id = cursor.lastrowid
            cursor.close()

            # Update weapon counts
            self._increment_weapon_count(event_data.get('name'))

            logger.info(f"Weapon detection saved: ID={event_id}, weapon={event_data.get('name')}")
            return event_id

        except Exception as e:
            logger.error(f"Error saving weapon detection: {e}")
            return None

    def _increment_weapon_count(self, weapon_name: str) -> bool:
        """Increment count for a weapon in weaponCounts table"""
        try:
            if not self.db._connection:
                self.db.connect()

            # Insert or update count
            query = """
                INSERT OR REPLACE INTO weaponCounts (name, count)
                VALUES (?, COALESCE((SELECT count FROM weaponCounts WHERE name = ?), 0) + 1)
            """

            cursor = self.db._connection.cursor()
            cursor.execute(query, (weapon_name, weapon_name))
            self.db._connection.commit()
            cursor.close()

            logger.debug(f"Incremented count for weapon: {weapon_name}")
            return True

        except Exception as e:
            logger.error(f"Error incrementing weapon count: {e}")
            return False

    def get_weapon_detections(
        self,
        limit: int = 50,
        offset: int = 0,
        weapon_filter: Optional[str] = None
    ) -> List[Dict[str, Any]]:
        """
        Get paginated weapon detections with optional weapon filter

        Args:
            limit: Maximum number of events to return
            offset: Number of events to skip
            weapon_filter: Optional filter by weapon name

        Returns:
            List of event dictionaries
        """
        try:
            base_query = """
                SELECT
                    id,
                    ts,
                    name,
                    distance,
                    camera_location
                FROM weaponDetections
            """

            params = []
            where_clause = ""

            if weapon_filter:
                where_clause = " WHERE name LIKE ?"
                params.append(f"%{weapon_filter}%")

            order_clause = " ORDER BY ts DESC"
            limit_clause = " LIMIT ? OFFSET ?"
            params.extend([limit, offset])

            query = base_query + where_clause + order_clause + limit_clause

            results = self.db.execute_query(query, params)

            events = []
            if results:
                for row in results:
                    event = {
                        'id': row['id'],
                        'ts': row['ts'],
                        'name': row['name'],
                        'distance': row['distance'],
                        'camera_location': row['camera_location']
                    }
                    events.append(event)

            logger.debug(f"Retrieved {len(events)} weapon detections (limit={limit}, offset={offset})")
            return events

        except Exception as e:
            logger.error(f"Error retrieving weapon detections: {e}")
            return []

    def get_weapon_counts(self, limit: int = 10) -> List[Dict[str, Any]]:
        """
        Get weapon counts ordered by count descending

        Args:
            limit: Maximum number of weapons to return

        Returns:
            List of weapon count dictionaries
        """
        try:
            query = """
                SELECT
                    name,
                    count
                FROM weaponCounts
                ORDER BY count DESC
                LIMIT ?
            """

            results = self.db.execute_query(query, [limit])

            counts = []
            if results:
                for row in results:
                    count_data = {
                        'name': row['name'],
                        'count': row['count']
                    }
                    counts.append(count_data)

            logger.debug(f"Retrieved {len(counts)} weapon counts")
            return counts

        except Exception as e:
            logger.error(f"Error retrieving weapon counts: {e}")
            return []

    def get_total_weapon_detections(self, weapon_filter: Optional[str] = None) -> int:
        """
        Get total count of weapon detections with optional weapon filter

        Args:
            weapon_filter: Optional filter by weapon name

        Returns:
            Total number of detections
        """
        try:
            base_query = "SELECT COUNT(*) FROM weaponDetections"
            params = []

            if weapon_filter:
                query = base_query + " WHERE name LIKE ?"
                params.append(f"%{weapon_filter}%")
            else:
                query = base_query

            result = self.db.execute_query(query, params)

            if result and len(result) > 0:
                count = result[0]['COUNT(*)']
                logger.debug(f"Total weapon detections count: {count}")
                return count
            else:
                return 0

        except Exception as e:
            logger.error(f"Error getting weapon detections count: {e}")
            return 0
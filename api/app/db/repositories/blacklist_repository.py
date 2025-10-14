"""
Blacklist Repository
Database operations for blacklist events
"""

from typing import List, Dict, Any, Optional, Tuple
from datetime import datetime

from app.core.logging import get_logger
from app.db.connection import DatabaseConnection

logger = get_logger(__name__)


class BlacklistRepository:
    """Repository for blacklist event operations"""
    
    def __init__(self, db_connection: DatabaseConnection):
        self.db = db_connection
    
    def save_blacklist_event(self, event_data: Dict[str, Any]) -> Optional[int]:
        """
        Save a new blacklist event to the database
        
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
                INSERT INTO BlacklistEvent (
                    person_name, 
                    confidence, 
                    distance, 
                    camera_location
                ) VALUES (?, ?, ?, ?)
            """
            
            params = (
                event_data.get('person_name'),
                event_data.get('confidence'),
                event_data.get('distance'),
                event_data.get('camera_location')
            )
            
            cursor = self.db._connection.cursor()
            cursor.execute(query, params)
            self.db._connection.commit()
            
            # Get the inserted ID
            event_id = cursor.lastrowid
            cursor.close()
            
            logger.info(f"Blacklist event saved: ID={event_id}, person={event_data.get('person_name')}")
            return event_id
                
        except Exception as e:
            logger.error(f"Error saving blacklist event: {e}")
            return None
    
    def get_blacklist_events(
        self, 
        limit: int = 50, 
        offset: int = 0, 
        person_filter: Optional[str] = None
    ) -> List[Dict[str, Any]]:
        """
        Get paginated blacklist events with optional person filter
        
        Args:
            limit: Maximum number of events to return
            offset: Number of events to skip
            person_filter: Optional filter by person name
            
        Returns:
            List of event dictionaries
        """
        try:
            base_query = """
                SELECT 
                    blacklist_event_id,
                    ts,
                    person_name,
                    confidence,
                    distance,
                    camera_location
                FROM BlacklistEvent
            """
            
            params = []
            where_clause = ""
            
            if person_filter:
                where_clause = " WHERE person_name LIKE ?"
                params.append(f"%{person_filter}%")
            
            order_clause = " ORDER BY ts DESC"
            limit_clause = " LIMIT ? OFFSET ?"
            params.extend([limit, offset])
            
            query = base_query + where_clause + order_clause + limit_clause
            
            results = self.db.execute_query(query, params)
            
            events = []
            if results:
                for row in results:
                    event = {
                        'blacklist_event_id': row['blacklist_event_id'],
                        'ts': row['ts'],
                        'person_name': row['person_name'],
                        'confidence': row['confidence'],
                        'distance': row['distance'],
                        'camera_location': row['camera_location']
                    }
                    events.append(event)
            
            logger.debug(f"Retrieved {len(events)} blacklist events (limit={limit}, offset={offset})")
            return events
            
        except Exception as e:
            logger.error(f"Error retrieving blacklist events: {e}")
            return []
    
    def get_total_count(self, person_filter: Optional[str] = None) -> int:
        """
        Get total count of blacklist events with optional person filter
        
        Args:
            person_filter: Optional filter by person name
            
        Returns:
            Total number of events
        """
        try:
            base_query = "SELECT COUNT(*) FROM BlacklistEvent"
            params = []
            
            if person_filter:
                query = base_query + " WHERE person_name LIKE ?"
                params.append(f"%{person_filter}%")
            else:
                query = base_query
            
            result = self.db.execute_query(query, params)
            
            if result and len(result) > 0:
                count = result[0]['COUNT(*)']
                logger.debug(f"Total blacklist events count: {count}")
                return count
            else:
                return 0
                
        except Exception as e:
            logger.error(f"Error getting blacklist events count: {e}")
            return 0
    
    def get_recent_events_by_person(self, person_name: str, limit: int = 10) -> List[Dict[str, Any]]:
        """
        Get recent events for a specific person
        
        Args:
            person_name: Name of the person to filter by
            limit: Maximum number of events to return
            
        Returns:
            List of recent events for the person
        """
        try:
            query = """
                SELECT 
                    blacklist_event_id,
                    ts,
                    person_name,
                    confidence,
                    distance,
                    camera_location
                FROM BlacklistEvent
                WHERE person_name = ?
                ORDER BY ts DESC
                LIMIT ?
            """
            
            results = self.db.execute_query(query, [person_name, limit])
            
            events = []
            if results:
                for row in results:
                    event = {
                        'blacklist_event_id': row['blacklist_event_id'],
                        'ts': row['ts'],
                        'person_name': row['person_name'],
                        'confidence': row['confidence'],
                        'distance': row['distance'],
                        'camera_location': row['camera_location']
                    }
                    events.append(event)
            
            logger.debug(f"Retrieved {len(events)} recent events for {person_name}")
            return events
            
        except Exception as e:
            logger.error(f"Error retrieving recent events for {person_name}: {e}")
            return []
    
    def get_top_detected_people(self, limit: int = 10) -> list:
        """
        Get statistics of people with most detections
        
        Args:
            limit: Maximum number of people to return
            
        Returns:
            List of dictionaries with person statistics
        """
        try:
            query = """
                SELECT 
                    person_name,
                    COUNT(*) as total_detections,
                    AVG(confidence) as avg_confidence,
                    MAX(ts) as last_detection,
                    MIN(ts) as first_detection
                FROM BlacklistEvent
                GROUP BY person_name
                ORDER BY total_detections DESC
                LIMIT ?
            """
            
            results = self.db.execute_query(query, [limit])
            
            stats = []
            if results:
                for row in results:
                    stat = {
                        'person_name': row['person_name'],
                        'total_detections': row['total_detections'],
                        'avg_confidence': round(row['avg_confidence'], 3),
                        'last_detection': row['last_detection'],
                        'first_detection': row['first_detection']
                    }
                    stats.append(stat)
            
            logger.debug(f"Retrieved stats for {len(stats)} people")
            return stats
            
        except Exception as e:
            logger.error(f"Error retrieving top detected people: {e}")
            return []
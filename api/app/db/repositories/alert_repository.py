"""
Alert repository
Handles alert-related database operations
"""

from typing import List, Dict, Any, Optional
from app.db.repositories.base import BaseRepository
from app.core.logging import get_logger

logger = get_logger(__name__)


class AlertRepository(BaseRepository):
    """Repository for alert operations"""
    
    def get_recent_alerts(self, limit: int = 10) -> List[Dict[str, Any]]:
        """Get recent alerts with type information"""
        query = """
        SELECT a.alert_id, a.ts, at.description, a.severity, a.bus_id, a.stop_id
        FROM Alert a
        JOIN AlertType at ON a.alert_type_id = at.alert_type_id
        ORDER BY a.ts DESC
        LIMIT ?
        """
        return self.execute_query(query, (limit,)) or []
    
    def get_alert_by_id(self, alert_id: int) -> Optional[Dict[str, Any]]:
        """Get a specific alert by ID"""
        query = """
        SELECT a.*, at.code, at.description
        FROM Alert a
        JOIN AlertType at ON a.alert_type_id = at.alert_type_id
        WHERE a.alert_id = ?
        """
        results = self.execute_query(query, (alert_id,))
        return results[0] if results else None
    
    def get_alerts_by_type(
        self, 
        alert_type_code: str, 
        limit: int = 10
    ) -> List[Dict[str, Any]]:
        """Get alerts filtered by type"""
        query = """
        SELECT a.*, at.code, at.description
        FROM Alert a
        JOIN AlertType at ON a.alert_type_id = at.alert_type_id
        WHERE at.code = ?
        ORDER BY a.ts DESC
        LIMIT ?
        """
        return self.execute_query(query, (alert_type_code, limit)) or []
    
    def create_alert(self, alert_data: Dict[str, Any]) -> int:
        """Create a new alert with specific data"""
        alert_type_code = alert_data.get("alert_type")
        severity = alert_data.get("severity", 3)
        bus_id = alert_data.get("bus_id")
        stop_id = alert_data.get("stop_id")
        
        # Get alert_type_id
        type_query = "SELECT alert_type_id FROM AlertType WHERE code = ?"
        type_result = self.execute_query(type_query, (alert_type_code,))
        
        if not type_result:
            raise ValueError(f"Unknown alert type: {alert_type_code}")
        
        alert_type_id = type_result[0]["alert_type_id"]
        
        # Insert alert
        alert_query = """
        INSERT INTO Alert (ts, alert_type_id, severity, bus_id, stop_id)
        VALUES (datetime('now'), ?, ?, ?, ?)
        """
        self.execute_query(alert_query, (alert_type_id, severity, bus_id, stop_id))
        
        # Get the inserted alert_id
        last_id_query = "SELECT last_insert_rowid() as alert_id"
        result = self.execute_query(last_id_query)
        alert_id = result[0]["alert_id"] if result else None
        
        # Insert specific event data if provided
        if alert_type_code == "ROBO" and "person_name" in alert_data:
            robbery_query = """
            INSERT INTO RobberyEvent (alert_id, person_name, confidence, camera_location)
            VALUES (?, ?, ?, ?)
            """
            self.execute_query(robbery_query, (
                alert_id,
                alert_data.get("person_name"),
                alert_data.get("confidence", 0.0),
                alert_data.get("camera_location")
            ))
        
        elif alert_type_code == "ARMA" and "weapon_type" in alert_data:
            weapon_query = """
            INSERT INTO WeaponEvent (alert_id, weapon_type, confidence, camera_location)
            VALUES (?, ?, ?, ?)
            """
            self.execute_query(weapon_query, (
                alert_id,
                alert_data.get("weapon_type"),
                alert_data.get("confidence", 0.0),
                alert_data.get("camera_location")
            ))
        
        logger.info(f"Alert created: id={alert_id}, type={alert_type_code}")
        return alert_id
    
    def get_alert_types(self) -> List[Dict[str, Any]]:
        """Get all alert types"""
        return self.get_all("AlertType", order_by="alert_type_id")





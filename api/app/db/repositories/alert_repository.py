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
    
    def create_alert(
        self, 
        alert_type_code: str, 
        severity: int,
        bus_id: Optional[int] = None,
        stop_id: Optional[int] = None
    ) -> bool:
        """Create a new alert"""
        # Get alert type ID
        type_query = "SELECT alert_type_id FROM AlertType WHERE code = ?"
        type_result = self.execute_query(type_query, (alert_type_code,))
        
        if not type_result:
            logger.error(f"Alert type not found: {alert_type_code}")
            return False
        
        alert_type_id = type_result[0]["alert_type_id"]
        
        # Insert alert
        alert_query = """
        INSERT INTO Alert (ts, alert_type_id, severity, bus_id, stop_id)
        VALUES (datetime('now'), ?, ?, ?, ?)
        """
        result = self.execute_query(alert_query, (alert_type_id, severity, bus_id, stop_id))
        
        if result is None:
            logger.info(f"Alert created: type={alert_type_code}, severity={severity}")
            return True
        else:
            logger.error("Failed to create alert")
            return False
    
    def get_alert_types(self) -> List[Dict[str, Any]]:
        """Get all alert types"""
        return self.get_all("AlertType", order_by="alert_type_id")





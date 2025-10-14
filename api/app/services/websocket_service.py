"""
WebSocket Service
Manages WebSocket connections and broadcasts
"""

import json
from typing import Dict, List, Set
from fastapi import WebSocket

from app.core.logging import get_logger

logger = get_logger(__name__)


class WebSocketService:
    """Service for managing WebSocket connections and broadcasts"""
    
    def __init__(self):
        # Connection pools by type
        self.connections: Dict[str, Set[WebSocket]] = {
            "alerts": set(),
            "traffic": set(),
            "stops": set(),
            "blacklist": set(),
            "weapon": set(),
            "general": set()
        }
    
    async def connect(self, websocket: WebSocket, connection_type: str = "general"):
        """
        Add a new WebSocket connection
        
        Args:
            websocket: WebSocket instance
            connection_type: Type of connection (alerts, traffic, stops, general)
        """
        await websocket.accept()
        
        if connection_type not in self.connections:
            connection_type = "general"
        
        self.connections[connection_type].add(websocket)
        logger.info(f"WebSocket connected: type={connection_type}, total={len(self.connections[connection_type])}")
    
    def disconnect(self, websocket: WebSocket, connection_type: str = "general"):
        """
        Remove a WebSocket connection
        
        Args:
            websocket: WebSocket instance
            connection_type: Type of connection
        """
        if connection_type in self.connections:
            self.connections[connection_type].discard(websocket)
            logger.info(f"WebSocket disconnected: type={connection_type}, remaining={len(self.connections[connection_type])}")
    
    async def broadcast(self, message: Dict, connection_type: str = "general"):
        """
        Broadcast a message to all connections of a specific type
        
        Args:
            message: Message to broadcast
            connection_type: Type of connections to broadcast to
        """
        if connection_type not in self.connections:
            logger.warning(f"Invalid connection type: {connection_type}")
            return
        
        connections = self.connections[connection_type].copy()
        disconnected = []
        sent_count = 0
        
        for connection in connections:
            try:
                await connection.send_json(message)
                sent_count += 1
            except Exception as e:
                logger.error(f"Broadcast error: {e}")
                disconnected.append(connection)
        
        # Remove disconnected connections
        for connection in disconnected:
            self.disconnect(connection, connection_type)
        
        logger.debug(f"Broadcast complete: type={connection_type}, sent={sent_count}")
    
    async def emit_alert(self, alert_data: Dict):
        """Emit an alert to alert connections"""
        await self.broadcast(alert_data, "alerts")
    
    async def emit_traffic_update(self, traffic_data: Dict):
        """Emit traffic update to traffic connections"""
        await self.broadcast(traffic_data, "traffic")
    
    async def emit_stop_update(self, stop_data: Dict):
        """Emit stop update to stop connections"""
        await self.broadcast(stop_data, "stops")
    
    async def emit_blacklist_event(self, blacklist_data: Dict):
        """Emit blacklist event to blacklist connections"""
        await self.broadcast(blacklist_data, "blacklist")
    
    def get_connection_count(self, connection_type: str = None) -> int:
        """Get number of active connections"""
        if connection_type:
            return len(self.connections.get(connection_type, set()))
        return sum(len(conns) for conns in self.connections.values())
    
    def get_stats(self) -> Dict:
        """Get WebSocket statistics"""
        return {
            "total_connections": self.get_connection_count(),
            "connections_by_type": {
                conn_type: len(conns) 
                for conn_type, conns in self.connections.items()
            }
        }





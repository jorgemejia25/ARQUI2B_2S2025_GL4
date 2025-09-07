"""
Gestor de WebSockets para emitir datos en tiempo real
"""

import json
import logging
from typing import List, Dict, Any
from fastapi import WebSocket, WebSocketDisconnect

logger = logging.getLogger(__name__)

class WebSocketManager:
    def __init__(self):
        self.active_connections: List[WebSocket] = []
        self.connection_types: Dict[WebSocket, str] = {}  # Tipo de conexión (stops, traffic, etc.)
    
    async def connect(self, websocket: WebSocket, connection_type: str = "general"):
        """Conectar un nuevo cliente WebSocket"""
        await websocket.accept()
        self.active_connections.append(websocket)
        self.connection_types[websocket] = connection_type
        logger.info(f"Nueva conexión WebSocket establecida: {connection_type}")
        
        # Enviar mensaje de bienvenida
        await self.send_personal_message({
            "type": "connection_established",
            "connection_type": connection_type,
            "message": "Conexión WebSocket establecida"
        }, websocket)
    
    def disconnect(self, websocket: WebSocket):
        """Desconectar un cliente WebSocket"""
        if websocket in self.active_connections:
            connection_type = self.connection_types.get(websocket, "unknown")
            self.active_connections.remove(websocket)
            if websocket in self.connection_types:
                del self.connection_types[websocket]
            logger.info(f"Conexión WebSocket cerrada: {connection_type}")
    
    async def send_personal_message(self, message: Dict[str, Any], websocket: WebSocket):
        """Enviar mensaje a un cliente específico"""
        try:
            await websocket.send_text(json.dumps(message, ensure_ascii=False))
        except Exception as e:
            logger.error(f"Error enviando mensaje personal: {e}")
            self.disconnect(websocket)
    
    async def broadcast_to_type(self, message: Dict[str, Any], connection_type: str):
        """Enviar mensaje a todos los clientes de un tipo específico"""
        disconnected = []
        sent_count = 0
        
        logger.info(f"Broadcasting a tipo '{connection_type}': {len([w for w in self.active_connections if self.connection_types.get(w) == connection_type])} conexiones")
        
        for websocket in self.active_connections:
            if self.connection_types.get(websocket) == connection_type:
                try:
                    await websocket.send_text(json.dumps(message, ensure_ascii=False))
                    sent_count += 1
                    logger.info(f"Mensaje enviado a cliente {connection_type} #{sent_count}")
                except Exception as e:
                    logger.error(f"Error enviando broadcast: {e}")
                    disconnected.append(websocket)
        
        logger.info(f"Total de mensajes enviados a tipo '{connection_type}': {sent_count}")
        
        # Limpiar conexiones desconectadas
        for websocket in disconnected:
            self.disconnect(websocket)
    
    async def broadcast_to_all(self, message: Dict[str, Any]):
        """Enviar mensaje a todos los clientes conectados"""
        disconnected = []
        sent_count = 0
        
        logger.info(f"Broadcasting general a {len(self.active_connections)} conexiones totales")
        
        for websocket in self.active_connections:
            try:
                await websocket.send_text(json.dumps(message, ensure_ascii=False))
                sent_count += 1
                connection_type = self.connection_types.get(websocket, "unknown")
                logger.info(f"Mensaje enviado a cliente {connection_type} #{sent_count}")
            except Exception as e:
                logger.error(f"Error enviando broadcast general: {e}")
                disconnected.append(websocket)
        
        logger.info(f"Total de mensajes enviados en broadcast general: {sent_count}")
        
        # Limpiar conexiones desconectadas
        for websocket in disconnected:
            self.disconnect(websocket)
    
    async def emit_stop_update(self, stop_data: Dict[str, Any]):
        """Emitir actualización de parada"""
        message = {
            "type": "stop_update",
            "timestamp": stop_data.get("timestamp"),
            "data": stop_data
        }
        logger.info("=== EMITIENDO ACTUALIZACIÓN DE PARADA ===")
        logger.info(f"Datos: {json.dumps(stop_data, ensure_ascii=False)}")
        await self.broadcast_to_type(message, "stops")
        logger.info(f"Actualización de parada emitida: {stop_data.get('stop_id')}")
        logger.info("=== FINALIZADA EMISIÓN DE PARADA ===")
    
    async def emit_traffic_update(self, traffic_data: Dict[str, Any]):
        """Emitir actualización de semáforo"""
        message = {
            "type": "traffic_update",
            "timestamp": traffic_data.get("timestamp"),
            "data": traffic_data
        }
        logger.info("=== EMITIENDO ACTUALIZACIÓN DE SEMÁFORO ===")
        logger.info(f"Datos: {json.dumps(traffic_data, ensure_ascii=False)}")
        await self.broadcast_to_type(message, "traffic")
        logger.info(f"Actualización de semáforo emitida: {traffic_data.get('signal_id')}")
        logger.info("=== FINALIZADA EMISIÓN DE SEMÁFORO ===")
    
    async def emit_alert(self, alert_data: Dict[str, Any]):
        """Emitir alerta general"""
        message = {
            "type": "alert",
            "timestamp": alert_data.get("timestamp"),
            "data": alert_data
        }
        logger.info("=== EMITIENDO ALERTA GENERAL ===")
        logger.info(f"Datos: {json.dumps(alert_data, ensure_ascii=False)}")
        await self.broadcast_to_type(message, "alerts")
        logger.info(f"Alerta emitida: {alert_data.get('alert_type')}")
        logger.info("=== FINALIZADA EMISIÓN DE ALERTA ===")
    
    def get_connection_count(self) -> Dict[str, int]:
        """Obtener conteo de conexiones por tipo"""
        counts = {}
        for connection_type in self.connection_types.values():
            counts[connection_type] = counts.get(connection_type, 0) + 1
        return counts
    
    def get_total_connections(self) -> int:
        """Obtener total de conexiones activas"""
        return len(self.active_connections)

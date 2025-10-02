"""
WebSocket endpoints
"""

from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Depends

from app.api.dependencies import get_websocket_service
from app.services.websocket_service import WebSocketService
from app.core.logging import get_logger

logger = get_logger(__name__)

router = APIRouter()


@router.websocket("/ws/alerts")
async def websocket_alerts(
    websocket: WebSocket,
    ws_service: WebSocketService = Depends(get_websocket_service)
):
    """WebSocket endpoint for alerts"""
    await ws_service.connect(websocket, "alerts")
    
    try:
        while True:
            # Keep connection alive and listen for messages
            data = await websocket.receive_text()
            logger.debug(f"Received from client: {data}")
    except WebSocketDisconnect:
        ws_service.disconnect(websocket, "alerts")
        logger.info("Alert WebSocket disconnected")


@router.websocket("/ws/traffic")
async def websocket_traffic(
    websocket: WebSocket,
    ws_service: WebSocketService = Depends(get_websocket_service)
):
    """WebSocket endpoint for traffic updates"""
    await ws_service.connect(websocket, "traffic")
    
    try:
        while True:
            data = await websocket.receive_text()
            logger.debug(f"Received from client: {data}")
    except WebSocketDisconnect:
        ws_service.disconnect(websocket, "traffic")
        logger.info("Traffic WebSocket disconnected")


@router.websocket("/ws/stops")
async def websocket_stops(
    websocket: WebSocket,
    ws_service: WebSocketService = Depends(get_websocket_service)
):
    """WebSocket endpoint for stop updates"""
    await ws_service.connect(websocket, "stops")
    
    try:
        while True:
            data = await websocket.receive_text()
            logger.debug(f"Received from client: {data}")
    except WebSocketDisconnect:
        ws_service.disconnect(websocket, "stops")
        logger.info("Stop WebSocket disconnected")





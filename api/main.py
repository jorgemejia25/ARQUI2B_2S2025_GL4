"""
API arqui2
Archivo principal que orquesta la aplicación
"""

import logging
import asyncio
from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware

from config import *
from mqtt_handler import MQTTHandler
from websocket_manager import WebSocketManager
from routes import router

# Configurar logging
logging.basicConfig(
    level=getattr(logging, LOG_LEVEL),
    format=LOG_FORMAT
)
logger = logging.getLogger(__name__)

# Crear aplicación FastAPI
app = FastAPI(
    title="API IoT - Puente MQTT",
    version="1.0.0",
    description="API para recibir datos MQTT y actuar como puente"
)

# Configurar CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=CORS_ORIGINS,
    allow_credentials=CORS_CREDENTIALS,
    allow_methods=CORS_METHODS,
    allow_headers=CORS_HEADERS,
)

# Crear instancia del gestor WebSocket
websocket_manager = WebSocketManager()

# Crear instancia del manejador MQTT
mqtt_handler = MQTTHandler(MQTT_BROKER, MQTT_PORT, MQTT_TOPICS, websocket_manager)

# Incluir rutas
app.include_router(router, prefix="/api/v1")

# Endpoints WebSocket
@app.websocket("/ws/stops")
async def websocket_stops(websocket: WebSocket):
    """WebSocket para actualizaciones de paradas"""
    await websocket_manager.connect(websocket, "stops")
    try:
        while True:
            # Mantener la conexión activa
            await websocket.receive_text()
    except WebSocketDisconnect:
        websocket_manager.disconnect(websocket)

@app.websocket("/ws/traffic")
async def websocket_traffic(websocket: WebSocket):
    """WebSocket para actualizaciones de semáforos"""
    await websocket_manager.connect(websocket, "traffic")
    try:
        while True:
            # Mantener la conexión activa
            await websocket.receive_text()
    except WebSocketDisconnect:
        websocket_manager.disconnect(websocket)

@app.websocket("/ws/alerts")
async def websocket_alerts(websocket: WebSocket):
    """WebSocket para alertas generales"""
    await websocket_manager.connect(websocket, "alerts")
    try:
        while True:
            # Mantener la conexión activa
            await websocket.receive_text()
    except WebSocketDisconnect:
        websocket_manager.disconnect(websocket)

@app.on_event("startup")
async def startup_event():
    """Inicializar conexión MQTT al arrancar la aplicación"""
    try:
        # Conectar al broker MQTT
        success = mqtt_handler.connect()
        if success:
            logger.info("API iniciado y conectado a MQTT broker")
        else:
            logger.error("Error conectando a MQTT broker")
            
    except Exception as e:
        logger.error(f"Error en el evento de inicio: {e}")

@app.on_event("shutdown")
async def shutdown_event():
    """Cerrar conexión MQTT al detener la aplicación"""
    try:
        mqtt_handler.disconnect()
        logger.info("API cerrado y conexión MQTT cerrada")
    except Exception as e:
        logger.error(f"Error en el evento de cierre: {e}")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        app, 
        host=SERVER_HOST, 
        port=SERVER_PORT,
        log_level=LOG_LEVEL.lower()
    )

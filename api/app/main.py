"""
Main application entry point
Initializes and configures the FastAPI application
"""

from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.core.config import settings
from app.core.logging import setup_logging, get_logger
from app.api.endpoints import health, alerts, websockets, dashboard
from app.api.dependencies import get_mqtt_service, get_websocket_service

# Setup logging
setup_logging()
logger = get_logger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Application lifespan manager
    Handles startup and shutdown events
    """
    # Startup
    logger.info(f"Starting {settings.APP_NAME} v{settings.APP_VERSION}")
    
    try:
        # Initialize WebSocket service
        websocket_service = get_websocket_service()
        logger.info("WebSocket service initialized")
        
        # Initialize and connect MQTT service
        mqtt_service = get_mqtt_service()
        mqtt_service.websocket_manager = websocket_service
        
        success = mqtt_service.connect()
        if success:
            logger.info("MQTT service connected successfully")
        else:
            logger.error("Failed to connect to MQTT broker")
    
    except Exception as e:
        logger.error(f"Startup error: {e}")
    
    yield
    
    # Shutdown
    logger.info("Shutting down application...")
    
    try:
        mqtt_service = get_mqtt_service()
        mqtt_service.disconnect()
        logger.info("MQTT service disconnected")
    except Exception as e:
        logger.error(f"Shutdown error: {e}")
    
    logger.info("Application shutdown complete")


# Create FastAPI application
app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    lifespan=lifespan
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=settings.CORS_CREDENTIALS,
    allow_methods=settings.CORS_METHODS,
    allow_headers=settings.CORS_HEADERS
)

# Include routers
app.include_router(health.router)  # Health endpoints at root
app.include_router(alerts.router, prefix=settings.API_V1_PREFIX)
app.include_router(dashboard.router, prefix=settings.API_V1_PREFIX)
app.include_router(websockets.router)


@app.get("/")
async def root():
    """Root endpoint"""
    return {
        "app_name": settings.APP_NAME,
        "version": settings.APP_VERSION,
        "docs_url": "/docs",
        "health_url": f"{settings.API_V1_PREFIX}/health"
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "app.main:app",
        host=settings.SERVER_HOST,
        port=settings.SERVER_PORT,
        reload=settings.DEBUG
    )


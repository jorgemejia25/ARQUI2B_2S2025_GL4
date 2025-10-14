"""
Plate Events Endpoints
API endpoints for vehicle plate event management
"""

from typing import Optional
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException
from fastapi.responses import JSONResponse

from app.core.logging import get_logger
from app.db.connection import DatabaseConnection
from app.db.repositories.plate_repository import PlateRepository
from app.schemas.plate_schemas import (
    PlateEventCreate,
    PlateEventResponse,
    PlateEventsResponse
)
from app.services.websocket_service import WebSocketService
from app.api.dependencies import get_websocket_service

logger = get_logger(__name__)

router = APIRouter()


def get_plate_repository() -> PlateRepository:
    """Dependency to get plate repository"""
    with DatabaseConnection() as db:
        return PlateRepository(db)


@router.post("/plate-events", status_code=201, response_model=PlateEventResponse)
async def create_plate_event(
    event: PlateEventCreate,
    repository: PlateRepository = Depends(get_plate_repository),
    websocket_service: WebSocketService = Depends(get_websocket_service)
):
    """
    Create a new vehicle plate detection event.
    
    Receives data from the plate detection AI module, stores it in the database,
    and broadcasts via WebSocket.
    """
    try:
        # Prepare data for repository
        event_data = {
            "plate_text": event.plate_text,
            "confidence": event.confidence,
            "camera_location": event.camera_location,
            "timestamp": datetime.now(),
            "image_base64": event.image_base64
        }

        event_id = repository.save_plate_event(event_data)

        if event_id is None:
            raise HTTPException(status_code=500, detail="Failed to save plate event")

        event_response = PlateEventResponse(
            plate_event_id=event_id,
            ts=event_data["timestamp"],
            plate_text=event.plate_text,
            confidence=event.confidence,
            camera_location=event.camera_location,
            image_base64=event.image_base64
        )

        # Broadcast through WebSocket
        websocket_data = {
            "type": "plate_event",
            "timestamp": datetime.now().timestamp(),
            "data": {
                "plate_event_id": event_id,
                "plate_text": event.plate_text,
                "confidence": event.confidence,
                "camera_location": event.camera_location
            }
        }

        await websocket_service.broadcast(websocket_data, "plates")
        logger.info(f"Plate event broadcasted: {event.plate_text}")

        return event_response

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error creating plate event: {e}")
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")


@router.get("/plate-events", response_model=PlateEventsResponse)
async def get_plate_events(
    limit: int = 50,
    offset: int = 0,
    plate: Optional[str] = None,
    repository: PlateRepository = Depends(get_plate_repository)
):
    """Get paginated list of plate events."""
    try:
        if limit < 1 or limit > 100:
            raise HTTPException(status_code=400, detail="Limit must be between 1 and 100")
        if offset < 0:
            raise HTTPException(status_code=400, detail="Offset must be non-negative")

        events = repository.get_plate_events(limit, offset, plate)
        total = repository.get_total_count(plate)

        event_responses = [
            PlateEventResponse(
                plate_event_id=e["plate_event_id"],
                ts=e["ts"],
                plate_text=e["plate_text"],
                confidence=e["confidence"],
                camera_location=e["camera_location"],
                image_base64=e.get("image_base64")
            )
            for e in events
        ]

        logger.info(f"Retrieved {len(event_responses)} plate events (total: {total})")

        return PlateEventsResponse(
            events=event_responses,
            total=total,
            limit=limit,
            offset=offset
        )

    except Exception as e:
        logger.error(f"Error retrieving plate events: {e}")
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")

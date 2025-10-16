"""
Blacklist Events Endpoints
API endpoints for blacklist event management
"""

from typing import Optional
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException
from fastapi.responses import JSONResponse

from app.core.logging import get_logger
from app.db.connection import DatabaseConnection
from app.db.repositories.blacklist_repository import BlacklistRepository
from app.schemas.blacklist_schemas import (
    BlacklistEventCreate, 
    BlacklistEventResponse, 
    BlacklistEventsResponse
)
from app.services.websocket_service import WebSocketService
from app.api.dependencies import get_websocket_service

logger = get_logger(__name__)

router = APIRouter()


def get_blacklist_repository() -> BlacklistRepository:
    """Dependency to get blacklist repository"""
    with DatabaseConnection() as db:
        return BlacklistRepository(db)


@router.post("/blacklist-events", status_code=201, response_model=BlacklistEventResponse)
async def create_blacklist_event(
    event: BlacklistEventCreate,
    repository: BlacklistRepository = Depends(get_blacklist_repository),
    websocket_service: WebSocketService = Depends(get_websocket_service)
):
    """
    Create a new blacklist event
    
    This endpoint receives events from the AI face recognition module
    and stores them in the database, then broadcasts via WebSocket
    """
    try:
        # Convert Pydantic model to dict for repository
        event_data = {
            'person_name': event.person_name,
            'confidence': event.confidence,
            'distance': event.distance,
            'camera_location': event.camera_location
        }
        
        # Save to database
        event_id = repository.save_blacklist_event(event_data)
        
        if event_id is None:
            raise HTTPException(
                status_code=500, 
                detail="Failed to save blacklist event"
            )
        
        # Create alert for robbery detection
        alert_data = {
            "alert_type": "ROBO",
            "severity": 4,
            "person_name": event.person_name,
            "confidence": event.confidence,
            "camera_location": event.camera_location
        }
        alert_id = alert_repo.create_alert(alert_data)
        
        # Prepare response data directly from input
        event_response = BlacklistEventResponse(
            blacklist_event_id=event_id,
            ts=datetime.now(),
            person_name=event.person_name,
            confidence=event.confidence,
            distance=event.distance,
            camera_location=event.camera_location
        )
        
        # Broadcast via WebSocket to blacklist connections
        websocket_data = {
            "type": "blacklist_event",
            "timestamp": datetime.now().timestamp(),
            "data": {
                "blacklist_event_id": event_id,
                "person_name": event.person_name,
                "confidence": event.confidence,
                "distance": event.distance,
                "camera_location": event.camera_location
            }
        }
        
        await websocket_service.broadcast(websocket_data, "blacklist")
        logger.info(f"Blacklist event broadcasted via WebSocket: {event.person_name}")
        
        return event_response
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error creating blacklist event: {e}")
        raise HTTPException(
            status_code=500, 
            detail=f"Internal server error: {str(e)}"
        )


@router.get("/blacklist-events", response_model=BlacklistEventsResponse)
async def get_blacklist_events(
    limit: int = 50,
    offset: int = 0,
    person: Optional[str] = None,
    repository: BlacklistRepository = Depends(get_blacklist_repository)
):
    """
    Get paginated blacklist events with optional person filter
    
    Args:
        limit: Maximum number of events to return (default: 50)
        offset: Number of events to skip (default: 0)
        person: Optional filter by person name (partial match)
    
    Returns:
        Paginated list of blacklist events
    """
    try:
        # Validate parameters
        if limit < 1 or limit > 100:
            raise HTTPException(
                status_code=400,
                detail="Limit must be between 1 and 100"
            )
        
        if offset < 0:
            raise HTTPException(
                status_code=400,
                detail="Offset must be non-negative"
            )
        
        # Get events and total count
        events = repository.get_blacklist_events(limit, offset, person)
        total = repository.get_total_count(person)
        
        # Convert to response models
        event_responses = []
        for event in events:
            event_response = BlacklistEventResponse(
                blacklist_event_id=event['blacklist_event_id'],
                ts=event['ts'],
                person_name=event['person_name'],
                confidence=event['confidence'],
                distance=event['distance'],
                camera_location=event['camera_location']
            )
            event_responses.append(event_response)
        
        logger.info(f"Retrieved {len(event_responses)} blacklist events (total: {total})")
        
        return BlacklistEventsResponse(
            events=event_responses,
            total=total,
            limit=limit,
            offset=offset
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error retrieving blacklist events: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Internal server error: {str(e)}"
        )


@router.get("/blacklist-events/stats/top-detections")
async def get_top_detections(
    limit: int = 10,
    repository: BlacklistRepository = Depends(get_blacklist_repository)
):
    """
    Get statistics of people with most detections in blacklist
    
    Args:
        limit: Maximum number of people to return (default: 10)
    
    Returns:
        List of people ordered by detection count with their statistics
    """
    try:
        if limit < 1 or limit > 50:
            raise HTTPException(
                status_code=400,
                detail="Limit must be between 1 and 50"
            )
        
        stats = repository.get_top_detected_people(limit)
        
        logger.info(f"Retrieved top {len(stats)} detected people stats")
        
        return {
            "stats": stats,
            "total_people": len(stats)
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error retrieving top detections: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Internal server error: {str(e)}"
        )


@router.get("/blacklist-events/person/{person_name}")
async def get_events_by_person(
    person_name: str,
    limit: int = 10,
    repository: BlacklistRepository = Depends(get_blacklist_repository)
):
    """
    Get recent events for a specific person
    
    Args:
        person_name: Name of the person to filter by
        limit: Maximum number of events to return (default: 10)
    
    Returns:
        List of recent events for the person
    """
    try:
        if limit < 1 or limit > 50:
            raise HTTPException(
                status_code=400,
                detail="Limit must be between 1 and 50"
            )
        
        events = repository.get_recent_events_by_person(person_name, limit)
        
        # Convert to response models
        event_responses = []
        for event in events:
            event_response = BlacklistEventResponse(
                blacklist_event_id=event['blacklist_event_id'],
                ts=event['ts'],
                person_name=event['person_name'],
                confidence=event['confidence'],
                distance=event['distance'],
                camera_location=event['camera_location']
            )
            event_responses.append(event_response)
        
        logger.info(f"Retrieved {len(event_responses)} events for person: {person_name}")
        
        return {
            "person_name": person_name,
            "events": event_responses,
            "count": len(event_responses)
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error retrieving events for person {person_name}: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Internal server error: {str(e)}"
        )

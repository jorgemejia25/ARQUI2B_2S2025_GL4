"""
Weapon Detection Endpoints
API endpoints for weapon detection event management
"""

from typing import Optional
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException
from fastapi.responses import JSONResponse

from app.core.logging import get_logger
from app.db.connection import DatabaseConnection
from app.db.repositories.weapon_repository import WeaponRepository
from app.schemas.weapon_schemas import (
    WeaponDetectionCreate,
    WeaponDetectionResponse,
    WeaponDetectionsResponse,
    WeaponCountsResponse,
    TopWeaponsResponse,
    TopWeaponItem
)
from app.services.websocket_service import WebSocketService
from app.api.dependencies import get_websocket_service

logger = get_logger(__name__)

router = APIRouter()


def get_weapon_repository() -> WeaponRepository:
    """Dependency to get weapon repository"""
    with DatabaseConnection() as db:
        return WeaponRepository(db)


@router.post("/weapon-detections", status_code=201, response_model=WeaponDetectionResponse)
async def create_weapon_detection(
    event: WeaponDetectionCreate,
    repository: WeaponRepository = Depends(get_weapon_repository),
    websocket_service: WebSocketService = Depends(get_websocket_service)
):
    """
    Create a new weapon detection event

    This endpoint receives events from the AI weapon detection module
    and stores them in the database, then broadcasts via WebSocket
    """
    try:
        # Convert Pydantic model to dict for repository
        event_data = {
            'name': event.name,
            'distance': event.distance,
            'camera_location': event.camera_location
        }

        # Save to database
        event_id = repository.save_weapon_detection(event_data)

        if event_id is None:
            raise HTTPException(
                status_code=500,
                detail="Failed to save weapon detection"
            )
        
        # Create alert for weapon detection
        alert_data = {
            "alert_type": "ARMA",
            "severity": 4,
            "weapon_type": event.name,
            "confidence": 0.8,  # Default confidence for weapon detection
            "camera_location": event.camera_location
        }
        alert_id = alert_repo.create_alert(alert_data)

        # Prepare response data directly from input
        event_response = WeaponDetectionResponse(
            id=event_id,
            ts=datetime.now(),
            name=event.name,
            distance=event.distance,
            camera_location=event.camera_location
        )

        # Broadcast via WebSocket to weapon connections
        websocket_data = {
            "type": "weapon_detection",
            "timestamp": datetime.now().timestamp(),
            "data": {
                "id": event_id,
                "name": event.name,
                "distance": event.distance,
                "camera_location": event.camera_location
            }
        }

        await websocket_service.broadcast(websocket_data, "weapon")
        logger.info(f"Weapon detection broadcasted via WebSocket: {event.name}")

        return event_response

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error creating weapon detection: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Internal server error: {str(e)}"
        )


@router.get("/weapon-detections", response_model=WeaponDetectionsResponse)
async def get_weapon_detections(
    limit: int = 50,
    offset: int = 0,
    weapon: Optional[str] = None,
    repository: WeaponRepository = Depends(get_weapon_repository)
):
    """
    Get paginated weapon detections with optional weapon filter

    Args:
        limit: Maximum number of events to return (default: 50)
        offset: Number of events to skip (default: 0)
        weapon: Optional filter by weapon name (partial match)

    Returns:
        Paginated list of weapon detections
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
        events = repository.get_weapon_detections(limit, offset, weapon)
        total = repository.get_total_weapon_detections(weapon)

        # Convert to response models
        event_responses = []
        for event in events:
            event_response = WeaponDetectionResponse(
                id=event['id'],
                ts=event['ts'],
                name=event['name'],
                distance=event['distance'],
                camera_location=event['camera_location']
            )
            event_responses.append(event_response)

        logger.info(f"Retrieved {len(event_responses)} weapon detections (total: {total})")

        return WeaponDetectionsResponse(
            events=event_responses,
            total=total,
            limit=limit,
            offset=offset
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error retrieving weapon detections: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Internal server error: {str(e)}"
        )


@router.get("/weapon-counts", response_model=WeaponCountsResponse)
async def get_weapon_counts(
    limit: int = 10,
    repository: WeaponRepository = Depends(get_weapon_repository)
):
    """
    Get weapon counts ordered by detection count descending

    Args:
        limit: Maximum number of weapons to return (default: 10)

    Returns:
        List of weapons ordered by count
    """
    try:
        if limit < 1 or limit > 50:
            raise HTTPException(
                status_code=400,
                detail="Limit must be between 1 and 50"
            )

        counts = repository.get_weapon_counts(limit)

        logger.info(f"Retrieved {len(counts)} weapon counts")

        return WeaponCountsResponse(
            counts=counts,
            total_weapons=len(counts)
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error retrieving weapon counts: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Internal server error: {str(e)}"
        )


@router.get("/top-weapons", response_model=TopWeaponsResponse)
async def get_top_weapons(
    limit: int = 3,
    repository: WeaponRepository = Depends(get_weapon_repository)
):
    """
    Get top weapons formatted as top1: name-count, top2: name-count, etc.

    Args:
        limit: Maximum number of top weapons to return (default: 3)

    Returns:
        Formatted list of top weapons
    """
    try:
        if limit < 1 or limit > 10:
            raise HTTPException(
                status_code=400,
                detail="Limit must be between 1 and 10"
            )

        counts = repository.get_weapon_counts(limit)

        # Format as structured objects
        top_weapons = []
        for i, count_data in enumerate(counts, 1):
            item = TopWeaponItem(
                top=i,
                name=count_data['name'],
                count=count_data['count']
            )
            top_weapons.append(item)

        logger.info(f"Retrieved top {len(top_weapons)} weapons")

        return TopWeaponsResponse(top_weapons=top_weapons)

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error retrieving top weapons: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Internal server error: {str(e)}"
        )
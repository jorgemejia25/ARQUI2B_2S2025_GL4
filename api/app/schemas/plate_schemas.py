"""
Schemas for plate detection events
"""

from datetime import datetime
from typing import List, Optional
from pydantic import BaseModel


class PlateEventCreate(BaseModel):
    plate_text: str
    confidence: float
    camera_location: str
    image_base64: Optional[str] = None


class PlateEventResponse(BaseModel):
    plate_event_id: int
    ts: datetime
    plate_text: str
    confidence: float
    camera_location: str
    image_base64: Optional[str] = None


class PlateEventsResponse(BaseModel):
    events: List[PlateEventResponse]
    total: int
    limit: int
    offset: int

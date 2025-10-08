"""
Schemas for Blacklist Events
Pydantic models for request/response validation
"""

from pydantic import BaseModel
from datetime import datetime
from typing import Optional


class BlacklistEventCreate(BaseModel):
    """Schema for creating a new blacklist event"""
    person_name: str
    confidence: float
    distance: float
    camera_location: Optional[str] = None


class BlacklistEventResponse(BaseModel):
    """Schema for blacklist event response"""
    blacklist_event_id: int
    ts: datetime
    person_name: str
    confidence: float
    distance: float
    camera_location: Optional[str]
    
    class Config:
        from_attributes = True


class BlacklistEventsResponse(BaseModel):
    """Schema for paginated blacklist events response"""
    events: list[BlacklistEventResponse]
    total: int
    limit: int
    offset: int

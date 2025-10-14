"""
Schemas for Weapon Detection Events
Pydantic models for request/response validation
"""

from pydantic import BaseModel
from datetime import datetime
from typing import Optional


class WeaponDetectionCreate(BaseModel):
    """Schema for creating a new weapon detection event"""
    name: str
    distance: float
    camera_location: Optional[str] = None


class WeaponDetectionResponse(BaseModel):
    """Schema for weapon detection response"""
    id: int
    ts: datetime
    name: str
    distance: float
    camera_location: Optional[str]

    class Config:
        from_attributes = True


class WeaponDetectionsResponse(BaseModel):
    """Schema for paginated weapon detections response"""
    events: list[WeaponDetectionResponse]
    total: int
    limit: int
    offset: int


class WeaponCountResponse(BaseModel):
    """Schema for weapon count response"""
    name: str
    count: int

    class Config:
        from_attributes = True


class WeaponCountsResponse(BaseModel):
    """Schema for weapon counts response"""
    counts: list[WeaponCountResponse]
    total_weapons: int


class TopWeaponItem(BaseModel):
    """Schema for a single top weapon item"""
    top: int
    name: str
    count: int

    class Config:
        from_attributes = True


class TopWeaponsResponse(BaseModel):
    """Schema for top weapons response (structured as array of objects)"""
    top_weapons: list[TopWeaponItem]
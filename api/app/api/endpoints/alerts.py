"""
Alert management endpoints
"""

from fastapi import APIRouter, HTTPException, Depends
from typing import List, Dict

from app.api.dependencies import get_alert_repository
from app.db.repositories.alert_repository import AlertRepository

router = APIRouter()


@router.get("/alerts", tags=["alerts"])
async def get_recent_alerts(
    limit: int = 10,
    alert_repo: AlertRepository = Depends(get_alert_repository)
) -> List[Dict]:
    """Get recent alerts"""
    try:
        alerts = alert_repo.get_recent_alerts(limit=limit)
        return alerts
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error retrieving alerts: {str(e)}")


@router.get("/alerts/{alert_id}", tags=["alerts"])
async def get_alert_by_id(
    alert_id: int,
    alert_repo: AlertRepository = Depends(get_alert_repository)
) -> Dict:
    """Get a specific alert by ID"""
    alert = alert_repo.get_alert_by_id(alert_id)
    
    if not alert:
        raise HTTPException(status_code=404, detail="Alert not found")
    
    return alert


@router.get("/alerts/type/{alert_type}", tags=["alerts"])
async def get_alerts_by_type(
    alert_type: str,
    limit: int = 10,
    alert_repo: AlertRepository = Depends(get_alert_repository)
) -> List[Dict]:
    """Get alerts filtered by type"""
    try:
        alerts = alert_repo.get_alerts_by_type(alert_type, limit=limit)
        return alerts
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error retrieving alerts: {str(e)}")


@router.get("/alert-types", tags=["alerts"])
async def get_alert_types(
    alert_repo: AlertRepository = Depends(get_alert_repository)
) -> List[Dict]:
    """Get all alert types"""
    try:
        types = alert_repo.get_alert_types()
        return types
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error retrieving alert types: {str(e)}")





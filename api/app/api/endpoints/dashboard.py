"""
Dashboard endpoints - Advanced version with filters
Provides comprehensive dashboard data and metrics with advanced filtering
"""

from fastapi import APIRouter, HTTPException, Depends, Query
from typing import List, Dict, Any, Optional
from datetime import datetime, timedelta

from app.api.dependencies import get_dashboard_repository
from app.db.repositories.dashboard_repository import DashboardRepository

router = APIRouter(prefix="/data/dashboard", tags=["dashboard"])


@router.get("/summary")
async def get_dashboard_summary(
    dashboard_repo: DashboardRepository = Depends(get_dashboard_repository)
) -> Dict[str, Any]:
    """
    Get dashboard summary with key metrics
    
    Returns:
        - Total alerts count
        - Recent alerts in last 24 hours
        - Total buses and routes
        - Alerts breakdown by type
        - Last alert information
    """
    try:
        summary = dashboard_repo.get_summary()
        return summary
    except Exception as e:
        raise HTTPException(
            status_code=500, 
            detail=f"Error retrieving dashboard summary: {str(e)}"
        )


@router.get("/metrics")
async def get_dashboard_metrics(
    dashboard_repo: DashboardRepository = Depends(get_dashboard_repository)
) -> Dict[str, Any]:
    """
    Get detailed dashboard metrics
    
    Returns:
        - Average severity
        - Alerts per hour distribution
        - Events breakdown by type
        - Top stops with most alerts
    """
    try:
        metrics = dashboard_repo.get_metrics()
        return metrics
    except Exception as e:
        raise HTTPException(
            status_code=500, 
            detail=f"Error retrieving dashboard metrics: {str(e)}"
        )


@router.get("/charts/gas")
async def get_gas_chart_data(
    hours: int = Query(24, ge=1, le=168, description="Hours to look back (1-168)"),
    dashboard_repo: DashboardRepository = Depends(get_dashboard_repository)
) -> Dict[str, Any]:
    """
    Get gas measurement data for chart visualization
    
    Args:
        hours: Number of hours to look back (default 24, max 168)
    
    Returns:
        List of gas measurements with timestamp and PPM values
    """
    try:
        data = dashboard_repo.get_gas_chart_data(hours=hours)
        return {
            "hours": hours,
            "data": data,
            "count": len(data)
        }
    except Exception as e:
        raise HTTPException(
            status_code=500, 
            detail=f"Error retrieving gas chart data: {str(e)}"
        )


@router.get("/charts/seismic")
async def get_seismic_chart_data(
    hours: int = Query(24, ge=1, le=168, description="Hours to look back (1-168)"),
    dashboard_repo: DashboardRepository = Depends(get_dashboard_repository)
) -> Dict[str, Any]:
    """
    Get seismic measurement data for chart visualization
    
    Args:
        hours: Number of hours to look back (default 24, max 168)
    
    Returns:
        List of seismic measurements with timestamp and intensity values
    """
    try:
        data = dashboard_repo.get_seismic_chart_data(hours=hours)
        return {
            "hours": hours,
            "data": data,
            "count": len(data)
        }
    except Exception as e:
        raise HTTPException(
            status_code=500, 
            detail=f"Error retrieving seismic chart data: {str(e)}"
        )


@router.get("/statistics")
async def get_alert_statistics(
    days: int = Query(7, ge=1, le=30, description="Days to analyze (1-30)"),
    dashboard_repo: DashboardRepository = Depends(get_dashboard_repository)
) -> Dict[str, Any]:
    """
    Get alert statistics for the specified period
    
    Args:
        days: Number of days to analyze (default 7, max 30)
    
    Returns:
        Alert statistics grouped by date and type
    """
    try:
        stats = dashboard_repo.get_alert_statistics(days=days)
        return stats
    except Exception as e:
        raise HTTPException(
            status_code=500, 
            detail=f"Error retrieving alert statistics: {str(e)}"
        )


@router.get("/bus-activity")
async def get_bus_activity(
    dashboard_repo: DashboardRepository = Depends(get_dashboard_repository)
) -> List[Dict[str, Any]]:
    """
    Get recent bus position activity
    
    Returns:
        List of recent bus positions with speed and location info
    """
    try:
        activity = dashboard_repo.get_bus_activity()
        return activity
    except Exception as e:
        raise HTTPException(
            status_code=500, 
            detail=f"Error retrieving bus activity: {str(e)}"
        )


@router.get("/events/{event_type}")
async def get_recent_events_by_type(
    event_type: str,
    limit: int = Query(10, ge=1, le=100, description="Number of events to return"),
    dashboard_repo: DashboardRepository = Depends(get_dashboard_repository)
) -> Dict[str, Any]:
    """
    Get recent events by specific type with details
    
    Args:
        event_type: Type of event (INFRACCION, PANICO, SISMO, GAS)
        limit: Number of events to return (default 10, max 100)
    
    Returns:
        List of events with specific details based on type
    """
    valid_types = ["INFRACCION", "PANICO", "SISMO", "GAS"]
    
    if event_type.upper() not in valid_types:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid event type. Must be one of: {', '.join(valid_types)}"
        )
    
    try:
        events = dashboard_repo.get_recent_events_by_type(
            event_type=event_type.upper(), 
            limit=limit
        )
        return {
            "event_type": event_type.upper(),
            "count": len(events),
            "events": events
        }
    except Exception as e:
        raise HTTPException(
            status_code=500, 
            detail=f"Error retrieving events: {str(e)}"
        )


@router.get("/analytics/advanced")
async def get_advanced_analytics(
    start_date: Optional[str] = Query(None, description="Start date (YYYY-MM-DD)"),
    end_date: Optional[str] = Query(None, description="End date (YYYY-MM-DD)"),
    event_types: Optional[str] = Query(None, description="Comma-separated event types"),
    severity_min: Optional[int] = Query(None, ge=1, le=4, description="Minimum severity (1-4)"),
    severity_max: Optional[int] = Query(None, ge=1, le=4, description="Maximum severity (1-4)"),
    group_by: str = Query("hour", description="Group by: hour, day, week, month"),
    dashboard_repo: DashboardRepository = Depends(get_dashboard_repository)
) -> Dict[str, Any]:
    """
    Get advanced analytics with custom filters
    
    Args:
        start_date: Filter from this date
        end_date: Filter to this date
        event_types: Filter by event types (e.g., "INFRACCION,PANICO")
        severity_min: Minimum severity level
        severity_max: Maximum severity level
        group_by: How to group the data (hour, day, week, month)
    
    Returns:
        Filtered and grouped analytics data
    """
    try:
        # Parse dates
        start = None
        end = None
        if start_date:
            start = datetime.strptime(start_date, "%Y-%m-%d")
        if end_date:
            end = datetime.strptime(end_date, "%Y-%m-%d")
        
        # Parse event types
        types_list = None
        if event_types:
            types_list = [t.strip().upper() for t in event_types.split(",")]
        
        analytics = dashboard_repo.get_advanced_analytics(
            start_date=start,
            end_date=end,
            event_types=types_list,
            severity_min=severity_min,
            severity_max=severity_max,
            group_by=group_by
        )
        return analytics
    except ValueError as e:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid date format. Use YYYY-MM-DD: {str(e)}"
        )
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error retrieving advanced analytics: {str(e)}"
        )


@router.get("/charts/timeline")
async def get_timeline_chart(
    start_date: Optional[str] = Query(None, description="Start date (YYYY-MM-DD)"),
    end_date: Optional[str] = Query(None, description="End date (YYYY-MM-DD)"),
    event_type: Optional[str] = Query(None, description="Filter by event type"),
    granularity: str = Query("hour", description="Time granularity: hour, day, week"),
    dashboard_repo: DashboardRepository = Depends(get_dashboard_repository)
) -> Dict[str, Any]:
    """
    Get timeline chart data with flexible filtering
    
    Args:
        start_date: Start date for timeline
        end_date: End date for timeline
        event_type: Filter by specific event type
        granularity: Time granularity (hour, day, week)
    
    Returns:
        Timeline data grouped by specified granularity
    """
    try:
        # Parse dates
        start = None
        end = None
        if start_date:
            start = datetime.strptime(start_date, "%Y-%m-%d")
        if end_date:
            end = datetime.strptime(end_date, "%Y-%m-%d")
        
        timeline = dashboard_repo.get_timeline_chart(
            start_date=start,
            end_date=end,
            event_type=event_type.upper() if event_type else None,
            granularity=granularity
        )
        return timeline
    except ValueError as e:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid date format. Use YYYY-MM-DD: {str(e)}"
        )
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error retrieving timeline chart: {str(e)}"
        )


@router.get("/charts/comparison")
async def get_comparison_chart(
    metric: str = Query(..., description="Metric to compare: alerts, severity, frequency"),
    start_date: Optional[str] = Query(None, description="Start date (YYYY-MM-DD)"),
    end_date: Optional[str] = Query(None, description="End date (YYYY-MM-DD)"),
    compare_by: str = Query("type", description="Compare by: type, severity, location"),
    dashboard_repo: DashboardRepository = Depends(get_dashboard_repository)
) -> Dict[str, Any]:
    """
    Get comparison chart data for different metrics
    
    Args:
        metric: What to compare (alerts, severity, frequency)
        start_date: Start date for comparison
        end_date: End date for comparison
        compare_by: How to group comparisons (type, severity, location)
    
    Returns:
        Comparison data for visualization
    """
    try:
        # Parse dates
        start = None
        end = None
        if start_date:
            start = datetime.strptime(start_date, "%Y-%m-%d")
        if end_date:
            end = datetime.strptime(end_date, "%Y-%m-%d")
        
        comparison = dashboard_repo.get_comparison_chart(
            metric=metric,
            start_date=start,
            end_date=end,
            compare_by=compare_by
        )
        return comparison
    except ValueError as e:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid date format. Use YYYY-MM-DD: {str(e)}"
        )
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error retrieving comparison chart: {str(e)}"
        )


@router.get("/analytics/gas")
async def get_gas_analytics(
    start_date: Optional[str] = Query(None, description="Start date (YYYY-MM-DD)"),
    end_date: Optional[str] = Query(None, description="End date (YYYY-MM-DD)"),
    dashboard_repo: DashboardRepository = Depends(get_dashboard_repository)
) -> Dict[str, Any]:
    """
    Get gas analytics data with timeline and statistics
    """
    try:
        start = None
        end = None
        if start_date:
            start = datetime.strptime(start_date, "%Y-%m-%d")
        if end_date:
            end = datetime.strptime(end_date, "%Y-%m-%d")
        
        gas_data = dashboard_repo.get_gas_analytics(start_date=start, end_date=end)
        return gas_data
    except ValueError as e:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid date format. Use YYYY-MM-DD: {str(e)}"
        )
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error retrieving gas analytics: {str(e)}"
        )


@router.get("/analytics/seismic")
async def get_seismic_analytics(
    start_date: Optional[str] = Query(None, description="Start date (YYYY-MM-DD)"),
    end_date: Optional[str] = Query(None, description="End date (YYYY-MM-DD)"),
    dashboard_repo: DashboardRepository = Depends(get_dashboard_repository)
) -> Dict[str, Any]:
    """
    Get seismic analytics data with measurements and statistics
    """
    try:
        start = None
        end = None
        if start_date:
            start = datetime.strptime(start_date, "%Y-%m-%d")
        if end_date:
            end = datetime.strptime(end_date, "%Y-%m-%d")
        
        seismic_data = dashboard_repo.get_seismic_analytics(start_date=start, end_date=end)
        return seismic_data
    except ValueError as e:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid date format. Use YYYY-MM-DD: {str(e)}"
        )
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error retrieving seismic analytics: {str(e)}"
        )


@router.get("/system/health")
async def get_system_health_metrics(
    dashboard_repo: DashboardRepository = Depends(get_dashboard_repository)
) -> Dict[str, Any]:
    """
    Get system health and operational metrics
    """
    try:
        health_data = dashboard_repo.get_system_health_metrics()
        return health_data
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error retrieving system health metrics: {str(e)}"
        )


@router.get("/realtime/stream")
async def get_realtime_stream(
    minutes: int = Query(5, ge=1, le=60, description="Minutes of recent data"),
    dashboard_repo: DashboardRepository = Depends(get_dashboard_repository)
) -> Dict[str, Any]:
    """
    Get real-time data stream for live dashboard updates
    
    Args:
        minutes: Number of recent minutes to include
    
    Returns:
        Real-time data for live monitoring
    """
    try:
        stream_data = dashboard_repo.get_realtime_stream(minutes=minutes)
        return stream_data
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error retrieving realtime stream: {str(e)}"
        )


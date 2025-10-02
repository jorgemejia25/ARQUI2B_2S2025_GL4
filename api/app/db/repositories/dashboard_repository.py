"""
Dashboard repository
Handles dashboard-related database operations and analytics
"""

from typing import List, Dict, Any, Optional
from datetime import datetime, timedelta
from app.db.repositories.base import BaseRepository
from app.core.logging import get_logger

logger = get_logger(__name__)


class DashboardRepository(BaseRepository):
    """Repository for dashboard operations and analytics"""
    
    def get_summary(self) -> Dict[str, Any]:
        """Get dashboard summary with key metrics"""
        try:
            # Total alerts count
            total_alerts_query = "SELECT COUNT(*) as count FROM Alert"
            total_alerts_result = self.execute_query(total_alerts_query)
            total_alerts = total_alerts_result[0]["count"] if total_alerts_result else 0
            
            # Recent alerts in last 24 hours
            recent_alerts_query = """
            SELECT COUNT(*) as count FROM Alert 
            WHERE ts >= datetime('now', '-24 hours')
            """
            recent_alerts_result = self.execute_query(recent_alerts_query)
            recent_alerts = recent_alerts_result[0]["count"] if recent_alerts_result else 0
            
            # Total buses and routes
            buses_query = "SELECT COUNT(*) as count FROM Bus"
            routes_query = "SELECT COUNT(*) as count FROM Route"
            buses_result = self.execute_query(buses_query)
            routes_result = self.execute_query(routes_query)
            total_buses = buses_result[0]["count"] if buses_result else 0
            total_routes = routes_result[0]["count"] if routes_result else 0
            
            # Alerts breakdown by type
            alerts_by_type_query = """
            SELECT at.code, at.description, COUNT(a.alert_id) as count
            FROM AlertType at
            LEFT JOIN Alert a ON at.alert_type_id = a.alert_type_id
            GROUP BY at.alert_type_id, at.code, at.description
            ORDER BY count DESC
            """
            alerts_by_type = self.execute_query(alerts_by_type_query) or []
            
            # Last alert information
            last_alert_query = """
            SELECT a.alert_id, a.ts, at.code, at.description, a.severity
            FROM Alert a
            JOIN AlertType at ON a.alert_type_id = at.alert_type_id
            ORDER BY a.ts DESC
            LIMIT 1
            """
            last_alert_result = self.execute_query(last_alert_query)
            last_alert = last_alert_result[0] if last_alert_result else None
            
            return {
                "total_alerts": total_alerts,
                "recent_alerts_24h": recent_alerts,
                "total_buses": total_buses,
                "total_routes": total_routes,
                "alerts_by_type": alerts_by_type,
                "last_alert": last_alert
            }
        except Exception as e:
            logger.error(f"Error getting dashboard summary: {e}")
            raise
    
    def get_metrics(self) -> Dict[str, Any]:
        """Get detailed dashboard metrics"""
        try:
            # Average severity
            avg_severity_query = "SELECT AVG(severity) as avg_severity FROM Alert WHERE severity IS NOT NULL"
            avg_severity_result = self.execute_query(avg_severity_query)
            avg_severity = round(avg_severity_result[0]["avg_severity"], 2) if avg_severity_result and avg_severity_result[0]["avg_severity"] else 0
            
            # Alerts per hour distribution (last 24 hours)
            alerts_per_hour_query = """
            SELECT strftime('%H', ts) as hour, COUNT(*) as count
            FROM Alert
            WHERE ts >= datetime('now', '-24 hours')
            GROUP BY strftime('%H', ts)
            ORDER BY hour
            """
            alerts_per_hour = self.execute_query(alerts_per_hour_query) or []
            
            # Events breakdown by type with details
            events_breakdown_query = """
            SELECT at.code, at.description, 
                   COUNT(a.alert_id) as count,
                   AVG(a.severity) as avg_severity
            FROM AlertType at
            LEFT JOIN Alert a ON at.alert_type_id = a.alert_type_id
            GROUP BY at.alert_type_id, at.code, at.description
            ORDER BY count DESC
            """
            events_breakdown = self.execute_query(events_breakdown_query) or []
            
            # Top stops with most alerts
            top_stops_query = """
            SELECT s.name as stop_name, COUNT(a.alert_id) as alert_count
            FROM Stop s
            LEFT JOIN Alert a ON s.stop_id = a.stop_id
            GROUP BY s.stop_id, s.name
            HAVING alert_count > 0
            ORDER BY alert_count DESC
            LIMIT 5
            """
            top_stops = self.execute_query(top_stops_query) or []
            
            return {
                "average_severity": avg_severity,
                "alerts_per_hour": alerts_per_hour,
                "events_breakdown": events_breakdown,
                "top_stops": top_stops
            }
        except Exception as e:
            logger.error(f"Error getting dashboard metrics: {e}")
            raise
    
    def get_gas_chart_data(self, hours: int = 24) -> List[Dict[str, Any]]:
        """Get gas measurement data for chart visualization"""
        try:
            query = """
            SELECT ts, ppm
            FROM GasMeasurement
            WHERE ts >= datetime('now', '-{} hours')
            ORDER BY ts ASC
            """.format(hours)
            
            return self.execute_query(query) or []
        except Exception as e:
            logger.error(f"Error getting gas chart data: {e}")
            raise
    
    def get_seismic_chart_data(self, hours: int = 24) -> List[Dict[str, Any]]:
        """Get seismic measurement data for chart visualization"""
        try:
            query = """
            SELECT ts, intensity_g
            FROM SeismicMeasurement
            WHERE ts >= datetime('now', '-{} hours')
            ORDER BY ts ASC
            """.format(hours)
            
            return self.execute_query(query) or []
        except Exception as e:
            logger.error(f"Error getting seismic chart data: {e}")
            raise
    
    def get_alert_statistics(self, days: int = 7) -> Dict[str, Any]:
        """Get alert statistics for the specified period"""
        try:
            # Daily alert counts
            daily_stats_query = """
            SELECT DATE(ts) as date, 
                   COUNT(*) as total_alerts,
                   COUNT(CASE WHEN severity >= 3 THEN 1 END) as high_severity,
                   COUNT(CASE WHEN severity < 3 THEN 1 END) as low_severity
            FROM Alert
            WHERE ts >= datetime('now', '-{} days')
            GROUP BY DATE(ts)
            ORDER BY date DESC
            """.format(days)
            
            daily_stats = self.execute_query(daily_stats_query) or []
            
            # Alerts by type for the period
            type_stats_query = """
            SELECT at.code, at.description, COUNT(a.alert_id) as count
            FROM AlertType at
            LEFT JOIN Alert a ON at.alert_type_id = a.alert_type_id 
                AND a.ts >= datetime('now', '-{} days')
            GROUP BY at.alert_type_id, at.code, at.description
            ORDER BY count DESC
            """.format(days)
            
            type_stats = self.execute_query(type_stats_query) or []
            
            return {
                "period_days": days,
                "daily_statistics": daily_stats,
                "type_statistics": type_stats
            }
        except Exception as e:
            logger.error(f"Error getting alert statistics: {e}")
            raise
    
    def get_bus_activity(self) -> List[Dict[str, Any]]:
        """Get recent bus position activity"""
        try:
            query = """
            SELECT bp.position_id, bp.ts, bp.speed_kmh, bp.distance_to_next_stop_m,
                   b.code as bus_code, r.name as route_name
            FROM BusPosition bp
            JOIN Bus b ON bp.bus_id = b.bus_id
            LEFT JOIN Route r ON b.route_id = r.route_id
            ORDER BY bp.ts DESC
            LIMIT 20
            """
            
            return self.execute_query(query) or []
        except Exception as e:
            logger.error(f"Error getting bus activity: {e}")
            raise
    
    def get_recent_events_by_type(self, event_type: str, limit: int = 10) -> List[Dict[str, Any]]:
        """Get recent events by specific type with details"""
        try:
            if event_type == "INFRACCION":
                query = """
                SELECT a.alert_id, a.ts, a.severity, ti.signal_color,
                       b.code as bus_code, s.name as stop_name
                FROM Alert a
                JOIN AlertType at ON a.alert_type_id = at.alert_type_id
                JOIN TrafficInfraction ti ON a.alert_id = ti.alert_id
                LEFT JOIN Bus b ON a.bus_id = b.bus_id
                LEFT JOIN Stop s ON a.stop_id = s.stop_id
                WHERE at.code = ?
                ORDER BY a.ts DESC
                LIMIT ?
                """
            elif event_type == "PANICO":
                query = """
                SELECT a.alert_id, a.ts, a.severity, pe.button_id,
                       b.code as bus_code, s.name as stop_name
                FROM Alert a
                JOIN AlertType at ON a.alert_type_id = at.alert_type_id
                JOIN PanicEvent pe ON a.alert_id = pe.alert_id
                LEFT JOIN Bus b ON a.bus_id = b.bus_id
                LEFT JOIN Stop s ON a.stop_id = s.stop_id
                WHERE at.code = ?
                ORDER BY a.ts DESC
                LIMIT ?
                """
            elif event_type == "SISMO":
                query = """
                SELECT a.alert_id, a.ts, a.severity, se.intensity_g, se.duration_ms,
                       b.code as bus_code, s.name as stop_name
                FROM Alert a
                JOIN AlertType at ON a.alert_type_id = at.alert_type_id
                JOIN SeismicEvent se ON a.alert_id = se.alert_id
                LEFT JOIN Bus b ON a.bus_id = b.bus_id
                LEFT JOIN Stop s ON a.stop_id = s.stop_id
                WHERE at.code = ?
                ORDER BY a.ts DESC
                LIMIT ?
                """
            elif event_type == "GAS":
                query = """
                SELECT a.alert_id, a.ts, a.severity, ge.ppm, ge.threshold_ppm,
                       b.code as bus_code, s.name as stop_name
                FROM Alert a
                JOIN AlertType at ON a.alert_type_id = at.alert_type_id
                JOIN GasEvent ge ON a.alert_id = ge.alert_id
                LEFT JOIN Bus b ON a.bus_id = b.bus_id
                LEFT JOIN Stop s ON a.stop_id = s.stop_id
                WHERE at.code = ?
                ORDER BY a.ts DESC
                LIMIT ?
                """
            else:
                return []
            
            return self.execute_query(query, (event_type, limit)) or []
        except Exception as e:
            logger.error(f"Error getting recent events by type: {e}")
            raise
    
    def get_advanced_analytics(
        self,
        start_date: Optional[datetime] = None,
        end_date: Optional[datetime] = None,
        event_types: Optional[List[str]] = None,
        severity_min: Optional[int] = None,
        severity_max: Optional[int] = None,
        group_by: str = "hour"
    ) -> Dict[str, Any]:
        """Get advanced analytics with custom filters"""
        try:
            # Build WHERE clause
            where_conditions = []
            params = []
            
            if start_date:
                where_conditions.append("a.ts >= ?")
                params.append(start_date.strftime("%Y-%m-%d %H:%M:%S"))
            
            if end_date:
                where_conditions.append("a.ts <= ?")
                # Incluir todo el día final hasta 23:59:59
                end_date_with_time = end_date.replace(hour=23, minute=59, second=59)
                params.append(end_date_with_time.strftime("%Y-%m-%d %H:%M:%S"))
            
            if event_types:
                placeholders = ",".join(["?" for _ in event_types])
                where_conditions.append(f"at.code IN ({placeholders})")
                params.extend(event_types)
            
            if severity_min is not None:
                where_conditions.append("a.severity >= ?")
                params.append(severity_min)
            
            if severity_max is not None:
                where_conditions.append("a.severity <= ?")
                params.append(severity_max)
            
            where_clause = "WHERE " + " AND ".join(where_conditions) if where_conditions else ""
            
            # Build GROUP BY clause
            if group_by == "hour":
                group_clause = "strftime('%Y-%m-%d %H:00:00', a.ts)"
            elif group_by == "day":
                group_clause = "DATE(a.ts)"
            elif group_by == "week":
                group_clause = "strftime('%Y-W%W', a.ts)"
            elif group_by == "month":
                group_clause = "strftime('%Y-%m', a.ts)"
            else:
                group_clause = "strftime('%Y-%m-%d %H:00:00', a.ts)"
            
            # Main analytics query
            analytics_query = f"""
            SELECT {group_clause} as period,
                   COUNT(*) as total_alerts,
                   AVG(a.severity) as avg_severity,
                   COUNT(CASE WHEN a.severity >= 3 THEN 1 END) as high_severity_count,
                   at.code as event_type,
                   COUNT(DISTINCT a.bus_id) as unique_buses,
                   COUNT(DISTINCT a.stop_id) as unique_stops
            FROM Alert a
            JOIN AlertType at ON a.alert_type_id = at.alert_type_id
            {where_clause}
            GROUP BY {group_clause}, at.code
            ORDER BY period DESC, total_alerts DESC
            """
            
            analytics_data = self.execute_query(analytics_query, params) or []
            
            # Summary statistics
            summary_query = f"""
            SELECT COUNT(*) as total_alerts,
                   AVG(a.severity) as avg_severity,
                   MIN(a.severity) as min_severity,
                   MAX(a.severity) as max_severity,
                   COUNT(DISTINCT a.bus_id) as unique_buses,
                   COUNT(DISTINCT a.stop_id) as unique_stops
            FROM Alert a
            JOIN AlertType at ON a.alert_type_id = at.alert_type_id
            {where_clause}
            """
            
            summary_result = self.execute_query(summary_query, params)
            summary = summary_result[0] if summary_result else {}
            
            return {
                "filters": {
                    "start_date": start_date.isoformat() if start_date else None,
                    "end_date": end_date.isoformat() if end_date else None,
                    "event_types": event_types,
                    "severity_range": [severity_min, severity_max],
                    "group_by": group_by
                },
                "summary": summary,
                "analytics": analytics_data
            }
        except Exception as e:
            logger.error(f"Error getting advanced analytics: {e}")
            raise
    
    def get_timeline_chart(
        self,
        start_date: Optional[datetime] = None,
        end_date: Optional[datetime] = None,
        event_type: Optional[str] = None,
        granularity: str = "hour"
    ) -> Dict[str, Any]:
        """Get timeline chart data with flexible filtering"""
        try:
            # Build WHERE clause
            where_conditions = []
            params = []
            
            if start_date:
                where_conditions.append("a.ts >= ?")
                params.append(start_date.strftime("%Y-%m-%d %H:%M:%S"))
            
            if end_date:
                where_conditions.append("a.ts <= ?")
                # Incluir todo el día final hasta 23:59:59
                end_date_with_time = end_date.replace(hour=23, minute=59, second=59)
                params.append(end_date_with_time.strftime("%Y-%m-%d %H:%M:%S"))
            
            if event_type:
                where_conditions.append("at.code = ?")
                params.append(event_type)
            
            where_clause = "WHERE " + " AND ".join(where_conditions) if where_conditions else ""
            
            # Build time grouping
            if granularity == "hour":
                time_group = "strftime('%Y-%m-%d %H:00:00', a.ts)"
            elif granularity == "day":
                time_group = "DATE(a.ts)"
            elif granularity == "week":
                time_group = "strftime('%Y-W%W', a.ts)"
            else:
                time_group = "strftime('%Y-%m-%d %H:00:00', a.ts)"
            
            timeline_query = f"""
            SELECT {time_group} as time_period,
                   COUNT(*) as alert_count,
                   AVG(a.severity) as avg_severity,
                   at.code as event_type
            FROM Alert a
            JOIN AlertType at ON a.alert_type_id = at.alert_type_id
            {where_clause}
            GROUP BY {time_group}, at.code
            ORDER BY time_period ASC
            """
            
            timeline_data = self.execute_query(timeline_query, params) or []
            
            return {
                "granularity": granularity,
                "event_type": event_type,
                "timeline": timeline_data
            }
        except Exception as e:
            logger.error(f"Error getting timeline chart: {e}")
            raise
    
    def get_comparison_chart(
        self,
        metric: str,
        start_date: Optional[datetime] = None,
        end_date: Optional[datetime] = None,
        compare_by: str = "type"
    ) -> Dict[str, Any]:
        """Get comparison chart data for different metrics"""
        try:
            # Build WHERE clause
            where_conditions = []
            params = []
            
            if start_date:
                where_conditions.append("a.ts >= ?")
                params.append(start_date.strftime("%Y-%m-%d %H:%M:%S"))
            
            if end_date:
                where_conditions.append("a.ts <= ?")
                # Incluir todo el día final hasta 23:59:59
                end_date_with_time = end_date.replace(hour=23, minute=59, second=59)
                params.append(end_date_with_time.strftime("%Y-%m-%d %H:%M:%S"))
            
            where_clause = "WHERE " + " AND ".join(where_conditions) if where_conditions else ""
            
            # Build comparison query based on compare_by
            if compare_by == "type":
                group_field = "at.code"
                label_field = "at.description"
            elif compare_by == "severity":
                group_field = "a.severity"
                label_field = "a.severity"
            elif compare_by == "location":
                group_field = "s.name"
                label_field = "s.name"
            else:
                group_field = "at.code"
                label_field = "at.description"
            
            # Build metric calculation
            if metric == "alerts":
                metric_calc = "COUNT(*)"
            elif metric == "severity":
                metric_calc = "AVG(a.severity)"
            elif metric == "frequency":
                metric_calc = "COUNT(*) / (julianday(MAX(a.ts)) - julianday(MIN(a.ts)) + 1)"
            else:
                metric_calc = "COUNT(*)"
            
            comparison_query = f"""
            SELECT {group_field} as category,
                   {label_field} as label,
                   {metric_calc} as value
            FROM Alert a
            JOIN AlertType at ON a.alert_type_id = at.alert_type_id
            LEFT JOIN Stop s ON a.stop_id = s.stop_id
            {where_clause}
            GROUP BY {group_field}
            ORDER BY value DESC
            """
            
            comparison_data = self.execute_query(comparison_query, params) or []
            
            return {
                "metric": metric,
                "compare_by": compare_by,
                "comparison": comparison_data
            }
        except Exception as e:
            logger.error(f"Error getting comparison chart: {e}")
            raise
    
    def get_gas_analytics(self, start_date: Optional[datetime] = None, end_date: Optional[datetime] = None) -> Dict[str, Any]:
        """Get gas analytics data"""
        try:
            where_conditions = []
            params = []
            
            if start_date:
                where_conditions.append("ts >= ?")
                params.append(start_date.strftime("%Y-%m-%d %H:%M:%S"))
            
            if end_date:
                end_date_with_time = end_date.replace(hour=23, minute=59, second=59)
                where_conditions.append("ts <= ?")
                params.append(end_date_with_time.strftime("%Y-%m-%d %H:%M:%S"))
            
            where_clause = "WHERE " + " AND ".join(where_conditions) if where_conditions else ""
            
            # Gas measurements over time
            gas_timeline_query = f"""
            SELECT strftime('%Y-%m-%d %H:00:00', ts) as time_period,
                   COUNT(*) as measurement_count,
                   AVG(ppm) as avg_ppm,
                   MAX(ppm) as max_ppm,
                   MIN(ppm) as min_ppm
            FROM GasMeasurement
            {where_clause}
            GROUP BY strftime('%Y-%m-%d %H:00:00', ts)
            ORDER BY time_period ASC
            """
            
            gas_timeline = self.execute_query(gas_timeline_query, params) or []
            
            # Gas statistics
            gas_stats_query = f"""
            SELECT COUNT(*) as total_measurements,
                   AVG(ppm) as avg_ppm,
                   MAX(ppm) as max_ppm,
                   MIN(ppm) as min_ppm,
                   COUNT(CASE WHEN ppm > 300 THEN 1 END) as high_readings
            FROM GasMeasurement
            {where_clause}
            """
            
            gas_stats_result = self.execute_query(gas_stats_query, params)
            gas_stats = gas_stats_result[0] if gas_stats_result else {}
            
            return {
                "timeline": gas_timeline,
                "statistics": gas_stats,
                "threshold_ppm": 300
            }
        except Exception as e:
            logger.error(f"Error getting gas analytics: {e}")
            raise
    
    def get_seismic_analytics(self, start_date: Optional[datetime] = None, end_date: Optional[datetime] = None) -> Dict[str, Any]:
        """Get seismic analytics data"""
        try:
            where_conditions = []
            params = []
            
            if start_date:
                where_conditions.append("ts >= ?")
                params.append(start_date.strftime("%Y-%m-%d %H:%M:%S"))
            
            if end_date:
                end_date_with_time = end_date.replace(hour=23, minute=59, second=59)
                where_conditions.append("ts <= ?")
                params.append(end_date_with_time.strftime("%Y-%m-%d %H:%M:%S"))
            
            where_clause = "WHERE " + " AND ".join(where_conditions) if where_conditions else ""
            
            # Seismic measurements
            seismic_query = f"""
            SELECT seis_id, ts, intensity_g
            FROM SeismicMeasurement
            {where_clause}
            ORDER BY ts DESC
            """
            
            seismic_data = self.execute_query(seismic_query, params) or []
            
            # Seismic statistics
            seismic_stats_query = f"""
            SELECT COUNT(*) as total_measurements,
                   AVG(intensity_g) as avg_intensity,
                   MAX(intensity_g) as max_intensity,
                   MIN(intensity_g) as min_intensity,
                   COUNT(CASE WHEN intensity_g > 2.0 THEN 1 END) as significant_events
            FROM SeismicMeasurement
            {where_clause}
            """
            
            seismic_stats_result = self.execute_query(seismic_stats_query, params)
            seismic_stats = seismic_stats_result[0] if seismic_stats_result else {}
            
            return {
                "measurements": seismic_data,
                "statistics": seismic_stats,
                "threshold_intensity": 2.0
            }
        except Exception as e:
            logger.error(f"Error getting seismic analytics: {e}")
            raise
    
    def get_system_health_metrics(self) -> Dict[str, Any]:
        """Get system health and operational metrics"""
        try:
            # Bus status
            bus_query = """
            SELECT COUNT(*) as total_buses,
                   COUNT(CASE WHEN bus_id IN (SELECT DISTINCT bus_id FROM Alert WHERE bus_id IS NOT NULL) THEN 1 END) as buses_with_alerts
            FROM Bus
            """
            bus_stats = self.execute_query(bus_query)
            
            # Route coverage
            route_query = """
            SELECT r.name as route_name,
                   COUNT(DISTINCT rs.stop_id) as stops_count,
                   COUNT(DISTINCT b.bus_id) as buses_count
            FROM Route r
            LEFT JOIN RouteStop rs ON r.route_id = rs.route_id
            LEFT JOIN Bus b ON r.route_id = b.route_id
            GROUP BY r.route_id, r.name
            """
            route_coverage = self.execute_query(route_query) or []
            
            # Alert frequency by hour
            hourly_alerts_query = """
            SELECT strftime('%H', ts) as hour,
                   COUNT(*) as alert_count
            FROM Alert
            GROUP BY strftime('%H', ts)
            ORDER BY hour
            """
            hourly_alerts = self.execute_query(hourly_alerts_query) or []
            
            return {
                "bus_statistics": bus_stats[0] if bus_stats else {},
                "route_coverage": route_coverage,
                "hourly_alert_pattern": hourly_alerts
            }
        except Exception as e:
            logger.error(f"Error getting system health metrics: {e}")
            raise

    def get_realtime_stream(self, minutes: int = 5) -> Dict[str, Any]:
        """Get real-time data stream for live dashboard updates"""
        try:
            # Recent alerts
            recent_alerts_query = """
            SELECT a.alert_id, a.ts, at.code, at.description, a.severity,
                   b.code as bus_code, s.name as stop_name
            FROM Alert a
            JOIN AlertType at ON a.alert_type_id = at.alert_type_id
            LEFT JOIN Bus b ON a.bus_id = b.bus_id
            LEFT JOIN Stop s ON a.stop_id = s.stop_id
            WHERE a.ts >= datetime('now', '-{} minutes')
            ORDER BY a.ts DESC
            """.format(minutes)
            
            recent_alerts = self.execute_query(recent_alerts_query) or []
            
            # Recent gas measurements
            recent_gas_query = """
            SELECT ts, ppm
            FROM GasMeasurement
            WHERE ts >= datetime('now', '-{} minutes')
            ORDER BY ts DESC
            LIMIT 10
            """.format(minutes)
            
            recent_gas = self.execute_query(recent_gas_query) or []
            
            # Recent seismic measurements
            recent_seismic_query = """
            SELECT ts, intensity_g
            FROM SeismicMeasurement
            WHERE ts >= datetime('now', '-{} minutes')
            ORDER BY ts DESC
            LIMIT 10
            """.format(minutes)
            
            recent_seismic = self.execute_query(recent_seismic_query) or []
            
            # Recent bus positions
            recent_bus_query = """
            SELECT bp.ts, bp.speed_kmh, b.code as bus_code, r.name as route_name
            FROM BusPosition bp
            JOIN Bus b ON bp.bus_id = b.bus_id
            LEFT JOIN Route r ON b.route_id = r.route_id
            WHERE bp.ts >= datetime('now', '-{} minutes')
            ORDER BY bp.ts DESC
            LIMIT 10
            """.format(minutes)
            
            recent_bus = self.execute_query(recent_bus_query) or []
            
            return {
                "timeframe_minutes": minutes,
                "timestamp": datetime.now().isoformat(),
                "recent_alerts": recent_alerts,
                "recent_gas": recent_gas,
                "recent_seismic": recent_seismic,
                "recent_bus": recent_bus
            }
        except Exception as e:
            logger.error(f"Error getting realtime stream: {e}")
            raise
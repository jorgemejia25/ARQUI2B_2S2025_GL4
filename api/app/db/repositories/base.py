"""
Base repository with common database operations
"""

from typing import Optional, List, Dict, Any
from app.db.connection import DatabaseConnection
from app.core.logging import get_logger

logger = get_logger(__name__)


class BaseRepository:
    """Base repository class with common database operations"""
    
    def __init__(self, db_connection: DatabaseConnection):
        self.db = db_connection
    
    def execute_query(
        self, 
        query: str, 
        params: tuple = ()
    ) -> Optional[List[Dict[str, Any]]]:
        """Execute a database query"""
        return self.db.execute_query(query, params)
    
    def get_by_id(self, table: str, id_column: str, id_value: Any) -> Optional[Dict[str, Any]]:
        """Get a single record by ID"""
        query = f"SELECT * FROM {table} WHERE {id_column} = ?"
        results = self.execute_query(query, (id_value,))
        return results[0] if results else None
    
    def get_all(
        self, 
        table: str, 
        limit: Optional[int] = None,
        order_by: Optional[str] = None
    ) -> List[Dict[str, Any]]:
        """Get all records from a table"""
        query = f"SELECT * FROM {table}"
        
        if order_by:
            query += f" ORDER BY {order_by}"
        
        if limit:
            query += f" LIMIT {limit}"
        
        return self.execute_query(query) or []
    
    def insert(self, table: str, data: Dict[str, Any]) -> bool:
        """Insert a new record"""
        columns = ", ".join(data.keys())
        placeholders = ", ".join(["?" for _ in data])
        query = f"INSERT INTO {table} ({columns}) VALUES ({placeholders})"
        
        result = self.execute_query(query, tuple(data.values()))
        return result is None  # None indicates successful INSERT
    
    def update(
        self, 
        table: str, 
        id_column: str, 
        id_value: Any, 
        data: Dict[str, Any]
    ) -> bool:
        """Update an existing record"""
        set_clause = ", ".join([f"{key} = ?" for key in data.keys()])
        query = f"UPDATE {table} SET {set_clause} WHERE {id_column} = ?"
        
        params = tuple(data.values()) + (id_value,)
        result = self.execute_query(query, params)
        return result is None  # None indicates successful UPDATE
    
    def delete(self, table: str, id_column: str, id_value: Any) -> bool:
        """Delete a record"""
        query = f"DELETE FROM {table} WHERE {id_column} = ?"
        result = self.execute_query(query, (id_value,))
        return result is None  # None indicates successful DELETE





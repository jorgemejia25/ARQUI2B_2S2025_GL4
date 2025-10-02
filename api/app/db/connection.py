"""
Database connection management
Handles SQLite connection lifecycle
"""

import sqlite3
from typing import Optional, List, Dict, Any
from contextlib import contextmanager

from app.core.config import settings
from app.core.logging import get_logger

logger = get_logger(__name__)


class DatabaseConnection:
    """Manages database connection and basic operations"""
    
    def __init__(self, db_path: Optional[str] = None):
        self.db_path = db_path or settings.DATABASE_PATH
        self._connection: Optional[sqlite3.Connection] = None
    
    def connect(self) -> bool:
        """Establish database connection"""
        try:
            self._connection = sqlite3.connect(
                self.db_path,
                check_same_thread=False  # Allow connection across threads for FastAPI
            )
            self._connection.row_factory = sqlite3.Row
            logger.info(f"Connected to database: {self.db_path}")
            return True
        except Exception as e:
            logger.error(f"Database connection error: {e}")
            return False
    
    def disconnect(self) -> None:
        """Close database connection"""
        if self._connection:
            self._connection.close()
            self._connection = None
            logger.info("Database connection closed")
    
    def execute_query(
        self, 
        query: str, 
        params: tuple = ()
    ) -> Optional[List[Dict[str, Any]]]:
        """
        Execute SQL query and return results
        
        Args:
            query: SQL query string
            params: Query parameters tuple
            
        Returns:
            List of dictionaries for SELECT queries, None for INSERT/UPDATE/DELETE
        """
        try:
            if not self._connection:
                self.connect()
            
            cursor = self._connection.cursor()
            cursor.execute(query, params)
            
            if query.strip().upper().startswith('SELECT'):
                results = cursor.fetchall()
                return [dict(row) for row in results]
            else:
                self._connection.commit()
                return None
                
        except Exception as e:
            logger.error(f"Query execution error: {e}")
            if self._connection:
                self._connection.rollback()
            return None
    
    @contextmanager
    def transaction(self):
        """Context manager for database transactions"""
        if not self._connection:
            self.connect()
        
        try:
            yield self._connection
            self._connection.commit()
        except Exception as e:
            self._connection.rollback()
            logger.error(f"Transaction error: {e}")
            raise
    
    def __enter__(self):
        """Context manager entry"""
        self.connect()
        return self
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        """Context manager exit"""
        self.disconnect()





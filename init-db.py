#!/usr/bin/env python3
"""
Script para inicializar la base de datos en el despliegue
"""
import os
import sqlite3
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def init_database():
    """Inicializa la base de datos con el esquema"""
    db_path = os.getenv("DATABASE_PATH", "/app/data/ARQUI_2.db")
    
    # Crear directorio si no existe
    os.makedirs(os.path.dirname(db_path), exist_ok=True)
    
    # Leer el archivo SQL
    sql_file = "/app/SQL/DB_ARQUI2_SQLite.sql"
    if not os.path.exists(sql_file):
        sql_file = "SQL/DB_ARQUI2_SQLite.sql"
    
    if not os.path.exists(sql_file):
        logger.error("No se encontró el archivo SQL para inicializar la BD")
        return False
    
    try:
        # Conectar a la base de datos
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        # Leer y ejecutar el script SQL
        with open(sql_file, 'r', encoding='utf-8') as f:
            sql_script = f.read()
        
        # Ejecutar el script
        cursor.executescript(sql_script)
        conn.commit()
        conn.close()
        
        logger.info(f"Base de datos inicializada correctamente en: {db_path}")
        return True
        
    except Exception as e:
        logger.error(f"Error inicializando la base de datos: {e}")
        return False

if __name__ == "__main__":
    init_database()

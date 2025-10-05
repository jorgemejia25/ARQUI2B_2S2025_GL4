"""
Script para inicializar la base de datos SQLite con el esquema completo
"""

import sqlite3
import os
import logging

logger = logging.getLogger(__name__)

def init_database(db_path: str = "./seguridad_trafico.db"):
    """
    Inicializar la base de datos con el esquema completo
    """
    try:
        # Crear directorio si no existe
        os.makedirs(os.path.dirname(db_path), exist_ok=True)
        
        # Conectar a la base de datos
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        # Leer y ejecutar el esquema SQL
        schema_path = os.path.join(os.path.dirname(__file__), "..", "SQL", "DB_ARQUI2_SQLite.sql")
        
        if os.path.exists(schema_path):
            with open(schema_path, 'r', encoding='utf-8') as f:
                schema_sql = f.read()
            
            # Ejecutar el esquema
            cursor.executescript(schema_sql)
            conn.commit()
            
            logger.info(f"Base de datos inicializada correctamente: {db_path}")
            print(f"✅ Base de datos inicializada: {db_path}")
            
            # Verificar que las tablas se crearon
            cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
            tables = cursor.fetchall()
            print(f"📊 Tablas creadas: {len(tables)}")
            for table in tables:
                print(f"   - {table[0]}")
            
            return True
            
        else:
            logger.error(f"Archivo de esquema no encontrado: {schema_path}")
            print(f"❌ Error: Archivo de esquema no encontrado: {schema_path}")
            return False
            
    except Exception as e:
        logger.error(f"Error inicializando base de datos: {e}")
        print(f"❌ Error inicializando base de datos: {e}")
        return False
        
    finally:
        if conn:
            conn.close()

def verify_database(db_path: str = "./seguridad_trafico.db"):
    """
    Verificar que la base de datos esté correctamente inicializada
    """
    try:
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        # Verificar tablas principales
        required_tables = [
            'Alert', 'AlertType', 'TrafficInfraction', 'PanicEvent', 
            'SeismicEvent', 'GasEvent', 'GasMeasurement', 'SeismicMeasurement',
            'Bus', 'BusPosition', 'Route', 'Stop', 'RouteStop'
        ]
        
        cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
        existing_tables = [row[0] for row in cursor.fetchall()]
        
        missing_tables = [table for table in required_tables if table not in existing_tables]
        
        if missing_tables:
            print(f"❌ Tablas faltantes: {missing_tables}")
            return False
        
        # Verificar tipos de alerta
        cursor.execute("SELECT COUNT(*) FROM AlertType")
        alert_types_count = cursor.fetchone()[0]
        
        if alert_types_count == 0:
            print("❌ No hay tipos de alerta configurados")
            return False
        
        print(f"✅ Base de datos verificada correctamente")
        print(f"📊 Tablas: {len(existing_tables)}")
        print(f"🚨 Tipos de alerta: {alert_types_count}")
        
        return True
        
    except Exception as e:
        print(f"❌ Error verificando base de datos: {e}")
        return False
        
    finally:
        if conn:
            conn.close()

if __name__ == "__main__":
    print("🔧 Inicializando base de datos de Seguridad de Tráfico...")
    
    # Inicializar base de datos
    success = init_database()
    
    if success:
        print("\n🔍 Verificando base de datos...")
        verify_database()
    else:
        print("❌ Error en la inicialización")
"""
Inicializa la base de datos SQLite (ARQUI_2.db) usando el esquema en SQL/DB_ARQUI2_SQLite.sql
Uso: python init_db.py
"""

import sqlite3
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SQL_FILE = ROOT / "SQL" / "DB_ARQUI2_SQLite.sql"
DB_FILE = ROOT / "ARQUI_2.db"


def init_db():
    sql_text = SQL_FILE.read_text(encoding="utf-8")
    with sqlite3.connect(DB_FILE) as conn:
        conn.executescript(sql_text)
    print(f"Base creada/actualizada: {DB_FILE}")


if __name__ == "__main__":
    if not SQL_FILE.exists():
        raise SystemExit(f"No se encontró el archivo SQL: {SQL_FILE}")
    DB_FILE.parent.mkdir(parents=True, exist_ok=True)
    init_db()

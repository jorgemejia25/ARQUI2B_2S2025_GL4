#!/bin/bash
set -e

echo "Inicializando base de datos..."
python init-db.py

echo "Iniciando API..."
uvicorn main:app --host 0.0.0.0 --port ${PORT:-8001}

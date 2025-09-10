#!/bin/bash
set -e

echo "Inicializando base de datos..."
python init-db.py

echo "Iniciando API..."
# Railway asigna el puerto automáticamente, usar 8001 como fallback
PORT=${PORT:-8001}
echo "Usando puerto: $PORT"
uvicorn main:app --host 0.0.0.0 --port $PORT

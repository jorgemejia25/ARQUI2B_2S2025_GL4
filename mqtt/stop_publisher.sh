#!/bin/bash
# Script para detener el publicador MQTT

echo "Deteniendo publicador MQTT..."

# Buscar el proceso
PUBLISHER_PID=$(pgrep -f "arduino_mqtt_publisher.py")

if [ -z "$PUBLISHER_PID" ]; then
    echo "No se encontró el publicador ejecutándose"
    exit 1
fi

echo "Publicador encontrado con PID: $PUBLISHER_PID"

# Detener el proceso
kill $PUBLISHER_PID

# Esperar un poco
sleep 2

# Verificar si se detuvo
if kill -0 $PUBLISHER_PID 2>/dev/null; then
    echo "Forzando detención..."
    kill -9 $PUBLISHER_PID
fi

echo "Publicador detenido"

# Limpiar archivos
rm -f publisher.pid
echo "Archivos de control limpiados"

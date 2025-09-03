#!/bin/bash
# Script para iniciar el publicador MQTT en background

echo "Iniciando publicador MQTT de datos simulados del Arduino..."
cd "$(dirname "$0")"

# Verificar si ya está ejecutándose
if pgrep -f "arduino_mqtt_publisher.py" > /dev/null; then
    echo "El publicador ya está ejecutándose"
    exit 1
fi

# Ejecutar en background
nohup python3 arduino_mqtt_publisher.py > publisher.log 2>&1 &

# Obtener el PID
PUBLISHER_PID=$!
echo "Publicador iniciado con PID: $PUBLISHER_PID"
echo "Logs guardados en: publisher.log"
echo "Para detener: kill $PUBLISHER_PID"
echo "Para ver logs: tail -f publisher.log"

# Guardar PID en archivo
echo $PUBLISHER_PID > publisher.pid
echo "PID guardado en: publisher.pid"

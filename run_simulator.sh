#!/bin/bash

# Script para ejecutar el simulador interactivo de eventos MQTT
# Sistema de Seguridad de Tráfico - Arquitectura de Software 2

echo "Iniciando Simulador Interactivo de Eventos MQTT..."
echo "Asegúrate de que el broker MQTT esté ejecutándose (./start_mosquitto.sh)"
echo ""

# Activar entorno virtual
source venv/bin/activate

# Ejecutar simulador
python interactive_mqtt_simulator.py











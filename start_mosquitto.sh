#!/bin/bash
# Script para iniciar el broker Mosquitto local
# Proyecto de Seguridad de Tráfico - Arquitectura de Software 2

echo "Iniciando broker Mosquitto local..."

# Crear directorio de datos si no existe
mkdir -p mosquitto_data

# Iniciar Mosquitto con configuración personalizada
/opt/homebrew/opt/mosquitto/sbin/mosquitto -c mosquitto_local.conf -v

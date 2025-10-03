#!/usr/bin/env bash
set -euo pipefail

echo "Iniciando broker Mosquitto local..."

# Intentar encontrar el binario en el PATH (Linux)
MOSQUITTO_BIN="$(command -v mosquitto || true)"

if [[ -n "${MOSQUITTO_BIN}" ]]; then
  # Arrancar en primer plano (útil para ver logs). Cambia puertos si necesitas.
  exec "${MOSQUITTO_BIN}" -v -p 1883
else
  # Fallback: rutas típicas de macOS Homebrew (por si corre en Mac)
  if [[ -x "/opt/homebrew/opt/mosquitto/sbin/mosquitto" ]]; then
    exec /opt/homebrew/opt/mosquitto/sbin/mosquitto -v -p 1883
  elif [[ -x "/usr/local/opt/mosquitto/sbin/mosquitto" ]]; then
    exec /usr/local/opt/mosquitto/sbin/mosquitto -v -p 1883
  else
    echo "Mosquitto no encontrado. Instálalo:"
    echo "  Linux: sudo apt-get install -y mosquitto mosquitto-clients"
    echo "  macOS (Homebrew): brew install mosquitto"
    exit 1
  fi
fi
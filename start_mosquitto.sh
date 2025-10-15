#!/usr/bin/env bash
echo "Iniciando broker Mosquitto local..."
MOSQUITTO_BIN="$(command -v mosquitto || true)"

if [[ -n "${MOSQUITTO_BIN}" ]]; then
  echo "Usando Mosquitto en: ${MOSQUITTO_BIN}"
  exec "${MOSQUITTO_BIN}" -c "$(dirname "$0")/mosquitto_local.conf" -v
else
  echo " Mosquitto no encontrado. Instálalo con:"
  echo "  sudo apt install -y mosquitto mosquitto-clients"
  exit 1
fi
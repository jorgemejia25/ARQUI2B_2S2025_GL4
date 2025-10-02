#!/bin/bash
# Script para activar el entorno virtual de Python
# Proyecto de Seguridad de Tráfico - Arquitectura de Software 2

echo "Activando entorno virtual de Python..."
source venv/bin/activate

echo "Entorno virtual activado correctamente."
echo "Para desactivar el entorno, ejecuta: deactivate"
echo ""
echo "Comandos disponibles:"
echo "  - Ejecutar API: python api/main.py"
echo "  - Ejecutar MQTT: python mqtt/main.py"
echo "  - Instalar nuevas dependencias: pip install <paquete>"

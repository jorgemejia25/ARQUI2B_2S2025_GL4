#!/bin/bash

echo "=========================================="
echo "INSTALACIÓN DE DEPENDENCIAS PARA IA MODULES"
echo "=========================================="

# Activar el entorno virtual si existe
if [ -d "venv" ]; then
    echo "Activando entorno virtual..."
    source venv/bin/activate
fi

echo "Instalando face_recognition_models..."
pip install git+https://github.com/ageitgey/face_recognition_models

echo "Instalando dependencias adicionales..."
pip install --upgrade pip
pip install opencv-python
pip install numpy
pip install requests
pip install ultralytics
pip install easyocr

echo "=========================================="
echo "INSTALACIÓN COMPLETADA"
echo "=========================================="
echo "Ahora puedes ejecutar:"
echo "  cd ia_modules"
echo "  python run.py"
echo "=========================================="

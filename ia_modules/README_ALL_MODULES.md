# Sistema de Módulos de IA - Todos los Módulos Simultáneos

Este sistema permite ejecutar **todos los módulos de IA simultáneamente** usando una sola cámara:
- **Reconocimiento Facial** (detección de personas en lista negra)
- **Detección de Placas** (OCR de placas vehiculares)
- **Detección de Armas** (detección de armas blancas con YOLO)

## 🚀 Inicio Rápido

### 1. Instalar Dependencias
```bash
# Desde el directorio raíz del proyecto
./install_dependencies.sh
```

### 2. Ejecutar el Sistema
```bash
cd ia_modules
python run.py
```

## 🔧 Configuración

### Parámetros de Cámara
```bash
python run.py --camera 0 --fps 30 --width 640 --height 480
```

### Parámetros de Reconocimiento Facial
```bash
python run.py --threshold 0.50 --cooldown 8 --detect-every 5
```

### Parámetros de Detección de Armas
```bash
python run.py --yolo-conf 0.25 --yolo-imgsz 416 --yolo-detect-every 3
```

## 📊 Optimizaciones de Rendimiento

El sistema está optimizado para manejar múltiples módulos simultáneamente:

- **Reconocimiento Facial**: Procesa cada 5 frames
- **Detección de Armas**: Procesa cada 3 frames con imagen limitada a 416px
- **Detección de Placas**: Tiene cooldown para evitar saturar la API

## 🎮 Controles

- **ESC**: Salir del sistema
- **S**: Mostrar estado de los módulos
- **D**: Alternar visualización (ON/OFF)

## 🔍 Funcionamiento

1. **Carga Automática**: El sistema carga automáticamente todos los módulos disponibles
2. **Procesamiento Paralelo**: Cada módulo procesa los frames de forma independiente
3. **Visualización Unificada**: Todos los resultados se muestran en una sola ventana
4. **Robustez**: Si un módulo falla, los otros continúan funcionando

## 📡 APIs

El sistema envía eventos a las siguientes APIs:

- **Reconocimiento Facial**: `http://localhost:8001/api/v1/blacklist-events`
- **Detección de Placas**: `http://localhost:8001/api/v1/plate-events`
- **Detección de Armas**: `http://localhost:8001/api/v1/weapon-detections`

## 🛠️ Solución de Problemas

### Error de Certificado SSL (macOS)
Si aparece un error de certificado SSL, el sistema automáticamente:
- Desactiva la verificación SSL para EasyOCR
- Continúa funcionando con los otros módulos

### Módulos Faltantes
Si algún módulo no se puede cargar:
- El sistema muestra una advertencia
- Continúa con los módulos disponibles
- No interrumpe el funcionamiento

### Dependencias Faltantes
```bash
# Instalar face_recognition_models
pip install git+https://github.com/ageitgey/face_recognition_models

# Instalar otras dependencias
pip install opencv-python numpy requests ultralytics easyocr
```

## 📈 Monitoreo

El sistema muestra información en tiempo real:
- Estado de cada módulo
- Número de frames procesados
- Detecciones activas
- Errores y advertencias

## 🔄 Integración con Sistema Principal

El sistema está diseñado para integrarse con:
- **API Principal**: Envía eventos a `localhost:8001`
- **Trigger Server**: Escucha en puerto 5001 para activar detección de placas
- **Base de Datos**: Almacena eventos de detección

## 📝 Logs

Los logs incluyen:
- Estado de inicialización de módulos
- Detecciones en tiempo real
- Errores y advertencias
- Estadísticas de rendimiento


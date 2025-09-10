# Guía de Despliegue en la Nube - Aplicación IoT

Esta guía te llevará paso a paso para desplegar tu aplicación IoT (API, MQTT y Base de Datos) en la nube de forma **GRATUITA**.

## Opción Recomendada: Railway (Más Fácil)

Railway ofrece hasta $5 USD mensuales gratuitos, perfecto para tu aplicación.

### Paso 1: Preparar el Repositorio

1. **Crear cuenta en GitHub** (si no tienes):
   - Ve a https://github.com
   - Crea una cuenta gratuita

2. **Subir tu código a GitHub**:
   ```bash
   cd /home/jorgis/Documents/Proyectos/ARQUI2B_2S2025_GL4
   git init
   git add .
   git commit -m "Initial commit - IoT App"
   # Crear repositorio en GitHub y seguir las instrucciones para push
   ```

### Paso 2: Desplegar en Railway

1. **Crear cuenta en Railway**:
   - Ve a https://railway.app
   - Regístrate con tu cuenta de GitHub
   - Obtienes $5 USD gratis al mes

2. **Crear nuevo proyecto**:
   - Click en "New Project"
   - Selecciona "Deploy from GitHub repo"
   - Conecta tu repositorio

3. **Configurar el servicio API**:
   - Railway detectará automáticamente el Dockerfile.api
   - En Settings → Environment, agregar:
     ```
     MQTT_BROKER=mqtt-service
     PORT=8001
     DATABASE_PATH=/app/data/ARQUI_2.db
     ```
   - Click en "Deploy"

4. **Configurar el servicio MQTT**:
   - Crear un segundo servicio en el mismo proyecto
   - Usar Dockerfile.mqtt
   - En Settings → Environment, agregar:
     ```
     MQTT_BROKER=localhost
     ```

5. **Agregar broker MQTT (Mosquitto)**:
   - Crear tercer servicio
   - Usar imagen: `eclipse-mosquitto:latest`
   - Puerto: 1883

### Paso 3: Obtener URLs y Probar

1. **Obtener URL del API**:
   - Railway te dará una URL como: `https://tu-app.railway.app`
   - Probar: `https://tu-app.railway.app/api/v1/`

2. **Probar endpoints**:
   - Status: `https://tu-app.railway.app/api/v1/status`
   - Debug: `https://tu-app.railway.app/api/v1/debug/received`

## Opción Alternativa: Render (También Gratis)

Si Railway no funciona, Render es otra excelente opción gratuita.

### Paso 1: Crear cuenta en Render

1. Ve a https://render.com
2. Regístrate con GitHub
3. Tier gratuito: 750 horas mensuales

### Paso 2: Desplegar servicios

1. **API Service**:
   - New → Web Service
   - Conectar repositorio GitHub
   - Build Command: `docker build -f Dockerfile.api -t api .`
   - Start Command: `/app/start-api.sh`

2. **MQTT Service**:
   - New → Background Worker
   - Build Command: `docker build -f Dockerfile.mqtt -t mqtt .`
   - Start Command: `python main.py --simulation`

## Opción 3: Heroku (Limitada pero funcional)

Heroku cambió su tier gratuito, pero puedes usar GitHub Codespaces + ngrok.

### Paso 1: GitHub Codespaces

1. En tu repositorio GitHub, click en "Code" → "Codespaces"
2. Crear nuevo Codespace
3. Ejecutar:
   ```bash
   docker-compose up -d
   ```

### Paso 2: Exponer con ngrok

1. Instalar ngrok:
   ```bash
   curl -s https://ngrok-agent.s3.amazonaws.com/ngrok.asc | sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null
   echo "deb https://ngrok-agent.s3.amazonaws.com buster main" | sudo tee /etc/apt/sources.list.d/ngrok.list
   sudo apt update && sudo apt install ngrok
   ```

2. Exponer el API:
   ```bash
   ngrok http 8001
   ```

## Pruebas Locales Antes del Despliegue

Antes de desplegar, prueba localmente:

```bash
# Construir y ejecutar con Docker
docker-compose up -d

# Probar el API
curl http://localhost:8001/api/v1/
curl http://localhost:8001/api/v1/status

# Ver logs
docker-compose logs -f
```

## URLs y Endpoints de tu Aplicación

Una vez desplegado, tendrás acceso a:

- **API Principal**: `https://tu-dominio/api/v1/`
- **Status del Sistema**: `https://tu-dominio/api/v1/status`
- **Datos MQTT recibidos**: `https://tu-dominio/api/v1/debug/received`
- **WebSocket Paradas**: `wss://tu-dominio/ws/stops`
- **WebSocket Tráfico**: `wss://tu-dominio/ws/traffic`
- **WebSocket Alertas**: `wss://tu-dominio/ws/alerts`

## Monitoreo y Logs

### Railway:
- Dashboard → tu proyecto → Logs
- Métricas en tiempo real
- Alertas automáticas

### Render:
- Dashboard → Services → Logs
- Métricas de uso
- Health checks automáticos

## Solución de Problemas Comunes

### Error: No se conecta MQTT
```bash
# Verificar que el broker esté corriendo
curl https://tu-dominio/api/v1/status
```

### Error: Base de datos no inicializada
- Los logs mostrarán si init-db.py falló
- Verificar que SQL/DB_ARQUI2_SQLite.sql existe

### Error: Puerto no disponible
- Railway asigna PORT automáticamente
- Verificar que uses ${PORT:-8001} en el script

## Costos y Límites

### Railway (Recomendado):
- **Gratis**: $5 USD/mes en créditos
- **Límites**: 500 horas de ejecución
- **Perfecto para**: Tu aplicación IoT

### Render:
- **Gratis**: 750 horas/mes
- **Límites**: Duerme después de 15 min sin uso
- **Perfecto para**: Demos y pruebas

### GitHub Codespaces + ngrok:
- **Gratis**: 120 horas/mes core
- **Límites**: Solo para desarrollo
- **Perfecto para**: Pruebas temporales

## Siguiente Paso: Conectar tu App Flutter

Una vez desplegado, actualiza tu app Flutter con las nuevas URLs:

```dart
// En tu app Flutter
const String API_BASE_URL = 'https://tu-dominio.railway.app/api/v1';
const String WEBSOCKET_URL = 'wss://tu-dominio.railway.app/ws';
```

¡Tu aplicación IoT estará funcionando 24/7 en la nube de forma gratuita!

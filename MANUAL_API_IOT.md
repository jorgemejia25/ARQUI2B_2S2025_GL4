# Manual Técnico - API IoT Sistema de Monitoreo

## Tabla de Contenidos

1. [Introducción](#introducción)
2. [Configuración e Instalación](#configuración-e-instalación)
3. [Arquitectura del Sistema](#arquitectura-del-sistema)
4. [Endpoints de la API](#endpoints-de-la-api)
5. [Ejemplos de Uso](#ejemplos-de-uso)
6. [Códigos de Error](#códigos-de-error)
7. [WebSockets](#websockets)
8. [Despliegue](#despliegue)
9. [Troubleshooting](#troubleshooting)

---

## Introducción

La API IoT es un sistema de monitoreo en tiempo real que actúa como puente entre dispositivos IoT (Arduino) y aplicaciones cliente (Flutter). El sistema recibe datos MQTT de sensores, los almacena en una base de datos SQLite y los expone a través de endpoints REST y WebSockets.

### Características Principales

- **Monitoreo en Tiempo Real**: Recepción de datos MQTT de sensores Arduino
- **Almacenamiento Persistente**: Base de datos SQLite para historial de datos
- **API REST**: Endpoints para consulta de datos históricos y en tiempo real
- **WebSockets**: Conexiones en tiempo real para actualizaciones automáticas
- **Dashboard Ready**: Endpoints optimizados para aplicaciones Flutter
- **CORS Habilitado**: Compatible con aplicaciones web y móviles

### Tecnologías Utilizadas

- **Backend**: FastAPI (Python)
- **Base de Datos**: SQLite
- **MQTT**: Paho-MQTT Client
- **WebSockets**: FastAPI WebSocket
- **Deployment**: Docker + Railway

---

## Configuración e Instalación

### Requisitos del Sistema

- Python 3.8+
- SQLite3
- Broker MQTT (Mosquitto)

### Instalación Local

1. **Clonar el repositorio**
```bash
git clone <repository-url>
cd arqui2/api
```

2. **Crear entorno virtual**
```bash
python -m venv venv
source venv/bin/activate  # Linux/Mac
# o
venv\Scripts\activate  # Windows
```

3. **Instalar dependencias**
```bash
pip install -r requirements.txt
```

4. **Configurar variables de entorno**
```bash
# Crear archivo .env
SERVER_HOST=0.0.0.0
SERVER_PORT=8001
MQTT_BROKER=localhost
MQTT_PORT=1883
MQTT_USERNAME=jorge
MQTT_PASSWORD=34eikykmbd8w5igpjiebialeisx0yu02
LOG_LEVEL=INFO
```

5. **Inicializar base de datos**
```bash
python init-db.py
```

6. **Ejecutar la aplicación**
```bash
python main.py
```

### Instalación con Docker

```bash
# Construir imagen
docker build -f Dockerfile.api -t api-iot .

# Ejecutar contenedor
docker run -p 8001:8001 \
  -e MQTT_BROKER=your-broker \
  -e MQTT_USERNAME=your-username \
  -e MQTT_PASSWORD=your-password \
  api-iot
```

---

## Arquitectura del Sistema

### Diagrama de Arquitectura

```
┌─────────────────┐    MQTT     ┌─────────────────┐    HTTP/WS    ┌─────────────────┐
│   Arduino       │ ──────────► │   MQTT Broker   │ ◄─────────── │   Flutter App   │
│   (Sensores)    │             │   (Mosquitto)   │              │   (Dashboard)   │
└─────────────────┘             └─────────────────┘              └─────────────────┘
                                         │
                                         │ MQTT
                                         ▼
                                ┌─────────────────┐
                                │   API IoT       │
                                │   (FastAPI)     │
                                └─────────────────┘
                                         │
                                         │ SQL
                                         ▼
                                ┌─────────────────┐
                                │   SQLite DB     │
                                │   (Datos)       │
                                └─────────────────┘
```

### Componentes del Sistema

1. **MQTT Handler**: Maneja la conexión y recepción de datos MQTT
2. **Database Manager**: Gestiona operaciones de base de datos SQLite
3. **WebSocket Manager**: Administra conexiones WebSocket en tiempo real
4. **Data Endpoints**: Expone datos a través de API REST
5. **Routes**: Define rutas principales y de debugging

### Estructura de Base de Datos

#### Tablas Principales

- **Bus**: Información de buses del sistema
- **Route**: Rutas de transporte
- **Stop**: Paradas de buses
- **AlertType**: Tipos de alertas del sistema

#### Tablas de Datos

- **BusPosition**: Posiciones GPS de buses
- **GasMeasurement**: Mediciones de sensores de gas
- **SeismicMeasurement**: Mediciones sísmicas
- **Alert**: Alertas del sistema

#### Tablas de Eventos

- **TrafficInfraction**: Infracciones de tráfico
- **PanicEvent**: Eventos de botón de pánico
- **SeismicEvent**: Eventos sísmicos
- **GasEvent**: Eventos de gas

---

## Endpoints de la API

### Base URL
```
http://localhost:8001/api/v1
```

### Endpoints Principales

#### 1. Estado del Sistema

**GET** `/status`
Verifica el estado general del API y conexión MQTT.

**Respuesta:**
```json
{
  "mqtt_connected": true,
  "broker": "localhost:1883",
  "topics_count": 1,
  "topics": ["arduino/data"]
}
```

#### 2. Endpoints de Datos

##### Posiciones de Buses

**GET** `/data/bus-positions`
Obtiene las últimas posiciones de buses.

**Parámetros:**
- `bus_id` (opcional): ID del bus específico
- `bus_code` (opcional): Código del bus (BUS_TRANSMETRO, BUS_TRANSURBANO)
- `limit` (opcional): Número de registros (1-500, default: 20)

**Ejemplo:**
```bash
GET /api/v1/data/bus-positions?bus_code=BUS_TRANSMETRO&limit=10
```

**Respuesta:**
```json
[
  {
    "position_id": 1,
    "ts": "2024-01-15 10:30:00",
    "bus_id": 1,
    "speed_kmh": 45.5,
    "distance_to_next_stop_m": 150,
    "bus_code": "BUS_TRANSMETRO"
  }
]
```

**Endpoints Específicos:**
- `GET /data/bus-positions/bus/1` - Solo BUS_TRANSMETRO
- `GET /data/bus-positions/bus/2` - Solo BUS_TRANSURBANO

##### Historial de Sensores

**GET** `/data/gas-history`
Obtiene historial de mediciones de gas.

**Parámetros:**
- `from_ts` (opcional): Fecha inicio (YYYY-MM-DD HH:MM:SS)
- `to_ts` (opcional): Fecha fin (YYYY-MM-DD HH:MM:SS)
- `limit` (opcional): Número de registros (1-2000, default: 100)

**Ejemplo:**
```bash
GET /api/v1/data/gas-history?from_ts=2024-01-15 00:00:00&limit=50
```

**Respuesta:**
```json
[
  {
    "gas_id": 1,
    "ts": "2024-01-15 10:30:00",
    "ppm": 25.3
  }
]
```

**Endpoints Específicos:**
- `GET /data/gas-history/origin/1` - Gas origen 1
- `GET /data/gas-history/origin/2` - Gas origen 2

**GET** `/data/seismic-history`
Obtiene historial de mediciones sísmicas.

**Parámetros:** Iguales que gas-history

**Respuesta:**
```json
[
  {
    "seis_id": 1,
    "ts": "2024-01-15 10:30:00",
    "intensity_g": 0.1
  }
]
```

##### Eventos y Alertas

**GET** `/data/tables/traffic-infractions`
Obtiene infracciones de tráfico.

**Parámetros:**
- `alert_id` (opcional): ID de alerta específica
- `limit` (opcional): Número de registros (1-5000, default: 200)

**Respuesta:**
```json
[
  {
    "alert_id": 1,
    "signal_color": "red"
  }
]
```

**Endpoints Similares:**
- `GET /data/tables/panic-events` - Eventos de pánico
- `GET /data/tables/seismic-events` - Eventos sísmicos
- `GET /data/tables/gas-events` - Eventos de gas

### Endpoints para Dashboard

#### Resumen General

**GET** `/data/dashboard/summary`
Obtiene resumen completo del sistema para dashboard.

**Respuesta:**
```json
{
  "alerts_summary": [
    {
      "code": "INFRACCION",
      "description": "Infracción de tráfico (semáforo)",
      "count": 5
    }
  ],
  "buses_status": [
    {
      "code": "BUS_TRANSMETRO",
      "ts": "2024-01-15 10:30:00",
      "speed_kmh": 45.5,
      "distance_to_next_stop_m": 150
    }
  ],
  "latest_gas": [
    {
      "ppm": 25.3,
      "ts": "2024-01-15 10:30:00"
    }
  ],
  "latest_seismic": [
    {
      "intensity_g": 0.1,
      "ts": "2024-01-15 10:30:00"
    }
  ],
  "timestamp": "now"
}
```

#### Datos para Gráficas

**GET** `/data/dashboard/charts/gas`
Datos de gas para gráficas.

**Parámetros:**
- `hours` (opcional): Horas hacia atrás (1-168, default: 24)

**Respuesta:**
```json
[
  {
    "ts": "2024-01-15 09:00:00",
    "ppm": 20.5
  },
  {
    "ts": "2024-01-15 09:30:00",
    "ppm": 22.1
  }
]
```

**Endpoints Similares:**
- `GET /data/dashboard/charts/seismic` - Datos sísmicos
- `GET /data/dashboard/charts/bus-positions` - Posiciones de buses

#### Alertas Recientes

**GET** `/data/dashboard/alerts/recent`
Alertas recientes con detalles completos.

**Parámetros:**
- `limit` (opcional): Número de alertas (1-100, default: 20)

**Respuesta:**
```json
[
  {
    "alert_id": 1,
    "ts": "2024-01-15 10:30:00",
    "alert_type": "INFRACCION",
    "description": "Infracción de tráfico (semáforo)",
    "severity": 3,
    "bus_code": "BUS_TRANSMETRO",
    "stop_name": "Parada1_Transmetro",
    "detail_value": "red"
  }
]
```

#### Estadísticas por Período

**GET** `/data/dashboard/stats/hourly`
Estadísticas agregadas por hora.

**Parámetros:**
- `hours` (opcional): Horas hacia atrás (1-168, default: 24)

**Respuesta:**
```json
{
  "alerts_by_hour": [
    {
      "hour": "2024-01-15 10:00:00",
      "alert_type": "INFRACCION",
      "count": 2
    }
  ],
  "gas_by_hour": [
    {
      "hour": "2024-01-15 10:00:00",
      "avg_ppm": 22.5,
      "max_ppm": 25.3,
      "min_ppm": 20.1
    }
  ],
  "seismic_by_hour": [
    {
      "hour": "2024-01-15 10:00:00",
      "avg_intensity": 0.08,
      "max_intensity": 0.1,
      "min_intensity": 0.05
    }
  ]
}
```

#### Estado de Buses

**GET** `/data/dashboard/buses/status`
Estado actual de todos los buses.

**Respuesta:**
```json
[
  {
    "bus_id": 1,
    "code": "BUS_TRANSMETRO",
    "route_name": "Ruta Transmetro",
    "last_position_time": "2024-01-15 10:30:00",
    "speed_kmh": 45.5,
    "distance_to_next_stop_m": 150,
    "status": "active"
  }
]
```

#### Métricas del Sistema

**GET** `/data/dashboard/metrics`
Métricas generales del sistema.

**Respuesta:**
```json
{
  "table_counts": [
    {
      "table_name": "GasMeasurement",
      "count": 1250
    }
  ],
  "severity_distribution": [
    {
      "severity": 3,
      "count": 15
    }
  ],
  "hourly_activity": [
    {
      "hour": "09",
      "total_events": 45
    }
  ]
}
```

### Endpoints de Debugging

**GET** `/debug/received`
Muestra los últimos datos recibidos por MQTT.

**GET** `/debug/mqtt-test`
Prueba la conexión MQTT.

**GET** `/debug/database-stats`
Estadísticas de la base de datos.

**GET** `/debug/websocket-stats`
Estadísticas de WebSocket.

**POST** `/debug/clear`
Limpia el historial de eventos recibidos.

---

## Ejemplos de Uso

### Consumo desde Flutter

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  static const String baseUrl = 'http://localhost:8001/api/v1';
  
  // Obtener resumen del dashboard
  static Future<Map<String, dynamic>> getDashboardSummary() async {
    final response = await http.get(
      Uri.parse('$baseUrl/data/dashboard/summary')
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Error al cargar datos del dashboard');
  }
  
  // Obtener datos de gas para gráficas
  static Future<List<dynamic>> getGasChartData({int hours = 24}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/data/dashboard/charts/gas?hours=$hours')
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Error al cargar datos de gas');
  }
  
  // Obtener alertas recientes
  static Future<List<dynamic>> getRecentAlerts({int limit = 20}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/data/dashboard/alerts/recent?limit=$limit')
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Error al cargar alertas');
  }
  
  // Obtener estado de buses
  static Future<List<dynamic>> getBusesStatus() async {
    final response = await http.get(
      Uri.parse('$baseUrl/data/dashboard/buses/status')
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Error al cargar estado de buses');
  }
}
```

### Consumo desde JavaScript/Web

```javascript
class ApiClient {
  constructor(baseUrl = 'http://localhost:8001/api/v1') {
    this.baseUrl = baseUrl;
  }
  
  async getDashboardSummary() {
    const response = await fetch(`${this.baseUrl}/data/dashboard/summary`);
    if (!response.ok) {
      throw new Error('Error al cargar datos del dashboard');
    }
    return await response.json();
  }
  
  async getGasChartData(hours = 24) {
    const response = await fetch(
      `${this.baseUrl}/data/dashboard/charts/gas?hours=${hours}`
    );
    if (!response.ok) {
      throw new Error('Error al cargar datos de gas');
    }
    return await response.json();
  }
  
  async getRecentAlerts(limit = 20) {
    const response = await fetch(
      `${this.baseUrl}/data/dashboard/alerts/recent?limit=${limit}`
    );
    if (!response.ok) {
      throw new Error('Error al cargar alertas');
    }
    return await response.json();
  }
}

// Uso
const api = new ApiClient();
api.getDashboardSummary().then(data => {
  console.log('Dashboard data:', data);
});
```

### Consumo desde Python

```python
import requests
import json

class ApiClient:
    def __init__(self, base_url="http://localhost:8001/api/v1"):
        self.base_url = base_url
    
    def get_dashboard_summary(self):
        response = requests.get(f"{self.base_url}/data/dashboard/summary")
        response.raise_for_status()
        return response.json()
    
    def get_gas_chart_data(self, hours=24):
        response = requests.get(
            f"{self.base_url}/data/dashboard/charts/gas",
            params={"hours": hours}
        )
        response.raise_for_status()
        return response.json()
    
    def get_recent_alerts(self, limit=20):
        response = requests.get(
            f"{self.base_url}/data/dashboard/alerts/recent",
            params={"limit": limit}
        )
        response.raise_for_status()
        return response.json()

# Uso
api = ApiClient()
dashboard_data = api.get_dashboard_summary()
print("Dashboard data:", dashboard_data)
```

---

## Códigos de Error

### Códigos HTTP Estándar

- **200 OK**: Solicitud exitosa
- **400 Bad Request**: Parámetros inválidos
- **404 Not Found**: Endpoint no encontrado
- **500 Internal Server Error**: Error interno del servidor

### Errores Específicos

#### Error de Conexión MQTT
```json
{
  "detail": "Error conectando a MQTT broker",
  "status": "mqtt_connection_failed"
}
```

#### Error de Base de Datos
```json
{
  "detail": "Error ejecutando consulta",
  "status": "database_error"
}
```

#### Error de Parámetros
```json
{
  "detail": "Parámetro 'limit' debe estar entre 1 y 500",
  "status": "validation_error"
}
```

---

## WebSockets

### Conexiones Disponibles

#### WebSocket de Paradas
**URL:** `ws://localhost:8001/ws/stops`

#### WebSocket de Tráfico
**URL:** `ws://localhost:8001/ws/traffic`

#### WebSocket de Alertas
**URL:** `ws://localhost:8001/ws/alerts`

### Ejemplo de Uso en JavaScript

```javascript
const ws = new WebSocket('ws://localhost:8001/ws/alerts');

ws.onopen = function(event) {
  console.log('Conectado al WebSocket de alertas');
};

ws.onmessage = function(event) {
  const data = JSON.parse(event.data);
  console.log('Nueva alerta:', data);
  // Actualizar UI con nueva alerta
};

ws.onclose = function(event) {
  console.log('Conexión WebSocket cerrada');
};

ws.onerror = function(error) {
  console.error('Error en WebSocket:', error);
};
```

### Ejemplo de Uso en Flutter

```dart
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  late WebSocketChannel channel;
  
  void connectToAlerts() {
    channel = WebSocketChannel.connect(
      Uri.parse('ws://localhost:8001/ws/alerts')
    );
    
    channel.stream.listen((data) {
      final alert = json.decode(data);
      // Procesar nueva alerta
      _handleNewAlert(alert);
    });
  }
  
  void _handleNewAlert(Map<String, dynamic> alert) {
    // Actualizar UI con nueva alerta
  }
  
  void disconnect() {
    channel.sink.close();
  }
}
```

---

## Despliegue

### Despliegue Local

1. **Configurar variables de entorno**
2. **Ejecutar migraciones de base de datos**
3. **Iniciar servicios MQTT**
4. **Ejecutar la aplicación**

### Despliegue con Docker

```bash
# Construir imagen
docker build -f Dockerfile.api -t api-iot .

# Ejecutar con docker-compose
docker-compose up -d
```

### Despliegue en Railway

1. **Configurar variables de entorno en Railway**
2. **Conectar repositorio Git**
3. **Configurar Railway.json**
4. **Desplegar automáticamente**

### Variables de Entorno Requeridas

```bash
# Servidor
SERVER_HOST=0.0.0.0
SERVER_PORT=8001

# MQTT
MQTT_BROKER=your-broker-url
MQTT_PORT=1883
MQTT_USERNAME=your-username
MQTT_PASSWORD=your-password

# Base de datos
DATABASE_PATH=/app/data/ARQUI_2.db

# Logging
LOG_LEVEL=INFO
```

---

## Troubleshooting

### Problemas Comunes

#### 1. Error de Conexión MQTT

**Síntomas:**
- API no recibe datos de sensores
- Logs muestran "Error conectando a MQTT broker"

**Soluciones:**
- Verificar que el broker MQTT esté ejecutándose
- Confirmar credenciales MQTT
- Verificar conectividad de red
- Revisar configuración de firewall

#### 2. Error de Base de Datos

**Síntomas:**
- Endpoints retornan errores 500
- Logs muestran "Error ejecutando consulta"

**Soluciones:**
- Verificar permisos de archivo de base de datos
- Confirmar que la base de datos existe
- Ejecutar `init-db.py` para recrear esquema
- Verificar espacio en disco

#### 3. Problemas de CORS

**Síntomas:**
- Errores de CORS en aplicaciones web
- Requests bloqueados desde navegador

**Soluciones:**
- Verificar configuración CORS en `config.py`
- Confirmar que el origen está permitido
- Revisar headers de respuesta

#### 4. WebSocket No Conecta

**Síntomas:**
- Conexiones WebSocket fallan
- No se reciben actualizaciones en tiempo real

**Soluciones:**
- Verificar URL del WebSocket
- Confirmar que el servidor soporta WebSockets
- Revisar configuración de proxy/firewall

### Logs y Monitoreo

#### Niveles de Log

- **DEBUG**: Información detallada para debugging
- **INFO**: Información general del sistema
- **WARNING**: Advertencias no críticas
- **ERROR**: Errores que requieren atención

#### Ubicación de Logs

- **Desarrollo**: Consola
- **Producción**: Archivos de log o servicio de logging

#### Monitoreo Recomendado

- Estado de conexión MQTT
- Rendimiento de base de datos
- Conexiones WebSocket activas
- Uso de memoria y CPU

### Comandos de Diagnóstico

```bash
# Verificar estado del API
curl http://localhost:8001/api/v1/status

# Probar conexión MQTT
curl http://localhost:8001/api/v1/debug/mqtt-test

# Ver estadísticas de base de datos
curl http://localhost:8001/api/v1/debug/database-stats

# Ver estadísticas de WebSocket
curl http://localhost:8001/api/v1/debug/websocket-stats
```

---

## Conclusión

Esta API IoT proporciona una interfaz completa para el monitoreo de sistemas IoT en tiempo real. Con endpoints optimizados para dashboards, soporte para WebSockets y una arquitectura robusta, es ideal para aplicaciones de monitoreo industrial y urbano.

Para soporte técnico o consultas adicionales, contactar al equipo de desarrollo.

---

**Versión del Manual:** 1.0  
**Última Actualización:** Enero 2024  
**Compatibilidad:** API v1.0.0




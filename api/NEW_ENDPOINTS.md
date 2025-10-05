# Nuevos Endpoints - Sensores y Posiciones de Buses

## 📡 Endpoints Creados

Se agregaron 4 nuevos endpoints GET a la API para acceder a los datos de las nuevas tablas:

---

### 1. **GET** `/data/dashboard/sensors/metro`
Obtiene datos del grupo de sensores activos para Metro

**Parámetros de consulta:**
- `hours` (opcional): Horas hacia atrás (1-168), default: 24
- `limit` (opcional): Máximo de registros (1-1000), default: 100

**Ejemplo de uso:**
```bash
curl "http://localhost:8000/data/dashboard/sensors/metro?hours=24&limit=100"
```

**Respuesta:**
```json
{
  "hours": 24,
  "limit": 100,
  "count": 15,
  "data": [
    {
      "sensor_group_metro_id": 1,
      "ts": "2025-10-02 19:30:00",
      "sensor_name": "GAS_SENSOR_1"
    }
  ]
}
```

---

### 2. **GET** `/data/dashboard/sensors/urban`
Obtiene datos del grupo de sensores activos para Urbano

**Parámetros de consulta:**
- `hours` (opcional): Horas hacia atrás (1-168), default: 24
- `limit` (opcional): Máximo de registros (1-1000), default: 100

**Ejemplo de uso:**
```bash
curl "http://localhost:8000/data/dashboard/sensors/urban?hours=48&limit=50"
```

**Respuesta:**
```json
{
  "hours": 48,
  "limit": 50,
  "count": 20,
  "data": [
    {
      "sensor_group_urban_id": 1,
      "ts": "2025-10-02 19:30:00",
      "sensor_name": "SEISMIC_SENSOR_2"
    }
  ]
}
```

---

### 3. **GET** `/data/dashboard/bus-position/metro`
Obtiene posiciones de buses para Metro

**Parámetros de consulta:**
- `hours` (opcional): Horas hacia atrás (1-168), default: 24
- `bus_id` (opcional): Filtrar por ID de bus específico
- `limit` (opcional): Máximo de registros (1-1000), default: 100

**Ejemplo de uso:**
```bash
# Todas las posiciones
curl "http://localhost:8000/data/dashboard/bus-position/metro?hours=12&limit=200"

# Filtrar por bus específico
curl "http://localhost:8000/data/dashboard/bus-position/metro?hours=12&bus_id=1"
```

**Respuesta:**
```json
{
  "hours": 12,
  "bus_id": null,
  "limit": 200,
  "count": 45,
  "data": [
    {
      "position_metro_id": 1,
      "ts": "2025-10-02 19:30:00",
      "bus_id": 1,
      "bus_code": "BUS_TRANSMETRO",
      "speed_kmh": 45.5,
      "position": "14.6349,-90.5069",
      "distance_to_next_stop": 250.0
    }
  ]
}
```

---

### 4. **GET** `/data/dashboard/bus-position/urban`
Obtiene posiciones de buses para Urbano

**Parámetros de consulta:**
- `hours` (opcional): Horas hacia atrás (1-168), default: 24
- `bus_id` (opcional): Filtrar por ID de bus específico
- `limit` (opcional): Máximo de registros (1-1000), default: 100

**Ejemplo de uso:**
```bash
# Todas las posiciones
curl "http://localhost:8000/data/dashboard/bus-position/urban?hours=6"

# Filtrar por bus específico
curl "http://localhost:8000/data/dashboard/bus-position/urban?bus_id=2&hours=24"
```

**Respuesta:**
```json
{
  "hours": 6,
  "bus_id": 2,
  "limit": 100,
  "count": 30,
  "data": [
    {
      "position_urban_id": 1,
      "ts": "2025-10-02 19:30:00",
      "bus_id": 2,
      "bus_code": "BUS_TRANSURBANO",
      "speed_kmh": 38.2,
      "position": "14.6300,-90.5100",
      "distance_to_next_stop": 180.5
    }
  ]
}
```

---

## 🚀 Cómo probar los endpoints

1. **Asegúrate de que la API esté corriendo:**
```bash
cd /home/dant/Escritorio/USAC/ARQ2/ARQUI2B_2S2025_GL4/api
python3 run.py
```

2. **Visita la documentación interactiva de Swagger:**
   - Abre tu navegador en: `http://localhost:8000/docs`
   - Busca la sección "dashboard"
   - Encontrarás los 4 nuevos endpoints

3. **Prueba con curl o Postman:**
```bash
# Sensores Metro
curl "http://localhost:8000/data/dashboard/sensors/metro"

# Sensores Urbano
curl "http://localhost:8000/data/dashboard/sensors/urban"

# Posiciones Bus Metro
curl "http://localhost:8000/data/dashboard/bus-position/metro"

# Posiciones Bus Urbano
curl "http://localhost:8000/data/dashboard/bus-position/urban"
```

---

## 📊 Campos de las tablas

### ActiveSensorGroupMetro / ActiveSensorGroupUrban
- `sensor_group_[metro|urban]_id`: ID único
- `ts`: Timestamp de registro
- `sensor_name`: Nombre del sensor activo

### BusPositionMetro / BusPositionUrban
- `position_[metro|urban]_id`: ID único
- `ts`: Timestamp de la posición
- `bus_id`: ID del bus (FK)
- `bus_code`: Código del bus (ej: "BUS_TRANSMETRO")
- `speed_kmh`: Velocidad en km/h
- `position`: Coordenadas o descripción de posición
- `distance_to_next_stop`: Distancia a próxima parada

---

## 🔧 Archivos modificados

1. **SQL Schema**: `/SQL/DB_ARQUI2_SQLite.sql`
   - Agregadas 4 nuevas tablas con índices

2. **Repository**: `/api/app/db/repositories/dashboard_repository.py`
   - Agregados 4 métodos nuevos para consultar las tablas

3. **Endpoints**: `/api/app/api/endpoints/dashboard.py`
   - Agregados 4 endpoints GET con filtros y paginación

---

## ✅ Próximos pasos

Para que los datos aparezcan en estas tablas, necesitarás:

1. **Actualizar el script de inicialización de BD** para crear las nuevas tablas:
```bash
cd /home/dant/Escritorio/USAC/ARQ2/ARQUI2B_2S2025_GL4/api
python3 init_database.py
```

2. **Modificar el MQTT handler** para insertar datos en estas tablas cuando lleguen mensajes

3. **Probar con datos de ejemplo** para verificar que todo funciona

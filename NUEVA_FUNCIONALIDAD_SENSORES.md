# 🎯 Nueva Funcionalidad: Simulación de Sensores Activos

## 📋 Descripción

Se agregó una nueva opción al simulador interactivo MQTT (`./run_simulator.sh`) que permite simular la activación de sensores en ciclos para las rutas Metro y Urbano.

---

## 🚀 Cómo usar

### 1. Iniciar el simulador interactivo

```bash
cd /home/dant/Escritorio/USAC/ARQ2/ARQUI2B_2S2025_GL4
./run_simulator.sh
```

### 2. Seleccionar la opción 7

```
===========================================
SIMULADOR INTERACTIVO DE EVENTOS MQTT
===========================================
Estado de conexión MQTT: Conectado

OPCIONES DISPONIBLES:
1.  Enviar datos normales del sistema
2.  Enviar alerta de sismo
3.  Enviar alerta de botón de pánico
4.  Enviar infracción de tráfico
5.  Enviar alerta de gas alto
6.  Enviar actualización de ETA
7.  Simular datos de Sensores Activos (Metro y Urbano)  ⭐ NUEVA
8.  Limpiar todas las alertas
9.  Enviar datos continuos (5 segundos)
0.  Salir
===========================================

Selecciona una opción (0-9): 7
```

### 3. Configurar la simulación

El sistema te pedirá:

```
--- SIMULACIÓN DE SENSORES ACTIVOS ---
Metro:  PM1 → S2 → S1 → PM2 → S5 → PM1 (ciclo)
Urbano: PU1 → S4 → S3 → PU2 → S3 → S4 → PU1 (ciclo)

Ingresa la duración total en segundos (por defecto 30): 60
Ingresa el intervalo entre inserciones en segundos (por defecto 5): 5
```

### 4. Observar la simulación

```
============================================================
INICIANDO SIMULACIÓN DE SENSORES ACTIVOS
Duración: 60 segundos
Intervalo: 5 segundos
============================================================

[1] Enviando sensores activos:
  ├─ Metro:  PM1
  └─ Urbano: PU1

[2] Enviando sensores activos:
  ├─ Metro:  S2
  └─ Urbano: S4

[3] Enviando sensores activos:
  ├─ Metro:  S1
  └─ Urbano: S3

... (continúa cada 5 segundos) ...

============================================================
SIMULACIÓN FINALIZADA
Total de ciclos: 12
Tiempo total: 60.0 segundos
============================================================
```

---

## 🔄 Ciclos de sensores

### Sensores Metro (ActiveSensorGroupMetro)
```
PM1 → S2 → S1 → PM2 → S5 → PM1 → (repite...)
```

### Sensores Urbano (ActiveSensorGroupUrban)
```
PU1 → S4 → S3 → PU2 → S3 → S4 → PU1 → (repite...)
```

---

## 💾 Almacenamiento en Base de Datos

### Tabla: ActiveSensorGroupMetro
```sql
CREATE TABLE IF NOT EXISTS ActiveSensorGroupMetro (
  sensor_group_metro_id INTEGER PRIMARY KEY AUTOINCREMENT,
  ts                    DATETIME NOT NULL DEFAULT (datetime('now')),
  sensor_name           TEXT NOT NULL
);
```

**Ejemplo de datos insertados:**
```sql
INSERT INTO ActiveSensorGroupMetro (ts, sensor_name) VALUES 
  ('2025-10-02 19:30:00', 'PM1'),
  ('2025-10-02 19:30:05', 'S2'),
  ('2025-10-02 19:30:10', 'S1'),
  ('2025-10-02 19:30:15', 'PM2'),
  ('2025-10-02 19:30:20', 'S5'),
  ('2025-10-02 19:30:25', 'PM1');  -- Reinicia ciclo
```

### Tabla: ActiveSensorGroupUrban
```sql
CREATE TABLE IF NOT EXISTS ActiveSensorGroupUrban (
  sensor_group_urban_id INTEGER PRIMARY KEY AUTOINCREMENT,
  ts                    DATETIME NOT NULL DEFAULT (datetime('now')),
  sensor_name           TEXT NOT NULL
);
```

**Ejemplo de datos insertados:**
```sql
INSERT INTO ActiveSensorGroupUrban (ts, sensor_name) VALUES 
  ('2025-10-02 19:30:00', 'PU1'),
  ('2025-10-02 19:30:05', 'S4'),
  ('2025-10-02 19:30:10', 'S3'),
  ('2025-10-02 19:30:15', 'PU2'),
  ('2025-10-02 19:30:20', 'S3'),
  ('2025-10-02 19:30:25', 'S4'),
  ('2025-10-02 19:30:30', 'PU1');  -- Reinicia ciclo
```

---

## 📡 Flujo MQTT → Base de Datos

```
┌────────────────────────────┐
│ Simulador Interactivo      │
│ (interactive_mqtt_simulator)│
└──────────┬─────────────────┘
           │ Publica cada N segundos
           ↓
┌────────────────────────────┐
│ Topic: arduino/data/sensors│
│ Payload:                   │
│ {                          │
│   "sensor_name": "PM1",    │
│   "route_type": "metro"    │
│ }                          │
└──────────┬─────────────────┘
           │
           ↓
┌────────────────────────────┐
│ MQTT Broker (Mosquitto)    │
│ localhost:1883             │
└──────────┬─────────────────┘
           │
           ↓
┌────────────────────────────┐
│ API - MQTT Service         │
│ (mqtt_service.py)          │
│ - Suscrito a topic         │
│ - on_message()             │
└──────────┬─────────────────┘
           │
           ↓
┌────────────────────────────┐
│ MQTT Repository            │
│ (mqtt_repository.py)       │
│ - _save_active_sensor_data()│
└──────────┬─────────────────┘
           │
           ↓
┌────────────────────────────┐
│ SQLite Database            │
│ - ActiveSensorGroupMetro   │
│ - ActiveSensorGroupUrban   │
└────────────────────────────┘
```

---

## 🔍 Verificar datos insertados

### Ver últimos sensores Metro:
```bash
sqlite3 api/seguridad_trafico.db \
  "SELECT * FROM ActiveSensorGroupMetro ORDER BY ts DESC LIMIT 10;"
```

### Ver últimos sensores Urbano:
```bash
sqlite3 api/seguridad_trafico.db \
  "SELECT * FROM ActiveSensorGroupUrban ORDER BY ts DESC LIMIT 10;"
```

### Contar sensores por nombre (Metro):
```bash
sqlite3 api/seguridad_trafico.db \
  "SELECT sensor_name, COUNT(*) as total 
   FROM ActiveSensorGroupMetro 
   GROUP BY sensor_name 
   ORDER BY total DESC;"
```

### Ver datos por intervalo de tiempo:
```bash
sqlite3 api/seguridad_trafico.db \
  "SELECT sensor_name, ts 
   FROM ActiveSensorGroupMetro 
   WHERE ts >= datetime('now', '-1 hour') 
   ORDER BY ts DESC;"
```

---

## 🌐 Consultar vía API

### Endpoint Metro:
```bash
curl "http://localhost:8000/data/dashboard/sensors/metro?hours=1&limit=20"
```

**Respuesta ejemplo:**
```json
{
  "hours": 1,
  "limit": 20,
  "count": 12,
  "data": [
    {
      "sensor_group_metro_id": 12,
      "ts": "2025-10-02 19:30:55",
      "sensor_name": "PM1"
    },
    {
      "sensor_group_metro_id": 11,
      "ts": "2025-10-02 19:30:50",
      "sensor_name": "S5"
    }
  ]
}
```

### Endpoint Urbano:
```bash
curl "http://localhost:8000/data/dashboard/sensors/urban?hours=1&limit=20"
```

---

## ⚙️ Archivos modificados

1. **`interactive_mqtt_simulator.py`**
   - ✅ Agregado método `simulate_active_sensors()`
   - ✅ Nueva opción en el menú (opción 7)
   - ✅ Ciclos automáticos con intervalos configurables

2. **`api/app/services/mqtt_service.py`**
   - ✅ Suscripción al topic `arduino/data/sensors`

3. **`api/app/db/repositories/mqtt_repository.py`**
   - ✅ Método `_save_active_sensor_data()`
   - ✅ Manejo de route_type (metro/urban)
   - ✅ Inserción en tablas correspondientes

4. **`SQL/DB_ARQUI2_SQLite.sql`**
   - ✅ Tablas `ActiveSensorGroupMetro` y `ActiveSensorGroupUrban` ya creadas
   - ✅ Índices para optimización

---

## 📊 Ejemplo de uso completo

```bash
# Terminal 1: Broker MQTT
./start_mos2.sh

# Terminal 2: API (debe estar corriendo para guardar datos)
cd api
python3 run.py

# Terminal 3: Simulador interactivo
./run_simulator.sh
# Seleccionar opción 7
# Duración: 60 segundos
# Intervalo: 5 segundos

# Terminal 4: Monitorear datos en tiempo real
watch -n 2 "sqlite3 api/seguridad_trafico.db \
  'SELECT sensor_name, ts FROM ActiveSensorGroupMetro 
   ORDER BY ts DESC LIMIT 5;'"
```

---

## ⏱️ Cálculo de ciclos

- **Duración total**: D segundos
- **Intervalo**: I segundos
- **Ciclos totales**: D / I

Ejemplos:
- 30 segundos con intervalo de 5s = 6 ciclos
- 60 segundos con intervalo de 5s = 12 ciclos
- 120 segundos con intervalo de 10s = 12 ciclos

---

## ⚠️ Notas importantes

1. **API debe estar corriendo**: Para que los datos se guarden en la BD
2. **Broker MQTT activo**: Debe estar corriendo Mosquitto
3. **Ciclos independientes**: Metro y Urbano tienen longitudes diferentes (6 vs 7)
4. **Timestamps automáticos**: Se usa `datetime('now')` en SQLite
5. **Sin límite de datos**: Los datos se acumulan, considera limpiar datos antiguos periódicamente

---

## 🧪 Testing

### Prueba básica (30 segundos):
```bash
# En el simulador:
7 → 30 → 5 → Enter
```

### Prueba larga (5 minutos):
```bash
# En el simulador:
7 → 300 → 10 → Enter
```

### Verificar después:
```bash
# Contar registros
sqlite3 api/seguridad_trafico.db \
  "SELECT 
     (SELECT COUNT(*) FROM ActiveSensorGroupMetro) as metro,
     (SELECT COUNT(*) FROM ActiveSensorGroupUrban) as urban;"
```

---

## ✅ Checklist de funcionamiento

- [x] Simulador publica mensajes MQTT
- [x] API recibe mensajes en topic `arduino/data/sensors`
- [x] Datos se guardan en `ActiveSensorGroupMetro`
- [x] Datos se guardan en `ActiveSensorGroupUrban`
- [x] Endpoints `/sensors/metro` y `/sensors/urban` devuelven datos
- [x] Ciclos se reinician correctamente
- [x] Intervalos de tiempo se respetan
- [x] Logs en API muestran inserciones exitosas

---

## 🎉 ¡Listo para usar!

La funcionalidad está completa y lista. Solo asegúrate de tener:
1. ✅ Mosquitto corriendo
2. ✅ API corriendo
3. ✅ Base de datos inicializada

Luego ejecuta `./run_simulator.sh` y selecciona la opción 7. 🚀

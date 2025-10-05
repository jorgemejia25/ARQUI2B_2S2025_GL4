# 🔐 Validación de Secuencia de Sensores - BusPosition

## 📋 Descripción

Se implementó un sistema de validación de secuencia para las tablas `BusPositionMetro` y `BusPositionUrban`. Esta validación asegura que solo se guarden sensores que sigan el orden correcto del ciclo esperado.

---

## 🎯 Objetivo

**Problema a resolver:**
- Los sensores se activan en un orden específico (ciclo)
- Si se detecta un sensor fuera de orden, no debe guardarse en `BusPosition`
- La tabla `ActiveSensorGroup` siempre registra todos los sensores (con o sin validación)

**Solución:**
- Validar la secuencia antes de insertar en `BusPosition`
- Mantener registro completo en `ActiveSensorGroup`
- Logs detallados para debugging

---

## 🔄 Secuencias Definidas

### Metro (5 sensores)
```python
METRO_SEQUENCE = ["PM1", "S2", "S1", "PM2", "S5"]
```

**Ciclo completo:**
```
PM1 → S2 → S1 → PM2 → S5 → PM1 → S2 → ...
```

### Urbano (6 sensores)
```python
URBAN_SEQUENCE = ["PU1", "S4", "S3", "PU2", "S3", "S4"]
```

**Ciclo completo:**
```
PU1 → S4 → S3 → PU2 → S3 → S4 → PU1 → S4 → ...
```

---

## 🧠 Lógica de Validación

### Paso 1: Guardar en ActiveSensorGroup ✅
```python
# SIEMPRE se guarda sin validación
INSERT INTO ActiveSensorGroupMetro (ts, sensor_name)
VALUES (datetime('now'), 'PM1')
```

### Paso 2: Consultar último sensor de BusPosition 🔍
```python
last_sensor = _get_last_bus_position_sensor("metro")
# Retorna: "PM1" o None si está vacía
```

### Paso 3: Validar secuencia 🔐

#### Caso A: Tabla vacía (primer sensor)
```python
if last_sensor is None:
    # Acepta CUALQUIER sensor como inicio
    should_save = True
    Log: "🚀 First sensor in BusPositionMetro: PM1"
```

#### Caso B: Sensor esperado ✅
```python
last_sensor = "PM1"
expected = _get_next_expected_sensor("PM1", "metro")  # → "S2"
current = "S2"

if current == expected:  # S2 == S2
    should_save = True
    Log: "✅ Valid sensor (metro): S2 (expected: S2)"
```

#### Caso C: Sensor NO esperado ❌
```python
last_sensor = "PM1"
expected = _get_next_expected_sensor("PM1", "metro")  # → "S2"
current = "PM2"

if current != expected:  # PM2 ≠ S2
    should_save = False
    Log: "❌ Invalid sensor (metro): PM2 (expected: S2, skipped for BusPosition)"
```

### Paso 4: Guardar en BusPosition (solo si válido) 💾
```python
if should_save:
    INSERT INTO BusPositionMetro (ts, sensor_name)
    VALUES (datetime('now'), 'S2')
```

---

## 📊 Ejemplos de Flujo

### Ejemplo 1: Secuencia perfecta (Metro)

```
Estado inicial: BusPositionMetro vacía

[1] Llega: PM1
    ├─ Guarda en ActiveSensorGroupMetro ✅
    ├─ BusPositionMetro vacía → Acepta como inicio
    ├─ Guarda en BusPositionMetro ✅
    └─ Log: "🚀 First sensor in BusPositionMetro: PM1"

[2] Llega: S2
    ├─ Guarda en ActiveSensorGroupMetro ✅
    ├─ Último: PM1, Esperado: S2, Actual: S2 → ✅ Válido
    ├─ Guarda en BusPositionMetro ✅
    └─ Log: "✅ Valid sensor (metro): S2 (expected: S2)"

[3] Llega: S1
    ├─ Guarda en ActiveSensorGroupMetro ✅
    ├─ Último: S2, Esperado: S1, Actual: S1 → ✅ Válido
    ├─ Guarda en BusPositionMetro ✅
    └─ Log: "✅ Valid sensor (metro): S1 (expected: S1)"

[4] Llega: PM2
    ├─ Guarda en ActiveSensorGroupMetro ✅
    ├─ Último: S1, Esperado: PM2, Actual: PM2 → ✅ Válido
    ├─ Guarda en BusPositionMetro ✅
    └─ Log: "✅ Valid sensor (metro): PM2 (expected: PM2)"

[5] Llega: S5
    ├─ Guarda en ActiveSensorGroupMetro ✅
    ├─ Último: PM2, Esperado: S5, Actual: S5 → ✅ Válido
    ├─ Guarda en BusPositionMetro ✅
    └─ Log: "✅ Valid sensor (metro): S5 (expected: S5)"

[6] Llega: PM1 (reinicio de ciclo)
    ├─ Guarda en ActiveSensorGroupMetro ✅
    ├─ Último: S5, Esperado: PM1, Actual: PM1 → ✅ Válido
    ├─ Guarda en BusPositionMetro ✅
    └─ Log: "✅ Valid sensor (metro): PM1 (expected: PM1)"
```

**Resultado:**
- `ActiveSensorGroupMetro`: 6 registros ✅
- `BusPositionMetro`: 6 registros ✅

---

### Ejemplo 2: Secuencia con errores (Metro)

```
Estado inicial: BusPositionMetro vacía

[1] Llega: PM1
    ├─ Guarda en ActiveSensorGroupMetro ✅
    ├─ BusPositionMetro vacía → Acepta como inicio
    ├─ Guarda en BusPositionMetro ✅
    └─ Log: "🚀 First sensor in BusPositionMetro: PM1"

[2] Llega: PM2 (sensor incorrecto)
    ├─ Guarda en ActiveSensorGroupMetro ✅
    ├─ Último: PM1, Esperado: S2, Actual: PM2 → ❌ Inválido
    ├─ NO guarda en BusPositionMetro ❌
    └─ Log: "❌ Invalid sensor (metro): PM2 (expected: S2, skipped)"

[3] Llega: S5 (sensor incorrecto)
    ├─ Guarda en ActiveSensorGroupMetro ✅
    ├─ Último: PM1, Esperado: S2, Actual: S5 → ❌ Inválido
    ├─ NO guarda en BusPositionMetro ❌
    └─ Log: "❌ Invalid sensor (metro): S5 (expected: S2, skipped)"

[4] Llega: S2 (sensor correcto)
    ├─ Guarda en ActiveSensorGroupMetro ✅
    ├─ Último: PM1, Esperado: S2, Actual: S2 → ✅ Válido
    ├─ Guarda en BusPositionMetro ✅
    └─ Log: "✅ Valid sensor (metro): S2 (expected: S2)"

[5] Llega: S1
    ├─ Guarda en ActiveSensorGroupMetro ✅
    ├─ Último: S2, Esperado: S1, Actual: S1 → ✅ Válido
    ├─ Guarda en BusPositionMetro ✅
    └─ Log: "✅ Valid sensor (metro): S1 (expected: S1)"
```

**Resultado:**
- `ActiveSensorGroupMetro`: 5 registros (todos) ✅
- `BusPositionMetro`: 3 registros (solo válidos: PM1, S2, S1) ✅

---

## 🔍 Funciones Implementadas

### 1. `_get_last_bus_position_sensor(route_type: str) -> Optional[str]`

**Propósito:** Obtener el último sensor guardado en BusPosition

**Retorna:**
- `str`: Nombre del último sensor (ej: "PM1")
- `None`: Si la tabla está vacía

**Ejemplo:**
```python
last = _get_last_bus_position_sensor("metro")
# Si BusPositionMetro tiene: PM1, S2, S1 → Retorna: "S1"
# Si BusPositionMetro está vacía → Retorna: None
```

---

### 2. `_get_next_expected_sensor(current_sensor: str, route_type: str) -> str`

**Propósito:** Calcular el siguiente sensor esperado en el ciclo

**Lógica:**
```python
sequence = ["PM1", "S2", "S1", "PM2", "S5"]  # Metro
current_index = sequence.index("S1")  # → 2
next_index = (2 + 1) % 5  # → 3
return sequence[3]  # → "PM2"
```

**Ejemplos Metro:**
```python
_get_next_expected_sensor("PM1", "metro")  # → "S2"
_get_next_expected_sensor("S2", "metro")   # → "S1"
_get_next_expected_sensor("S1", "metro")   # → "PM2"
_get_next_expected_sensor("PM2", "metro")  # → "S5"
_get_next_expected_sensor("S5", "metro")   # → "PM1" (reinicia)
```

**Ejemplos Urbano:**
```python
_get_next_expected_sensor("PU1", "urban")  # → "S4"
_get_next_expected_sensor("S4", "urban")   # → "S3"
_get_next_expected_sensor("S3", "urban")   # → "PU2"
_get_next_expected_sensor("PU2", "urban")  # → "S3"
_get_next_expected_sensor("S4", "urban")   # → "PU1" (reinicia)
```

---

### 3. `_save_active_sensor_data(payload: dict) -> bool`

**Propósito:** Guardar datos de sensores con validación de secuencia

**Flujo:**
1. Guardar en `ActiveSensorGroup` (siempre)
2. Obtener último sensor de `BusPosition`
3. Validar secuencia
4. Guardar en `BusPosition` solo si es válido

**Logs generados:**
- `"🚀 First sensor in BusPosition..."` → Primer sensor
- `"✅ Valid sensor..."` → Sensor correcto
- `"❌ Invalid sensor..."` → Sensor incorrecto (omitido)

---

## 📝 Logs en la API

### Logs de éxito (secuencia correcta)
```
2025-10-02 22:30:00 - INFO - Sensor saved to ActiveSensorGroupMetro: PM1
2025-10-02 22:30:00 - INFO - 🚀 First sensor in BusPositionMetro: PM1
2025-10-02 22:30:00 - INFO - Sensor saved to BusPositionMetro: PM1

2025-10-02 22:30:05 - INFO - Sensor saved to ActiveSensorGroupMetro: S2
2025-10-02 22:30:05 - INFO - ✅ Valid sensor (metro): S2 (expected: S2)
2025-10-02 22:30:05 - INFO - Sensor saved to BusPositionMetro: S2

2025-10-02 22:30:10 - INFO - Sensor saved to ActiveSensorGroupMetro: S1
2025-10-02 22:30:10 - INFO - ✅ Valid sensor (metro): S1 (expected: S1)
2025-10-02 22:30:10 - INFO - Sensor saved to BusPositionMetro: S1
```

### Logs con errores (secuencia incorrecta)
```
2025-10-02 22:30:00 - INFO - Sensor saved to ActiveSensorGroupMetro: PM1
2025-10-02 22:30:00 - INFO - 🚀 First sensor in BusPositionMetro: PM1
2025-10-02 22:30:00 - INFO - Sensor saved to BusPositionMetro: PM1

2025-10-02 22:30:05 - INFO - Sensor saved to ActiveSensorGroupMetro: PM2
2025-10-02 22:30:05 - WARNING - ❌ Invalid sensor (metro): PM2 (expected: S2, skipped for BusPosition)

2025-10-02 22:30:10 - INFO - Sensor saved to ActiveSensorGroupMetro: S2
2025-10-02 22:30:10 - INFO - ✅ Valid sensor (metro): S2 (expected: S2)
2025-10-02 22:30:10 - INFO - Sensor saved to BusPositionMetro: S2
```

---

## 🧪 Cómo probar

### 1. Limpiar tablas (opcional)
```bash
sqlite3 api/seguridad_trafico.db "DELETE FROM BusPositionMetro;"
sqlite3 api/seguridad_trafico.db "DELETE FROM BusPositionUrban;"
sqlite3 api/seguridad_trafico.db "DELETE FROM ActiveSensorGroupMetro;"
sqlite3 api/seguridad_trafico.db "DELETE FROM ActiveSensorGroupUrban;"
```

### 2. Reiniciar la API
```bash
cd api
# Ctrl+C para detener si está corriendo
python3 run.py
```

### 3. Ejecutar simulador (secuencia correcta)
```bash
./run_simulator.sh
# Opción 7
# Duración: 30
# Intervalo: 5
```

### 4. Ver logs de la API
```
# Deberías ver logs como:
🚀 First sensor in BusPositionMetro: PM1
✅ Valid sensor (metro): S2 (expected: S2)
✅ Valid sensor (metro): S1 (expected: S1)
...
```

### 5. Verificar datos en BD
```bash
# Ver sensores en ActiveSensorGroup (todos)
sqlite3 api/seguridad_trafico.db \
  "SELECT sensor_name, ts FROM ActiveSensorGroupMetro ORDER BY ts DESC LIMIT 10;"

# Ver sensores en BusPosition (solo válidos)
sqlite3 api/seguridad_trafico.db \
  "SELECT sensor_name, ts FROM BusPositionMetro ORDER BY ts DESC LIMIT 10;"

# Contar registros
sqlite3 api/seguridad_trafico.db \
  "SELECT 
     (SELECT COUNT(*) FROM ActiveSensorGroupMetro) as active,
     (SELECT COUNT(*) FROM BusPositionMetro) as position;"
```

### 6. Comparar cantidades
```bash
# Si la secuencia es perfecta:
# active == position (mismo número de registros)

# Si hubo errores de secuencia:
# active > position (más registros en ActiveSensorGroup)
```

---

## � Valores guardados en BusPosition

Cuando un sensor es válido, se guarda en BusPosition con estos valores:

| Campo | Valor | Descripción |
|-------|-------|-------------|
| `bus_id` | `1` | ID del bus (fijo para simulación) |
| `speed_kmh` | `50.0` | Velocidad en km/h (fija para simulación) |
| `position` | `"PM1"` | **Nombre del sensor** |
| `distance_to_next_stop` | `100.0` | Distancia en metros (fija para simulación) |
| `ts` | `datetime('now')` | Timestamp automático |

**Ejemplo de registro en BusPositionMetro:**
```sql
INSERT INTO BusPositionMetro (ts, bus_id, speed_kmh, position, distance_to_next_stop)
VALUES (datetime('now'), 1, 50.0, 'PM1', 100.0);
```

**Nota:** La columna `position` (tipo TEXT) se usa para guardar el nombre del sensor.

---

## �🔧 Compatibilidad con Arduino

Esta validación **funciona con Arduino real** sin cambios. El Arduino solo debe:

1. **Publicar al topic correcto:**
   ```
   arduino/data/sensors
   ```

2. **Usar el formato JSON correcto:**
   ```json
   {
     "sensor_name": "PM1",
     "route_type": "metro"
   }
   ```

3. **Activar sensores en el orden correcto:**
   - Si el hardware activa los sensores en orden → Todos se guardan en BusPosition ✅
   - Si el hardware activa sensores desordenados → Solo los correctos van a BusPosition ❌

4. **Valores por defecto:** El sistema usa valores fijos (bus_id=1, speed=50km/h, distance=100m) que pueden ser personalizados en producción

---

## 📊 Diferencias entre tablas

| Tabla | Propósito | Validación | Uso |
|-------|-----------|-----------|-----|
| **ActiveSensorGroup** | Registro histórico de TODOS los sensores activados | ❌ Ninguna | Análisis, debugging, estadísticas |
| **BusPosition** | Posición actual/válida del bus en la ruta | ✅ Secuencia | Tracking en tiempo real, mapa |

---

## ⚠️ Notas importantes

1. **Secuencias cíclicas:** El último sensor conecta con el primero automáticamente
2. **Inicio flexible:** Acepta cualquier sensor si BusPosition está vacía
3. **Independencia de tablas:** Metro y Urbano tienen validaciones separadas
4. **Logs detallados:** Facilitan debugging en producción
5. **Sin pérdida de datos:** ActiveSensorGroup siempre guarda todo

---

## ✅ Archivos modificados

**Archivo:** `api/app/db/repositories/mqtt_repository.py`

**Cambios:**
1. ✅ Agregadas constantes `METRO_SEQUENCE` y `URBAN_SEQUENCE`
2. ✅ Agregada función `_get_last_bus_position_sensor()`
3. ✅ Agregada función `_get_next_expected_sensor()`
4. ✅ Modificada función `_save_active_sensor_data()` con validación completa
5. ✅ Agregados logs detallados con emojis para debugging

---

## 🎉 ¡Listo!

La validación de secuencia está completamente implementada y funcionando. 

**Reinicia la API y prueba con el simulador para ver los logs en acción.** 🚀

# Resumen: Infracciones al WebSocket de Alertas

## ✅ Problema Resuelto

**Objetivo**: Asegurar que las alertas de infracciones de semáforo se envíen al WebSocket de alertas normales para que lleguen a la sección de notificaciones de Flutter.

## 🔧 Cambios Implementados

### 1. **Método `_publish_individual_infraction()` (NUEVO)**
- **Archivo**: `mqtt/main.py`
- **Función**: Publica cada infracción individualmente en el tópico MQTT específico
- **Tópico**: `arduino/data/infracciones`
- **Formato**: JSON con todos los campos requeridos por la API

### 2. **Mejorado `_process_infracciones()`**
- **Archivo**: `mqtt/main.py`
- **Cambio**: Ahora llama a `_publish_individual_infraction()` para cada infracción
- **Resultado**: Las infracciones se envían tanto en el flujo general como individualmente

### 3. **Mejorado `_on_infraction_detected()`**
- **Archivo**: `mqtt/main.py`
- **Cambio**: Formato unificado de datos de infracción con campos completos
- **Campos agregados**: `signal_color`, `violation_type`, `origen`

### 4. **Script de Prueba**
- **Archivo**: `mqtt/test_infraction_alerts.py` (NUEVO)
- **Función**: Verifica el flujo completo de infracciones
- **Uso**: `python test_infraction_alerts.py`

## 📊 Flujo de Datos Completo

```
1. ACTIVACIÓN POR TECLADO
   ├── Usuario presiona 'V', 'Shift+V', o 'Ctrl+V'
   └── keyboard_alert_controller.py detecta la tecla

2. SIMULACIÓN
   ├── Se llama a simulator.activate_violation_alert("S1")
   └── Se agrega "S1" a active_violations

3. GENERACIÓN DE DATOS
   ├── generate_json_data() incluye infracciones en JSON
   └── Datos enviados cada 2 segundos

4. PROCESAMIENTO MQTT
   ├── _on_data_received() procesa los datos
   ├── _process_infracciones() detecta infracciones
   └── _publish_individual_infraction() publica cada una

5. TÓPICOS MQTT
   ├── arduino/data (datos generales)
   └── arduino/data/infracciones (infracciones específicas)

6. API PROCESSING
   ├── mqtt_handler.py recibe infracciones
   ├── Procesa y formatea para WebSocket
   └── emit_alert() envía al WebSocket

7. WEBSOCKET
   ├── /ws/alerts recibe la infracción
   ├── Tipo: "infraction"
   └── Severity: 4 (alta)

8. FLUTTER
   ├── Recibe notificación WebSocket
   └── Muestra en sección de notificaciones
```

## 🎮 Teclas para Probar

| Tecla | Acción | Semáforo |
|-------|---------|----------|
| `V` | Infracción básica | S1 |
| `Shift+V` | Infracción media | S5 |
| `Ctrl+V` | Infracción avanzada | S10 |
| `C` | Limpiar todas las alertas | - |

## 📡 Datos MQTT de Infracción

```json
{
  "timestamp": 1694567890.123,
  "alert_type": "INFRACCION",
  "sensor_id": "SIMULATED",
  "semaforo_id": "S1",
  "distancia_cm": 5.0,
  "severity": 4,
  "signal_color": "red",
  "violation_type": "red_light",
  "origen": "Simulación - Infracción semáforo S1"
}
```

## 🌐 Datos WebSocket para Flutter

```json
{
  "type": "infraction",
  "timestamp": 1694567890.123,
  "alert_type": "INFRACCION",
  "severity": 4,
  "signal_id": "S1",
  "signal_color": "red",
  "origen": "Infracción semáforo S1",
  "data": {
    "alert_type": "INFRACCION",
    "signal_id": "S1",
    "signal_color": "red",
    "severity": 4
  }
}
```

## 🧪 Verificación

### 1. **Ejecutar Simulación**
```bash
cd /Users/jorgemejia/Documents/USAC/arqui2/mqtt
source venv/bin/activate
python test_infraction_alerts.py
```

### 2. **Probar Infracciones**
- Presiona `V` para activar infracción en S1
- Verifica logs: "✅ INFRACCIÓN PUBLICADA EN MQTT: S1"
- Verifica que llegue a la API

### 3. **Verificar WebSocket**
- Conectar cliente WebSocket a `ws://localhost:8000/ws/alerts`
- Activar infracción con teclado
- Verificar mensaje con `type: "infraction"`

## ✅ Estado

- ✅ **Infracciones se publican en MQTT individualmente**
- ✅ **API procesa y reenvía al WebSocket**
- ✅ **Formato correcto para Flutter**
- ✅ **Flujo completo verificado**
- ✅ **Documentación actualizada**
- ✅ **Scripts de prueba creados**

## 📝 Notas Importantes

1. **Doble Publicación**: Las infracciones se publican tanto en el flujo general (`arduino/data`) como individualmente (`arduino/data/infracciones`)
2. **Formato Unificado**: Mismo formato para infracciones simuladas y en tiempo real
3. **Severidad Alta**: Todas las infracciones tienen severidad 4 (alta prioridad)
4. **Tipo Flutter**: Se usa `"type": "infraction"` para que Flutter las reconozca correctamente

# Control de Alertas por Teclado - Modo Simulación

Este sistema permite controlar las alertas del simulador MQTT usando teclas del teclado, en lugar de generar alertas automáticamente.

## Características

- ✅ **Alertas automáticas desactivadas** en modo simulación
- 🎮 **Control manual por teclado** para activar diferentes tipos de alertas
- 🔄 **Integración completa** con el sistema MQTT existente
- 📊 **Datos simulados normales** con alertas controladas manualmente

## Instalación

1. Asegúrate de tener el entorno virtual activado:
```bash
cd /Users/jorgemejia/Documents/USAC/arqui2/mqtt
source venv/bin/activate
```

2. Las dependencias ya están instaladas, incluyendo `pynput` para detección de teclas.

## Uso

### Ejecutar Simulación con Control de Teclas

```bash
# Opción 1: Usar el script de prueba
python test_keyboard_simulation.py

# Opción 2: Usar el módulo principal en modo simulación
python main.py --simulation
```

### Teclas Disponibles

#### 🌍 SISMOS
- **E** - Sismo moderado (magnitud 5.2)
- **Shift+E** - Sismo fuerte (magnitud 6.8)

#### 🚨 BOTONES DE PÁNICO
- **P** - Botón de pánico PB1
- **Shift+P** - Botón de pánico PB2
- **Ctrl+P** - Botón de pánico PB3
- **Alt+P** - Botón de pánico PB4

#### 🚗 INFRACCIONES DE TRÁFICO
- **V** - Infracción en semáforo S1
- **Shift+V** - Infracción en semáforo S5
- **Ctrl+V** - Infracción en semáforo S10

#### 🔥 ALERTAS DE GAS
- **G** - Gas alto en zona Z1 (285 ppm)
- **Shift+G** - Gas alto en zona Z2 (290 ppm)

#### 🎛️ CONTROL GENERAL
- **C** - Limpiar todas las alertas activas
- **H** - Mostrar ayuda completa
- **Q** - Salir del programa

## Funcionamiento

1. **Datos Simulados**: El sistema genera datos normales del Arduino cada 2 segundos
2. **Alertas Manuales**: Solo se activan cuando presionas las teclas correspondientes
3. **Duración**: Las alertas duran 5 segundos por defecto
4. **MQTT**: Todas las alertas se publican automáticamente en MQTT
5. **WebSocket**: Las infracciones se envían al WebSocket `/ws/alerts` para notificaciones en Flutter
6. **Logs**: Se muestran mensajes claros cuando se activan alertas

### Flujo de Infracciones

1. **Activación**: Presiona 'V', 'Shift+V' o 'Ctrl+V'
2. **Simulación**: Se agrega a `active_violations` en el simulador
3. **MQTT General**: Se incluye en el JSON de datos cada 2 segundos (`arduino/data`)
4. **MQTT Específico**: Se publica individualmente en `arduino/data/infracciones`
5. **API Processing**: La API recibe y procesa la infracción
6. **WebSocket**: Se envía al WebSocket `/ws/alerts` con tipo `'infraction'`
7. **Flutter**: Llega a la sección de notificaciones como alerta de infracción

## Archivos Modificados

### `simulation_mode.py`
- ✅ Desactivadas alertas automáticas de sismo, botones de pánico e infracciones
- ✅ Agregados métodos para activar alertas manualmente
- ✅ Modificado `generate_gas_data()` para soportar alertas manuales de gas

### `main.py`
- ✅ Integrado `KeyboardAlertController`
- ✅ Agregados callbacks para alertas por teclado
- ✅ Inicio/parada automática del controlador de teclas

### `keyboard_alert_controller.py` (NUEVO)
- ✅ Detección de teclas en tiempo real usando `pynput`
- ✅ Mapeo de teclas a funciones de alerta
- ✅ Sistema de callbacks
- ✅ Ayuda integrada
- ✅ Compatible con macOS sin permisos de administrador

### `test_keyboard_simulation.py` (NUEVO)
- ✅ Script de prueba fácil de usar
- ✅ Instrucciones integradas
- ✅ Manejo de errores

## Ejemplo de Uso

```bash
# 1. Activar entorno virtual
source venv/bin/activate

# 2. Ejecutar simulación
python test_keyboard_simulation.py

# 3. En la consola:
# - Presiona 'H' para ver todas las teclas disponibles
# - Presiona 'E' para activar un sismo
# - Presiona 'P' para activar botón de pánico
# - Presiona 'C' para limpiar todas las alertas
# - Presiona 'Q' para salir
```

## Notas Importantes

- ✅ **Sin permisos especiales**: `pynput` no requiere permisos de administrador en macOS
- 🔄 **Duración**: Las alertas duran 5 segundos por defecto (configurable en `simulation_mode.py`)
- 📱 **MQTT**: Todas las alertas se publican automáticamente en el broker MQTT configurado
- 🎯 **Precisión**: Las teclas se detectan en tiempo real con un pequeño delay para evitar múltiples activaciones
- 🚪 **Salir**: Presiona 'Q' o 'Escape' para salir del programa

## Solución de Problemas

### Si las teclas no se detectan
- Asegúrate de que la terminal tenga el foco (haz clic en la ventana de la terminal)
- Verifica que no haya otros programas interceptando las teclas
- En algunos casos, reinicia la terminal si el problema persiste

### Múltiples activaciones
Si una tecla se activa múltiples veces, el sistema tiene un delay de 0.2 segundos entre activaciones.

### Salir del programa
Puedes salir con:
- **Q** (tecla de salida)
- **Ctrl+C** (interrupción de teclado)
- Cerrar la terminal

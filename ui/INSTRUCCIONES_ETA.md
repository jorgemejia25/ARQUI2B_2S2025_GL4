# Instrucciones para Probar la Funcionalidad ETA

## Problema Identificado
El Arduino no estaba enviando los datos ETA en el JSON principal, solo en líneas separadas. Esto causaba que la interfaz no recibiera los datos ETA en modo serial.

## Solución Implementada

### 1. Modificación del Arduino (`arduino/main/main.ino`)
- Se agregó el campo `"eta"` al JSON que se envía cada 2 segundos
- Los datos ETA ahora se incluyen en el formato correcto dentro del JSON principal
- Se actualizó la versión del protocolo a "1.1"

### 2. Formato de Datos ETA en Arduino
```json
{
  "eta": {
    "P1": "TU,ETA_S=45,FROM=Centro,TO=P1",
    "P2": "TU,ETA_S=120,FROM=Zona1,TO=P2",
    "P3": "M,ETA_S=30,FROM=Estacion1,TO=P3",
    "P4": "M,ETA_S=180,FROM=Estacion2,TO=P4",
    "P5": "TU,ETA_S=90,FROM=Zona2,TO=P5",
    "P6": "M,ETA_S=240,FROM=Estacion3,TO=P6"
  }
}
```

## Cómo Probar

### Opción 1: Con Arduino Real
1. **Subir el código modificado** al Arduino:
   ```bash
   cd arduino/main/
   # Subir main.ino al Arduino
   ```

2. **Conectar Arduino** y verificar que envía datos JSON con campo `eta`

3. **Ejecutar Processing** y verificar que recibe datos ETA en modo serial

### Opción 2: Con Simulador Python
1. **Ejecutar el simulador**:
   ```bash
   cd ui/
   python3 test_eta_serial.py
   ```

2. **Redirigir salida** a un puerto serial virtual o usar como entrada para Processing

### Opción 3: Modo Simulación en Processing
1. **Ejecutar Processing** en modo simulación
2. **Presionar 'M'** para cambiar entre modos
3. **Verificar** que los datos ETA aparecen en la pantalla de distancias

## Verificación

### En la Pantalla de Distancias
- ✅ **Tarjetas de parada**: Deben mostrar ETA con formato legible
- ✅ **Colores**: Verde (próximo), Naranja (en ruta), Gris (lejano)
- ✅ **Mapa urbano**: Paradas deben mostrar información ETA
- ✅ **Panel de resumen**: Debe mostrar "ETAs disponibles: X/6"

### En la Consola de Processing
- ✅ **Mensajes**: Debe mostrar "JSON aplicado" con datos ETA
- ✅ **Estado**: Debe mostrar "Datos Reales" cuando recibe datos serial

### Controles de Debug
- **'C'**: Mostrar estado detallado del sistema
- **'M'**: Cambiar entre modo simulado y real
- **'S'**: Activar/desactivar simulación
- **'T'**: Reset timeout de serial

## Troubleshooting

### Si no aparecen datos ETA:
1. **Verificar conexión serial**: Presionar 'C' para ver estado
2. **Verificar formato JSON**: Los datos deben incluir campo `"eta"`
3. **Verificar procesamiento**: Revisar consola de Processing

### Si hay errores de parsing:
1. **Verificar formato ETA**: Debe ser `M,ETA_S=30,FROM=x,TO=y`
2. **Verificar JSON válido**: Usar validador JSON online
3. **Revisar logs**: Consola de Processing muestra errores

## Archivos Modificados
- `arduino/main/main.ino`: Agregado campo ETA al JSON
- `ui/DataProvider.pde`: Procesamiento de datos ETA
- `ui/DistanceScreen.pde`: Visualización de ETA
- `ui/test_eta_serial.py`: Simulador para pruebas
- `ui/example_serial_message.json`: Ejemplo actualizado
- `ui/eta_example.json`: Ejemplo específico de ETA

## Resultado Esperado
Al completar las pruebas, la interfaz debe mostrar:
- Tiempo de llegada estimado en cada parada
- Indicadores visuales de proximidad
- Información estadística de ETAs
- Actualización en tiempo real desde Arduino

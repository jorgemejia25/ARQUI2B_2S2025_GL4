# Funcionalidad ETA (Tiempo de Llegada Estimado)

## Descripción
Se ha implementado la funcionalidad de ETA (Estimated Time of Arrival) en la interfaz de monitoreo de distancias. Esta funcionalidad permite mostrar el tiempo estimado de llegada de los buses a cada parada de transporte.

## Formato de Datos ETA

### Desde Arduino
El Arduino debe enviar los datos ETA en el siguiente formato JSON:

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

### Formato de String ETA
Cada entrada ETA sigue el formato: `M,ETA_S,FROM=x,TO=y,<seg> | TU,ETA_S,FROM=x`

- **M**: Metro
- **TU**: Transurbano
- **ETA_S**: Tiempo estimado en segundos
- **FROM**: Punto de origen
- **TO**: Punto de destino (opcional)

### Ejemplos de Formato
- `TU,ETA_S=45,FROM=Centro,TO=P1` - Transurbano llegando en 45 segundos desde Centro a P1
- `M,ETA_S=120,FROM=Estacion1` - Metro llegando en 2 minutos desde Estacion1
- `TU,ETA_S=30,FROM=Zona1,TO=P2` - Transurbano llegando en 30 segundos desde Zona1 a P2

## Visualización en la Interfaz

### En las Tarjetas de Parada
- **ETA**: Muestra el tiempo de llegada en formato legible (ej: "45s", "2:30")
- **Status**: Indica el estado del bus:
  - **Próximo**: < 60 segundos (verde)
  - **En ruta**: 60-180 segundos (naranja)
  - **Lejano**: > 180 segundos (gris)
- **Tipo**: Muestra si es Metro o Transurbano

### En el Mapa Urbano
- Las paradas muestran la información ETA debajo de la distancia
- Formato compacto para ahorrar espacio

### En el Panel de Resumen
- **ETAs disponibles**: Número de paradas con datos ETA
- **ETA promedio**: Tiempo promedio de llegada de todos los buses

## Procesamiento Automático

### En DataProvider
- Los datos ETA se procesan automáticamente cuando llegan del Arduino
- Se convierten de string a objeto JSON estructurado
- Se calcula automáticamente el status basado en el tiempo
- Se manejan errores de formato graciosamente

### Datos Simulados
- En modo simulación, se generan ETAs aleatorios entre 30 segundos y 5 minutos
- Se asignan tipos de transporte según la parada (P1-P2: Transurbano, P3-P6: Metro)

## Integración con el Sistema Existente

### Compatibilidad
- Totalmente compatible con el sistema existente
- No afecta otras funcionalidades
- Fallback graceful si no hay datos ETA

### Actualización en Tiempo Real
- Los ETAs se actualizan junto con las distancias
- Se reflejan cambios inmediatamente en la interfaz
- Mantiene sincronización con datos del Arduino

## Archivos Modificados

1. **DataProvider.pde**: Agregado manejo de datos ETA
2. **DistanceScreen.pde**: Integrada visualización de ETA
3. **example_serial_message.json**: Actualizado con formato ETA
4. **eta_example.json**: Nuevo archivo de ejemplo

## Uso

### Para el Arduino
Enviar datos ETA en el campo `eta` del JSON:

```json
{
  "ts": "2025-01-27T15:30:45Z",
  "dist_cm": { "P1": 85, "P2": 40, ... },
  "eta": {
    "P1": "TU,ETA_S=45,FROM=Centro,TO=P1",
    "P2": "TU,ETA_S=120,FROM=Zona1,TO=P2"
  }
}
```

### Para el Usuario
- Los ETAs se muestran automáticamente en la pantalla de distancias
- No requiere configuración adicional
- Se actualiza en tiempo real con los datos del Arduino

## Notas Técnicas

- **Formato de tiempo**: Se muestra en segundos si < 60s, en formato MM:SS si ≥ 60s
- **Colores**: Verde (próximo), Naranja (en ruta), Gris (lejano)
- **Error handling**: Muestra "Sin datos ETA" si no hay información disponible
- **Performance**: Procesamiento eficiente sin impacto en rendimiento

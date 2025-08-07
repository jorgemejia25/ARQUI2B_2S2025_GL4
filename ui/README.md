# Sistema Inteligente de Seguridad y Gestión de Tráfico Urbano

### Compilar y ejecutar
```bash
# Comando relativo (desde la carpeta del proyecto)
processing-java --sketch=ui --run
```

### Formato JSON
```json
{
  "ts": "2025-08-07T14:42:11Z",
  "semaforos": {
    "S1": "ROJO",
    "S2": "VERDE", 
    "S3": "AMARILLO",
    "S4": "VERDE",
    "S5": "ROJO",
    "S6": "VERDE",
    "S7": "AMARILLO",
    "S8": "ROJO",
    "S9": "VERDE",
    "S10": "AMARILLO"
  },
  "dist_cm": {
    "P1": 38,
    "P2": 112,
    "P3": 250,
    "P4": 89,
    "P5": 156,
    "P6": 203
  },
  "gas_ppm": {
    "Z1": 165,
    "Z2": 180,
    "Z3": 175
  },
  "panico": {
    "Z1": 0,
    "Z2": 1,
    "Z3": 0
  },
  "infracciones": ["P1", "P3"]
}
```


# Configuración de APIs Duales

El sistema de módulos de IA ahora soporta el envío de datos a dos APIs diferentes simultáneamente.

## Variables de Entorno

### API Principal (obligatoria)
```bash
API_PRIMARY_URL=http://localhost:8001
```

### API Secundaria (opcional)
```bash
API_SECONDARY_URL=http://localhost:8002
```

### Habilitar APIs Duales
```bash
USE_DUAL_APIS=true
```

## Ejemplos de Configuración

### 1. Solo API Primaria
```bash
export API_PRIMARY_URL=http://localhost:8001
export USE_DUAL_APIS=false
```

### 2. APIs Duales (Local)
```bash
export API_PRIMARY_URL=http://localhost:8001
export API_SECONDARY_URL=http://localhost:8002
export USE_DUAL_APIS=true
```

### 3. APIs en Diferentes Servidores
```bash
export API_PRIMARY_URL=http://api1.ejemplo.com
export API_SECONDARY_URL=http://api2.ejemplo.com
export USE_DUAL_APIS=true
```

## Comportamiento

- **API Primaria**: Siempre se intenta enviar (obligatoria)
- **API Secundaria**: Solo se envía si está configurada y `USE_DUAL_APIS=true`
- **Éxito**: Se considera exitoso si al menos la API primaria responde correctamente
- **Logs**: Se muestran logs separados para cada API (Primary/Secondary)

## Módulos Afectados

- **Face Recognition**: Envía eventos de blacklist a ambas APIs
- **Weapon Detection**: Envía detecciones de armas a ambas APIs  
- **Plate Detection**: Envía eventos de placas a ambas APIs

## Ejecución

```bash
# Con variables de entorno
export API_PRIMARY_URL=http://localhost:8001
export API_SECONDARY_URL=http://localhost:8002
export USE_DUAL_APIS=true
python -m ia_modules.run

# O directamente en la línea de comandos
API_PRIMARY_URL=http://localhost:8001 API_SECONDARY_URL=http://localhost:8002 USE_DUAL_APIS=true python -m ia_modules.run
```

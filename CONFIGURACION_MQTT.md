# Configuración MQTT con Variables de Entorno

Este proyecto ahora utiliza variables de entorno para la configuración MQTT, lo que permite mayor flexibilidad y seguridad.

## Configuración Requerida

Crea un archivo `.env` en la raíz del proyecto con las siguientes variables:

```bash
# Configuración MQTT
MQTT_BROKER=trolley.proxy.rlwy.net
MQTT_PORT=55424
MQTT_USERNAME=jorge
MQTT_PASSWORD=34eikykmbd8w5igpjiebialeisx0yu02
MQTT_TOPIC=arduino/data

# Configuración adicional MQTT (opcional)
MQTT_CLIENT_ID_PREFIX=arduino
MQTT_KEEPALIVE=60
MQTT_QOS=0

# Configuración del servidor API
SERVER_HOST=0.0.0.0
SERVER_PORT=8001

# Configuración de logging
LOG_LEVEL=INFO
```

## Variables de Entorno Explicadas

### MQTT_BROKER
- **Descripción**: Dirección del broker MQTT
- **Valor por defecto**: `localhost`
- **Ejemplo**: `trolley.proxy.rlwy.net`

### MQTT_PORT
- **Descripción**: Puerto del broker MQTT
- **Valor por defecto**: `1883`
- **Ejemplo**: `55424`

### MQTT_USERNAME
- **Descripción**: Nombre de usuario para autenticación MQTT
- **Valor por defecto**: `""` (vacío)
- **Ejemplo**: `jorge`

### MQTT_PASSWORD
- **Descripción**: Contraseña para autenticación MQTT
- **Valor por defecto**: `""` (vacío)
- **Ejemplo**: `34eikykmbd8w5igpjiebialeisx0yu02`

### MQTT_TOPIC
- **Descripción**: Tópico MQTT para publicar/suscribirse
- **Valor por defecto**: `arduino/data`
- **Ejemplo**: `arduino/data`

### MQTT_CLIENT_ID_PREFIX
- **Descripción**: Prefijo para los IDs de cliente MQTT
- **Valor por defecto**: `arduino`
- **Ejemplo**: `arduino`

### MQTT_KEEPALIVE
- **Descripción**: Tiempo de keepalive en segundos
- **Valor por defecto**: `60`
- **Ejemplo**: `60`

### MQTT_QOS
- **Descripción**: Nivel de calidad de servicio (0, 1, o 2)
- **Valor por defecto**: `0`
- **Ejemplo**: `0`

## Archivos Modificados

Los siguientes archivos han sido actualizados para usar variables de entorno:

### Módulo MQTT
1. **mqtt/main.py** - Controlador principal MQTT
2. **mqtt/arduino_mqtt_publisher.py** - Publicador de datos simulados
3. **mqtt/test_mqtt.py** - Cliente de prueba MQTT
4. **mqtt/mqtt_config.py** - Configuración centralizada (nuevo)

### Módulo API
5. **api/config.py** - Configuración del API con credenciales MQTT
6. **api/mqtt_handler.py** - Manejador MQTT con autenticación
7. **api/test_mqtt_connection.py** - Script de prueba para conexión MQTT (nuevo)

## Instalación de Dependencias

Asegúrate de instalar las dependencias actualizadas:

```bash
# Para el módulo MQTT
cd mqtt
pip install -r requirements.txt

# Para el módulo API
cd ../api
pip install -r requirements.txt
```

## Uso

### Verificar Configuración

Puedes verificar la configuración MQTT ejecutando:

```bash
# Para el módulo MQTT
cd mqtt
python mqtt_config.py

# Para el módulo API
cd ../api
python test_mqtt_connection.py
```

### Ejecutar con Configuración Personalizada

Los archivos ahora cargarán automáticamente las variables de entorno desde el archivo `.env`. Si no existe el archivo `.env`, usarán los valores por defecto.

### Ejemplo de Uso en Código

```python
from mqtt_config import MQTT_BROKER, MQTT_PORT, MQTT_USERNAME, MQTT_PASSWORD

# O usar la función de configuración completa
from mqtt_config import get_mqtt_config
config = get_mqtt_config()
```

## Seguridad

- **Nunca** commits el archivo `.env` al repositorio
- El archivo `.env` está incluido en `.gitignore`
- Usa el archivo `.env.example` como plantilla
- Mantén las credenciales seguras y no las compartas públicamente

## Troubleshooting

### Error: "No module named 'dotenv'"
```bash
pip install python-dotenv
```

### Error de conexión MQTT
1. Verifica que las credenciales sean correctas
2. Confirma que el broker esté disponible
3. Revisa la configuración de firewall
4. Usa `python mqtt_config.py` para verificar la configuración

### Problemas específicos del API

#### Error de autenticación MQTT en el API
```bash
# Probar la conexión del API
cd api
python test_mqtt_connection.py
```

#### El API no recibe datos MQTT
1. Verifica que el broker MQTT esté funcionando
2. Confirma que las credenciales sean correctas
3. Revisa que el tópico sea el correcto (`arduino/data`)
4. Asegúrate de que haya datos siendo publicados

#### El API no se conecta al broker
1. Verifica la conectividad de red
2. Confirma que el puerto esté abierto
3. Revisa los logs del API para errores específicos
4. Usa el script de prueba para diagnosticar

### Logs del API
Para ver los logs detallados del API:
```bash
cd api
python main.py
```

Los logs mostrarán:
- Estado de conexión MQTT
- Mensajes recibidos
- Errores de autenticación
- Problemas de WebSocket

# Documentación WebSocket - API IoT

## 📋 **Descripción General**

El API IoT implementa WebSockets para proporcionar actualizaciones en tiempo real de eventos IoT, incluyendo paradas, semáforos y alertas generales. Los WebSockets permiten a los clientes recibir notificaciones instantáneas sin necesidad de polling.

## 🔌 **Endpoints WebSocket Disponibles**

### 1. **Paradas (Stops)**
- **URL Local**: `ws://localhost:8001/ws/stops`
- **URL Remota**: `ws://192.168.1.181:8001/ws/stops`
- **Propósito**: Recibir actualizaciones de eventos en paradas de buses
- **Tipo de conexión**: `stops`

### 2. **Semáforos (Traffic)**
- **URL Local**: `ws://localhost:8001/ws/traffic`
- **URL Remota**: `ws://192.168.1.181:8001/ws/traffic`
- **Propósito**: Recibir actualizaciones de infracciones y estado de semáforos
- **Tipo de conexión**: `traffic`

### 3. **Alertas (Alerts)**
- **URL Local**: `ws://localhost:8001/ws/alerts`
- **URL Remota**: `ws://192.168.1.181:8001/ws/alerts`
- **Propósito**: Recibir todas las alertas del sistema (gas, sismos, etc.)
- **Tipo de conexión**: `alerts`

## 📡 **Formato de Datos Recibidos**

### **Estructura Base de Mensajes**
Todos los mensajes WebSocket siguen esta estructura:
```json
{
  "type": "tipo_mensaje",
  "timestamp": 1234567890.123,
  "data": {
    // Datos específicos del mensaje
  }
}
```

### **Tipos de Mensajes**

#### 1. **Mensaje de Conexión**
```json
{
  "type": "connection_established",
  "connection_type": "stops|traffic|alerts",
  "message": "Conexión WebSocket establecida"
}
```

#### 2. **Actualización de Parada**

**Descripción:** Información sobre paradas de buses, incluyendo botones de pánico activos y ETAs de transporte.

##### **2.1 Botón de Pánico**
```json
{
  "type": "stop_update",
  "timestamp": 1234567890.123,
  "data": {
    "stop_id": "PARADA_001",
    "event_type": "panic_button",
    "button_id": 2,
    "severity": 3,
    "timestamp": "2025-09-03T13:45:00Z",
    "data": {
      "alert_type": "PANICO",
      "stop_id": "PARADA_001",
      "button_id": 2,
      "severity": 3
    }
  }
}
```

##### **2.2 Actualización de ETA (Tiempo de Llegada)**

**NUEVO**: Información sobre buses que están en camino a las paradas, incluyendo tiempo estimado de llegada.

```json
{
  "type": "stop_update",
  "timestamp": 1234567890.123,
  "data": {
    "stop_id": "P3",
    "event_type": "eta_update",
    "eta_info": {
      "tipo_transporte": "Transurbano",
      "tiempo_segundos": 193,
      "origen": "Centro",
      "info": "TU,ETA_S=193,FROM=Centro,TO=P3"
    },
    "data": {
      "alert_type": "ETA_UPDATE",
      "stop_id": "P3",
      "tipo_transporte": "Transurbano",
      "tiempo_segundos": 193,
      "origen": "Centro",
      "severity": 1
    }
  }
}
```

**Campos del ETA:**
- `tipo_transporte`: "Transurbano" o "Transmetro"
- `tiempo_segundos`: Tiempo estimado de llegada en segundos
- `origen`: Punto de origen del transporte (ej: "Centro", "Estación Norte")
- `info`: String completo con información del ETA

#### 3. **Actualización de Semáforo**

**NUEVO**: Ahora se emiten actualizaciones para todos los colores de semáforos (rojo, amarillo, verde).

##### **Colores de Semáforos Soportados**
- **`"red"`**: Semáforo en rojo (infracción)
- **`"yellow"`**: Semáforo en amarillo (actualización)
- **`"green"`**: Semáforo en verde (actualización)

##### **Tipos de Violación**
- **`"red_light"`**: Solo para semáforos en rojo (infracción)
- **`"signal_update"`**: Para semáforos en amarillo o verde (actualización normal)

##### **Ejemplos de Diferentes Estados**

**Semáforo en Rojo (Infracción):**
```json
{
  "type": "traffic_update",
  "timestamp": 1234567890.123,
  "data": {
    "signal_id": "S1",
    "signal_color": "red",
    "violation_type": "red_light",
    "data": {
      "alert_type": "INFRACCION",
      "signal_id": "S1",
      "signal_color": "red",
      "severity": 3
    }
  }
}
```

**Semáforo en Amarillo (Actualización):**
```json
{
  "type": "traffic_update",
  "timestamp": 1234567890.123,
  "data": {
    "signal_id": "S3",
    "signal_color": "yellow",
    "violation_type": "signal_update",
    "data": {
      "alert_type": "SIGNAL_UPDATE",
      "signal_id": "S3",
      "signal_color": "yellow",
      "severity": 1
    }
  }
}
```

**Semáforo en Verde (Actualización):**
```json
{
  "type": "traffic_update",
  "timestamp": 1234567890.123,
  "data": {
    "signal_id": "S5",
    "signal_color": "green",
    "violation_type": "signal_update",
    "data": {
      "alert_type": "SIGNAL_UPDATE",
      "signal_id": "S5",
      "signal_color": "green",
      "severity": 1
    }
  }
}
```

#### 4. **Alerta General**
```json
{
  "type": "alert",
  "timestamp": 1234567890.123,
  "data": {
    "alert_type": "GAS_ALERT|SEISMIC_ALERT|INFRACCION|PANICO|SIGNAL_UPDATE",
    "severity": 3,
    "timestamp": "2025-09-03T13:46:00Z",
    "data": {
      // Datos específicos de la alerta
    }
  }
}
```

## 🚀 **Ejemplos de Implementación**

### **JavaScript (Navegador)**
```javascript
// Conectar a WebSocket de Paradas (desde computadora remota)
const stopsSocket = new WebSocket('ws://192.168.1.181:8001/ws/stops');

stopsSocket.onopen = function(event) {
    console.log('Conectado a WebSocket de Paradas');
};

stopsSocket.onmessage = function(event) {
    const data = JSON.parse(event.data);
    console.log('Mensaje recibido:', data);
    
    if (data.type === 'stop_update') {
        handleStopUpdate(data.data);
    }
};

stopsSocket.onclose = function(event) {
    console.log('Conexión WebSocket cerrada');
};

stopsSocket.onerror = function(error) {
    console.error('Error WebSocket:', error);
};

function handleStopUpdate(stopData) {
    console.log(`Evento en parada ${stopData.stop_id}: ${stopData.event_type}`);
    // Procesar la actualización de parada
}
```

### **Python (WebSocket Client)**
```python
import asyncio
import websockets
import json

async def connect_to_stops():
    uri = "ws://192.168.1.181:8001/ws/stops"
    
    async with websockets.connect(uri) as websocket:
        print("Conectado a WebSocket de Paradas")
        
        try:
            async for message in websocket:
                data = json.loads(message)
                print(f"Mensaje recibido: {data}")
                
                if data["type"] == "stop_update":
                    handle_stop_update(data["data"])
                    
        except websockets.exceptions.ConnectionClosed:
            print("Conexión WebSocket cerrada")

def handle_stop_update(stop_data):
    print(f"Evento en parada {stop_data['stop_id']}: {stop_data['event_type']}")
    # Procesar la actualización de parada

# Ejecutar
asyncio.run(connect_to_stops())
```

### **Node.js (WebSocket Client)**
```javascript
const WebSocket = require('ws');

// Conectar a WebSocket de Semáforos (desde computadora remota)
const trafficSocket = new WebSocket('ws://192.168.1.181:8001/ws/traffic');

trafficSocket.on('open', function open() {
    console.log('Conectado a WebSocket de Semáforos');
});

trafficSocket.on('message', function message(data) {
    const parsedData = JSON.parse(data);
    console.log('Mensaje recibido:', parsedData);
    
    if (parsedData.type === 'traffic_update') {
        handleTrafficUpdate(parsedData.data);
    }
});

trafficSocket.on('close', function close() {
    console.log('Conexión WebSocket cerrada');
});

function handleTrafficUpdate(trafficData) {
    console.log(`Infracción en semáforo ${trafficData.signal_id}: ${trafficData.violation_type}`);
    // Procesar la actualización de semáforo
}
```

## 📊 **Estados de Conexión**

### **Estados del WebSocket**
- **0 (CONNECTING)**: Conectando
- **1 (OPEN)**: Conectado y listo para comunicación
- **2 (CLOSING)**: Cerrando conexión
- **3 (CLOSED)**: Conexión cerrada

### **Manejo de Reconexión**
```javascript
function connectWithRetry(url, maxRetries = 5) {
    let retryCount = 0;
    
    function connect() {
        const ws = new WebSocket(url);
        
        ws.onopen = function() {
            console.log('WebSocket conectado');
            retryCount = 0;
        };
        
        ws.onclose = function() {
            console.log('WebSocket desconectado');
            
            if (retryCount < maxRetries) {
                retryCount++;
                console.log(`Reintentando conexión en 2 segundos... (${retryCount}/${maxRetries})`);
                setTimeout(connect, 2000);
            }
        };
        
        return ws;
    }
    
    return connect();
}

// Uso
const socket = connectWithRetry('ws://localhost:8001/ws/alerts');
```

## 🔍 **Monitoreo y Debugging**

### **Verificar Estado de WebSockets**
```bash
# Obtener estadísticas de conexiones WebSocket (desde computadora remota)
curl http://192.168.1.181:8001/api/v1/debug/websocket-stats

# Respuesta esperada:
{
  "total_connections": 2,
  "connections_by_type": {
    "stops": 1,
    "traffic": 1
  }
}
```

### **Verificar Estado del API**
```bash
# Estado general del API (desde computadora remota)
curl http://192.168.1.181:8001/api/v1/status

# Respuesta esperada:
{
  "mqtt_connected": true,
  "broker": "192.168.1.181:1883",
  "topics_count": 1,
  "topics": ["arduino/data"]
}
```

## 📝 **Tipos de Eventos MQTT que Activan WebSockets**

### **Alertas de Semáforo**

#### **Infracción de Semáforo (Rojo)**
```json
{
  "alert_type": "INFRACCION",
  "signal_id": "S1",
  "signal_color": "red",
  "severity": 3
}
```
**WebSocket activado**: `/ws/traffic` y `/ws/alerts`

#### **Actualización de Semáforo (Amarillo/Verde)**
```json
{
  "alert_type": "SIGNAL_UPDATE",
  "signal_id": "S3",
  "signal_color": "yellow",
  "severity": 1
}
```
**WebSocket activado**: `/ws/traffic`

**NUEVO**: Ahora se emiten actualizaciones para todos los colores de semáforos, no solo infracciones en rojo.

### **Botones de Pánico**
```json
{
  "alert_type": "PANICO",
  "stop_id": "PARADA_001",
  "button_id": 2,
  "severity": 3
}
```
**WebSocket activado**: `/ws/stops` y `/ws/alerts`

### **ETAs de Transporte (NUEVO)**
```json
{
  "alert_type": "ETA_UPDATE",
  "stop_id": "P1",
  "tipo_transporte": "Transmetro",
  "tiempo_segundos": 87,
  "origen": "Estación Norte",
  "severity": 1
}
```
**WebSocket activado**: `/ws/stops`

**Descripción**: Se emiten actualizaciones de ETA cada vez que hay buses en camino a las paradas, sin necesidad de botones de pánico activos.

**Paradas Válidas**:
- **P1, P2**: Transmetro (solo ETAs entre P1 ↔ P2)
- **P3, P4**: Transurbano (solo ETAs entre P3 ↔ P4)

**Validación**: El sistema rechaza automáticamente ETAs que no coincidan con la categoría correcta de parada.

### **Alertas de Gas**
```json
{
  "gas_ppm": 250.0,
  "threshold_ppm": 100.0
}
```
**WebSocket activado**: `/ws/alerts` (solo si supera umbral)

### **Alertas Sísmicas**
```json
{
  "seismic_intensity": 3.5,
  "threshold_g": 2.0
}
```
**WebSocket activado**: `/ws/alerts` (solo si supera umbral)

## 🛠️ **Configuración del Cliente**

### **Headers Recomendados**
```javascript
// Para conexiones seguras (si se implementa en el futuro)
const headers = {
    'Authorization': 'Bearer your-token-here',
    'User-Agent': 'IoT-Client/1.0'
};

const ws = new WebSocket('ws://localhost:8001/ws/alerts', [], { headers });
```

### **Timeouts y Heartbeats**
```javascript
class WebSocketClient {
    constructor(url, options = {}) {
        this.url = url;
        this.options = {
            reconnectInterval: 2000,
            maxReconnectAttempts: 5,
            heartbeatInterval: 30000,
            ...options
        };
        
        this.reconnectAttempts = 0;
        this.heartbeatTimer = null;
        this.connect();
    }
    
    connect() {
        this.ws = new WebSocket(this.url);
        this.setupEventHandlers();
        this.startHeartbeat();
    }
    
    setupEventHandlers() {
        this.ws.onopen = () => {
            console.log('Conectado');
            this.reconnectAttempts = 0;
        };
        
        this.ws.onclose = () => {
            this.handleReconnect();
        };
        
        this.ws.onmessage = (event) => {
            const data = JSON.parse(event.data);
            this.handleMessage(data);
        };
    }
    
    startHeartbeat() {
        this.heartbeatTimer = setInterval(() => {
            if (this.ws.readyState === WebSocket.OPEN) {
                this.ws.send(JSON.stringify({ type: 'heartbeat' }));
            }
        }, this.options.heartbeatInterval);
    }
    
    handleReconnect() {
        if (this.reconnectAttempts < this.options.maxReconnectAttempts) {
            this.reconnectAttempts++;
            setTimeout(() => this.connect(), this.options.reconnectInterval);
        }
    }
    
    handleMessage(data) {
        console.log('Mensaje recibido:', data);
        // Procesar mensaje según el tipo
    }
}

// Uso
const client = new WebSocketClient('ws://localhost:8001/ws/stops');
```

## 🚨 **Manejo de Errores**

### **Errores Comunes y Soluciones**

#### **1. Conexión Rechazada**
```javascript
ws.onerror = function(error) {
    console.error('Error de conexión:', error);
    // Verificar que el API esté ejecutándose
    // Verificar la URL del WebSocket
};
```

#### **2. Mensaje Malformado**
```javascript
ws.onmessage = function(event) {
    try {
        const data = JSON.parse(event.data);
        // Procesar datos
    } catch (error) {
        console.error('Error parseando mensaje:', error);
        console.log('Mensaje raw:', event.data);
    }
};
```

#### **3. Conexión Perdida**
```javascript
ws.onclose = function(event) {
    if (!event.wasClean) {
        console.log('Conexión perdida inesperadamente');
        // Implementar lógica de reconexión
    }
};
```

## 📱 **Ejemplo de Aplicación Móvil (React Native)**

```javascript
import { useEffect, useState } from 'react';
import { Alert } from 'react-native';

export const useWebSocket = (url) => {
    const [socket, setSocket] = useState(null);
    const [isConnected, setIsConnected] = useState(false);
    const [messages, setMessages] = useState([]);

    useEffect(() => {
        const ws = new WebSocket(url);
        
        ws.onopen = () => {
            setIsConnected(true);
            console.log('WebSocket conectado');
        };
        
        ws.onmessage = (event) => {
            const data = JSON.parse(event.data);
            setMessages(prev => [...prev, data]);
            
            // Mostrar notificación push para alertas críticas
            if (data.type === 'alert' && data.data.severity >= 3) {
                Alert.alert(
                    'Alerta Crítica',
                    `Tipo: ${data.data.alert_type}\nSeveridad: ${data.data.severity}`,
                    [{ text: 'OK' }]
                );
            }
        };
        
        ws.onclose = () => {
            setIsConnected(false);
            console.log('WebSocket desconectado');
        };
        
        setSocket(ws);
        
        return () => {
            ws.close();
        };
    }, [url]);

    return { socket, isConnected, messages };
};

// Uso en componente
const TrafficMonitor = () => {
    const { socket, isConnected, messages } = useWebSocket('ws://localhost:8001/ws/traffic');
    
    return (
        <View>
            <Text>Estado: {isConnected ? 'Conectado' : 'Desconectado'}</Text>
            <Text>Mensajes recibidos: {messages.length}</Text>
            {messages.map((msg, index) => (
                <Text key={index}>{JSON.stringify(msg)}</Text>
            ))}
        </View>
    );
};
```

## 🔧 **Testing y Desarrollo**

### **Página de Prueba HTML**
El API incluye una página de prueba en `websocket_test.html` que permite:
- Conectar/desconectar a cada WebSocket
- Ver mensajes recibidos en tiempo real
- Monitorear estadísticas de conexiones
- Probar diferentes tipos de eventos

### **Enviar Datos de Prueba**
```bash
# Infracción de semáforo
mosquitto_pub -h 192.168.1.181 -t "arduino/data" -m '{"alert_type": "INFRACCION", "signal_id": "TEST_001", "signal_color": "red", "severity": 3}'

# Botón de pánico
mosquitto_pub -h 192.168.1.181 -t "arduino/data" -m '{"alert_type": "PANICO", "stop_id": "TEST_STOP", "button_id": 1, "severity": 3}'

# Alerta de gas
mosquitto_pub -h 192.168.1.181 -t "arduino/data" -m '{"gas_ppm": 300.0, "threshold_ppm": 100.0}'
```

## 📚 **Recursos Adicionales**

- **Documentación del API**: `README.md`
- **Página de prueba**: `websocket_test.html`
- **Configuración**: `config.py`
- **Ejemplos de código**: Ver ejemplos en esta documentación

## 🆘 **Soporte y Troubleshooting**

### **Problemas Comunes**
1. **WebSocket no conecta**: Verificar que el API esté ejecutándose en el puerto 8001
2. **No se reciben mensajes**: Verificar que haya datos MQTT llegando al tópico `arduino/data`
3. **Conexión se pierde**: Implementar lógica de reconexión automática

### **Logs del Sistema**
Los logs del API muestran:
- Conexiones WebSocket establecidas
- Mensajes emitidos por WebSocket
- Errores de conexión
- Estadísticas de broadcasting

### **Contacto**
Para soporte técnico, revisar los logs del API o consultar la documentación del proyecto.

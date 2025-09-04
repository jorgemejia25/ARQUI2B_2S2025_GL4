# Ejemplos Prácticos WebSocket - API IoT

## 🚀 **Ejemplos de Implementación por Lenguaje**

### **1. JavaScript (Navegador)**

#### **Cliente Básico de Paradas**
```html
<!DOCTYPE html>
<html>
<head>
    <title>Cliente WebSocket - Paradas</title>
</head>
<body>
    <h1>Monitor de Paradas</h1>
    <div id="status">Desconectado</div>
    <div id="messages"></div>
    
    <script>
        const ws = new WebSocket('ws://192.168.1.181:8001/ws/stops');
        const statusDiv = document.getElementById('status');
        const messagesDiv = document.getElementById('messages');
        
        ws.onopen = function() {
            statusDiv.textContent = 'Conectado';
            statusDiv.style.color = 'green';
        };
        
        ws.onmessage = function(event) {
            const data = JSON.parse(event.data);
            const messageDiv = document.createElement('div');
            messageDiv.innerHTML = `
                <strong>${new Date(data.timestamp * 1000).toLocaleString()}</strong><br>
                Tipo: ${data.type}<br>
                Datos: ${JSON.stringify(data.data, null, 2)}
            `;
            messagesDiv.appendChild(messageDiv);
        };
        
        ws.onclose = function() {
            statusDiv.textContent = 'Desconectado';
            statusDiv.style.color = 'red';
        };
    </script>
</body>
</html>
```

#### **Cliente Avanzado con Reconexión**
```javascript
class AdvancedWebSocketClient {
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
        this.messageHandlers = new Map();
        this.isConnected = false;
        
        this.connect();
    }
    
    connect() {
        this.ws = new WebSocket(this.url);
        this.setupEventHandlers();
    }
    
    setupEventHandlers() {
        this.ws.onopen = () => {
            this.isConnected = true;
            this.reconnectAttempts = 0;
            this.startHeartbeat();
            this.onConnect();
        };
        
        this.ws.onclose = () => {
            this.isConnected = false;
            this.stopHeartbeat();
            this.onDisconnect();
            this.handleReconnect();
        };
        
        this.ws.onmessage = (event) => {
            try {
                const data = JSON.parse(event.data);
                this.handleMessage(data);
            } catch (error) {
                console.error('Error parseando mensaje:', error);
            }
        };
        
        this.ws.onerror = (error) => {
            console.error('Error WebSocket:', error);
            this.onError(error);
        };
    }
    
    startHeartbeat() {
        this.heartbeatTimer = setInterval(() => {
            if (this.isConnected) {
                this.send({ type: 'heartbeat', timestamp: Date.now() });
            }
        }, this.options.heartbeatInterval);
    }
    
    stopHeartbeat() {
        if (this.heartbeatTimer) {
            clearInterval(this.heartbeatTimer);
            this.heartbeatTimer = null;
        }
    }
    
    handleReconnect() {
        if (this.reconnectAttempts < this.options.maxReconnectAttempts) {
            this.reconnectAttempts++;
            console.log(`Reintentando conexión en ${this.options.reconnectInterval}ms... (${this.reconnectAttempts}/${this.options.maxReconnectAttempts})`);
            setTimeout(() => this.connect(), this.options.reconnectInterval);
        } else {
            console.error('Máximo de reintentos alcanzado');
        }
    }
    
    send(data) {
        if (this.isConnected) {
            this.ws.send(JSON.stringify(data));
        }
    }
    
    onConnect() {
        console.log('WebSocket conectado');
    }
    
    onDisconnect() {
        console.log('WebSocket desconectado');
    }
    
    onError(error) {
        console.error('Error WebSocket:', error);
    }
    
    handleMessage(data) {
        const handler = this.messageHandlers.get(data.type);
        if (handler) {
            handler(data);
        } else {
            console.log('Mensaje no manejado:', data);
        }
    }
    
    onMessage(type, handler) {
        this.messageHandlers.set(type, handler);
    }
    
    close() {
        this.ws.close();
    }
}

// Uso
const client = new AdvancedWebSocketClient('ws://192.168.1.181:8001/ws/alerts');

client.onMessage('alert', (data) => {
    console.log('Alerta recibida:', data);
    // Mostrar notificación
    if (data.data.severity >= 3) {
        showNotification(`Alerta Crítica: ${data.data.alert_type}`);
    }
});

client.onMessage('stop_update', (data) => {
    console.log('Actualización de parada:', data);
    updateStopDisplay(data.data);
});

function showNotification(message) {
    if ('Notification' in window && Notification.permission === 'granted') {
        new Notification('API IoT', { body: message });
    }
}
```

### **2. Python**

#### **Cliente Básico**
```python
import asyncio
import websockets
import json
from datetime import datetime

async def basic_websocket_client():
    uri = "ws://192.168.1.181:8001/ws/alerts"
    
    try:
        async with websockets.connect(uri) as websocket:
            print(f"[{datetime.now()}] Conectado a WebSocket de Alertas")
            
            async for message in websocket:
                data = json.loads(message)
                print(f"[{datetime.now()}] Mensaje recibido: {data}")
                
                if data["type"] == "alert":
                    handle_alert(data["data"])
                elif data["type"] == "stop_update":
                    handle_stop_update(data["data"])
                elif data["type"] == "traffic_update":
                    handle_traffic_update(data["data"])
                    
    except websockets.exceptions.ConnectionClosed:
        print("Conexión WebSocket cerrada")
    except Exception as e:
        print(f"Error: {e}")

def handle_alert(alert_data):
    print(f"Alerta: {alert_data['alert_type']} - Severidad: {alert_data['severity']}")
    if alert_data['severity'] >= 3:
        print("⚠️ ALERTA CRÍTICA DETECTADA ⚠️")

def handle_stop_update(stop_data):
    print(f"Parada {stop_data['stop_id']}: {stop_data['event_type']}")

def handle_traffic_update(traffic_data):
    signal_id = traffic_data['signal_id']
    signal_color = traffic_data['signal_color']
    violation_type = traffic_data['violation_type']
    severity = traffic_data['data']['severity']
    
    if violation_type == "red_light":
        print(f"🚨 INFRACCIÓN: Semáforo {signal_id} en ROJO (severity: {severity})")
    elif violation_type == "signal_update":
        color_emoji = {"red": "🔴", "yellow": "🟡", "green": "🟢"}.get(signal_color, "⚪")
        print(f"{color_emoji} ACTUALIZACIÓN: Semáforo {signal_id} en {signal_color.upper()} (severity: {severity})")

if __name__ == "__main__":
    asyncio.run(basic_websocket_client())
```

#### **Cliente Avanzado con Reconexión**
```python
import asyncio
import websockets
import json
import logging
from datetime import datetime
from typing import Dict, Any, Callable

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class PythonWebSocketClient:
    def __init__(self, url: str, options: Dict[str, Any] = None):
        self.url = url
        self.options = {
            'reconnect_interval': 2.0,
            'max_reconnect_attempts': 5,
            'heartbeat_interval': 30.0,
            **(options or {})
        }
        
        self.reconnect_attempts = 0
        self.heartbeat_task = None
        self.message_handlers: Dict[str, Callable] = {}
        self.is_connected = False
        self.websocket = None
        
    async def connect(self):
        """Conectar al WebSocket"""
        try:
            self.websocket = await websockets.connect(self.url)
            self.is_connected = True
            self.reconnect_attempts = 0
            logger.info(f"Conectado a {self.url}")
            
            # Iniciar heartbeat
            self.heartbeat_task = asyncio.create_task(self.heartbeat_loop())
            
            # Escuchar mensajes
            await self.listen_for_messages()
            
        except Exception as e:
            logger.error(f"Error conectando: {e}")
            await self.handle_reconnect()
    
    async def listen_for_messages(self):
        """Escuchar mensajes del WebSocket"""
        try:
            async for message in self.websocket:
                await self.handle_message(message)
        except websockets.exceptions.ConnectionClosed:
            logger.info("Conexión WebSocket cerrada")
            self.is_connected = False
            await self.handle_reconnect()
        except Exception as e:
            logger.error(f"Error escuchando mensajes: {e}")
    
    async def handle_message(self, message: str):
        """Procesar mensaje recibido"""
        try:
            data = json.loads(message)
            message_type = data.get('type')
            
            if message_type in self.message_handlers:
                await self.message_handlers[message_type](data)
            else:
                logger.info(f"Mensaje no manejado: {data}")
                
        except json.JSONDecodeError as e:
            logger.error(f"Error parseando mensaje: {e}")
    
    async def heartbeat_loop(self):
        """Enviar heartbeat periódico"""
        while self.is_connected:
            try:
                await asyncio.sleep(self.options['heartbeat_interval'])
                if self.is_connected:
                    await self.send({
                        'type': 'heartbeat',
                        'timestamp': datetime.now().isoformat()
                    })
            except Exception as e:
                logger.error(f"Error en heartbeat: {e}")
    
    async def send(self, data: Dict[str, Any]):
        """Enviar mensaje al WebSocket"""
        if self.is_connected and self.websocket:
            try:
                await self.websocket.send(json.dumps(data))
            except Exception as e:
                logger.error(f"Error enviando mensaje: {e}")
    
    async def handle_reconnect(self):
        """Manejar reconexión automática"""
        if self.reconnect_attempts < self.options['max_reconnect_attempts']:
            self.reconnect_attempts += 1
            logger.info(f"Reintentando conexión en {self.options['reconnect_interval']}s... ({self.reconnect_attempts}/{self.options['max_reconnect_attempts']})")
            await asyncio.sleep(self.options['reconnect_interval'])
            await self.connect()
        else:
            logger.error("Máximo de reintentos alcanzado")
    
    def on_message(self, message_type: str, handler: Callable):
        """Registrar manejador para tipo de mensaje"""
        self.message_handlers[message_type] = handler
    
    async def close(self):
        """Cerrar conexión WebSocket"""
        self.is_connected = False
        if self.heartbeat_task:
            self.heartbeat_task.cancel()
        if self.websocket:
            await self.websocket.close()

# Ejemplo de uso
async def main():
    client = PythonWebSocketClient('ws://192.168.1.181:8001/ws/stops')
    
    # Registrar manejadores
    async def handle_stop_update(data):
        print(f"🛑 Actualización de parada: {data['data']['stop_id']}")
    
    async def handle_alert(data):
        print(f"🚨 Alerta: {data['data']['alert_type']}")
    
    client.on_message('stop_update', handle_stop_update)
    client.on_message('alert', handle_alert)
    
    try:
        await client.connect()
    except KeyboardInterrupt:
        print("\nCerrando cliente...")
        await client.close()

if __name__ == "__main__":
    asyncio.run(main())
```

### **3. Node.js**

#### **Cliente Básico**
```javascript
const WebSocket = require('ws');

class NodeWebSocketClient {
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
        this.messageHandlers = new Map();
        this.isConnected = false;
        
        this.connect();
    }
    
    connect() {
        this.ws = new WebSocket(this.url);
        this.setupEventHandlers();
    }
    
    setupEventHandlers() {
        this.ws.on('open', () => {
            this.isConnected = true;
            this.reconnectAttempts = 0;
            this.startHeartbeat();
            console.log('WebSocket conectado');
        });
        
        this.ws.on('message', (data) => {
            try {
                const message = JSON.parse(data.toString());
                this.handleMessage(message);
            } catch (error) {
                console.error('Error parseando mensaje:', error);
            }
        });
        
        this.ws.on('close', () => {
            this.isConnected = false;
            this.stopHeartbeat();
            console.log('WebSocket desconectado');
            this.handleReconnect();
        });
        
        this.ws.on('error', (error) => {
            console.error('Error WebSocket:', error);
        });
    }
    
    startHeartbeat() {
        this.heartbeatTimer = setInterval(() => {
            if (this.isConnected) {
                this.send({ type: 'heartbeat', timestamp: Date.now() });
            }
        }, this.options.heartbeatInterval);
    }
    
    stopHeartbeat() {
        if (this.heartbeatTimer) {
            clearInterval(this.heartbeatTimer);
            this.heartbeatTimer = null;
        }
    }
    
    handleReconnect() {
        if (this.reconnectAttempts < this.options.maxReconnectAttempts) {
            this.reconnectAttempts++;
            console.log(`Reintentando conexión en ${this.options.reconnectInterval}ms... (${this.reconnectAttempts}/${this.options.maxReconnectAttempts})`);
            setTimeout(() => this.connect(), this.options.reconnectInterval);
        } else {
            console.error('Máximo de reintentos alcanzado');
        }
    }
    
    send(data) {
        if (this.isConnected) {
            this.ws.send(JSON.stringify(data));
        }
    }
    
    handleMessage(message) {
        const handler = this.messageHandlers.get(message.type);
        if (handler) {
            handler(message);
        } else {
            console.log('Mensaje no manejado:', message);
        }
    }
    
    onMessage(type, handler) {
        this.messageHandlers.set(type, handler);
    }
    
    close() {
        this.ws.close();
    }
}

// Ejemplo de uso
const client = new NodeWebSocketClient('ws://192.168.1.181:8001/ws/traffic');

client.onMessage('traffic_update', (data) => {
    const signalId = data.data.signal_id;
    const signalColor = data.data.signal_color;
    const violationType = data.data.violation_type;
    const severity = data.data.data.severity;
    
    if (violationType === "red_light") {
        console.log(`🚨 INFRACCIÓN: Semáforo ${signalId} en ROJO (severity: ${severity})`);
    } else if (violationType === "signal_update") {
        const colorEmoji = {"red": "🔴", "yellow": "🟡", "green": "🟢"}[signalColor] || "⚪";
        console.log(`${colorEmoji} ACTUALIZACIÓN: Semáforo ${signalId} en ${signalColor.toUpperCase()} (severity: ${severity})`);
    }
});

client.onMessage('alert', (data) => {
    console.log('🚨 Alerta recibida:', data.data.alert_type);
});

// Manejar cierre del proceso
process.on('SIGINT', () => {
    console.log('\nCerrando cliente...');
    client.close();
    process.exit(0);
});
```

### **4. React Native**

```javascript
import React, { useEffect, useState } from 'react';
import { View, Text, StyleSheet, Alert, ScrollView } from 'react-native';

const useWebSocket = (url) => {
    const [socket, setSocket] = useState(null);
    const [isConnected, setIsConnected] = useState(false);
    const [messages, setMessages] = useState([]);
    const [error, setError] = useState(null);

    useEffect(() => {
        const ws = new WebSocket(url);
        
        ws.onopen = () => {
            setIsConnected(true);
            setError(null);
            console.log('WebSocket conectado');
        };
        
        ws.onmessage = (event) => {
            try {
                const data = JSON.parse(event.data);
                setMessages(prev => [...prev, data]);
                
                // Mostrar alerta para mensajes críticos
                if (data.type === 'alert' && data.data.severity >= 3) {
                    Alert.alert(
                        'Alerta Crítica',
                        `Tipo: ${data.data.alert_type}\nSeveridad: ${data.data.severity}`,
                        [{ text: 'OK' }]
                    );
                }
            } catch (error) {
                console.error('Error parseando mensaje:', error);
            }
        };
        
        ws.onclose = () => {
            setIsConnected(false);
            console.log('WebSocket desconectado');
        };
        
        ws.onerror = (error) => {
            setError('Error de conexión WebSocket');
            console.error('Error WebSocket:', error);
        };
        
        setSocket(ws);
        
        return () => {
            ws.close();
        };
    }, [url]);

    return { socket, isConnected, messages, error };
};

const WebSocketMonitor = ({ title, url, messageType }) => {
    const { isConnected, messages, error } = useWebSocket(url);
    
    const filteredMessages = messages.filter(msg => msg.type === messageType);
    
    return (
        <View style={styles.container}>
            <Text style={styles.title}>{title}</Text>
            <View style={[styles.statusIndicator, { backgroundColor: isConnected ? '#4CAF50' : '#F44336' }]}>
                <Text style={styles.statusText}>
                    {isConnected ? 'Conectado' : 'Desconectado'}
                </Text>
            </View>
            
            {error && (
                <Text style={styles.errorText}>{error}</Text>
            )}
            
            <Text style={styles.messageCount}>
                Mensajes recibidos: {filteredMessages.length}
            </Text>
            
            <ScrollView style={styles.messagesContainer}>
                {filteredMessages.map((msg, index) => (
                    <View key={index} style={styles.messageItem}>
                        <Text style={styles.messageType}>{msg.type}</Text>
                        <Text style={styles.messageData}>
                            {JSON.stringify(msg.data, null, 2)}
                        </Text>
                    </View>
                ))}
            </ScrollView>
        </View>
    );
};

const App = () => {
    return (
        <View style={styles.appContainer}>
            <Text style={styles.appTitle}>Monitor IoT - WebSockets</Text>
            
            <WebSocketMonitor
                title="Paradas"
                url="ws://192.168.1.181:8001/ws/stops"
                messageType="stop_update"
            />
            
            <WebSocketMonitor
                title="Semáforos"
                url="ws://192.168.1.181:8001/ws/traffic"
                messageType="traffic_update"
            />
            
            <WebSocketMonitor
                title="Alertas"
                url="ws://192.168.1.181:8001/ws/alerts"
                messageType="alert"
            />
        </View>
    );
};

const styles = StyleSheet.create({
    appContainer: {
        flex: 1,
        padding: 20,
        backgroundColor: '#f5f5f5',
    },
    appTitle: {
        fontSize: 24,
        fontWeight: 'bold',
        textAlign: 'center',
        marginBottom: 20,
    },
    container: {
        backgroundColor: 'white',
        padding: 15,
        marginBottom: 15,
        borderRadius: 8,
        elevation: 2,
    },
    title: {
        fontSize: 18,
        fontWeight: 'bold',
        marginBottom: 10,
    },
    statusIndicator: {
        padding: 8,
        borderRadius: 4,
        marginBottom: 10,
    },
    statusText: {
        color: 'white',
        textAlign: 'center',
        fontWeight: 'bold',
    },
    errorText: {
        color: '#F44336',
        marginBottom: 10,
    },
    messageCount: {
        fontSize: 14,
        marginBottom: 10,
        color: '#666',
    },
    messagesContainer: {
        maxHeight: 200,
    },
    messageItem: {
        borderLeftWidth: 3,
        borderLeftColor: '#2196F3',
        paddingLeft: 10,
        marginBottom: 8,
        backgroundColor: '#f8f9fa',
        padding: 8,
    },
    messageType: {
        fontWeight: 'bold',
        marginBottom: 5,
    },
    messageData: {
        fontSize: 12,
        fontFamily: 'monospace',
    },
});

export default App;
```

## 🔧 **Configuración del Entorno**

### **Instalación de Dependencias**

#### **Python**
```bash
pip install websockets
```

#### **Node.js**
```bash
npm install ws
```

#### **React Native**
```bash
npm install react-native-websocket
```

## 📱 **Testing de los Ejemplos**

1. **Ejecutar el API IoT** en el puerto 8001
2. **Ejecutar el ejemplo** en el lenguaje deseado
3. **Enviar datos MQTT** para activar los WebSockets
4. **Verificar** que los mensajes lleguen al cliente

## 🚨 **Notas Importantes**

- Los ejemplos están configurados para conectarse a la Raspberry Pi en `192.168.1.181:8001`
- Para desarrollo local, cambiar las URLs a `localhost:8001`
- Para producción, cambiar las URLs a la IP/hostname correcto
- Implementar manejo de errores robusto en aplicaciones de producción
- Considerar implementar autenticación para WebSockets en producción

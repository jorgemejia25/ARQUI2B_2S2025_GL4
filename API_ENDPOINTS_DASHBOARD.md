# Endpoints de la API para Dashboard Flutter

## Resumen de Endpoints Disponibles

Tu API ahora incluye endpoints específicos para el dashboard de Flutter. Todos los endpoints están disponibles bajo el prefijo `/api/v1/data/`.

### 1. Resumen General del Dashboard
**GET** `/api/v1/data/dashboard/summary`

Obtiene un resumen completo del estado del sistema:
- Alertas por tipo en las últimas 24 horas
- Estado actual de los buses
- Últimas mediciones de sensores

**Respuesta:**
```json
{
  "alerts_summary": [
    {"code": "INFRACCION", "description": "Infracción de tráfico", "count": 5},
    {"code": "PANICO", "description": "Botón de pánico", "count": 2}
  ],
  "buses_status": [
    {"code": "BUS_TRANSMETRO", "ts": "2024-01-15 10:30:00", "speed_kmh": 45.5, "distance_to_next_stop_m": 150}
  ],
  "latest_gas": [{"ppm": 25.3, "ts": "2024-01-15 10:30:00"}],
  "latest_seismic": [{"intensity_g": 0.1, "ts": "2024-01-15 10:30:00"}]
}
```

### 2. Datos para Gráficas

#### Gas
**GET** `/api/v1/data/dashboard/charts/gas?hours=24`

Datos de gas para gráficas de las últimas N horas.

**Parámetros:**
- `hours`: Número de horas hacia atrás (1-168, default: 24)

**Respuesta:**
```json
[
  {"ts": "2024-01-15 09:00:00", "ppm": 20.5},
  {"ts": "2024-01-15 09:30:00", "ppm": 22.1},
  {"ts": "2024-01-15 10:00:00", "ppm": 25.3}
]
```

#### Datos Sísmicos
**GET** `/api/v1/data/dashboard/charts/seismic?hours=24`

Datos sísmicos para gráficas.

**Respuesta:**
```json
[
  {"ts": "2024-01-15 09:00:00", "intensity_g": 0.05},
  {"ts": "2024-01-15 09:30:00", "intensity_g": 0.08},
  {"ts": "2024-01-15 10:00:00", "intensity_g": 0.1}
]
```

#### Posiciones de Buses
**GET** `/api/v1/data/dashboard/charts/bus-positions?hours=24`

Datos de posiciones de buses para gráficas.

**Respuesta:**
```json
[
  {"ts": "2024-01-15 09:00:00", "bus_code": "BUS_TRANSMETRO", "speed_kmh": 40.0, "distance_to_next_stop_m": 200},
  {"ts": "2024-01-15 09:30:00", "bus_code": "BUS_TRANSMETRO", "speed_kmh": 45.5, "distance_to_next_stop_m": 150}
]
```

### 3. Alertas Recientes
**GET** `/api/v1/data/dashboard/alerts/recent?limit=20`

Alertas recientes con detalles completos.

**Parámetros:**
- `limit`: Número de alertas a retornar (1-100, default: 20)

**Respuesta:**
```json
[
  {
    "alert_id": 1,
    "ts": "2024-01-15 10:30:00",
    "alert_type": "INFRACCION",
    "description": "Infracción de tráfico (semáforo)",
    "severity": 3,
    "bus_code": "BUS_TRANSMETRO",
    "stop_name": "Parada1_Transmetro",
    "detail_value": "red"
  }
]
```

### 4. Estadísticas por Período
**GET** `/api/v1/data/dashboard/stats/hourly?hours=24`

Estadísticas agregadas por hora.

**Respuesta:**
```json
{
  "alerts_by_hour": [
    {"hour": "2024-01-15 10:00:00", "alert_type": "INFRACCION", "count": 2}
  ],
  "gas_by_hour": [
    {"hour": "2024-01-15 10:00:00", "avg_ppm": 22.5, "max_ppm": 25.3, "min_ppm": 20.1}
  ],
  "seismic_by_hour": [
    {"hour": "2024-01-15 10:00:00", "avg_intensity": 0.08, "max_intensity": 0.1, "min_intensity": 0.05}
  ]
}
```

### 5. Estado de Buses
**GET** `/api/v1/data/dashboard/buses/status`

Estado actual de todos los buses.

**Respuesta:**
```json
[
  {
    "bus_id": 1,
    "code": "BUS_TRANSMETRO",
    "route_name": "Ruta Transmetro",
    "last_position_time": "2024-01-15 10:30:00",
    "speed_kmh": 45.5,
    "distance_to_next_stop_m": 150,
    "status": "active"
  }
]
```

### 6. Métricas del Sistema
**GET** `/api/v1/data/dashboard/metrics`

Métricas generales del sistema.

**Respuesta:**
```json
{
  "table_counts": [
    {"table_name": "GasMeasurement", "count": 1250},
    {"table_name": "SeismicMeasurement", "count": 980},
    {"table_name": "BusPosition", "count": 450},
    {"table_name": "Alert", "count": 25}
  ],
  "severity_distribution": [
    {"severity": 3, "count": 15},
    {"severity": 2, "count": 8},
    {"severity": 1, "count": 2}
  ],
  "hourly_activity": [
    {"hour": "09", "total_events": 45},
    {"hour": "10", "total_events": 52}
  ]
}
```

## Endpoints Existentes (Mejorados)

### Posiciones de Buses
- **GET** `/api/v1/data/bus-positions` - Todas las posiciones
- **GET** `/api/v1/data/bus-positions/bus/1` - Solo BUS_TRANSMETRO
- **GET** `/api/v1/data/bus-positions/bus/2` - Solo BUS_TRANSURBANO

### Historial de Sensores
- **GET** `/api/v1/data/gas-history` - Historial de gas
- **GET** `/api/v1/data/gas-history/origin/1` - Gas origen 1
- **GET** `/api/v1/data/gas-history/origin/2` - Gas origen 2
- **GET** `/api/v1/data/seismic-history` - Historial sísmico

### Tablas de Eventos
- **GET** `/api/v1/data/tables/traffic-infractions` - Infracciones de tráfico
- **GET** `/api/v1/data/tables/panic-events` - Eventos de pánico
- **GET** `/api/v1/data/tables/seismic-events` - Eventos sísmicos
- **GET** `/api/v1/data/tables/gas-events` - Eventos de gas

## Uso en Flutter

### Ejemplo de Consumo con HTTP

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  static const String baseUrl = 'http://tu-servidor:8000/api/v1/data';
  
  // Obtener resumen del dashboard
  static Future<Map<String, dynamic>> getDashboardSummary() async {
    final response = await http.get(Uri.parse('$baseUrl/dashboard/summary'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Error al cargar datos del dashboard');
  }
  
  // Obtener datos de gas para gráficas
  static Future<List<dynamic>> getGasChartData({int hours = 24}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/dashboard/charts/gas?hours=$hours')
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Error al cargar datos de gas');
  }
  
  // Obtener alertas recientes
  static Future<List<dynamic>> getRecentAlerts({int limit = 20}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/dashboard/alerts/recent?limit=$limit')
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Error al cargar alertas');
  }
}
```

### Ejemplo de Uso en Widget

```dart
class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic> dashboardData = {};
  bool isLoading = true;
  
  @override
  void initState() {
    super.initState();
    loadDashboardData();
  }
  
  Future<void> loadDashboardData() async {
    try {
      final data = await ApiService.getDashboardSummary();
      setState(() {
        dashboardData = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'))
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    
    return Scaffold(
      appBar: AppBar(title: Text('Dashboard IoT')),
      body: Column(
        children: [
          // Mostrar resumen de alertas
          if (dashboardData['alerts_summary'] != null)
            AlertSummaryWidget(
              alerts: dashboardData['alerts_summary']
            ),
          
          // Mostrar estado de buses
          if (dashboardData['buses_status'] != null)
            BusStatusWidget(
              buses: dashboardData['buses_status']
            ),
          
          // Mostrar últimas mediciones
          if (dashboardData['latest_gas'] != null)
            SensorWidget(
              gasData: dashboardData['latest_gas'],
              seismicData: dashboardData['latest_seismic']
            ),
        ],
      ),
    );
  }
}
```

## Notas Importantes

1. **CORS**: La API ya tiene CORS configurado para permitir requests desde Flutter
2. **Formato de Fechas**: Todas las fechas están en formato ISO (YYYY-MM-DD HH:MM:SS)
3. **Límites**: Los endpoints tienen límites por defecto para evitar sobrecarga
4. **Parámetros**: Usa los parámetros de query para filtrar datos por tiempo
5. **Error Handling**: Siempre maneja los errores HTTP en tu aplicación Flutter

## Próximos Pasos

1. **WebSocket**: Considera usar WebSockets para actualizaciones en tiempo real
2. **Caché**: Implementa caché en Flutter para mejorar el rendimiento
3. **Refresh**: Agrega funcionalidad de pull-to-refresh
4. **Filtros**: Implementa filtros por fecha/hora en la UI
5. **Notificaciones**: Usa los datos de alertas para notificaciones push




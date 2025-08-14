// Proveedor de datos simulado para el sistema de tráfico urbano
// Simula comunicación serial con datos de semáforos y paradas

class DataProvider {
  private JSONObject currentData;
  private long lastUpdateTime;
  private int updateInterval = 2000; // Actualizar cada 2 segundos
  
  // Modos de operación
  private boolean serialMode = false;
  private boolean simulationEnabled = true; // Nuevo: permite intercambiar entre simulado y real
  
  // Metadatos de diagnóstico
  private String lastSource = "simulado"; // "simulado" | "serial" | "desconectado"
  private int updateCount = 0;
  private long serialTimeoutMs = 5000; // 5 segundos sin datos serial = modo simulado automático
  private long lastSerialDataTime = 0;
  
  // Estados posibles para semáforos
  private String[] semaforoStates = {"ROJO", "VERDE", "AMARILLO"};
  
  // IDs de semáforos (10 semáforos)
  private String[] semaforoIds = {"S1", "S2", "S3", "S4", "S5", "S6", "S7", "S8", "S9", "S10"};
  
  // IDs de paradas (6 paradas)
  private String[] paradaIds = {"P1", "P2", "P3", "P4", "P5", "P6"};
  
  // Zonas de gas y pánico (simplificado a 3 zonas)
  private String[] zonaIds = {"Z1", "Z2", "Z3"};
  
  DataProvider() {
    lastUpdateTime = millis();
    lastSerialDataTime = millis();
    generateNewData();
  }
  // Método principal para obtener datos actuales
  JSONObject getCurrentData() {
    // Verificar timeout de datos serial
    checkSerialTimeout();
    
    // Solo generar datos simulados si está habilitado y no hay datos reales recientes
    if (simulationEnabled && (!serialMode || isSerialTimedOut())) {
      if (millis() - lastUpdateTime > updateInterval) {
        generateNewData();
        lastUpdateTime = millis();
      }
    }
    
    return currentData;
  }
  
  // Verificar si hay timeout en datos serial
  private void checkSerialTimeout() {
    if (serialMode && isSerialTimedOut() && !simulationEnabled) {
      println("[DataProvider] Timeout de datos serial. Cambiando a modo simulado automáticamente.");
      simulationEnabled = true;
      lastSource = "simulado_auto";
    }
  }
  
  private boolean isSerialTimedOut() {
    return (millis() - lastSerialDataTime) > serialTimeoutMs;
  }
  
  // Generar nuevos datos simulados
  void generateNewData() {
    currentData = new JSONObject();
    
    // Timestamp actual
    currentData.setString("ts", getCurrentTimestamp());
    
    // Generar estados de semáforos (legacy S1..S10)
    JSONObject semaforos = new JSONObject();
    for (String semaforoId : semaforoIds) {
      String estado = semaforoStates[int(random(3))];
      semaforos.setString(semaforoId, estado);
    }
    currentData.setJSONObject("semaforos", semaforos);

    // NUEVO: Generar estados de semáforos por tipo y calle (A1..A3, B1..B3)
    JSONObject semaforosAB = new JSONObject();
    for (int i = 1; i <= 3; i++) {
      semaforosAB.setString("A" + i, semaforoStates[int(random(3))]);
    }
    for (int i = 1; i <= 3; i++) {
      semaforosAB.setString("B" + i, semaforoStates[int(random(3))]);
    }
    currentData.setJSONObject("semaforosAB", semaforosAB);
    
    // Generar distancias en paradas (en cm)
    JSONObject distancias = new JSONObject();
    for (String paradaId : paradaIds) {
      int distancia = int(random(20, 500)); // 20cm a 5m
      distancias.setInt(paradaId, distancia);
    }
    currentData.setJSONObject("dist_cm", distancias);
    
    // Generar niveles de gas (en ppm)
    JSONObject gas = new JSONObject();
    for (String zonaId : zonaIds) {
      int gasPpm = int(random(150, 300)); // 150-300 ppm
      gas.setInt(zonaId, gasPpm);
    }
    currentData.setJSONObject("gas_ppm", gas);
    
    // Generar estado de pánico (0 o 1)
    JSONObject panico = new JSONObject();
    for (String zonaId : zonaIds) {
      int panicoState = random(1) > 0.8 ? 1 : 0; // 20% probabilidad de pánico
      panico.setInt(zonaId, panicoState);
    }
    currentData.setJSONObject("panico", panico);
    
    // Generar infracciones (lista de paradas con infracciones) - legacy
    JSONArray infracciones = new JSONArray();
    for (String paradaId : paradaIds) {
      if (random(1) > 0.7) { // 30% probabilidad de infracción
        infracciones.append(paradaId);
      }
    }
    currentData.setJSONArray("infracciones", infracciones);

    // NUEVO: Infracciones detalladas por tipo/calle
    JSONArray infrDet = new JSONArray();
    // Simular 0-3 infracciones al azar
    int n = int(random(0, 3.99));
    for (int i = 0; i < n; i++) {
      JSONObject d = new JSONObject();
      d.setString("tipo", random(1) > 0.5 ? "A" : "B");
      d.setInt("calle", int(random(1, 3.99))); // 1..3
      infrDet.append(d);
    }
    currentData.setJSONArray("infracciones_detalle", infrDet);
    
    if (simulationEnabled) {
      lastSource = serialMode && !isSerialTimedOut() ? "simulado_manual" : "simulado";
    }
    updateCount++;
  }
  
  // Obtener datos formateados como String (para mostrar o enviar por serial)
  String getDataAsString() {
    return getCurrentData().toString();
  }
  
  // Obtener datos formateados como JSON legible
  String getDataAsFormattedString() {
    JSONObject data = getCurrentData();
    StringBuilder sb = new StringBuilder();
    
    sb.append("{\n");
    sb.append("  \"ts\": \"").append(data.getString("ts")).append("\",\n");
    
    // Semáforos
    sb.append("  \"semaforos\": {");
    JSONObject semaforos = data.getJSONObject("semaforos");
    String[] keys = (String[]) semaforos.keys().toArray(new String[0]);
    for (int i = 0; i < keys.length; i++) {
      sb.append("\"").append(keys[i]).append("\":\"").append(semaforos.getString(keys[i])).append("\"");
      if (i < keys.length - 1) sb.append(",");
    }
    sb.append("},\n");
    
    // Distancias
    sb.append("  \"dist_cm\": {");
    JSONObject distancias = data.getJSONObject("dist_cm");
    keys = (String[]) distancias.keys().toArray(new String[0]);
    for (int i = 0; i < keys.length; i++) {
      sb.append("\"").append(keys[i]).append("\":").append(distancias.getInt(keys[i]));
      if (i < keys.length - 1) sb.append(",");
    }
    sb.append("},\n");
    
    // Gas
    sb.append("  \"gas_ppm\": {");
    JSONObject gas = data.getJSONObject("gas_ppm");
    keys = (String[]) gas.keys().toArray(new String[0]);
    for (int i = 0; i < keys.length; i++) {
      sb.append("\"").append(keys[i]).append("\":").append(gas.getInt(keys[i]));
      if (i < keys.length - 1) sb.append(",");
    }
    sb.append("},\n");
    
    // Pánico
    sb.append("  \"panico\": {");
    JSONObject panico = data.getJSONObject("panico");
    keys = (String[]) panico.keys().toArray(new String[0]);
    for (int i = 0; i < keys.length; i++) {
      sb.append("\"").append(keys[i]).append("\":").append(panico.getInt(keys[i]));
      if (i < keys.length - 1) sb.append(",");
    }
    sb.append("},\n");
    
    // Infracciones
    sb.append("  \"infracciones\": [");
    JSONArray infracciones = data.getJSONArray("infracciones");
    for (int i = 0; i < infracciones.size(); i++) {
      sb.append("\"").append(infracciones.getString(i)).append("\"");
      if (i < infracciones.size() - 1) sb.append(",");
    }
    sb.append("]\n");
    
    sb.append("}");
    
    return sb.toString();
  }
  
  // Generar timestamp actual en formato ISO
  String getCurrentTimestamp() {
    return year() + "-" + 
           nf(month(), 2) + "-" + 
           nf(day(), 2) + "T" + 
           nf(hour(), 2) + ":" + 
           nf(minute(), 2) + ":" + 
           nf(second(), 2) + "Z";
  }
  
  // Métodos específicos para obtener datos por categoría
  JSONObject getSemaforoData() {
    return getCurrentData().getJSONObject("semaforos");
  }
  
  JSONObject getDistanciaData() {
    return getCurrentData().getJSONObject("dist_cm");
  }
  
  JSONObject getGasData() {
    return getCurrentData().getJSONObject("gas_ppm");
  }
  
  JSONObject getPanicoData() {
    return getCurrentData().getJSONObject("panico");
  }
  
  JSONArray getInfraccionesData() {
    return getCurrentData().getJSONArray("infracciones");
  }
  
  // Configurar intervalo de actualización
  void setUpdateInterval(int intervalMs) {
    this.updateInterval = intervalMs;
  }
  
  
  // Habilitar/deshabilitar modo serial (datos externos)
  void setSerialMode(boolean enabled) {
    this.serialMode = enabled;
    if (enabled) {
      lastSerialDataTime = millis(); // Resetear timeout
      println("[DataProvider] Modo serial activado. Esperando datos reales...");
    } else {
      println("[DataProvider] Modo serial desactivado. Usando datos simulados.");
    }
  }
  
  boolean isSerialMode() {
    return serialMode;
  }
  
  // Nuevos métodos para control de simulación
  void setSimulationEnabled(boolean enabled) {
    this.simulationEnabled = enabled;
    if (enabled) {
      println("[DataProvider] Simulación activada.");
      lastSource = "simulado_manual";
    } else {
      println("[DataProvider] Simulación desactivada. Solo datos reales.");
      lastSource = serialMode ? "serial" : "desconectado";
    }
  }
  
  boolean isSimulationEnabled() {
    return simulationEnabled;
  }
  
  // Intercambiar entre modos
  void toggleDataMode() {
    if (serialMode && !simulationEnabled) {
      // Está en modo serial puro -> cambiar a simulado
      setSimulationEnabled(true);
      println("[DataProvider] Cambiado a: DATOS SIMULADOS");
    } else if (simulationEnabled) {
      // Está en modo simulado -> cambiar a serial puro (si hay conexión)
      if (serialMode) {
        setSimulationEnabled(false);
        println("[DataProvider] Cambiado a: DATOS REALES (Serial)");
      } else {
        println("[DataProvider] No hay conexión serial. Manteniendo simulación.");
      }
    }
  }
  
  // Obtener estado actual del modo
  String getCurrentMode() {
    if (!serialMode) {
      return "Solo Simulado";
    } else if (simulationEnabled) {
      return isSerialTimedOut() ? "Simulado (Serial timeout)" : "Simulado (Manual)";
    } else {
      return isSerialTimedOut() ? "Desconectado" : "Datos Reales";
    }
  }
  
  // Inyectar datos externos (por ejemplo, desde Arduino)
  void setExternalData(JSONObject externalData) {
    if (externalData == null) return;
    
    this.currentData = externalData;
    this.lastUpdateTime = millis();
    this.lastSerialDataTime = millis(); // Actualizar timestamp de datos serial
    this.lastSource = "serial";
    updateCount++;
    
    // Si recibimos datos reales, automáticamente desactivar simulación (a menos que esté forzada)
    if (simulationEnabled && serialMode) {
      println("[DataProvider] Datos reales recibidos. Desactivando simulación automática.");
      // No desactivar simulationEnabled aquí para mantener control manual
    }
  }
  
  
  // Forzar actualización de datos
  void forceUpdate() {
    if (simulationEnabled) {
      generateNewData();
      lastUpdateTime = millis();
      println("[DataProvider] Actualización forzada de datos simulados.");
    } else if (serialMode) {
      println("[DataProvider] En modo serial. No se pueden forzar datos simulados.");
    }
  }
  
  // Forzar reconexión serial
  void forceSerialReconnection() {
    lastSerialDataTime = millis();
    println("[DataProvider] Timeout de serial reseteado. Intentando reconectar...");
  }

  // --- Diagnóstico ---
  String getLastSource() {
    return lastSource;
  }

  int getUpdateCount() {
    return updateCount;
  }

  String getLastTimestamp() {
    if (currentData == null) return "";
    if (currentData.hasKey("ts")) return currentData.getString("ts");
    return "";
  }
  
  // Información de estado detallada
  String getDetailedStatus() {
    StringBuilder status = new StringBuilder();
    status.append("=== ESTADO DEL DATA PROVIDER ===\n");
    status.append("Modo actual: ").append(getCurrentMode()).append("\n");
    status.append("Serial habilitado: ").append(serialMode ? "SÍ" : "NO").append("\n");
    status.append("Simulación habilitada: ").append(simulationEnabled ? "SÍ" : "NO").append("\n");
    status.append("Última fuente: ").append(lastSource).append("\n");
    status.append("Actualizaciones totales: ").append(updateCount).append("\n");
    status.append("Último timestamp: ").append(getLastTimestamp()).append("\n");
    
    if (serialMode) {
      long timeSinceSerial = millis() - lastSerialDataTime;
      status.append("Tiempo sin datos serial: ").append(timeSinceSerial).append("ms\n");
      status.append("Timeout serial: ").append(isSerialTimedOut() ? "SÍ" : "NO").append("\n");
    }
    
    status.append("Intervalo de actualización: ").append(updateInterval).append("ms\n");
    status.append("=================================");
    return status.toString();
  }
  
  // Obtener estadísticas rápidas
  TrafficStats getStats() {
    JSONObject data = getCurrentData();
    
    // Contar semáforos por estado
    JSONObject semaforos = data.getJSONObject("semaforos");
    int rojosCount = 0, verdesCount = 0, amarillosCount = 0;
    
    for (String semaforoId : semaforoIds) {
      String estado = semaforos.getString(semaforoId);
      if (estado.equals("ROJO")) rojosCount++;
      else if (estado.equals("VERDE")) verdesCount++;
      else if (estado.equals("AMARILLO")) amarillosCount++;
    }
    
    // Contar zonas en pánico
    JSONObject panico = data.getJSONObject("panico");
    int panicoCount = 0;
    for (String zonaId : zonaIds) {
      if (panico.getInt(zonaId) == 1) panicoCount++;
    }
    
    // Contar infracciones
    JSONArray infracciones = data.getJSONArray("infracciones");
    int infraccionesCount = infracciones.size();
    
    // Calcular promedio de gas
    JSONObject gas = data.getJSONObject("gas_ppm");
    int gasTotal = 0;
    for (String zonaId : zonaIds) {
      gasTotal += gas.getInt(zonaId);
    }
    int gasPromedio = gasTotal / zonaIds.length;
    
    return new TrafficStats(rojosCount, verdesCount, amarillosCount, 
                           panicoCount, infraccionesCount, gasPromedio);
  }
}

// Clase auxiliar para estadísticas
class TrafficStats {
  public int semaforosRojos;
  public int semaforosVerdes; 
  public int semaforosAmarillos;
  public int zonasPanico;
  public int infracciones;
  public int gasPromedio;
  
  TrafficStats(int rojos, int verdes, int amarillos, int panico, int infracciones, int gas) {
    this.semaforosRojos = rojos;
    this.semaforosVerdes = verdes;
    this.semaforosAmarillos = amarillos;
    this.zonasPanico = panico;
    this.infracciones = infracciones;
    this.gasPromedio = gas;
  }
}

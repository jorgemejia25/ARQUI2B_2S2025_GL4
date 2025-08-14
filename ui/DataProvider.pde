// Proveedor de datos simulado para el sistema de tráfico urbano
// Simula comunicación serial con datos de semáforos y paradas

class DataProvider {
  private JSONObject currentData;
  private long lastUpdateTime;
  private int updateInterval = 2000; // Actualizar cada 2 segundos
  
  // Cuando está activo, el proveedor no genera datos simulados y
  // espera datos externos (por ejemplo, por Serial)
  private boolean serialMode = false;
  
  // Metadatos de diagnóstico
  private String lastSource = "simulado"; // "simulado" | "serial"
  private int updateCount = 0;
  
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
    generateNewData();
  }
  
  // Método principal para obtener datos actuales
  JSONObject getCurrentData() {
    // En modo serial, no generamos datos simulados automáticamente
    if (!serialMode) {
      if (millis() - lastUpdateTime > updateInterval) {
        generateNewData();
        lastUpdateTime = millis();
      }
    }
    
    return currentData;
  }
  
  // Generar nuevos datos simulados
  void generateNewData() {
    currentData = new JSONObject();
    
    // Timestamp actual
    currentData.setString("ts", getCurrentTimestamp());
    
    // Generar estados de semáforos
    JSONObject semaforos = new JSONObject();
    for (String semaforoId : semaforoIds) {
      String estado = semaforoStates[int(random(3))];
      semaforos.setString(semaforoId, estado);
    }
    currentData.setJSONObject("semaforos", semaforos);
    
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
    
    // Generar infracciones (lista de paradas con infracciones)
    JSONArray infracciones = new JSONArray();
    for (String paradaId : paradaIds) {
      if (random(1) > 0.7) { // 30% probabilidad de infracción
        infracciones.append(paradaId);
      }
    }
    currentData.setJSONArray("infracciones", infracciones);
    lastSource = "simulado";
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
  }
  
  boolean isSerialMode() {
    return serialMode;
  }
  
  // Inyectar datos externos (por ejemplo, desde Arduino)
  void setExternalData(JSONObject externalData) {
    if (externalData == null) return;
    this.currentData = externalData;
    this.lastUpdateTime = millis();
    this.lastSource = "serial";
    updateCount++;
  }
  
  // Forzar actualización de datos
  void forceUpdate() {
    if (!serialMode) {
      generateNewData();
      lastUpdateTime = millis();
    }
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

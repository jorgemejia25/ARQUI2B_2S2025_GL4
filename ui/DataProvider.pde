import java.util.HashSet;

// Proveedor de datos para el sistema de tráfico urbano
class DataProvider {
  private JSONObject currentData;
  private long lastUpdateTime;
  private int updateInterval = 2000; // Actualizar cada 2 segundos
  private int semaforoCycleMs = 5000; // Duración del ciclo para semáforos
  private long lastSemaforoChangeTime = 0;
  private JSONObject semaforosCache = null; // cache para mantener estado hasta próximo ciclo
  
  // Modos de operación
  private boolean serialMode = false;
  private boolean simulationEnabled = true;
  
  // Metadatos de diagnóstico
  private String lastSource = "simulado"; // "simulado" | "serial" | "desconectado"
  private int updateCount = 0;
  private long serialTimeoutMs = 5000; // 5 s sin datos serial => timeout
  private long lastSerialDataTime = 0;
  
  // Estados posibles para semáforos
  private String[] semaforoStates = {"ROJO", "VERDE", "AMARILLO"};
  
  // IDs
  private String[] semaforoIds = {"S1", "S2", "S3", "S4", "S5", "S6", "S7", "S8", "S9", "S10"};
  private String[] paradaIds   = {"P1", "P2", "P3", "P4", "P5", "P6"};
  private String[] zonaIds     = {"Z1", "Z2"};
  private String[] panicButtonIds = {"PB1", "PB2", "PB3", "PB4"};
  private int[] panicButtonsCooldown = new int[4];

  // Sismo simulado
  private int sismoCooldown = 0;
  private float lastSismoMagnitud = 0;
  private String sismoOrigin = "";
  
  // === NUEVO: conjunto de infracciones recibidas ===
  private final HashSet<String> infraSet = new HashSet<String>();

  DataProvider() {
    lastUpdateTime = millis();
    lastSerialDataTime = millis();
    generateNewData();
  }

  // ======= Reglas de fallback (solo si NO llega 'infracciones' desde Arduino) =======
  JSONArray computeInfraccionesFromSemaforos(JSONObject data) {
    JSONArray result = new JSONArray();
    try {
      JSONObject semaforos = data.getJSONObject("semaforos");
      JSONObject dist = data.getJSONObject("dist_cm");
      int umbral = 50;
      for (int i = 0; i < semaforoIds.length; i++) {
        String semId = semaforoIds[i];
        int pidx = (i % paradaIds.length); // S1..S10 -> P1..P6 cíclico
        String paradaId = paradaIds[pidx];
        if (semaforos.hasKey(semId) && dist.hasKey(paradaId)) {
          String estado = semaforos.getString(semId);
          int d = dist.getInt(paradaId);
          if ("ROJO".equals(estado) && d < umbral) result.append(semId);
        }
      }
    } catch (Exception e) { }
    return result;
  }

  // Método principal para obtener datos actuales
  JSONObject getCurrentData() {
    checkSerialTimeout();
    if (simulationEnabled && (!serialMode || isSerialTimedOut())) {
      if (millis() - lastUpdateTime > updateInterval) {
        generateNewData();
        lastUpdateTime = millis();
      }
    }
    return currentData;
  }
  
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
    currentData.setString("ts", getCurrentTimestamp());
    
    updateSemaforosIfNeeded();
    currentData.setJSONObject("semaforos", semaforosCache);

    // Distancias
    JSONObject distancias = new JSONObject();
    for (String paradaId : paradaIds) {
      int distancia = int(random(20, 500));
      distancias.setInt(paradaId, distancia);
    }
    currentData.setJSONObject("dist_cm", distancias);
    
    // Gas
    JSONObject gas = new JSONObject();
    for (String zonaId : zonaIds) {
      int gasPpm = int(random(150, 300));
      gas.setInt(zonaId, gasPpm);
    }
    currentData.setJSONObject("gas_ppm", gas);
    
    // Zumbador (derivable de PBs si quieres, lo dejamos aleatorio simple)
    JSONObject zumbador = new JSONObject();
    for (String zonaId : zonaIds) {
      int zState = random(1) > 0.8 ? 1 : 0;
      zumbador.setInt(zonaId, zState);
    }
    currentData.setJSONObject("zumbador", zumbador);

    // Sismo
    JSONObject sismo = new JSONObject();
    if (sismoCooldown > 0) {
      sismo.setInt("activo", 1);
      sismo.setFloat("magnitud", lastSismoMagnitud);
      sismo.setString("origen", sismoOrigin == null ? "" : sismoOrigin);
      sismoCooldown--;
    } else {
      if (random(1) > 0.95) {
        lastSismoMagnitud = round(random(3.0, 6.8) * 10) / 10.0;
        sismoCooldown = int(random(2, 5));
        sismoOrigin = "simulado";
        sismo.setInt("activo", 1);
        sismo.setFloat("magnitud", lastSismoMagnitud);
        sismo.setString("origen", sismoOrigin);
      } else {
        sismo.setInt("activo", 0);
        sismo.setFloat("magnitud", 0);
        sismo.setString("origen", "");
        sismoOrigin = "";
      }
    }
    currentData.setJSONObject("sismo", sismo);

    // Botones de pánico (4)
    JSONObject panicButtons = new JSONObject();
    for (int i = 0; i < panicButtonIds.length; i++) {
      int active;
      if (panicButtonsCooldown[i] > 0) { active = 1; panicButtonsCooldown[i]--; }
      else { active = (random(1) > 0.94) ? 1 : 0; if (active==1) panicButtonsCooldown[i] = int(random(1,3)); }
      JSONObject btn = new JSONObject();
      btn.setInt("activo", active);
      btn.setString("ts", getCurrentTimestamp());
      btn.setString("id", panicButtonIds[i]);
      panicButtons.setJSONObject(panicButtonIds[i], btn);
    }
    currentData.setJSONObject("panic_buttons", panicButtons);

    // === Infracciones: en simulación, por defecto VACÍO ===
    currentData.setJSONArray("infracciones", new JSONArray());
    infraSet.clear();

    if (simulationEnabled) {
      lastSource = serialMode && !isSerialTimedOut() ? "simulado_manual" : "simulado";
    }
    updateCount++;
  }
  
  // Strings helper
  String getDataAsString() { return getCurrentData().toString(); }
  String getDataAsFormattedString() {
    JSONObject data = getCurrentData();
    StringBuilder sb = new StringBuilder();
    sb.append("{\n");
    sb.append("  \"ts\": \"").append(data.getString("ts")).append("\",\n");
    sb.append("  \"semaforos\": ").append(data.getJSONObject("semaforos")).append(",\n");
    sb.append("  \"dist_cm\": ").append(data.getJSONObject("dist_cm")).append(",\n");
    sb.append("  \"gas_ppm\": ").append(data.getJSONObject("gas_ppm")).append(",\n");
    sb.append("  \"zumbador\": ").append(data.getJSONObject("zumbador")).append(",\n");
    sb.append("  \"infracciones\": ").append(data.getJSONArray("infracciones")).append("\n");
    sb.append("}");
    return sb.toString();
  }
  
  String getCurrentTimestamp() {
    return year() + "-" + nf(month(), 2) + "-" + nf(day(), 2) + "T" +
           nf(hour(), 2) + ":" + nf(minute(), 2) + ":" + nf(second(), 2) + "Z";
  }
  
  JSONObject getSemaforoData() { return getCurrentData().getJSONObject("semaforos"); }
  JSONObject getDistanciaData() { return getCurrentData().getJSONObject("dist_cm"); }
  JSONObject getGasData() { return getCurrentData().getJSONObject("gas_ppm"); }
  JSONObject getZumbadorData() { return getCurrentData().getJSONObject("zumbador"); }
  JSONObject getSismoData() { return getCurrentData().getJSONObject("sismo"); }
  JSONObject getPanicButtonsData() { return getCurrentData().getJSONObject("panic_buttons"); }
  JSONArray  getInfraccionesData() { return getCurrentData().getJSONArray("infracciones"); }

  // === NUEVO: consulta para la UI ===
  boolean isInfraction(String sid) { return infraSet.contains(sid); }

  // Sismos manuales (opcional)
  void triggerSismo(float magnitud, int duracionCiclos, String origin) {
    if (magnitud <= 0) magnitud = round(random(3.0, 6.5) * 10) / 10.0;
    if (duracionCiclos <= 0) duracionCiclos = 3;
    lastSismoMagnitud = magnitud;
    sismoCooldown = duracionCiclos;
    sismoOrigin = origin == null ? "manual" : origin;
    JSONObject sismo = new JSONObject();
    sismo.setInt("activo", 1);
    sismo.setFloat("magnitud", lastSismoMagnitud);
    sismo.setString("origen", sismoOrigin);
    currentData.setJSONObject("sismo", sismo);
  }
  void resetSismo() {
    lastSismoMagnitud = 0; sismoCooldown = 0; sismoOrigin = "";
    JSONObject sismo = new JSONObject();
    sismo.setInt("activo", 0); sismo.setFloat("magnitud", 0); sismo.setString("origen", "");
    currentData.setJSONObject("sismo", sismo);
  }
  void triggerPanicButton(String origin) {
    // Forzar PB1 solo en sim
    if (simulationEnabled) {
      JSONObject pb = currentData.hasKey("panic_buttons") ? currentData.getJSONObject("panic_buttons") : new JSONObject();
      JSONObject btn = new JSONObject();
      btn.setInt("activo", 1);
      btn.setString("ts", getCurrentTimestamp());
      btn.setString("id", "PB1");
      pb.setJSONObject("PB1", btn);
      currentData.setJSONObject("panic_buttons", pb);
    }
  }
  void resetPanicButton() {
    if (simulationEnabled) {
      JSONObject pb = currentData.hasKey("panic_buttons") ? currentData.getJSONObject("panic_buttons") : new JSONObject();
      JSONObject btn = new JSONObject();
      btn.setInt("activo", 0);
      btn.setString("ts", getCurrentTimestamp());
      btn.setString("id", "PB1");
      pb.setJSONObject("PB1", btn);
      currentData.setJSONObject("panic_buttons", pb);
    }
  }
  
  // Config
  void setUpdateInterval(int intervalMs) { this.updateInterval = intervalMs; }
  int  getUpdateInterval() { return updateInterval; }
  void setSemaforoCycle(int ms) { semaforoCycleMs = ms; }
  int  getSemaforoCycle() { return semaforoCycleMs; }
  
  void setSerialMode(boolean enabled) {
    this.serialMode = enabled;
    if (enabled) {
      lastSerialDataTime = millis();
      println("[DataProvider] Modo serial activado. Esperando datos reales...");
    } else {
      println("[DataProvider] Modo serial desactivado. Usando datos simulados.");
    }
  }
  boolean isSerialMode() { return serialMode; }
  
  void setSimulationEnabled(boolean enabled) {
    this.simulationEnabled = enabled;
    if (enabled) { println("[DataProvider] Simulación activada."); lastSource = "simulado_manual"; }
    else { println("[DataProvider] Simulación desactivada. Solo datos reales."); lastSource = serialMode ? "serial" : "desconectado"; }
  }
  boolean isSimulationEnabled() { return simulationEnabled; }
  
  void toggleDataMode() {
    if (serialMode && !simulationEnabled) {
      setSimulationEnabled(true);
      println("[DataProvider] Cambiado a: DATOS SIMULADOS");
    } else if (simulationEnabled) {
      if (serialMode) {
        setSimulationEnabled(false);
        println("[DataProvider] Cambiado a: DATOS REALES (Serial)");
      } else {
        println("[DataProvider] No hay conexión serial. Manteniendo simulación.");
      }
    }
  }
  
  String getCurrentMode() {
    if (!serialMode) return "Solo Simulado";
    else if (simulationEnabled) return isSerialTimedOut() ? "Simulado (Serial timeout)" : "Simulado (Manual)";
    else return isSerialTimedOut() ? "Desconectado" : "Datos Reales";
  }
  
  // Inyectar datos externos (Arduino)
  void setExternalData(JSONObject externalData) {
    if (externalData == null) return;
    
    this.currentData = externalData;
    this.lastUpdateTime = millis();
    this.lastSerialDataTime = millis();
    this.lastSource = "serial";
    updateCount++;

    // === Capturar infracciones EXACTAMENTE como vienen ===
    infraSet.clear();
    if (externalData.hasKey("infracciones")) {
      try {
        JSONArray arr = externalData.getJSONArray("infracciones");
        for (int i = 0; i < arr.size(); i++) {
          String sid = arr.getString(i);
          if (sid != null) infraSet.add(sid);
        }
      } catch(Exception e) { }
    } else {
      // Fallback: si Arduino no envía el campo, podemos calcularlo
      JSONArray fallback = computeInfraccionesFromSemaforos(externalData);
      for (int i = 0; i < fallback.size(); i++) infraSet.add(fallback.getString(i));
      currentData.setJSONArray("infracciones", fallback);
    }
  }
  
  void forceUpdate() {
    if (simulationEnabled) {
      generateNewData();
      lastUpdateTime = millis();
      println("[DataProvider] Actualización forzada de datos simulados.");
    } else if (serialMode) {
      println("[DataProvider] En modo serial. No se pueden forzar datos simulados.");
    }
  }
  void forceSerialReconnection() {
    lastSerialDataTime = millis();
    println("[DataProvider] Timeout de serial reseteado. Intentando reconectar...");
  }

  // --- Diagnóstico ---
  String getLastSource() { return lastSource; }
  int getUpdateCount() { return updateCount; }
  String getLastTimestamp() {
    if (currentData == null) return "";
    if (currentData.hasKey("ts")) return currentData.getString("ts");
    return "";
  }
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
  
  // Estadísticas rápidas (NO pisa 'infracciones' si ya vino de Arduino)
  TrafficStats getStats() {
    JSONObject data = getCurrentData();
    
    JSONObject semaforos = data.getJSONObject("semaforos");
    int rojosCount = 0, verdesCount = 0, amarillosCount = 0;
    for (String semaforoId : semaforoIds) {
      String estado = semaforos.getString(semaforoId);
      if ("ROJO".equals(estado)) rojosCount++;
      else if ("VERDE".equals(estado)) verdesCount++;
      else if ("AMARILLO".equals(estado)) amarillosCount++;
    }

    // Asegurar que currentData tenga el arreglo 'infracciones'
    if (!data.hasKey("infracciones")) {
      JSONArray fallback = computeInfraccionesFromSemaforos(data);
      data.setJSONArray("infracciones", fallback);
      infraSet.clear();
      for (int i = 0; i < fallback.size(); i++) infraSet.add(fallback.getString(i));
    }
    int infraccionesCount = data.getJSONArray("infracciones").size();

    // PBs activos como “zumbador”
    int zumbadorCount = 0;
    if (data.hasKey("panic_buttons")) {
      try {
        JSONObject pbs = data.getJSONObject("panic_buttons");
        String[] pbKeys = (String[]) pbs.keys().toArray(new String[0]);
        for (int i = 0; i < pbKeys.length; i++) {
          JSONObject btn = pbs.getJSONObject(pbKeys[i]);
          if (btn.hasKey("activo") && btn.getInt("activo") == 1) zumbadorCount++;
        }
      } catch(Exception ex) { }
    }

    JSONObject gas = data.getJSONObject("gas_ppm");
    int gasTotal = 0;
    for (String zonaId : zonaIds) gasTotal += gas.getInt(zonaId);
    int gasPromedio = gasTotal / zonaIds.length;
    
    return new TrafficStats(rojosCount, verdesCount, amarillosCount, zumbadorCount, infraccionesCount, gasPromedio);
  }

  // Actualiza los semáforos solo cuando el ciclo se cumple
  void updateSemaforosIfNeeded() {
    if (semaforosCache == null) {
      semaforosCache = new JSONObject();
      for (String id : semaforoIds) semaforosCache.setString(id, semaforoStates[int(random(3))]);
      lastSemaforoChangeTime = millis();
      return;
    }
    if (millis() - lastSemaforoChangeTime >= semaforoCycleMs) {
      for (String id : semaforoIds) {
        String estado = semaforosCache.getString(id);
        String nuevo = "ROJO";
        if ("ROJO".equals(estado)) nuevo = "VERDE";
        else if ("VERDE".equals(estado)) nuevo = "AMARILLO";
        else nuevo = "ROJO";
        semaforosCache.setString(id, nuevo);
      }
      lastSemaforoChangeTime = millis();
    }
  }
}

// Clase auxiliar para estadísticas
class TrafficStats {
  public int semaforosRojos;
  public int semaforosVerdes; 
  public int semaforosAmarillos;
  public int zonasZumbador;
  public int infracciones;
  public int gasPromedio;
  
  TrafficStats(int rojos, int verdes, int amarillos, int zumbadorCount, int infracciones, int gas) {
    this.semaforosRojos = rojos;
    this.semaforosVerdes = verdes;
    this.semaforosAmarillos = amarillos;
    this.zonasZumbador = zumbadorCount;
    this.infracciones = infracciones;
    this.gasPromedio = gas;
  }
}

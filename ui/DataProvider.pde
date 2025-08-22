// Proveedor de datos simulado para el sistema de tráfico urbano
// Simula comunicación serial con datos de semáforos y paradas

class DataProvider {
  private JSONObject currentData;
  private long lastUpdateTime;
  private int updateInterval = 2000; // Actualizar cada 2 segundos
  private int semaforoCycleMs = 5000; // Duración del ciclo rojo->verde (aprox) para semáforos
  private long lastSemaforoChangeTime = 0;
  private JSONObject semaforosCache = null; // cache para mantener estado hasta próximo ciclo
  
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
  private String[] zonaIds = {"Z1", "Z2"};

  // NUEVO: 4 botones de pánico independientes
  private String[] panicButtonIds = {"PB1", "PB2", "PB3", "PB4"};
  private int[] panicButtonsCooldown = new int[4];

  // --- NUEVO: Simulación de sismos y botón de pánico global ---
  private int sismoCooldown = 0;          // Cuántos ciclos más permanece activo un sismo
  private float lastSismoMagnitud = 0;    // Magnitud del sismo activo
  private boolean panicButtonActive = false; // Estado momentáneo del botón de pánico
  private int panicButtonCooldown = 0;       // Mantener activo algunos ciclos
  private String panicButtonOrigin = "simulado"; // Origen de última activación
  private String sismoOrigin = "";          // Origen del sismo (simulado/manual/serial)
  
  DataProvider() {
    lastUpdateTime = millis();
    lastSerialDataTime = millis();
    generateNewData();
  }

  // Derivar infracciones a partir de semáforos (S1..S10) y distancias en paradas (P1..P6)
  // Regla simple y documentada: si el semáforo correspondiente está en ROJO y la distancia
  // en la parada asociada < 50cm => contar como infracción para ese semáforo.
  // Asociaciones (simplificadas): P1->S1, P2->S2, P3->S3, P4->S4, P5->S5, P6->S6
  JSONArray computeInfraccionesFromSemaforos(JSONObject data) {
    JSONArray result = new JSONArray();
    try {
      JSONObject semaforos = data.getJSONObject("semaforos");
      JSONObject dist = data.getJSONObject("dist_cm");
      // Umbral de infracción en cm
      int umbral = 50;
      // Mapear semáforos S1..S10 a paradas P1..P6 de forma que todos los semáforos
      // se puedan evaluar: S1->P1, S2->P2, ... S6->P6, S7->P1, S8->P2, S9->P3, S10->P4
      for (int i = 0; i < semaforoIds.length; i++) {
        String semId = semaforoIds[i];
        int paradaIndex = i; // índice correspondiente a la parada
        if (paradaIndex >= paradaIds.length) {
          // envolver para cubrir S7..S10
          paradaIndex = paradaIndex % paradaIds.length;
        }
        String paradaId = paradaIds[paradaIndex];
        if (semaforos.hasKey(semId) && dist.hasKey(paradaId)) {
          String estado = semaforos.getString(semId);
          int d = dist.getInt(paradaId);
          if (estado.equals("ROJO") && d < umbral) {
            result.append(semId);
          }
        }
      }
    } catch (Exception e) {
      // si faltan datos, devolver arreglo vacío
    }
    return result;
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
    
  // Actualizar semáforos solo si tocó el ciclo
  updateSemaforosIfNeeded();
  currentData.setJSONObject("semaforos", semaforosCache);

  // Nota: se utiliza únicamente el mapa "semaforos" (S1..S10). Evitamos generar estructuras redundantes.
  // Si se desea una vista por calles, el UI puede derivarla desde "semaforos".
    
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
    
    // Generar estado de zumbador por zona (antes 'panico') (0 o 1)
    JSONObject zumbador = new JSONObject();
    for (String zonaId : zonaIds) {
      int zState = random(1) > 0.8 ? 1 : 0; // 20% probabilidad de activación
      zumbador.setInt(zonaId, zState);
    }
    currentData.setJSONObject("zumbador", zumbador);

    // --- NUEVO: Generar / mantener sismo ---
    JSONObject sismo = new JSONObject();
    if (sismoCooldown > 0) {
      // Sismo en curso (manual o simulado previamente)
      sismo.setInt("activo", 1);
      sismo.setFloat("magnitud", lastSismoMagnitud);
      sismo.setString("origen", sismoOrigin == null ? "" : sismoOrigin);
      sismoCooldown--;
    } else {
      // Posible nuevo sismo aleatorio (5% prob.) sólo si no hay uno manual activo
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

  // Nota: eliminamos el botón de pánico global. Solo mantenemos los botones individuales (panic_buttons).

    // --- NUEVO: Colección de 4 botones de pánico independientes ---
    JSONObject panicButtons = new JSONObject();
    for (int i = 0; i < panicButtonIds.length; i++) {
      int active;
      if (panicButtonsCooldown[i] > 0) {
        active = 1;
        panicButtonsCooldown[i]--;
      } else {
        // 6% probabilidad de activación si está inactivo
        if (random(1) > 0.94) {
          active = 1;
          panicButtonsCooldown[i] = int(random(1,3));
        } else {
          active = 0;
        }
      }
      JSONObject btn = new JSONObject();
      btn.setInt("activo", active);
      btn.setString("ts", getCurrentTimestamp());
      btn.setString("id", panicButtonIds[i]);
      panicButtons.setJSONObject(panicButtonIds[i], btn);
    }
    currentData.setJSONObject("panic_buttons", panicButtons);
    
  // (Se elimina infracciones_detalle: ahora las infracciones se derivan de semáforos)
    
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
    
    // Zumbador (antes 'panico')
    sb.append("  \"zumbador\": {");
    JSONObject zumb = data.getJSONObject("zumbador");
    keys = (String[]) zumb.keys().toArray(new String[0]);
    for (int i = 0; i < keys.length; i++) {
      sb.append("\"").append(keys[i]).append("\":").append(zumb.getInt(keys[i]));
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
  
  JSONObject getZumbadorData() {
    return getCurrentData().getJSONObject("zumbador");
  }

  // NUEVO: Acceso a datos de sismo
  JSONObject getSismoData() {
    return getCurrentData().getJSONObject("sismo");
  }

  // Acceso a los 4 botones
  JSONObject getPanicButtonsData() {
    return getCurrentData().getJSONObject("panic_buttons");
  }

  // --- Sismos manuales ---
  void triggerSismo(float magnitud, int duracionCiclos, String origin) {
    if (magnitud <= 0) magnitud = round(random(3.0, 6.5) * 10) / 10.0;
    if (duracionCiclos <= 0) duracionCiclos = 3;
    lastSismoMagnitud = magnitud;
    sismoCooldown = duracionCiclos;
    sismoOrigin = origin == null ? "manual" : origin;
    // Actualizar JSON inmediato
    JSONObject sismo = new JSONObject();
    sismo.setInt("activo", 1);
    sismo.setFloat("magnitud", lastSismoMagnitud);
    sismo.setString("origen", sismoOrigin);
    currentData.setJSONObject("sismo", sismo);
  }

  void resetSismo() {
    lastSismoMagnitud = 0;
    sismoCooldown = 0;
    sismoOrigin = "";
    JSONObject sismo = new JSONObject();
    sismo.setInt("activo", 0);
    sismo.setFloat("magnitud", 0);
    sismo.setString("origen", "");
    currentData.setJSONObject("sismo", sismo);
  }

  // Activar manualmente el botón de pánico (desde UI)
  void triggerPanicButton(String origin) {
    // Para compatibilidad, cuando se active manualmente actualizamos el primer panic button (PB1)
    panicButtonCooldown = 2; // mantener visible unos ciclos internamente si es necesario
    String originVal = origin == null ? "manual" : origin;
    if (simulationEnabled) {
      // Forzar actualización del estado de PB1
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
    panicButtonCooldown = 0;
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
  
  JSONArray getInfraccionesData() {
    return getCurrentData().getJSONArray("infracciones");
  }
  
  // Configurar intervalo de actualización
  void setUpdateInterval(int intervalMs) {
    this.updateInterval = intervalMs;
  }
  int getUpdateInterval() { return updateInterval; }
  
  // Ciclo de semáforos
  void setSemaforoCycle(int ms) { semaforoCycleMs = ms; }
  int getSemaforoCycle() { return semaforoCycleMs; }
  
  
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
    
    // Contar zonas con zumbador activo (derivado de botones de pánico activos)
    int zumbadorCount = 0;
    if (data.hasKey("panic_buttons")) {
      try {
        JSONObject pbs = data.getJSONObject("panic_buttons");
        String[] pbKeys = (String[]) pbs.keys().toArray(new String[0]);
        for (int i = 0; i < pbKeys.length; i++) {
          JSONObject btn = pbs.getJSONObject(pbKeys[i]);
            if (btn.hasKey("activo") && btn.getInt("activo") == 1) zumbadorCount++;
        }
      } catch(Exception ex) {
        // Silenciar errores en caso de formato inesperado
      }
    }
    
    // Contar infracciones: calcular a partir de semáforos (S1..S10) y distancias
    JSONArray computedInfracciones = computeInfraccionesFromSemaforos(data);
    int infraccionesCount = computedInfracciones.size();
    // Exponer el resultado en currentData para compatibilidad visual
    try {
      currentData.setJSONArray("infracciones", computedInfracciones);
    } catch (Exception e) {}
    
    // Calcular promedio de gas
    JSONObject gas = data.getJSONObject("gas_ppm");
    int gasTotal = 0;
    for (String zonaId : zonaIds) {
      gasTotal += gas.getInt(zonaId);
    }
    int gasPromedio = gasTotal / zonaIds.length;
    
  return new TrafficStats(rojosCount, verdesCount, amarillosCount, 
               zumbadorCount, infraccionesCount, gasPromedio);
  }

  // Actualiza los semáforos solo cuando el ciclo se cumple
  void updateSemaforosIfNeeded() {
    if (semaforosCache == null) {
      semaforosCache = new JSONObject();
      for (String id : semaforoIds) {
        semaforosCache.setString(id, semaforoStates[int(random(3))]);
      }
      lastSemaforoChangeTime = millis();
      return;
    }
    if (millis() - lastSemaforoChangeTime >= semaforoCycleMs) {
      for (String id : semaforoIds) {
        String estado = semaforosCache.getString(id);
        String nuevo;
        if (estado.equals("ROJO")) nuevo = "VERDE";
        else if (estado.equals("VERDE")) nuevo = "AMARILLO";
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

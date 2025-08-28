// Pantalla para monitoreo de distancias a paradas de transporte

class DistanceScreen extends Screen {
  private DataProvider dataProvider;
  private ArrayList<InfoCard> transmetroCards;
  private ArrayList<InfoCard> transurbanoCards;
  // Eliminado gráfico de distancias (DistanceChart)
  private boolean isLongDistance = false;
  
  // IDs de paradas para compatibilidad con DataProvider
  private String[] paradaIds = {"P1", "P2", "P3", "P4", "P5", "P6"};
  
  DistanceScreen(float x, float y, float width, float height, DataProvider dataProvider) {
    super("Monitor de Distancias", x, y, width, height);
    this.dataProvider = dataProvider;
    
    initializeComponents();
  }
  
  void initializeComponents() {
    transmetroCards = new ArrayList<InfoCard>();
    transurbanoCards = new ArrayList<InfoCard>();
    
    // Layout más moderno con mejor espaciado
    float sectionY = y + 100;
    float cardSpacing = 180;
    float sectionSpacing = width / 2 - 40;
    
    // Tarjetas para Transmetro (2 paradas) - Lado izquierdo
    for (int i = 1; i <= 2; i++) {
      InfoCard transmetroCard = new InfoCard(
        "Parada " + i, 
        "0 cm", 
        Theme.GREEN, 
        x + 40, 
        sectionY + (i-1) * cardSpacing
      );
      transmetroCards.add(transmetroCard);
    }
    
    // Tarjetas para Transurbano (2 paradas) - Lado derecho
    for (int i = 1; i <= 2; i++) {
      InfoCard transurbanoCard = new InfoCard(
        "Parada " + i, 
        "0 cm", 
        Theme.GREEN, 
        x + sectionSpacing + 40, 
        sectionY + (i-1) * cardSpacing
      );
      transurbanoCards.add(transurbanoCard);
    }
    
  // (Gráfico eliminado)
  }
  
  void renderContent() {
    // Actualizar datos antes de renderizar
    updateDistanceData();
    
    // Header moderno con iconos
    renderModernHeader();
    
  // Secciones de transporte con diseño card-based
    renderTransportSection("Transurbano", x + 40, y + 70, width/2 - 60, transmetroCards, Theme.BLUE);
    renderTransportSection("Transmetro", x + width/2 + 20, y + 70, width/2 - 60, transurbanoCards, Theme.GREEN);
    
  // (Gráfico eliminado)
    
  // Mapa urbano simplificado con rutas y paradas
  renderUrbanMap();

  // Panel de información minimalista
    renderMinimalInfo();
  }
  
  void renderModernHeader() {
    
    // Subtítulo con mejor contraste
    fill(80, 80, 80); // Gris más oscuro
    textSize(14);
    text("Monitoreo en tiempo real de paradas de transporte público", x + 40, y + 60);
  }
  
  void renderTransportSection(String title, float sectionX, float sectionY, float sectionWidth, ArrayList<InfoCard> cards, color accentColor) {
    // Fondo de sección con mejor contraste
    fill(255, 255, 255); // Fondo blanco puro
    stroke(220, 220, 220); // Borde sutil
    strokeWeight(1);
    rect(sectionX, sectionY, sectionWidth, 340, 12);
    
    // Línea de acento superior
    fill(accentColor);
    noStroke();
    rect(sectionX, sectionY, sectionWidth, 4, 12, 12, 0, 0);
    
    // Título de sección con mejor contraste
    fill(30, 30, 30); // Negro casi puro
    textAlign(LEFT, TOP);
    textSize(18);
    text(title, sectionX + 20, sectionY + 20);
    
    // Renderizar tarjetas
    for (int i = 0; i < cards.size(); i++) {
      InfoCard card = cards.get(i);
      renderModernCard(card, sectionX + 20, sectionY + 60 + i * 130, sectionWidth - 40, accentColor);
    }
  }
  
  void renderModernCard(InfoCard card, float cardX, float cardY, float cardWidth, color accentColor) {
    JSONObject distancias = dataProvider.getDistanciaData();
    
    // Determinar si hay bus cerca (distancia < 30cm)
    String paradaId = "P" + (card == transurbanoCards.get(0) ? "1" : 
                             card == transurbanoCards.get(1) ? "2" :
                             card == transmetroCards.get(0) ? "3" : "4");

    // ETA invertido respecto al mapeo de distancia actual
    String paradaIdEta = "P" + (card == transurbanoCards.get(0) ? "3" : 
                                 card == transurbanoCards.get(1) ? "4" :
                                 card == transmetroCards.get(0) ? "1" : "2");
    
    int distance = distancias.getInt(paradaId);
    boolean busPresent = distance < 30;
    
    // Fondo de la tarjeta con efecto hover/presente
    if (busPresent) {
      // Efecto de pulso cuando hay bus
      float pulseIntensity = (sin(millis() * 0.01f) + 1) * 0.5f;
      fill(red(accentColor), green(accentColor), blue(accentColor), 50 + pulseIntensity * 30);
      rect(cardX - 5, cardY - 5, cardWidth + 10, 110, 8);
    }
    
    // Tarjeta principal con mejor contraste
    fill(255, 255, 255);
    stroke(230, 230, 230);
    strokeWeight(1);
    drawSoftShadow(cardX, cardY, cardWidth, 100, 1);
    rect(cardX, cardY, cardWidth, 100, 8);
    
    // Indicador de estado (círculo en esquina superior derecha)
    float indicatorX = cardX + cardWidth - 25;
    float indicatorY = cardY + 15;
    
    noStroke();
    if (busPresent) {
      fill(accentColor);
      ellipse(indicatorX, indicatorY, 12, 12);
      fill(255, 255, 255);
      ellipse(indicatorX, indicatorY, 8, 8);
    } else {
      fill(180, 180, 180);
      ellipse(indicatorX, indicatorY, 12, 12);
    }
    
    // Título de parada con mejor contraste
    fill(30, 30, 30); 
    textAlign(LEFT, TOP);
    textSize(16);
    text(card.title, cardX + 20, cardY + 15);
    
    // Estado del bus con mejor contraste
    fill(70, 70, 70); 
    textSize(12);
    if (busPresent) {
      text(" Bus presente", cardX + 20, cardY + 35);
    } else {
      text(" Esperando...", cardX + 20, cardY + 35);
    }
    
    // Distancia con tipografía grande y mejor contraste
    fill(busPresent ? accentColor : color(40, 40, 40));
    textAlign(LEFT, CENTER);
    textSize(24);
    text(distance + " cm", cardX + 20, cardY + 60);
    
    // ETA (Tiempo de llegada estimado)
    renderEtaInfo(cardX + 20, cardY + 75, cardWidth - 40, paradaIdEta, accentColor);
    
    // Barra de proximidad
    renderProximityBar(cardX + 20, cardY + 95, cardWidth - 40, distance, accentColor);
  }
  
  void renderEtaInfo(float etaX, float etaY, float etaWidth, String paradaId, color accentColor) {
    JSONObject etaData = dataProvider.getEtaData();
    
    if (!etaData.hasKey(paradaId)) {
      // Si no hay datos ETA, mostrar mensaje
      fill(120, 120, 120);
      textAlign(LEFT, CENTER);
      textSize(11);
      text("Sin datos ETA", etaX, etaY);
      return;
    }
    
    try {
      JSONObject etaInfo = etaData.getJSONObject(paradaId);
      int etaSeconds = etaInfo.getInt("eta_s");
      String status = etaInfo.getString("status");
      String type = etaInfo.getString("type");
      
      // Color del status
      color statusColor;
      if (etaSeconds < 60) {
        statusColor = color(0, 150, 0); // Verde para próximo
      } else if (etaSeconds < 180) {
        statusColor = color(255, 140, 0); // Naranja para en ruta
      } else {
        statusColor = color(100, 100, 100); // Gris para lejano
      }
      
      // Formatear tiempo
      String timeDisplay;
      if (etaSeconds < 60) {
        timeDisplay = etaSeconds + "s";
      } else {
        int minutes = etaSeconds / 60;
        int seconds = etaSeconds % 60;
        timeDisplay = minutes + ":" + nf(seconds, 2);
      }
      
      // Mostrar ETA
      fill(statusColor);
      textAlign(LEFT, CENTER);
      textSize(12);
      text("ETA: " + timeDisplay, etaX, etaY);
      
      // Mostrar status
      fill(80, 80, 80);
      textSize(10);
      text(status + " • " + type, etaX, etaY + 12);
      
    } catch (Exception e) {
      // En caso de error, mostrar mensaje
      fill(120, 120, 120);
      textAlign(LEFT, CENTER);
      textSize(11);
      text("Error ETA", etaX, etaY);
    }
  }
  
  void renderProximityBar(float barX, float barY, float barWidth, int distance, color accentColor) {
    // Fondo de la barra
    fill(240);
    noStroke();
    rect(barX, barY, barWidth, 6, 3);
    
    // Barra de progreso (invertida: más cerca = más llena)
    float progress = map(constrain(distance, 0, 200), 200, 0, 0, 1);
    fill(progress > 0.7 ? accentColor : 
         progress > 0.4 ? Theme.ORANGE : 
         Theme.LIGHT_GRAY);
    
    rect(barX, barY, barWidth * progress, 6, 3);
  }
  
  void updateDistanceData() {
    JSONObject distancias = dataProvider.getDistanciaData();

    // Obtener las distancias reales de DataProvider
    float[] distances = new float[4];
    distances[0] = distancias.getFloat("P1");
    distances[1] = distancias.getFloat("P2");
    distances[2] = distancias.getFloat("P3");
    distances[3] = distancias.getFloat("P4");

    // Actualizar datos internos de las tarjetas (ya no se usan para renderizar)
    for (int i = 0; i < transurbanoCards.size(); i++) {
        InfoCard card = transurbanoCards.get(i);
        float dist = distances[i];
        card.updateValue(String.format("%.1f cm", dist));
    }

    for (int i = 0; i < transmetroCards.size(); i++) {
        InfoCard card = transmetroCards.get(i);
        float dist = distances[i + 2];
        card.updateValue(String.format("%.1f cm", dist));
    }
  }
  
  color getDistanceColor(float distance, color baseColor) {
    if (distance > 200) {
      return Theme.LIGHT_GRAY;     
    } else if (distance > 100) {
      return Theme.MEDIUM_GRAY;  
    } else if (distance > 30) {
      return baseColor;           
    } else {
      return baseColor;          
    }
  }
  
  void renderMinimalInfo() {
    float infoY = y + height - 90; // Ajustado para más espacio
    
    // Panel de información con mejor visibilidad
    fill(255, 255, 255); // Fondo blanco puro
    stroke(200, 200, 200); // Borde visible
    strokeWeight(1);
    rect(x + 40, infoY, width - 80, 70, 8); // Altura aumentada
    
    // Línea de acento más visible
    fill(Theme.BLUE);
    noStroke();
    rect(x + 40, infoY, 4, 70, 2);
    
    JSONObject distancias = dataProvider.getDistanciaData();
    float[] distances = new float[4];
    distances[0] = distancias.getInt("P3");
    distances[1] = distancias.getInt("P4");
    distances[2] = distancias.getInt("P1");
    distances[3] = distancias.getInt("P2");
    
    float avgDistance = 0;
    int busesPresentes = 0;
    for (float dist : distances) {
      avgDistance += dist;
      if (dist < 30) busesPresentes++;
    }
    avgDistance /= distances.length;
    
    // Información compacta con mejor contraste
    fill(30, 30, 30); // Negro casi puro
    textAlign(LEFT, TOP);
    textSize(16); // Tamaño aumentado
    text("Resumen del sistema", x + 60, infoY + 15);
    
    fill(60, 60, 60); // Gris oscuro
    textSize(14); // Tamaño aumentado
    text("Buses presentes: " + busesPresentes + "/4  •  Distancia promedio: " + String.format("%.0f", avgDistance) + " cm", x + 60, infoY + 25);
    
    // Información de ETA
    JSONObject etaData = dataProvider.getEtaData();
    int busesConEta = 0;
    int etaPromedio = 0;
    int totalEta = 0;
    
    for (String paradaId : paradaIds) {
      if (etaData.hasKey(paradaId)) {
        try {
          JSONObject etaInfo = etaData.getJSONObject(paradaId);
          int etaSeconds = etaInfo.getInt("eta_s");
          totalEta += etaSeconds;
          busesConEta++;
        } catch (Exception e) {}
      }
    }
    
    if (busesConEta > 0) {
      etaPromedio = totalEta / busesConEta;
      String etaDisplay = etaPromedio < 60 ? etaPromedio + "s" : (etaPromedio / 60) + ":" + nf(etaPromedio % 60, 2);
      text("ETAs disponibles: " + busesConEta + "/6  •  ETA promedio: " + etaDisplay, x + 60, infoY + 40);
    } else {
      text("ETAs disponibles: 0/6  •  Sin datos de tiempo de llegada", x + 60, infoY + 40);
    }
    
    JSONObject currentData = dataProvider.getCurrentData();
    text("Última actualización: " + currentData.getString("ts"), x + 60, infoY + 55);
  }
  
  // --- NUEVO: Mapa urbano simplificado ---
  void renderUrbanMap() {
    // Área dinámica debajo de secciones principales
    float mapY = y + 420; // Debajo de las secciones (70 + 340 + margen)
    float available = (y + height - 120) - mapY; // dejar espacio para panel info
    if (available < 120) return; // No hay espacio suficiente
    float mapH = min(available, 180);
    float mapX = x + 40;
    float mapW = width - 80;
    drawSoftShadow(mapX, mapY, mapW, mapH, 2);
    fill(255); noStroke(); rect(mapX, mapY, mapW, mapH, 10);
    fill(30); textAlign(LEFT, TOP); textSize(16); text("Mapa Urbano (Rutas y Paradas)", mapX + 15, mapY + 12);
    // Área interna
    float innerX = mapX + 20; float innerY = mapY + 40; float innerW = mapW - 40; float innerH = mapH - 60;
    // Dibujar cuadricula de 3x2 (6 bloques)
    stroke(230); strokeWeight(1); fill(250);
    int cols = 3; int rows = 2;
    float cellW = innerW / cols; float cellH = innerH / rows;
    for (int r=0;r<rows;r++) {
      for (int c=0;c<cols;c++) {
        rect(innerX + c*cellW, innerY + r*cellH, cellW, cellH, 4);
      }
    }
    // Rutas: Transurbano (azul) horizontal arriba, Transmetro (verde) horizontal abajo
    stroke(Theme.BLUE); strokeWeight(4);
    float y1 = innerY + cellH*0.5f; line(innerX + 10, y1, innerX + innerW - 10, y1);
    stroke(Theme.GREEN); float y2 = innerY + cellH*1.5f; line(innerX + 10, y2, innerX + innerW - 10, y2);
    // Paradas mapeadas a P1..P4 sobre las rutas
    JSONObject distancias = dataProvider.getDistanciaData();
    JSONObject etaData = dataProvider.getEtaData();
    // P1,P2 en ruta azul; P3,P4 en ruta verde
    float[] stopX = { innerX + innerW*0.2f, innerX + innerW*0.7f, innerX + innerW*0.3f, innerX + innerW*0.8f };
    float[] stopY = { y1, y1, y2, y2 };
    String[] stops = { "P1", "P2", "P3", "P4" };
    textAlign(CENTER, TOP); textSize(10);
    for (int i=0;i<stops.length;i++) {
      int d = distancias.getInt(stops[i]);
      boolean present = d < 30;
      float sx = stopX[i]; float sy = stopY[i];
      noStroke();
      if (present) {
        float pulse = 6 + (sin(millis()*0.01f)+1)*2;
        fill(255, 120, 0, 50); ellipse(sx, sy, pulse*3, pulse*3); // halo
        fill(255,120,0); ellipse(sx, sy, pulse, pulse);
      } else {
        fill(80); ellipse(sx, sy, 8, 8);
      }
      
      // Mostrar información de parada con ETA
      String stopInfo = stops[i] + "\n" + d + "cm";
      if (etaData.hasKey(stops[i])) {
        try {
          JSONObject etaInfo = etaData.getJSONObject(stops[i]);
          int etaSeconds = etaInfo.getInt("eta_s");
          String etaDisplay = etaSeconds < 60 ? etaSeconds + "s" : (etaSeconds / 60) + ":" + nf(etaSeconds % 60, 2);
          stopInfo += "\nETA: " + etaDisplay;
        } catch (Exception e) {}
      }
      
      fill(30); text(stopInfo, sx, sy + 10);
    }
    // Leyenda rápida
    textAlign(LEFT, CENTER); textSize(11); fill(60);
    float legendY = mapY + mapH - 18;
    fill(Theme.BLUE); rect(mapX + 15, legendY - 6, 14, 4, 2); fill(60); text("Transurbano", mapX + 34, legendY - 4);
    fill(Theme.GREEN); rect(mapX + 120, legendY - 6, 14, 4, 2); fill(60); text("Transmetro", mapX + 139, legendY - 4);
    fill(255,120,0); ellipse(mapX + 235, legendY - 4, 10,10); fill(60); text("Bus presente (<30cm)", mapX + 250, legendY - 4);
  }
  
  // Métodos no utilizados pero mantenidos por compatibilidad
  float[] calculateDistances(float baseDistance) {
    float[] distances = new float[4];
    long currentTime = millis();
    distances[0] = baseDistance + sin(currentTime * 0.001f) * 10;
    distances[1] = baseDistance + cos(currentTime * 0.0015f) * 8;
    distances[2] = baseDistance + sin(currentTime * 0.0008f) * 12;
    distances[3] = baseDistance + cos(currentTime * 0.0012f) * 15;
    
    for (int i = 0; i < distances.length; i++) {
      distances[i] = Math.max(0, distances[i]);
    }
    return distances;
  }
}
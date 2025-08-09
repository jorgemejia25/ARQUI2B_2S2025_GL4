// Pantalla para monitoreo de distancias a paradas de transporte

class DistanceScreen extends Screen {
  private DataProvider dataProvider;
  private ArrayList<InfoCard> transmetroCards;
  private ArrayList<InfoCard> transurbanoCards;
  private DistanceChart distanceChart;
  private boolean isLongDistance = false;
  
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
        Theme.BLUE, 
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
    
    // Gráfico más compacto en la parte inferior
    distanceChart = new DistanceChart(x + 40, sectionY + 380, width - 80, 180, dataProvider);
  }
  
  void renderContent() {
    // Actualizar datos antes de renderizar
    updateDistanceData();
    
    // Header moderno con iconos
    renderModernHeader();
    
    // Secciones de transporte con diseño card-based
    renderTransportSection("Transurbano", x + 40, y + 70, width/2 - 60, transurbanoCards, Theme.BLUE);
    renderTransportSection("Transmetro", x + width/2 + 20, y + 70, width/2 - 60, transmetroCards, Theme.GREEN);
    
    // Gráfico con estilo moderno
    distanceChart.render();
    
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
    text(distance + " cm", cardX + 20, cardY + 70);
    
    // Barra de proximidad
    renderProximityBar(cardX + 20, cardY + 85, cardWidth - 40, distance, accentColor);
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
    distances[0] = distancias.getInt("P1");
    distances[1] = distancias.getInt("P2");
    distances[2] = distancias.getInt("P3");
    distances[3] = distancias.getInt("P4");
    
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
    text("Buses presentes: " + busesPresentes + "/4  •  Distancia promedio: " + String.format("%.0f", avgDistance) + " cm", x + 60, infoY + 35);
    
    JSONObject currentData = dataProvider.getCurrentData();
    text("Última actualización: " + currentData.getString("ts"), x + 60, infoY + 50);
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

// Clase para el gráfico de distancias 
class DistanceChart {
  private float x, y, width, height;
  private DataProvider dataProvider;
  private ArrayList<Float[]> allDistancesHistory;
  private int maxDataPoints = 25;

  DistanceChart(float x, float y, float width, float height, DataProvider dataProvider) {
    this.x = x;
    this.y = y;
    this.width = width;
    this.height = height;
    this.dataProvider = dataProvider;
    this.allDistancesHistory = new ArrayList<Float[]>();
  }

  void render() {
  updateData();

  // Área del gráfico
  float chartX = x + 60;
  float chartY = y + 30;
  float chartWidth = width - 120;
  float chartHeight = height - 50; 

  // Fondo del gráfico
  drawSoftShadow(chartX -20, chartY -20, chartWidth + 20, chartHeight + 20, 2);
  fill(255, 255, 255);
  stroke(220, 220, 220);
  strokeWeight(1);
  rect(chartX-60, chartY - 95, chartWidth + 120, chartHeight + 80, 2);

  // Título del gráfico más compacto
  fill(30, 30, 30);
  textAlign(LEFT, TOP);
  textSize(16);
  text("Distancia vs Tiempo por Parada", chartX-40, chartY - 80); // Kept close to the top

  // Leyenda horizontal compacta
  drawCompactLegend(chartX+240, chartY -70); // Positioned very close to the title

  // Grid y líneas
  float maxDistance = computeMaxDistance();
  drawTimeGrid(chartX, chartY-30, chartWidth + 30, chartHeight - 30, maxDistance);
    
  if (allDistancesHistory.size() > 1) {
    drawTimeLines(chartX, chartY -30, chartWidth, chartHeight - 30, maxDistance);
  }
}

  void updateData() {
    JSONObject distancias = dataProvider.getDistanciaData();
    Float[] distances = new Float[4];
    distances[0] = (float) distancias.getInt("P1");
    distances[1] = (float) distancias.getInt("P2");
    distances[2] = (float) distancias.getInt("P3");
    distances[3] = (float) distancias.getInt("P4");
    allDistancesHistory.add(distances);
    
    if (allDistancesHistory.size() > maxDataPoints) {
      allDistancesHistory.remove(0);
    }
  }

  float computeMaxDistance() {
    float maxFound = 0f;
    for (Float[] arr : allDistancesHistory) {
      for (Float v : arr) {
        if (v != null && v > maxFound) maxFound = v;
      }
    }
    // Establecer un máximo razonable
    float base = Math.max(150f, maxFound);
    base *= 1.1f;
    return Math.min(300f, base); // Máximo 300cm para mejor visualización
  }

  void drawTimeGrid(float chartX, float chartY, float chartWidth, float chartHeight, float maxDistance) {
    // Grid horizontal
    stroke(240, 240, 240);
    strokeWeight(1);
    
    for (int i = 0; i <= 4; i++) {
      float lineY = chartY + (chartHeight * i / 4.0f);
      line(chartX, lineY, chartX + chartWidth, lineY);
    }
    
    // Líneas verticales de tiempo (cada 5 puntos)
    stroke(245, 245, 245);
    for (int i = 0; i < maxDataPoints; i += 5) {
      float lineX = chartX + (chartWidth * i / (maxDataPoints - 1));
      line(lineX, chartY, lineX, chartY + chartHeight);
    }

    // Etiquetas del eje Y (distancia)
    fill(60, 60, 60);
    textAlign(RIGHT, CENTER);
    textSize(10);
    for (int i = 0; i <= 4; i++) {
      float lineY = chartY + (chartHeight * i / 4.0f);
      int valueLabel = (int)round(maxDistance - (maxDistance * i / 4.0f));
      text(valueLabel + "cm", chartX - 5, lineY);
    }
    
    // Etiquetas del eje X (tiempo)
    textAlign(CENTER, TOP);
    textSize(9);
    fill(100, 100, 100);
    for (int i = 0; i < maxDataPoints; i += 5) {
      float lineX = chartX + (chartWidth * i / (maxDataPoints - 1));
      text("-" + (maxDataPoints - i) * 2 + "s", lineX, chartY + chartHeight + 5);
    }
    
    noStroke();
  }

  void drawTimeLines(float chartX, float chartY, float chartWidth, float chartHeight, float maxDistance) {
    color[] lineColors = {
      color(59, 130, 246),   
      color(147, 197, 253),  
      color(34, 197, 94),    
      color(134, 239, 172)  
    };
    
    strokeWeight(2.5);
    
    for (int sensor = 0; sensor < 4; sensor++) {
      stroke(lineColors[sensor]);
      noFill();
      
      beginShape();
      for (int i = 0; i < allDistancesHistory.size(); i++) {
        Float[] distances = allDistancesHistory.get(i);
        float plotX = chartX + (chartWidth * i / (maxDataPoints - 1));
        float normalizedValue = distances[sensor] / maxDistance;
        float plotY = chartY+10 + chartHeight - ((chartHeight-30) * normalizedValue);
        
        vertex(plotX, plotY);
      }
      endShape();
      
      // Punto actual más visible
      if (allDistancesHistory.size() > 0) {
        Float[] lastDistances = allDistancesHistory.get(allDistancesHistory.size() - 1);
        float lastX = chartX + chartWidth;
        float normalizedValue = lastDistances[sensor] / maxDistance;
        float lastY = chartY+10 + chartHeight - ((chartHeight-30) * normalizedValue);
        
        fill(lineColors[sensor]);
        noStroke();
        ellipse(lastX, lastY, 8, 8);
        
        // Indicador de bus presente
        if (lastDistances[sensor] < 30) {
          fill(255, 255, 255);
          ellipse(lastX, lastY, 4, 4);
        }
      }
    }
    
    noStroke();
  }

  void drawCompactLegend(float legendX, float legendY) {
    String[] lineNames = {"U-P1", "U-P2", "T-P1", "T-P2"};
    color[] lineColors = {
      color(59, 130, 246),
      color(147, 197, 253),
      color(34, 197, 94),
      color(134, 239, 172)
    };

    textAlign(LEFT, CENTER);
    textSize(10);
    
    for (int i = 0; i < lineNames.length; i++) {
      float lx = legendX + i * 70; // Más compacto
      
      // Línea de color
      stroke(lineColors[i]);
      strokeWeight(3);
      line(lx + 15, legendY, lx + 25, legendY);
      
      // Nombre
      fill(40, 40, 40);
      text(lineNames[i], lx + 30, legendY);
    }
    
    noStroke();
  }
}



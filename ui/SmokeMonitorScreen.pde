// Pantalla para monitoreo de calidad del aire y detección de humo

class SmokeMonitorScreen extends Screen {
  private DataProvider dataProvider;
  private ArrayList<InfoCard> gasCards;
  private ArrayList<InfoCard> panicCards;
  private SmokeChart smokeChart;
  private Text alertText;
  private boolean isHighRisk = false;
  
  SmokeMonitorScreen(float x, float y, float width, float height, DataProvider dataProvider) {
    super("Monitor de Humo y Calidad del Aire", x, y, width, height);
    this.dataProvider = dataProvider;
    
    initializeComponents();
  }
  
  void initializeComponents() {
    gasCards = new ArrayList<InfoCard>();
    panicCards = new ArrayList<InfoCard>();
    
    // Posicionamiento para tarjetas de gas
    float cardY = y + 80;
    float cardSpacing = Theme.CARD_WIDTH + 20;
    
    // Tarjetas para cada zona de gas
  for (int i = 1; i <= 2; i++) {
      String zoneId = "Z" + i;
      InfoCard gasCard = new InfoCard(
        "Gas " + zoneId, 
        "0 ppm", 
        Theme.GREEN, 
        x + 20 + (i-1) * cardSpacing, 
        cardY
      );
      gasCards.add(gasCard);
      
      // Tarjeta de pánico para cada zona
      InfoCard panicCard = new InfoCard(
        "Pánico " + zoneId, 
        "Normal", 
        Theme.GREEN, 
        x + 20 + (i-1) * cardSpacing, 
        cardY + 140
      );
      panicCards.add(panicCard);
    }
    
    // Gráfico de tendencias de humo (con espacio para banner de alerta)
    smokeChart = new SmokeChart(x + 20, cardY + 320, width - 40, 180, dataProvider);
  }
  
  void renderContent() {
    // Actualizar datos antes de renderizar
    updateGasData();
    updatePanicData();
    
    // Renderizar tarjetas de gas
    for (InfoCard card : gasCards) {
      card.render();
    }
    
    // Renderizar tarjetas de pánico
    for (InfoCard card : panicCards) {
      card.render();
    }
    
    // Renderizar gráfico
    smokeChart.render();
    
    // Mostrar alertas si es necesario
    renderAlerts();
    
    // Información adicional
    renderAdditionalInfo();
  }
  
  void updateGasData() {
    JSONObject gasData = dataProvider.getGasData();
    
    for (int i = 0; i < gasCards.size(); i++) {
      String zoneId = "Z" + (i + 1);
      int gasLevel = gasData.getInt(zoneId);
      
      InfoCard card = gasCards.get(i);
      card.updateValue(gasLevel + " ppm");
      
      // Cambiar color según nivel de riesgo
      color cardColor = getGasLevelColor(gasLevel);
      card.cardColor = cardColor;
      card.valueText.setColor(cardColor);
    }
  }
  
  void updatePanicData() {
    JSONObject panicData = dataProvider.getPanicoData();
    
    for (int i = 0; i < panicCards.size(); i++) {
      String zoneId = "Z" + (i + 1);
      int panicLevel = panicData.getInt(zoneId);
      
      InfoCard card = panicCards.get(i);
      String statusText = panicLevel == 1 ? "¡PÁNICO!" : "Normal";
      color cardColor = panicLevel == 1 ? Theme.RED : Theme.GREEN;
      
      card.updateValue(statusText);
      card.cardColor = cardColor;
      card.valueText.setColor(cardColor);
    }
  }
  
  color getGasLevelColor(int gasLevel) {
    if (gasLevel > 250) {
      isHighRisk = true;
      return Theme.RED;        // Peligroso
    } else if (gasLevel > 200) {
      return Theme.ORANGE;     // Alto
    } else if (gasLevel > 180) {
      return Theme.ORANGE;     // Moderado
    } else {
      return Theme.GREEN;      // Normal
    }
  }
  
  void renderAlerts() {
    // Verificar si hay zonas en pánico o gas alto
    JSONObject panicData = dataProvider.getPanicoData();
    JSONObject gasData = dataProvider.getGasData();
    
    boolean hasPanic = false;
    boolean hasHighGas = false;
    
  for (int i = 1; i <= 2; i++) {
      String zoneId = "Z" + i;
      if (panicData.getInt(zoneId) == 1) hasPanic = true;
      if (gasData.getInt(zoneId) > 250) hasHighGas = true;
    }
    
    if (hasPanic || hasHighGas) {
      String alertMessage = "";
      color alertColor = Theme.RED;
      
      if (hasPanic && hasHighGas) {
        alertMessage = "¡EMERGENCIA! Pánico y Gas Peligroso";
        alertColor = Theme.RED;
      } else if (hasPanic) {
        alertMessage = "¡ALERTA! Pánico Detectado";
        alertColor = Theme.RED;
      } else if (hasHighGas) {
        alertMessage = "¡PELIGRO! Niveles de Gas Críticos";
        alertColor = Theme.ORANGE;
      }
      
      // Renderizar mensaje de alerta con fondo
      renderAlertBanner(alertMessage, alertColor);
      
      // Borde de alerta parpadeante solo en el perímetro
      if (millis() % 1000 < 500) {
        renderAlertBorder(alertColor);
      }
    }
  }
  
  void renderAlertBanner(String message, color alertColor) {
    // Banner de alerta en la parte superior
    float bannerHeight = 40;
    float bannerY = y + 60;
    
    // Fondo del banner
    fill(alertColor);
    noStroke();
    rect(x + 20, bannerY, width - 40, bannerHeight, 5);
    
    // Texto de la alerta
    fill(Theme.WHITE);
    textAlign(CENTER, CENTER);
    textSize(Theme.NORMAL_SIZE);
    text(message, x + width/2, bannerY + bannerHeight/2);
  }
  
  void renderAlertBorder(color alertColor) {
    // Borde parpadeante sutil
    stroke(alertColor);
    strokeWeight(3);
    noFill();
    rect(x + 15, y + 15, width - 30, height - 30, 8);
    noStroke();
  }
  
  void renderAdditionalInfo() {
    // Panel de información adicional
    float infoY = y + height - 100;
    
    drawSoftShadow(x + 20, infoY, width - 40, 80, 2);
    fill(Theme.WHITE);
    noStroke();
    rect(x + 20, infoY, width - 40, 80, 5);
    
    // Título del panel de información
    fill(Theme.DARK_GRAY);
    textAlign(LEFT, TOP);
    textSize(Theme.NORMAL_SIZE);
    text("Información del Sistema", x + 35, infoY + 12);
    
    // Estadísticas rápidas
    TrafficStats stats = dataProvider.getStats();
    fill(Theme.MEDIUM_GRAY);
    textSize(Theme.SMALL_SIZE);
    text("Zonas en pánico: " + stats.zonasPanico, x + 35, infoY + 32);
    text("Gas promedio: " + stats.gasPromedio + " ppm", x + 35, infoY + 46);
    text("Infracciones: " + stats.infracciones, x + 35, infoY + 60);
    
    // Rangos de referencia
    text("Rangos: Normal (150-180), Moderado (180-200), Alto (200-250), Crítico (>250)", 
         x + 200, infoY + 32);
    text("Actualización automática cada 2 segundos", x + 200, infoY + 46);
    
    // Timestamp de última actualización
    JSONObject currentData = dataProvider.getCurrentData();
    text("Última actualización: " + currentData.getString("ts"), x + 200, infoY + 60);
  }
}

// Clase para el gráfico de tendencias de humo
class SmokeChart {
  float x, y, width, height;
  DataProvider dataProvider;
  Text titleText;
  ArrayList<Float> gasHistory;
  int maxHistoryPoints = 20;
  
  SmokeChart(float x, float y, float width, float height, DataProvider dataProvider) {
    this.x = x;
    this.y = y;
    this.width = width;
    this.height = height;
    this.dataProvider = dataProvider;
    
    titleText = new Text("Tendencias de Gas en Tiempo Real", x + 20, y + 20, Theme.DARK_GRAY, Theme.NORMAL_SIZE);
    gasHistory = new ArrayList<Float>();
    
    // Inicializar con algunos valores
    for (int i = 0; i < maxHistoryPoints; i++) {
      gasHistory.add(random(150, 200));
    }
  }
  
  void render() {
    // Fondo del gráfico
    drawSoftShadow(x, y, width, height, 2);
    fill(Theme.WHITE);
    noStroke();
    rect(x, y, width, height, 5);
    
    titleText.render();
    
    // Actualizar datos
    updateHistory();
    
    // Dibujar líneas de referencia
    drawReferenceLines();
    
    // Dibujar gráfico de líneas
    drawGasLines();
    
    // Dibujar leyenda
    drawLegend();
  }
  
  void updateHistory() {
    // Agregar nuevo punto de datos (promedio de las 3 zonas)
    TrafficStats stats = dataProvider.getStats();
    gasHistory.add((float)stats.gasPromedio);
    
    // Mantener solo los últimos N puntos
    if (gasHistory.size() > maxHistoryPoints) {
      gasHistory.remove(0);
    }
  }
  
  void drawReferenceLines() {
    stroke(Theme.MEDIUM_GRAY);
    strokeWeight(1);
    
    float chartX = x + 40;
    float chartY = y + 40;
    float chartWidth = width - 80;
    float chartHeight = height - 80;
    
    // Líneas horizontales (niveles de gas)
    int[] levels = {150, 180, 200, 250, 300};
    for (int level : levels) {
      float lineY = chartY + chartHeight - map(level, 150, 300, 0, chartHeight);
      line(chartX, lineY, chartX + chartWidth, lineY);
      
      // Etiquetas
      fill(Theme.MEDIUM_GRAY);
      textAlign(RIGHT, CENTER);
      textSize(Theme.TINY_SIZE);
      text(level + " ppm", chartX - 5, lineY);
    }
    
    noStroke();
  }
  
  void drawGasLines() {
    if (gasHistory.size() < 2) return;
    
    float chartX = x + 40;
    float chartY = y + 40;
    float chartWidth = width - 80;
    float chartHeight = height - 80;
    
    stroke(Theme.PRIMARY_BLUE);
    strokeWeight(2);
    noFill();
    
    beginShape();
    for (int i = 0; i < gasHistory.size(); i++) {
      float gasValue = gasHistory.get(i);
      float pointX = chartX + map(i, 0, maxHistoryPoints - 1, 0, chartWidth);
      float pointY = chartY + chartHeight - map(gasValue, 150, 300, 0, chartHeight);
      vertex(pointX, pointY);
    }
    endShape();
    
    // Puntos en la línea
    fill(Theme.PRIMARY_BLUE);
    noStroke();
    for (int i = 0; i < gasHistory.size(); i++) {
      float gasValue = gasHistory.get(i);
      float pointX = chartX + map(i, 0, maxHistoryPoints - 1, 0, chartWidth);
      float pointY = chartY + chartHeight - map(gasValue, 150, 300, 0, chartHeight);
      ellipse(pointX, pointY, 4, 4);
    }
  }
  
  void drawLegend() {
    // Leyenda de colores
    float legendY = y + height - 25;
    
    fill(Theme.GREEN);
    rect(x + 40, legendY, 15, 10);
    fill(Theme.DARK_GRAY);
    textAlign(LEFT, CENTER);
    textSize(Theme.TINY_SIZE);
    text("Normal", x + 60, legendY + 5);
    
    fill(Theme.ORANGE);
    rect(x + 120, legendY, 15, 10);
    fill(Theme.DARK_GRAY);
    text("Alto", x + 140, legendY + 5);
    
    fill(Theme.RED);
    rect(x + 180, legendY, 15, 10);
    fill(Theme.DARK_GRAY);
    text("Crítico", x + 200, legendY + 5);
  }
}

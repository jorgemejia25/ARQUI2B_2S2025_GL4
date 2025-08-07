// Pantalla principal del dashboard con vista general del sistema

class DashboardScreen extends Screen {
  private DataProvider dataProvider;
  private ArrayList<InfoCard> summaryCards;
  private TrafficOverviewChart trafficChart;
  private Text statusText;
  
  DashboardScreen(float x, float y, float width, float height, DataProvider dataProvider) {
    super("Dashboard Principal", x, y, width, height);
    this.dataProvider = dataProvider;
    
    initializeComponents();
  }
  
  void initializeComponents() {
    summaryCards = new ArrayList<InfoCard>();
    
    // Posicionamiento para tarjetas resumen
    float cardY = y + 80;
    float cardSpacing = Theme.CARD_WIDTH + 20;
    
    // Tarjetas de resumen general
    InfoCard semaforosCard = new InfoCard("Semáforos Verdes", "0", Theme.GREEN, 
                                         x + 20, cardY);
    summaryCards.add(semaforosCard);
    
    InfoCard infraccionesCard = new InfoCard("Infracciones", "0", Theme.ORANGE, 
                                           x + 20 + cardSpacing, cardY);
    summaryCards.add(infraccionesCard);
    
    InfoCard panicoCard = new InfoCard("Zonas Pánico", "0", Theme.RED, 
                                      x + 20 + cardSpacing * 2, cardY);
    summaryCards.add(panicoCard);
    
    InfoCard gasCard = new InfoCard("Gas Promedio", "0 ppm", Theme.PRIMARY_BLUE, 
                                   x + 20 + cardSpacing * 3, cardY);
    summaryCards.add(gasCard);
    
    // Gráfico de vista general del tráfico
    trafficChart = new TrafficOverviewChart(x + 20, cardY + 160, width - 40, 300, dataProvider);
    
    // Texto de estado del sistema
    statusText = new Text("Sistema Operativo", x + 20, cardY + 480, Theme.GREEN, Theme.LARGE_SIZE);
  }
  
  void renderContent() {
    // Actualizar datos
    updateSummaryCards();
    
    // Renderizar tarjetas
    for (InfoCard card : summaryCards) {
      card.render();
    }
    
    // Renderizar gráfico
    trafficChart.render();
    
    // Estado del sistema
    renderSystemStatus();
    
    // Información de tiempo real
    renderRealTimeInfo();
  }
  
  void updateSummaryCards() {
    TrafficStats stats = dataProvider.getStats();
    
    summaryCards.get(0).updateValue(str(stats.semaforosVerdes));
    summaryCards.get(1).updateValue(str(stats.infracciones));
    summaryCards.get(2).updateValue(str(stats.zonasPanico));
    summaryCards.get(3).updateValue(stats.gasPromedio + " ppm");
  }
  
  void renderSystemStatus() {
    TrafficStats stats = dataProvider.getStats();
    
    // Determinar estado del sistema
    String systemStatus = "Sistema Operativo";
    color statusColor = Theme.GREEN;
    
    if (stats.zonasPanico > 0 || stats.gasPromedio > 250) {
      systemStatus = "¡EMERGENCIA ACTIVA!";
      statusColor = Theme.RED;
    } else if (stats.infracciones > 3 || stats.gasPromedio > 200) {
      systemStatus = "Estado de Alerta";
      statusColor = Theme.ORANGE;
    }
    
    statusText.setContent(systemStatus);
    statusText.setColor(statusColor);
    statusText.render();
  }
  
  void renderRealTimeInfo() {
    // Panel de información en tiempo real
    float infoY = y + height - 100;
    
    drawSoftShadow(x + 20, infoY, width - 40, 80, 2);
    fill(Theme.WHITE);
    noStroke();
    rect(x + 20, infoY, width - 40, 80, 5);
    
    fill(Theme.DARK_GRAY);
    textAlign(LEFT, TOP);
    textSize(Theme.NORMAL_SIZE);
    text("Estado Actual del Sistema", x + 35, infoY + 15);
    
    // Información detallada
    JSONObject currentData = dataProvider.getCurrentData();
    TrafficStats stats = dataProvider.getStats();
    
    fill(Theme.MEDIUM_GRAY);
    textSize(Theme.SMALL_SIZE);
    
    String infoLine1 = "Semáforos: " + stats.semaforosRojos + " rojos, " + 
                      stats.semaforosVerdes + " verdes, " + 
                      stats.semaforosAmarillos + " amarillos";
    text(infoLine1, x + 35, infoY + 40);
    
    String infoLine2 = "Monitoreo: " + stats.zonasPanico + " zonas pánico, " + 
                      stats.infracciones + " infracciones, " + 
                      "Gas: " + stats.gasPromedio + " ppm";
    text(infoLine2, x + 35, infoY + 55);
    
    // Timestamp
    fill(Theme.MEDIUM_GRAY);
    textAlign(RIGHT, TOP);
    text("Última actualización: " + currentData.getString("ts"), 
         x + width - 25, infoY + 40);
  }
}

// Clase para gráfico de vista general del tráfico
class TrafficOverviewChart {
  float x, y, width, height;
  DataProvider dataProvider;
  Text titleText;
  
  TrafficOverviewChart(float x, float y, float width, float height, DataProvider dataProvider) {
    this.x = x;
    this.y = y;
    this.width = width;
    this.height = height;
    this.dataProvider = dataProvider;
    
    titleText = new Text("Vista General del Tráfico", x + 20, y + 20, Theme.DARK_GRAY, Theme.NORMAL_SIZE);
  }
  
  void render() {
    // Fondo del gráfico
    drawSoftShadow(x, y, width, height, 2);
    fill(Theme.WHITE);
    noStroke();
    rect(x, y, width, height, 5);
    
    titleText.render();
    
    // Dibujar gráfico de barras para semáforos
    drawSemaphorosChart();
    
    // Dibujar estado de las paradas
    drawParadasStatus();
  }
  
  void drawSemaphorosChart() {
    TrafficStats stats = dataProvider.getStats();
    
    float chartX = x + 40;
    float chartY = y + 60;
    float chartWidth = (width - 100) / 2;
    float chartHeight = height - 120;
    
    // Título del gráfico de semáforos
    fill(Theme.DARK_GRAY);
    textAlign(LEFT, TOP);
    textSize(Theme.SMALL_SIZE);
    text("Estados de Semáforos", chartX, chartY - 10);
    
    // Datos para las barras
    int[] values = {stats.semaforosRojos, stats.semaforosVerdes, stats.semaforosAmarillos};
    color[] colors = {Theme.RED, Theme.GREEN, Theme.ORANGE};
    String[] labels = {"Rojo", "Verde", "Amarillo"};
    
    float barWidth = chartWidth / 3 - 20;
    int maxValue = max(max(values), 1);
    
    for (int i = 0; i < 3; i++) {
      float barHeight = map(values[i], 0, maxValue, 0, chartHeight - 40);
      float barX = chartX + i * (barWidth + 20);
      float barY = chartY + chartHeight - 40 - barHeight;
      
      // Dibujar barra
      fill(colors[i]);
      noStroke();
      rect(barX, barY, barWidth, barHeight, 3);
      
      // Valor en la barra
      fill(Theme.WHITE);
      textAlign(CENTER, CENTER);
      textSize(Theme.NORMAL_SIZE);
      if (barHeight > 20) {
        text(str(values[i]), barX + barWidth/2, barY + barHeight/2);
      }
      
      // Etiqueta
      fill(Theme.DARK_GRAY);
      textAlign(CENTER, TOP);
      textSize(Theme.SMALL_SIZE);
      text(labels[i], barX + barWidth/2, chartY + chartHeight - 35);
    }
  }
  
  void drawParadasStatus() {
    JSONObject distancias = dataProvider.getDistanciaData();
    JSONArray infracciones = dataProvider.getInfraccionesData();
    
    float chartX = x + width/2 + 20;
    float chartY = y + 60;
    float chartWidth = width/2 - 60;
    float chartHeight = height - 120;
    
    // Título
    fill(Theme.DARK_GRAY);
    textAlign(LEFT, TOP);
    textSize(Theme.SMALL_SIZE);
    text("Estado de Paradas", chartX, chartY - 10);
    
    // Dibujar representación de paradas
    int rows = 2;
    int cols = 3;
    float cellWidth = chartWidth / cols - 10;
    float cellHeight = (chartHeight - 40) / rows - 10;
    
    for (int i = 1; i <= 6; i++) {
      String paradaId = "P" + i;
      int row = (i - 1) / cols;
      int col = (i - 1) % cols;
      
      float cellX = chartX + col * (cellWidth + 10);
      float cellY = chartY + row * (cellHeight + 10);
      
      // Determinar color según estado
      color cellColor = Theme.GREEN; // Normal
      boolean hasInfraction = false;
      
      // Verificar si tiene infracción
      for (int j = 0; j < infracciones.size(); j++) {
        if (infracciones.getString(j).equals(paradaId)) {
          hasInfraction = true;
          break;
        }
      }
      
      if (hasInfraction) {
        cellColor = Theme.RED;
      } else {
        int distancia = distancias.getInt(paradaId);
        if (distancia < 50) {
          cellColor = Theme.ORANGE; // Muy cerca
        }
      }
      
      // Dibujar celda
      fill(cellColor);
      noStroke();
      rect(cellX, cellY, cellWidth, cellHeight, 5);
      
      // Texto de la parada
      fill(Theme.WHITE);
      textAlign(CENTER, CENTER);
      textSize(Theme.SMALL_SIZE);
      text(paradaId, cellX + cellWidth/2, cellY + cellHeight/2 - 5);
      
      // Distancia
      int distancia = distancias.getInt(paradaId);
      textSize(Theme.TINY_SIZE);
      text(distancia + "cm", cellX + cellWidth/2, cellY + cellHeight/2 + 8);
    }
  }
}

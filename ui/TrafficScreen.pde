// Pantalla para monitoreo específico de tráfico y semáforos

class TrafficScreen extends Screen {
  private DataProvider dataProvider;
  private ArrayList<SemaforoCard> semaforoCards;
  private ArrayList<ParadaCard> paradaCards;
  
  TrafficScreen(float x, float y, float width, float height, DataProvider dataProvider) {
    super("Monitor de Tráfico", x, y, width, height);
    this.dataProvider = dataProvider;
    
    initializeComponents();
  }
  
  void initializeComponents() {
    semaforoCards = new ArrayList<SemaforoCard>();
    paradaCards = new ArrayList<ParadaCard>();
    
    // Crear tarjetas para semáforos (2 filas de 5)
    float cardWidth = 100;
    float cardHeight = 80;
    float startX = x + 30;
    float startY = y + 80;
    
    for (int i = 1; i <= 10; i++) {
      int row = (i - 1) / 5;
      int col = (i - 1) % 5;
      
      float cardX = startX + col * (cardWidth + 15);
      float cardY = startY + row * (cardHeight + 20);
      
      SemaforoCard card = new SemaforoCard("S" + i, cardX, cardY, cardWidth, cardHeight);
      semaforoCards.add(card);
    }
    
    // Crear tarjetas para paradas (2 filas de 3)
    float paradaStartY = startY + 200;
    for (int i = 1; i <= 6; i++) {
      int row = (i - 1) / 3;
      int col = (i - 1) % 3;
      
      float cardX = startX + col * (cardWidth * 1.5 + 20);
      float cardY = paradaStartY + row * (cardHeight + 20);
      
      ParadaCard card = new ParadaCard("P" + i, cardX, cardY, cardWidth * 1.5, cardHeight);
      paradaCards.add(card);
    }
  }
  
  void renderContent() {
    // Título para semáforos
    fill(Theme.DARK_GRAY);
    textAlign(LEFT, TOP);
    textSize(Theme.SUBTITLE_SIZE);
    text("Estado de Semáforos", x + 30, y + 50);
    
    // Actualizar y renderizar semáforos
    updateSemaforoCards();
    for (SemaforoCard card : semaforoCards) {
      card.render();
    }
    
    // Título para paradas
    fill(Theme.DARK_GRAY);
    text("Estado de Paradas", x + 30, y + 250);
    
    // Actualizar y renderizar paradas
    updateParadaCards();
    for (ParadaCard card : paradaCards) {
      card.render();
    }
    
    // Información adicional
    renderTrafficInfo();
  }
  
  void updateSemaforoCards() {
    JSONObject semaforoData = dataProvider.getSemaforoData();
    
    for (SemaforoCard card : semaforoCards) {
      String estado = semaforoData.getString(card.getId());
      card.setEstado(estado);
    }
  }
  
  void updateParadaCards() {
    JSONObject distanciaData = dataProvider.getDistanciaData();
    JSONArray infracciones = dataProvider.getInfraccionesData();
    
    for (ParadaCard card : paradaCards) {
      int distancia = distanciaData.getInt(card.getId());
      boolean hasInfraction = false;
      
      // Verificar infracciones
      for (int i = 0; i < infracciones.size(); i++) {
        if (infracciones.getString(i).equals(card.getId())) {
          hasInfraction = true;
          break;
        }
      }
      
      card.setDistancia(distancia);
      card.setInfraccion(hasInfraction);
    }
  }
  
  void renderTrafficInfo() {
    // Panel de información de tráfico
    float infoY = y + height - 120;
    
    drawSoftShadow(x + 20, infoY, width - 40, 100, 2);
    fill(Theme.WHITE);
    noStroke();
    rect(x + 20, infoY, width - 40, 100, 5);
    
    fill(Theme.DARK_GRAY);
    textAlign(LEFT, TOP);
    textSize(Theme.NORMAL_SIZE);
    text("Resumen de Tráfico", x + 35, infoY + 15);
    
    TrafficStats stats = dataProvider.getStats();
    fill(Theme.MEDIUM_GRAY);
    textSize(Theme.SMALL_SIZE);
    
    String line1 = "Total semáforos: 10 | Rojos: " + stats.semaforosRojos + 
                   " | Verdes: " + stats.semaforosVerdes + 
                   " | Amarillos: " + stats.semaforosAmarillos;
    text(line1, x + 35, infoY + 40);
    
    String line2 = "Paradas monitoreadas: 6 | Infracciones activas: " + stats.infracciones;
    text(line2, x + 35, infoY + 55);
    
    JSONObject currentData = dataProvider.getCurrentData();
    text("Última actualización: " + currentData.getString("ts"), x + 35, infoY + 70);
  }
}

// Clase para representar una tarjeta de semáforo
class SemaforoCard {
  private String id;
  private float x, y, width, height;
  private String estado = "ROJO";
  
  SemaforoCard(String id, float x, float y, float width, float height) {
    this.id = id;
    this.x = x;
    this.y = y;
    this.width = width;
    this.height = height;
  }
  
  void render() {
    // Fondo de la tarjeta
    drawSoftShadow(x, y, width, height, 2);
    fill(Theme.WHITE);
    noStroke();
    rect(x, y, width, height, 5);
    
    // Color según estado
    color stateColor = Theme.RED;
    if (estado.equals("VERDE")) stateColor = Theme.GREEN;
    else if (estado.equals("AMARILLO")) stateColor = Theme.ORANGE;
    
    // Círculo del semáforo
    fill(stateColor);
    ellipse(x + width/2, y + height/2 - 10, 30, 30);
    
    // ID del semáforo
    fill(Theme.DARK_GRAY);
    textAlign(CENTER, CENTER);
    textSize(Theme.SMALL_SIZE);
    text(id, x + width/2, y + height - 15);
    
    // Estado
    textSize(Theme.TINY_SIZE);
    text(estado, x + width/2, y + height/2 + 20);
  }
  
  void setEstado(String estado) {
    this.estado = estado;
  }
  
  String getId() { return id; }
}

// Clase para representar una tarjeta de parada
class ParadaCard {
  private String id;
  private float x, y, width, height;
  private int distancia = 0;
  private boolean hasInfraccion = false;
  
  ParadaCard(String id, float x, float y, float width, float height) {
    this.id = id;
    this.x = x;
    this.y = y;
    this.width = width;
    this.height = height;
  }
  
  void render() {
    // Fondo de la tarjeta
    color bgColor = hasInfraccion ? Theme.RED : Theme.WHITE;
    drawSoftShadow(x, y, width, height, 2);
    fill(bgColor);
    noStroke();
    rect(x, y, width, height, 5);
    
    // Borde según estado
    stroke(hasInfraccion ? Theme.RED : (distancia < 50 ? Theme.ORANGE : Theme.GREEN));
    strokeWeight(2);
    noFill();
    rect(x, y, width, height, 5);
    noStroke();
    
    // ID de la parada
    fill(hasInfraccion ? Theme.WHITE : Theme.DARK_GRAY);
    textAlign(CENTER, CENTER);
    textSize(Theme.NORMAL_SIZE);
    text(id, x + width/2, y + height/2 - 10);
    
    // Distancia
    textSize(Theme.SMALL_SIZE);
    text(distancia + " cm", x + width/2, y + height/2 + 8);
    
    // Estado
    if (hasInfraccion) {
      fill(Theme.WHITE);
      textSize(Theme.TINY_SIZE);
      text("INFRACCIÓN", x + width/2, y + height/2 + 22);
    }
  }
  
  void setDistancia(int distancia) {
    this.distancia = distancia;
  }
  
  void setInfraccion(boolean infraccion) {
    this.hasInfraccion = infraccion;
  }
  
  String getId() { return id; }
}

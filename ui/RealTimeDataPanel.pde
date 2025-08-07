// Panel de datos en tiempo real que muestra la información del DataProvider

class RealTimeDataPanel implements Component {
  private float x, y, width, height;
  private DataProvider dataProvider;
  private Text titleText;
  private ArrayList<InfoCard> statusCards;
  private Text jsonDisplayText;
  private int maxJsonLines = 15;
  private color backgroundColor;
  
  RealTimeDataPanel(float x, float y, float width, float height, DataProvider dataProvider) {
    this.x = x;
    this.y = y;
    this.width = width;
    this.height = height;
    this.dataProvider = dataProvider;
    this.backgroundColor = Theme.WHITE;
    
    // Inicializar componentes
    initializeComponents();
  }
  
  void initializeComponents() {
    // Título del panel
    titleText = new Text("Datos en Tiempo Real", x + 20, y + 25);
    titleText.setStyle(Theme.DARK_GRAY, Theme.SUBTITLE_SIZE);
    
    // Tarjetas de estadísticas
    statusCards = new ArrayList<InfoCard>();
    initializeStatusCards();
    
    // Texto para mostrar JSON
    jsonDisplayText = new Text("", x + 20, y + 180);
    jsonDisplayText.setStyle(Theme.DARK_GRAY, Theme.TINY_SIZE);
    jsonDisplayText.setAlignment(LEFT, TOP);
  }
  
  void initializeStatusCards() {
    float cardY = y + 50;
    float cardSpacing = (Theme.CARD_WIDTH + 15);
  }
  
  void render() {
    // Fondo del panel
    drawSoftShadow(x, y, width, height, 3);
    fill(backgroundColor);
    noStroke();
    rect(x, y, width, height, 8);
    
    // Título
    titleText.render();
    
    // Actualizar y renderizar tarjetas
    updateStatusCards();
    for (InfoCard card : statusCards) {
      card.render();
    }
    
    // Mostrar datos JSON
    renderJsonData();
    
    // Línea separadora
    stroke(Theme.MEDIUM_GRAY);
    strokeWeight(1);
    line(x + 20, y + 175, x + width - 20, y + 175);
    noStroke();
  }
  
  void updateStatusCards() {
    TrafficStats stats = dataProvider.getStats();
    
  }
  
  void renderJsonData() {
    fill(Theme.MEDIUM_GRAY);
    textAlign(LEFT, TOP);
    textSize(Theme.SMALL_SIZE);
    text("JSON Data Stream:", x + 20, y + 190);
    
    // Obtener datos formateados
    String jsonData = dataProvider.getDataAsFormattedString();
    String[] lines = jsonData.split("\n");
    
    // Mostrar solo las primeras líneas para que quepa en el panel
    fill(Theme.DARK_GRAY);
    textSize(Theme.TINY_SIZE);
    
    int linesToShow = min(lines.length, maxJsonLines);
    for (int i = 0; i < linesToShow; i++) {
      float lineY = y + 210 + i * 15;
      if (lineY < y + height - 20) {
        text(lines[i], x + 25, lineY);
      }
    }
    
    // Indicador si hay más líneas
    if (lines.length > maxJsonLines) {
      fill(Theme.MEDIUM_GRAY);
      text("... (" + (lines.length - maxJsonLines) + " líneas más)", 
           x + 25, y + 210 + linesToShow * 15);
    }
  }
  
  // Método para simular envío de datos por serial
  void simulateSerialSend() {
    String data = dataProvider.getDataAsString();
    println("SERIAL SEND: " + data);
  }
  
  // Método para forzar actualización
  void forceUpdate() {
    dataProvider.forceUpdate();
  }
  
  // Configurar intervalo de actualización
  void setUpdateInterval(int intervalMs) {
    dataProvider.setUpdateInterval(intervalMs);
  }
  
  // Getters
  float getX() { return x; }
  float getY() { return y; }
  float getWidth() { return width; }
  float getHeight() { return height; }
}

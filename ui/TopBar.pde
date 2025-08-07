// Barra superior del layout

class TopBar {
  private float x, y, width, height;
  
  // Elementos de la barra superior
  private Text titleText;
  private Text timeText;
  
  TopBar(float x, float y, float width, float height) {
    this.x = x;
    this.y = y;
    this.width = width;
    this.height = height;
    
    // Inicializar elementos
    initializeElements();
  }
  
  private void initializeElements() {
    // Título de la aplicación
    titleText = new Text("Sistema de Tráfico Urbano", 
                        x + Theme.MARGIN, 
                        y + height/2 - 5, 
                        Theme.DARK_GRAY, 
                        Theme.TITLE_SIZE);
    
    // Reloj en tiempo real
    timeText = new Text(getCurrentTime(), 
                       x + width - 120, 
                       y + height/2 - 5, 
                       Theme.MEDIUM_GRAY, 
                       Theme.NORMAL_SIZE);
  }
  
  void render() {
    // Fondo de la barra superior
    fill(Theme.WHITE);
    noStroke();
    rect(x, y, width, height);
    
    // Sombra inferior
    drawHorizontalShadow(x, y + height, width, 3);
    
    // Actualizar tiempo
    timeText.setContent(getCurrentTime());
    
    // Renderizar elementos
    titleText.render();
    timeText.render();
    
    // Línea divisoria opcional
    stroke(Theme.MEDIUM_GRAY);
    strokeWeight(1);
    line(x, y + height - 1, x + width, y + height - 1);
    noStroke();
  }
}

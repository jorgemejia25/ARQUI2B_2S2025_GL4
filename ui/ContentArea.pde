// Área de contenido modular - Contenedor para futuros componentes

class ContentArea implements Component, Clickable, Positionable, Resizable {
  private String title;
  private float x, y, width, height;
  private boolean isActive = false;
  private ArrayList<Component> childComponents;
  
  ContentArea(String title, float x, float y, float width, float height) {
    this.title = title;
    this.x = x;
    this.y = y;
    this.width = width;
    this.height = height;
    
    // Inicializar lista de componentes hijos
    childComponents = new ArrayList<Component>();
  }
  
  void render() {
    // Sombra del contenedor
    drawSoftShadow(x, y, width, height, 2);
    
    // Fondo del área
    fill(Theme.WHITE);
    noStroke();
    rect(x, y, width, height);
    
    // Borde si está activa
    if (isActive) {
      stroke(Theme.PRIMARY_BLUE);
      strokeWeight(2);
      noFill();
      rect(x, y, width, height);
      noStroke();
    }
    
    // Header del área
    renderHeader();
    
    // Mensaje placeholder
    renderPlaceholder();
    
    // Renderizar componentes hijos
    for (Component child : childComponents) {
      child.render();
    }
  }
  
  private void renderHeader() {
    // Línea de título
    fill(Theme.PRIMARY_BLUE);
    rect(x, y, width, 40);
    
    // Texto del título
    fill(Theme.WHITE);
    textAlign(LEFT, CENTER);
    textSize(Theme.SUBTITLE_SIZE);
    text(title, x + Theme.MARGIN, y + 20);
  }
  
  private void renderPlaceholder() {
    // Área de contenido vacío
    fill(Theme.LIGHT_GRAY);
    textAlign(CENTER, CENTER);
    textSize(Theme.NORMAL_SIZE);
    text("[ Contenido por agregar ]", 
         x + width/2, 
         y + height/2);
    
    // Texto de ayuda
    fill(Theme.MEDIUM_GRAY);
    textSize(Theme.SMALL_SIZE);
    text("Haz clic para configurar este área", 
         x + width/2, 
         y + height/2 + 25);
  }
  
  void handleClick(float mouseX, float mouseY) {
    if (isClicked(mouseX, mouseY)) {
      setActive(!isActive);
      println("ContentArea clicked: " + title);
    }
  }
  
  boolean isClicked(float mouseX, float mouseY) {
    return mouseX >= x && mouseX <= x + width && 
           mouseY >= y && mouseY <= y + height;
  }
  
  void setActive(boolean active) {
    this.isActive = active;
  }
  
  boolean isActive() {
    return isActive;
  }
  
  // Implementación de Positionable
  void setPosition(float x, float y) {
    this.x = x;
    this.y = y;
  }
  
  float getX() { return x; }
  float getY() { return y; }
  
  // Implementación de Resizable
  void resize(float width, float height) {
    this.width = width;
    this.height = height;
  }
  
  float getWidth() { return width; }
  float getHeight() { return height; }
  
  // Métodos para gestionar componentes hijos
  void addChild(Component component) {
    childComponents.add(component);
  }
  
  void removeChild(Component component) {
    childComponents.remove(component);
  }
  
  void clearChildren() {
    childComponents.clear();
  }
  
  String getTitle() {
    return title;
  }
  
  void setTitle(String title) {
    this.title = title;
  }
}

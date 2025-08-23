// Clase base para las diferentes pantallas del sistema

abstract class Screen implements Component {
  protected float x, y, width, height;
  protected String screenTitle;
  protected boolean isActive = false;
  protected Text titleText;
  
  Screen(String title, float x, float y, float width, float height) {
    this.screenTitle = title;
    this.x = x;
    this.y = y;
    this.width = width;
    this.height = height;
    
    // Título de la pantalla
    titleText = new Text(title, x + 20, y + 25, Theme.DARK_GRAY, Theme.TITLE_SIZE);
  }
  
  // Método abstracto que cada pantalla debe implementar
  abstract void renderContent();
  
  void render() {
    if (!isActive) return;
    
    // Fondo de la pantalla
    fill(Theme.LIGHT_GRAY);
    noStroke();
    rect(x, y, width, height);
    
    // Título
    titleText.render();
    
    // Contenido específico de la pantalla
    renderContent();
  }
  
  void setActive(boolean active) {
    this.isActive = active;
  }
  
  boolean isActive() {
    return isActive;
  }
  
  // Getters
  float getX() { return x; }
  float getY() { return y; }
  float getWidth() { return width; }
  float getHeight() { return height; }
  String getTitle() { return screenTitle; }
}

// Elemento de menú modular

class MenuItem implements Component, Clickable, Stateful {
  private String label;
  private float x, y, width, height;
  private boolean isSelected = false;
  private boolean isHovered = false;
  private Text textComponent;
  
  MenuItem(String label, float x, float y, float width, float height, boolean selected) {
    this.label = label;
    this.x = x;
    this.y = y;
    this.width = width;
    this.height = height;
    this.isSelected = selected;
    
    // Crear componente de texto
    textComponent = new Text(label, x + 15, y + height/2 - 5, Theme.DARK_GRAY, Theme.NORMAL_SIZE);
  }
  
  void render() {
    // Color de fondo según estado
    if (isSelected) {
      fill(Theme.PRIMARY_BLUE);
    } else if (isHovered) {
      fill(Theme.LIGHT_GRAY);
    } else {
      fill(Theme.WHITE);
    }
    
    noStroke();
    rect(x, y, width, height, 5);
    
    // Actualizar color del texto
    color textColor = isSelected ? Theme.WHITE : Theme.DARK_GRAY;
    textComponent.setColor(textColor);
    
    // Renderizar texto
    textComponent.render();
    
    // Indicador de selección
    if (isSelected) {
      fill(Theme.WHITE);
      rect(x - 3, y + 5, 3, height - 10);
    }
  }
  
  void handleClick(float mouseX, float mouseY) {
    if (isClicked(mouseX, mouseY)) {
      setSelected(true);
    }
  }
  
  boolean isClicked(float mouseX, float mouseY) {
    return mouseX >= x && mouseX <= x + width && 
           mouseY >= y && mouseY <= y + height;
  }
  
  void setSelected(boolean selected) {
    this.isSelected = selected;
  }
  
  boolean isSelected() {
    return isSelected;
  }
  
  void setHovered(boolean hovered) {
    this.isHovered = hovered;
  }
  
  // Implementación de Stateful
  void setState(String state) {
    switch(state.toLowerCase()) {
      case "selected":
        setSelected(true);
        break;
      case "normal":
        setSelected(false);
        setHovered(false);
        break;
      case "hovered":
        setHovered(true);
        break;
    }
  }
  
  String getState() {
    if (isSelected) return "selected";
    if (isHovered) return "hovered";
    return "normal";
  }
  
  // Getters
  String getLabel() { return label; }
  float getX() { return x; }
  float getY() { return y; }
  float getWidth() { return width; }
  float getHeight() { return height; }
}

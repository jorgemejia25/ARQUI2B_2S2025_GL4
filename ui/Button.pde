// Botón básico reutilizable

class Button {
  String label;
  float x, y, w, h;
  color bgColor, textColor;
  boolean isPressed;
  boolean isHovered;
  
  Button(String label, float x, float y, float w, float h) {
    this.label = label;
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
    this.bgColor = Theme.PRIMARY_BLUE;
    this.textColor = Theme.WHITE;
    this.isPressed = false;
    this.isHovered = false;
  }
  
  Button(String label, float x, float y, float w, float h, color bgColor, color textColor) {
    this(label, x, y, w, h);
    this.bgColor = bgColor;
    this.textColor = textColor;
  }
  
  void render() {
    updateState();
    
    // Fondo del botón
    if (isPressed) {
      fill(red(bgColor) * 0.8, green(bgColor) * 0.8, blue(bgColor) * 0.8);
    } else if (isHovered) {
      fill(red(bgColor) * 1.1, green(bgColor) * 1.1, blue(bgColor) * 1.1);
    } else {
      fill(bgColor);
    }
    
    noStroke();
    rect(x, y, w, h, 4);
    
    // Texto del botón
    fill(textColor);
    textAlign(CENTER, CENTER);
    textSize(Theme.SMALL_SIZE);
    text(label, x + w/2, y + h/2);
  }
  
  void updateState() {
    isHovered = mouseX >= x && mouseX <= x + w && mouseY >= y && mouseY <= y + h;
  }
  
  boolean isClicked() {
    return isHovered && mousePressed;
  }
  
  void setPosition(float x, float y) {
    this.x = x;
    this.y = y;
  }
  
  void setSize(float w, float h) {
    this.w = w;
    this.h = h;
  }
}

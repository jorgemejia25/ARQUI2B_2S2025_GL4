// Componente de texto con estilos predefinidos

class Text {
  String content;
  float x, y;
  color textColor;
  int textSize;
  int alignH, alignV;
  
  Text(String content, float x, float y) {
    this.content = content;
    this.x = x;
    this.y = y;
    this.textColor = Theme.DARK_GRAY;
    this.textSize = Theme.NORMAL_SIZE;
    this.alignH = LEFT;
    this.alignV = CENTER;
  }
  
  Text(String content, float x, float y, color textColor, int textSize) {
    this(content, x, y);
    this.textColor = textColor;
    this.textSize = textSize;
  }
  
  void render() {
    fill(textColor);
    textAlign(alignH, alignV);
    textSize(textSize);
    text(content, x, y);
  }
  
  void setContent(String newContent) {
    this.content = newContent;
  }
  
  void setPosition(float x, float y) {
    this.x = x;
    this.y = y;
  }
  
  void setAlignment(int horizontal, int vertical) {
    this.alignH = horizontal;
    this.alignV = vertical;
  }
  
  void setStyle(color textColor, int textSize) {
    this.textColor = textColor;
    this.textSize = textSize;
  }
  
  void setColor(color newColor) {
    this.textColor = newColor;
  }
  
  void setSize(int newSize) {
    this.textSize = newSize;
  }
  
  // Métodos para estilos predefinidos
  Text asTitle() {
    setStyle(Theme.DARK_GRAY, Theme.TITLE_SIZE);
    return this;
  }
  
  Text asSubtitle() {
    setStyle(Theme.DARK_GRAY, Theme.SUBTITLE_SIZE);
    return this;
  }
  
  Text asSmall() {
    setStyle(Theme.MEDIUM_GRAY, Theme.SMALL_SIZE);
    return this;
  }
  
  Text asLarge() {
    setStyle(textColor, Theme.LARGE_SIZE);
    return this;
  }
}

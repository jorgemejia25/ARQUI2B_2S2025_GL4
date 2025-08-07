// Tarjeta de información con valor y título

class InfoCard {
  String title;
  String value;
  color cardColor;
  float x, y;
  float width, height;
  Text titleText;
  Text valueText;
  
  InfoCard(String title, String value, color cardColor, float x, float y) {
    this.title = title;
    this.value = value;
    this.cardColor = cardColor;
    this.x = x;
    this.y = y;
    this.width = Theme.CARD_WIDTH;
    this.height = Theme.CARD_HEIGHT;
    
    // Crear componentes de texto
    this.titleText = new Text(title, x + 15, y + 20, Theme.DARK_GRAY, Theme.TINY_SIZE);
    this.titleText.setAlignment(LEFT, TOP);
    
    this.valueText = new Text(value, x + 15, y + height/2 + 10, cardColor, Theme.LARGE_SIZE);
    this.valueText.setAlignment(LEFT, CENTER);
  }
  
  void render() {
    // Sombra de la tarjeta
    drawSoftShadow(x, y, width, height, 3);
    
    // Fondo de la tarjeta
    fill(Theme.WHITE);
    noStroke();
    rect(x, y, width, height);
    
    // Línea de color superior
    fill(cardColor);
    rect(x, y, width, 4);
    
    // Renderizar textos
    titleText.render();
    valueText.render();
  }
  
  void updateValue(String newValue) {
    this.value = newValue;
    this.valueText.setContent(newValue);
  }
  
  void setPosition(float x, float y) {
    this.x = x;
    this.y = y;
    this.titleText.setPosition(x + 15, y + 20);
    this.valueText.setPosition(x + 15, y + height/2 + 10);
  }
  
  void setSize(float width, float height) {
    this.width = width;
    this.height = height;
    this.valueText.setPosition(x + 15, y + height/2 + 10);
  }
}

class SemaforoVisual {
  float x, y;
  String id;
  String estado;
  float width = 70;    // Tamaño reducido para que quepan todos
  float height = 100;  // Alto reducido para mejor ajuste
  
  // Colores para cada luz
  color colorRojo, colorAmarillo, colorVerde;
  
  SemaforoVisual(float x, float y, String id) {
    this.x = x;
    this.y = y;
    this.id = id;
    this.estado = "ROJO"; // Estado inicial
    actualizarColores();
  }
  
  void actualizarEstado(String nuevoEstado) {
    this.estado = nuevoEstado;
    actualizarColores();
  }
  
  void actualizarColores() {
    // Resetear colores (apagados)
    colorRojo = color(100, 50, 50);      // Rojo apagado
    colorAmarillo = color(100, 100, 50); // Amarillo apagado  
    colorVerde = color(50, 100, 50);     // Verde apagado
    
    // Encender color según estado
    switch(estado) {
      case "ROJO":
        colorRojo = Theme.DANGER_COLOR;
        break;
      case "AMARILLO":
        colorAmarillo = Theme.WARNING_COLOR;
        break;
      case "VERDE":
        colorVerde = Theme.SUCCESS_COLOR;
        break;
    }
  }
    void render() {
    float centerX = x + width/2;
    
    // Etiqueta "Semáforo X" arriba del semáforo
    fill(Theme.TEXT_COLOR);
    noStroke();
    textAlign(CENTER);
    textSize(Theme.SMALL_SIZE);
    String numeroSemaforo = id.substring(1); // Extrae el número del ID (ej: "S1" -> "1")
    text("Semáforo " + numeroSemaforo, centerX, y - 15);
    
    // Sombra del semáforo
    fill(0, 30);
    noStroke();
    rect(x + 3, y + 3, width, height, 12);
    
    // Marco del semáforo - más elegante
    fill(40, 40, 45);
    stroke(20);
    strokeWeight(3);
    rect(x, y, width, height, 12);
    
    // Marco interno
    fill(60, 60, 65);
    noStroke();
    rect(x + 8, y + 8, width - 16, height - 16, 8);
    
    // Luces del semáforo - ajustado para tamaño menor
    float lightRadius = 15;  // Radio reducido
    float lightSpacing = (height - 30) / 4;  // Espaciado ajustado
    
    // Luz roja (superior)
    fill(colorRojo);
    noStroke();
    circle(centerX, y + lightSpacing, lightRadius);
    // Borde de la luz
    stroke(255, 50);
    strokeWeight(1);
    noFill();
    circle(centerX, y + lightSpacing, lightRadius + 2);
    
    // Luz amarilla (medio)
    fill(colorAmarillo);
    noStroke();
    circle(centerX, y + 2 * lightSpacing, lightRadius);
    // Borde de la luz
    stroke(255, 50);
    strokeWeight(2);
    noFill();
    circle(centerX, y + 2 * lightSpacing, lightRadius + 2);
    
    // Luz verde (inferior)
    fill(colorVerde);
    noStroke();
    circle(centerX, y + 3 * lightSpacing, lightRadius);
    // Borde de la luz
    stroke(255, 50);
    strokeWeight(2);
    noFill();
    circle(centerX, y + 3 * lightSpacing, lightRadius + 2);
    
    // ID del semáforo - mejor posicionamiento
    fill(Theme.WHITE);
    stroke(Theme.DARK_GRAY);
    strokeWeight(1);
    textAlign(CENTER);
    textSize(Theme.NORMAL_SIZE);
    text(id, centerX, y + height + 20);
    
    // Estado actual - más visible
    fill(Theme.TEXT_COLOR);
    noStroke();
    textSize(Theme.SMALL_SIZE);
    text(estado, centerX, y + height + 40);
    
    // Efecto de brillo en luz activa - mejorado
    if (estado.equals("ROJO")) {
      drawGlow(centerX, y + lightSpacing, lightRadius, Theme.DANGER_COLOR);
    } else if (estado.equals("AMARILLO")) {
      drawGlow(centerX, y + 2 * lightSpacing, lightRadius, Theme.WARNING_COLOR);
    } else if (estado.equals("VERDE")) {
      drawGlow(centerX, y + 3 * lightSpacing, lightRadius, Theme.SUCCESS_COLOR);
    }
  }
    void drawGlow(float centerX, float centerY, float radius, color glowColor) {
    // Efecto de brillo más suave y atractivo
    noStroke();
    for (int i = 5; i >= 1; i--) {
      float alpha = 25.0 / i;  // Transparencia gradual
      fill(red(glowColor), green(glowColor), blue(glowColor), alpha);
      circle(centerX, centerY, radius + i * 6);
    }
    
    // Brillo central más intenso
    fill(255, 80);
    circle(centerX, centerY, radius * 0.6);
  }
  
  boolean isClicked(float mouseX, float mouseY) {
    return mouseX >= x && mouseX <= x + width && 
           mouseY >= y && mouseY <= y + height;
  }
}
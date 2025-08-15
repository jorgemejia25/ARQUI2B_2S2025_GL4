class SemaforoVisual {
  float x, y;
  String id;
  String estado;
  float width = 70;    // Tamaño reducido para que quepan todos
  float height = 100;  // Alto reducido para mejor ajuste
  boolean infraccion = false;
  
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
  
  void actualizarInfraccion(boolean hayInfraccion) {
    this.infraccion = hayInfraccion;
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
    
    // Etiqueta compacta arriba (id)
    fill(Theme.TEXT_COLOR);
    noStroke();
    textAlign(CENTER);
    textSize(Theme.TINY_SIZE);
    text(id, centerX, y - 10);
    
    // Sombra del semáforo
    fill(0, 30);
    noStroke();
    rect(x + 3, y + 3, width, height, 12);
    
    // Marco del semáforo - más elegante
    fill(40, 40, 45);
    stroke(20);
    strokeWeight(3);
    rect(x, y, width, height, 12);
    
    // Indicador de infracción: borde exterior resaltado
    if (infraccion) {
      noFill();
      stroke(Theme.DANGER_COLOR);
      strokeWeight(4);
      rect(x - 4, y - 4, width + 8, height + 8, 14);
    }

    // Badge de estado (icono): arriba a la derecha del marco
    drawInfractionBadge();
    
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
    
    // Estado actual compacto debajo
    fill(Theme.TEXT_COLOR);
    noStroke();
    textSize(Theme.TINY_SIZE);
    text(estado, centerX, y + height + 18);
    
    // Etiqueta de estado por infracción bajo el estado del semáforo
    textSize(Theme.TINY_SIZE);
    if (infraccion) {
      fill(Theme.DANGER_COLOR);
      text("Infracción", centerX, y + height + 32);
    } else {
      fill(Theme.SUCCESS_COLOR);
      text("OK", centerX, y + height + 32);
    }
    
    // Efecto de brillo en luz activa - mejorado
    if (estado.equals("ROJO")) {
      drawGlow(centerX, y + lightSpacing, lightRadius, Theme.DANGER_COLOR);
    } else if (estado.equals("AMARILLO")) {
      drawGlow(centerX, y + 2 * lightSpacing, lightRadius, Theme.WARNING_COLOR);
    } else if (estado.equals("VERDE")) {
      drawGlow(centerX, y + 3 * lightSpacing, lightRadius, Theme.SUCCESS_COLOR);
    }
  }

  void drawInfractionBadge() {
    float badgeSize = 18;
    float bx = x + width - badgeSize/2;
    float by = y - badgeSize/2;
    if (infraccion) {
      // Triángulo de alerta con signo de exclamación
      noStroke();
      fill(Theme.DANGER_COLOR);
      float h = badgeSize;
      float half = badgeSize / 2.0;
      triangle(bx - half, by + half, bx + half, by + half, bx, by - half);
      // Exclamación
      fill(255);
      rectMode(CENTER);
      rect(bx, by + 1, 3, h * 0.45);
      rect(bx, by + half * 0.6, 3, 3);
      rectMode(CORNER);
    } else {
      // Círculo verde con check
      noStroke();
      fill(Theme.SUCCESS_COLOR);
      circle(bx, by, badgeSize);
      // Check con líneas blancas
      stroke(255);
      strokeWeight(2);
      float cx = bx - badgeSize * 0.18;
      float cy = by + badgeSize * 0.05;
      line(cx - 3, cy, cx, cy + 4);
      line(cx, cy + 4, cx + 6, cy - 4);
      noStroke();
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
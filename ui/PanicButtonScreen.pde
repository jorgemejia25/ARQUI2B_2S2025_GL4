class PanicButtonScreen extends Screen {
  // Lista de botones
  private String[] botones = {"Parada 1", "Parada 2", "Lugar H1", "Lugar H2"};
  private boolean[] estadoBoton = {false, false, false, false}; // false = inactivo, true = activo
  private ArrayList<String> logEventos = new ArrayList<String>();
  
  PanicButtonScreen(float x, float y, float width, float height, DataProvider dataProvider) {
    super("Botones de Pánico", x, y, width, height);
    
    // Simular algunos eventos para prueba
    logEventos.add("[08:30:15] Parada 1 ACTIVADO");
    logEventos.add("[08:31:22] Parada 1 DESACTIVADO");
    logEventos.add("[09:15:45] Lugar H2 ACTIVADO");
  }
  
  // Implementar el método abstracto requerido
  void renderContent() {
    drawPanicButtons();
    drawEventLog();
  }
  
  private void drawPanicButtons() {
    fill(Theme.DARK_GRAY);
    textSize(18);
    textAlign(LEFT);
    text("Estado de Botones de Pánico:", x + Theme.MARGIN, y + 80);
    
    // Calcular el tamaño de los botones más grandes
    float btnSize = 80;
    float spacing = 150;
    float startX = x + Theme.MARGIN + 50;
    float startY = y + 120;
    
    for (int i = 0; i < botones.length; i++) {
      float btnX = startX + (i % 2) * spacing;
      float btnY = startY + (i / 2) * 120;
      
      // Contenedor para cada indicador
      fill(Theme.WHITE);
      stroke(Theme.MEDIUM_GRAY);
      strokeWeight(2);
      rect(btnX - 20, btnY - 20, 140, 100, 12);
      
      // Indicador de estado grande (círculo)
      fill(estadoBoton[i] ? color(255, 50, 50) : color(50, 200, 50));
      noStroke();
      ellipse(btnX + 20, btnY + 10, btnSize, btnSize);
      
      // Texto del botón
      fill(Theme.DARK_GRAY);
      textSize(14);
      textAlign(CENTER);
      text(botones[i], btnX + 20, btnY + 55);
      
      // Estado actual
      fill(estadoBoton[i] ? color(255, 50, 50) : color(50, 150, 50));
      textSize(12);
      textAlign(CENTER);
      String estado = estadoBoton[i] ? "ACTIVADO" : "NORMAL";
      text(estado, btnX + 20, btnY + 70);
      
      // Simular activación aleatoria para demo
      if (random(1000) < 1) {
        actualizarBotonPanico(i, !estadoBoton[i]);
      }
    }
    
    textAlign(LEFT); // Restaurar alineación
  }
  
  private void drawEventLog() {
    float logStartY = y + 380;
    
    // Título del log
    fill(Theme.DARK_GRAY);
    textSize(18);
    textAlign(LEFT);
    text("Registro de Eventos Recientes:", x + Theme.MARGIN, logStartY);
    
    // Contenedor del log
    fill(Theme.WHITE);
    stroke(Theme.MEDIUM_GRAY);
    strokeWeight(1);
    rect(x + Theme.MARGIN, logStartY + 20, width - 2 * Theme.MARGIN, 200, 8);
    
    // Eventos (mostrar solo los últimos 8 para que quepan)
    fill(Theme.DARK_GRAY);
    textSize(12);
    int startIndex = max(0, logEventos.size() - 8);
    
    for (int j = startIndex; j < logEventos.size(); j++) {
      float textY = logStartY + 45 + (j - startIndex) * 22;
      
      // Color del texto según el tipo de evento
      String evento = logEventos.get(j);
      if (evento.contains("ACTIVADO")) {
        fill(color(200, 50, 50));
      } else if (evento.contains("DESACTIVADO")) {
        fill(color(50, 150, 50));
      } else {
        fill(Theme.DARK_GRAY);
      }
      
      text(evento, x + Theme.MARGIN + 10, textY);
    }
    
    // Si no hay eventos
    if (logEventos.size() == 0) {
      fill(Theme.MEDIUM_GRAY);
      textAlign(CENTER);
      text("No hay eventos registrados", x + width/2, logStartY + 130);
      textAlign(LEFT);
    }
  }
  
  void actualizarBotonPanico(int index, boolean activo) {
    estadoBoton[index] = activo;
    String hora = nf(hour(), 2) + ":" + nf(minute(), 2) + ":" + nf(second(), 2);
    String evento = "[" + hora + "] " + botones[index] + (activo ? " ACTIVADO" : " DESACTIVADO");
    logEventos.add(evento);
    
    // Mantener solo los últimos 50 eventos para evitar overflow de memoria
    if (logEventos.size() > 50) {
      logEventos.remove(0);
    }
    
    println("Evento registrado: " + evento);
  }
  
  // Métodos públicos para que otras partes del sistema puedan acceder al estado
  boolean[] getEstadoBotones() {
    return estadoBoton.clone();
  }
  
  String[] getNombresBotones() {
    return botones.clone();
  }
  
  ArrayList<String> getLogEventos() {
    return new ArrayList<String>(logEventos);
  }
}
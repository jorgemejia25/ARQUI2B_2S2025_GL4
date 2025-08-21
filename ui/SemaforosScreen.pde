import java.util.HashMap;

class SemaforosScreen extends Screen {
  private ArrayList<SemaforoVisual> semaforosVisuales;
  private ArrayList<SemaforoVisual> semaforosAB; // A1..A5 (fila 1) y B1..B5 (fila 2)
  private TrafficStats stats;
  private DataProvider dataProvider;
  
  SemaforosScreen(float x, float y, float width, float height, DataProvider dataProvider) {
    super("Estado de Semáforos", x, y, width, height);
    this.dataProvider = dataProvider;
    inicializarSemaforos();
  }
  
  void inicializarSemaforos() {
    semaforosVisuales = new ArrayList<SemaforoVisual>();
    semaforosAB = new ArrayList<SemaforoVisual>();
    
    // Layout mejorado: 5 columnas x 2 filas (horizontal)
    int cols = 5;  // 5 semáforos por fila
    int rows = 2;  // 2 filas
    
    // Padding y márgenes optimizados
    float paddingX = 40;   // Padding horizontal reducido
    float paddingY = 80;   // Padding vertical superior reducido
    float bottomPadding = 80; // Espacio para leyenda reducido
    
    // Calcular área disponible
    float areaWidth = width - (2 * paddingX);
    float areaHeight = height - paddingY - bottomPadding;
    
  // Espaciado entre semáforos
  float spacingX = areaWidth / cols;
  // Distancia base entre filas (centro a centro)
  float desiredRowGap = 130; 
  float spacingY = (float) Math.min(areaHeight / rows, desiredRowGap);
  // Pequeño incremento adicional solo para la segunda fila
  float extraRowGap = 70; // píxeles extra entre la primera y la segunda fila
  // Nueva "fila" de separación por encima de la primera fila (espaciador superior)
  float topRowSpacer = 60; // píxeles extra para separar del título/estadísticas
    
    // (legacy S1..S10 omitido)

    // NUEVO: grilla 2x5: fila 1 = A1..A5, fila 2 = B1..B5
    int colsAB = 5;
    int rowsAB = 2;
    float gridPaddingX = 40;
    float gridTop = y + 140;
    float gridWidth = width - (2 * gridPaddingX);
    float gridSpacingX = gridWidth / colsAB;
    float cellW = 60;
    float cellH = 95;
    float rowGap = 55;
    for (int row = 0; row < rowsAB; row++) {
      for (int col = 0; col < colsAB; col++) {
        float gx = x + gridPaddingX + (col * gridSpacingX) + (gridSpacingX / 2) - (cellW/2);
        float gy = gridTop + row * (cellH + rowGap);
        String id = (row == 0 ? "A" : "B") + str(col + 1);
        semaforosAB.add(new SemaforoVisual(gx, gy, id));
      }
    }
  }
  
  @Override
  void renderContent() {
    // Obtener datos actuales (para A/B y estadísticas)
    JSONObject all = dataProvider.getCurrentData();
    stats = dataProvider.getStats();
    
    // (El título lo dibuja la clase base Screen)

    // Estadísticas en la parte superior
    renderEstadisticas();
    
    // Render A/B por calles
    JSONObject ab = null;
    JSONArray det = null;
    try {
      if (all != null && all.hasKey("semaforosAB")) ab = all.getJSONObject("semaforosAB");
      if (all != null && all.hasKey("infracciones_detalle")) det = all.getJSONArray("infracciones_detalle");
    } catch(Exception e) {}

    // Mapa de infracciones por id (A1..B3)
    HashMap<String, Boolean> infMap = new HashMap<String, Boolean>();
    if (det != null) {
      for (int i = 0; i < det.size(); i++) {
        try {
          JSONObject d = det.getJSONObject(i);
          String tipo = d.getString("tipo");
          int calle = d.getInt("calle");
          String key = tipo + calle;
          infMap.put(key, true);
        } catch(Exception ie) {}
      }
    }

    // Etiquetas de columnas
    fill(Theme.TEXT_COLOR);
    textAlign(CENTER);
    textSize(Theme.SMALL_SIZE);
    // Columnas
    if (semaforosAB.size() >= 10) {
      text("C1", semaforosAB.get(0).x + 25, semaforosAB.get(0).y - 30);
      text("C2", semaforosAB.get(1).x + 25, semaforosAB.get(1).y - 30);
      text("C3", semaforosAB.get(2).x + 25, semaforosAB.get(2).y - 30);
      text("C4", semaforosAB.get(3).x + 25, semaforosAB.get(3).y - 30);
      text("C5", semaforosAB.get(4).x + 25, semaforosAB.get(4).y - 30);
    }

    for (SemaforoVisual s : semaforosAB) {
      String estado = "ROJO";
      if (ab != null && ab.hasKey(s.id)) {
        estado = ab.getString(s.id);
      }
      s.actualizarEstado(estado);
      boolean hasInf = infMap.containsKey(s.id);
      s.actualizarInfraccion(hasInf);
      s.render();
    }
    
    // Leyenda en la parte inferior
    renderLeyenda();
    
    // Información de última actualización
    fill(Theme.TEXT_COLOR);
    textAlign(RIGHT);
    textSize(Theme.SMALL_SIZE);
    JSONObject data = dataProvider.getCurrentData();
    text("Última actualización: " + data.getString("ts"), x + width - 20, y + height - 10);
  }
  
  void renderEstadisticas() {
    // Panel de estadísticas
    fill(255, 250);
    stroke(Theme.BORDER_COLOR);
    rect(x + 20, y + 60, width - 40, 40);
    
    fill(Theme.TEXT_COLOR);
    textAlign(LEFT);
    textSize(Theme.SMALL_SIZE);
    
    float textX = x + 30;
    float textY = y + 82;
    
    // Rojos
    fill(Theme.DANGER_COLOR);
    text("Rojos: " + stats.semaforosRojos, textX, textY);
    
    // Verdes
    textX += 120;
    fill(Theme.SUCCESS_COLOR);
    text("Verdes: " + stats.semaforosVerdes, textX, textY);
    
    // Amarillos
    textX += 120;
    fill(Theme.WARNING_COLOR);
    text("Amarillos: " + stats.semaforosAmarillos, textX, textY);
    
    // Total
    textX += 140;
    fill(Theme.TEXT_COLOR);
  text("Total: 10 semáforos", textX, textY);
  }
  
  void renderLeyenda() {
    // Panel de leyenda en la esquina inferior derecha
    float leyendaX = x + width - 180;
    float leyendaY = y + height - 90;
    
    fill(255, 250);
    stroke(Theme.BORDER_COLOR);
    rect(leyendaX, leyendaY, 160, 70);
    
    fill(Theme.TEXT_COLOR);
    textAlign(LEFT);
    textSize(Theme.TINY_SIZE);
    text("Leyenda:", leyendaX + 10, leyendaY + 18);
    
    // Colores de estados compactos
    float iconY = leyendaY + 35;
    
    fill(Theme.DANGER_COLOR);
    circle(leyendaX + 20, iconY, 10);
    fill(Theme.TEXT_COLOR);
    text("Rojo", leyendaX + 30, iconY + 4);
    
    fill(Theme.SUCCESS_COLOR);
    circle(leyendaX + 70, iconY, 10);
    fill(Theme.TEXT_COLOR);
    text("Verde", leyendaX + 80, iconY + 4);
    
    fill(Theme.WARNING_COLOR);
    circle(leyendaX + 120, iconY, 10);
    fill(Theme.TEXT_COLOR);
    text("Amarillo", leyendaX + 130, iconY + 4);
    
    iconY += 20;
    fill(Theme.TEXT_COLOR);
    textSize(Theme.TINY_SIZE - 1);
    text("Actualización automática cada 2s", leyendaX + 10, iconY);
  }

  // Manejo de clics sobre los semáforos
  void handleMousePressed(int mx, int my) {
    if (semaforosAB == null) return;
    for (SemaforoVisual semaforo : semaforosAB) {
      if (semaforo.isClicked(mx, my)) {
        println("Click en " + semaforo.id + " (estado: " + semaforo.estado + ")");
        break;
      }
    }
  }
}
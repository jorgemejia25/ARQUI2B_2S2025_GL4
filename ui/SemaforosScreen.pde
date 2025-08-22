import java.util.HashMap;

class SemaforosScreen extends Screen {
  private ArrayList<SemaforoVisual> semaforos; // S1..S10
  private TrafficStats stats;
  private DataProvider dataProvider;
  
  SemaforosScreen(float x, float y, float width, float height, DataProvider dataProvider) {
    super("Estado de Semáforos", x, y, width, height);
    this.dataProvider = dataProvider;
    inicializarSemaforos();
  }
  
  void inicializarSemaforos() {
    semaforos = new ArrayList<SemaforoVisual>();
    
    // Layout: 5 columnas x 2 filas para 10 semáforos S1..S10
    int gridCols = 5;
    int gridRows = 2;
    float gridPaddingX = 40;
    float gridTop = y + 140;
    float gridWidth = width - (2 * gridPaddingX);
    float gridSpacingX = gridWidth / gridCols;
    float cellW = 60;
    float cellH = 95;
    float rowGap = 55;
    int idx = 1;
    for (int row = 0; row < gridRows; row++) {
      for (int col = 0; col < gridCols; col++) {
        float gx = x + gridPaddingX + (col * gridSpacingX) + (gridSpacingX / 2) - (cellW/2);
        float gy = gridTop + row * (cellH + rowGap);
        String id = "S" + str(idx);
        semaforos.add(new SemaforoVisual(gx, gy, id));
        idx++;
      }
    }
  }
  
  @Override
  void renderContent() {
    // Obtener datos actuales y estadísticas
    JSONObject all = dataProvider.getCurrentData();
    stats = dataProvider.getStats();

    renderEstadisticas();

    JSONObject sems = null;
      JSONArray det = new JSONArray();
      // infracciones_detalle removed: use computed infracciones if needed
      try {
        if (all != null && all.hasKey("semaforos")) sems = all.getJSONObject("semaforos");
    } catch(Exception e) {}

    // Mapa de infracciones por id (ahora infracciones contiene IDs de semáforos, p.ej. S1..S10)
    HashMap<String, Boolean> infMap = new HashMap<String, Boolean>();
    try {
      if (all != null && all.hasKey("infracciones")) {
        JSONArray infs = all.getJSONArray("infracciones");
        for (int i = 0; i < infs.size(); i++) {
          try {
            String sid = infs.getString(i);
            infMap.put(sid, true);
          } catch(Exception ex) {}
        }
      }
    } catch(Exception e) {}

    // Etiquetas de columnas
    fill(Theme.TEXT_COLOR);
    textAlign(CENTER);
    textSize(Theme.SMALL_SIZE);
    if (semaforos.size() >= 5) {
      text("C1", semaforos.get(0).x + 25, semaforos.get(0).y - 30);
      text("C2", semaforos.get(1).x + 25, semaforos.get(1).y - 30);
      text("C3", semaforos.get(2).x + 25, semaforos.get(2).y - 30);
      text("C4", semaforos.get(3).x + 25, semaforos.get(3).y - 30);
      text("C5", semaforos.get(4).x + 25, semaforos.get(4).y - 30);
    }

    for (SemaforoVisual s : semaforos) {
      String estado = "ROJO";
      if (sems != null && sems.hasKey(s.id)) {
        estado = sems.getString(s.id);
      }
      s.actualizarEstado(estado);
      boolean hasInf = infMap.containsKey(s.id);
      s.actualizarInfraccion(hasInf);
      s.render();
    }

    renderLeyenda();

    fill(Theme.TEXT_COLOR);
    textAlign(RIGHT);
    textSize(Theme.SMALL_SIZE);
    JSONObject data = dataProvider.getCurrentData();
    text("Última actualización: " + data.getString("ts"), x + width - 20, y + height - 10);
  }
  
  void renderEstadisticas() {
    fill(255, 250);
    stroke(Theme.BORDER_COLOR);
    rect(x + 20, y + 60, width - 40, 40);
    
    fill(Theme.TEXT_COLOR);
    textAlign(LEFT);
    textSize(Theme.SMALL_SIZE);
    
    float textX = x + 30;
    float textY = y + 82;
    
    fill(Theme.DANGER_COLOR);
    text("Rojos: " + stats.semaforosRojos, textX, textY);
    
    textX += 120;
    fill(Theme.SUCCESS_COLOR);
    text("Verdes: " + stats.semaforosVerdes, textX, textY);
    
    textX += 120;
    fill(Theme.WARNING_COLOR);
    text("Amarillos: " + stats.semaforosAmarillos, textX, textY);
    
    textX += 140;
    fill(Theme.TEXT_COLOR);
    text("Total: 10 semáforos", textX, textY);
  }
  
  void renderLeyenda() {
    float leyendaX = x + width - 180;
    float leyendaY = y + height - 90;
    
    fill(255, 250);
    stroke(Theme.BORDER_COLOR);
    rect(leyendaX, leyendaY, 160, 70);
    
    fill(Theme.TEXT_COLOR);
    textAlign(LEFT);
    textSize(Theme.TINY_SIZE);
    text("Leyenda:", leyendaX + 10, leyendaY + 18);
    
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

  void handleMousePressed(int mx, int my) {
  // Click handling disabled intentionally. Method kept to avoid breaking callers.
  }
}
class SemaforosScreen extends Screen {
  private ArrayList<SemaforoVisual> semaforosVisuales;
  private TrafficStats stats;
  private DataProvider dataProvider;
  
  SemaforosScreen(float x, float y, float width, float height, DataProvider dataProvider) {
    super("Estado de Semáforos", x, y, width, height);
    this.dataProvider = dataProvider;
    inicializarSemaforos();
  }
  
  void inicializarSemaforos() {
    semaforosVisuales = new ArrayList<SemaforoVisual>();
    
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
    
    // Crear semáforos de izquierda a derecha, arriba hacia abajo
    for (int i = 0; i < 10; i++) {
      int row = i / cols;  // Fila (0 o 1)
      int col = i % cols;  // Columna (0 a 4)
      
  // Posición centrada de cada semáforo (ajustado para tamaño menor)
  float semaforoX = x + paddingX + (col * spacingX) + (spacingX / 2) - 35; // -35 para centrar (tamaño 70)
  // Ajuste Y: fila 1 (segunda fila) recibe un pequeño offset adicional
  float rowOffset = (row == 1) ? extraRowGap : 0;
  float semaforoY = y + paddingY + topRowSpacer + 20 + (row * spacingY) + (spacingY / 2) - 50 + rowOffset; // -50 para centrar (tamaño 100)
      
      String semaforoId = "S" + (i + 1);
      semaforosVisuales.add(new SemaforoVisual(semaforoX, semaforoY, semaforoId));
    }
  }
  
  @Override
  void renderContent() {
    // Obtener datos actuales
    JSONObject semaforosData = dataProvider.getSemaforoData();
    JSONObject infraccionesSemData = null;
    try {
      JSONObject all = dataProvider.getCurrentData();
      if (all != null && all.hasKey("infracciones_semaforos")) {
        infraccionesSemData = all.getJSONObject("infracciones_semaforos");
      }
    } catch(Exception e) {
      // ignorar, se mantiene null
    }
    stats = dataProvider.getStats();
    
    // Título
    fill(Theme.PRIMARY_COLOR);
    textAlign(CENTER);
    textSize(Theme.TITLE_SIZE);
    text("Estado de Semáforos", x + width/2, y + 40);
    
    // Estadísticas en la parte superior
    renderEstadisticas();
    
    // Actualizar y renderizar semáforos
    for (SemaforoVisual semaforo : semaforosVisuales) {
      String estado = semaforosData.getString(semaforo.id);
      semaforo.actualizarEstado(estado);
      if (infraccionesSemData != null && infraccionesSemData.hasKey(semaforo.id)) {
        boolean inf = infraccionesSemData.getInt(semaforo.id) == 1;
        semaforo.actualizarInfraccion(inf);
      } else {
        semaforo.actualizarInfraccion(false);
      }
      semaforo.render();
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
    text("🔴 " + stats.semaforosRojos + " Rojos", textX, textY);
    
    // Verdes
    textX += 120;
    fill(Theme.SUCCESS_COLOR);
    text("🟢 " + stats.semaforosVerdes + " Verdes", textX, textY);
    
    // Amarillos
    textX += 120;
    fill(Theme.WARNING_COLOR);
    text("🟡 " + stats.semaforosAmarillos + " Amarillos", textX, textY);
    
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
    if (semaforosVisuales == null) return;
    for (SemaforoVisual semaforo : semaforosVisuales) {
      if (semaforo.isClicked(mx, my)) {
        // Por ahora solo informamos el clic; los estados vienen del DataProvider
        println("Click en " + semaforo.id + " (estado: " + semaforo.estado + ")");
        break;
      }
    }
  }
}
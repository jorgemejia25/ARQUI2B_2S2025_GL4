// Nueva pantalla de mapa urbano
// Muestra un grid 3x2 (3 columnas x 2 filas) representando sectores de la ciudad
// - Borde perimetral resaltado = ruta Transmetro
// - Línea horizontal interna doble = ruta Transurbano

class MapScreen extends Screen {
  DataProvider dataProvider;
  float gridX, gridY, gridW, gridH;
  int cols = 3;
  int rows = 2;
  float cellW, cellH;
  
  MapScreen(float x, float y, float width, float height, DataProvider dp) {
    super("Mapa Urbano", x, y, width, height);
    this.dataProvider = dp;
    float margin = 60; // margen interno amplio
    gridX = x + margin;
    gridY = y + 100; // dejar espacio para título arriba
    gridW = width - margin*2;
    gridH = height - 180; // reservar espacio inferior para leyenda
    cellW = gridW / cols;
    cellH = gridH / rows;
  }
  
  void renderContent() {
    renderTitle();
    renderGrid();
    renderRoutes();
    renderLegend();
  }
  
  void renderTitle() {
    fill(Theme.DARK_GRAY);
    textAlign(LEFT, TOP);
    textSize(Theme.TITLE_SIZE - 6);
    text("Mapa Urbano - Rutas de Transporte", x + 40, y + 40);
  }
  
  void renderGrid() {
    // Fondo del panel
    drawSoftShadow(gridX, gridY, gridW, gridH, 2);
    fill(Theme.WHITE);
    noStroke();
    rect(gridX, gridY, gridW, gridH, 10);
    // Bloques internos (rectángulos negros) 3x2
    float innerMargin = 24; // margen contra cada celda
    stroke(0);
    strokeWeight(4);
    noFill();
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        float cx = gridX + c * cellW + innerMargin;
        float cy = gridY + r * cellH + innerMargin;
        float w = cellW - innerMargin*2;
        float h = cellH - innerMargin*2;
        rect(cx, cy, w, h, 16);
      }
    }
  }
  
  void renderRoutes() {
    // Ruta Transmetro: rectángulo verde interno (ligeramente inset respecto al borde negro del mock)
    float inset = 18;
    noFill();
    stroke(Theme.GREEN);
    strokeWeight(8);
    rect(gridX + inset, gridY + inset, gridW - inset*2, gridH - inset*2, 14);
    // Ruta Transurbano: línea horizontal azul centrada entre filas (única línea)
    float midY = gridY + cellH; // línea divisoria entre fila superior e inferior
    stroke(Theme.PRIMARY_BLUE);
    strokeWeight(10);
    line(gridX + inset + 10, midY, gridX + gridW - inset - 10, midY);
  }
  
  void renderLegend() {
    float boxH = 70;
    float boxY = y + height - boxH - 30;
    float boxX = x + 40;
    float boxW = width - 80;
    drawSoftShadow(boxX, boxY, boxW, boxH, 2);
    fill(Theme.WHITE);
    noStroke();
    rect(boxX, boxY, boxW, boxH, 8);
    textAlign(LEFT, CENTER);
    textSize(14);
    float tx = boxX + 20;
    float ty = boxY + boxH/2;
  // Leyenda de colores
  // Transmetro
  fill(Theme.GREEN); rect(tx, ty-12, 40, 10, 4);
  fill(Theme.DARK_GRAY); text("Transmetro", tx + 55, ty-6);
  // Transurbano
  fill(Theme.PRIMARY_BLUE); rect(tx + 200, ty-8, 60, 6, 3);
  fill(Theme.DARK_GRAY); text("Transurbano", tx + 270, ty-6);
  }
}

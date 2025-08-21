// Pantalla para monitoreo de incendios (usa sensores de humo/gas MQ-02)

class IncendiosScreen extends Screen {
  private DataProvider dataProvider;
  private ArrayList<InfoCard> nivelCards;    // Niveles de humo/gas por zona
  private ArrayList<InfoCard> estadoCards;   // Estado de incendio (Incendio / Normal)
  private FireTrendChart fireChart;          // Tendencia de promedios
  private boolean anyCritical = false;
  
  IncendiosScreen(float x, float y, float width, float height, DataProvider dataProvider) {
    super("Incendios y Calidad del Aire", x, y, width, height);
    this.dataProvider = dataProvider;
    initializeComponents();
  }
  
  void initializeComponents() {
    nivelCards = new ArrayList<InfoCard>();
    estadoCards = new ArrayList<InfoCard>();
  // Mayor separación del título superior
  float topPadding = 115; // padding ampliado
  float cardY = y + topPadding;
  float horizontalPadding = 40; // antes 20
  float cardSpacing = Theme.CARD_WIDTH + 40; // más aire entre columnas
    // Dos zonas dinámicas (Z1, Z2)
    for (int i = 1; i <= 2; i++) {
      String zoneId = "Z" + i;
      InfoCard nivel = new InfoCard(
        "Nivel " + zoneId,
        "0 ppm",
        Theme.GREEN,
  x + horizontalPadding + (i-1) * cardSpacing,
        cardY
      );
      nivelCards.add(nivel);
      InfoCard estado = new InfoCard(
        "Incendio " + zoneId,
        "Normal",
        Theme.GREEN,
        x + horizontalPadding + (i-1) * cardSpacing,
        cardY + 150 // un poco más de separación vertical
      );
      estadoCards.add(estado);
    }
    // Reubicar gráfico más abajo por el nuevo padding
    fireChart = new FireTrendChart(x + horizontalPadding, cardY + 350, width - horizontalPadding*2, 190, dataProvider);
  }
  
  void renderContent() {
    updateNiveles();
    updateEstados();
    for (InfoCard c : nivelCards) c.render();
    for (InfoCard c : estadoCards) c.render();
    fireChart.render();
    renderEmergenciaBanner();
    renderInfoPanel();
  }
  
  void updateNiveles() {
    JSONObject gasData = dataProvider.getGasData();
    anyCritical = false;
    for (int i = 0; i < nivelCards.size(); i++) {
      String zoneId = "Z" + (i+1);
      int value = gasData.getInt(zoneId);
      InfoCard card = nivelCards.get(i);
      card.updateValue(value + " ppm");
      color col = nivelColor(value);
      if (col == Theme.RED) anyCritical = true;
      card.cardColor = col;
      card.valueText.setColor(col);
    }
  }
  
  void updateEstados() {
    JSONObject panic = dataProvider.getPanicoData(); // Reutilizamos panico como bandera de incendio detectado (digital)
    for (int i = 0; i < estadoCards.size(); i++) {
      String zoneId = "Z" + (i+1);
      int fire = panic.getInt(zoneId); // 1 => incendio confirmado
      InfoCard card = estadoCards.get(i);
      String txt = fire == 1 ? "INCENDIO" : "Normal";
      color col = fire == 1 ? Theme.RED : Theme.GREEN;
      card.updateValue(txt);
      card.cardColor = col;
      card.valueText.setColor(col);
    }
  }
  
  color nivelColor(int ppm) {
    if (ppm > 250) return Theme.RED;      // Crítico -> Incendio probable
    if (ppm > 200) return Theme.ORANGE;   // Alto
    if (ppm > 180) return Theme.ORANGE;   // Moderado
    return Theme.GREEN;                   // Normal
  }
  
  void renderEmergenciaBanner() {
    // Determinar si hay incendio (estadoCards en rojo) o niveles críticos
    boolean fireDetected = false;
    for (InfoCard c : estadoCards) {
      if (c.cardColor == Theme.RED) { fireDetected = true; break; }
    }
    if (!fireDetected && !anyCritical) return;
    String msg;
    color bg;
    if (fireDetected && anyCritical) { msg = "EMERGENCIA: Incendio y niveles críticos"; bg = Theme.RED; }
    else if (fireDetected) { msg = "ALERTA: Incendio detectado"; bg = Theme.RED; }
    else { msg = "Peligro: Niveles elevados de humo"; bg = Theme.ORANGE; }
    float bannerH = 44;
    float bannerY = y + 90; // antes 60, ahora debajo del nuevo padding
    float sidePad = 40;
    fill(bg); noStroke(); rect(x + sidePad, bannerY, width - sidePad*2, bannerH, 8);
    fill(Theme.WHITE); textAlign(CENTER, CENTER); textSize(Theme.NORMAL_SIZE);
    text(msg, x + width/2, bannerY + bannerH/2);
    if (millis() % 1000 < 450) { // borde parpadeante (ajustado a nuevo margen)
      stroke(bg); strokeWeight(3); noFill(); rect(x + 30, y + 30, width - 60, height - 60, 14); noStroke();
    }
  }
  
  void renderInfoPanel() {
  float infoY = y + height - 110;
  float sidePad = 40;
  drawSoftShadow(x + sidePad, infoY, width - sidePad*2, 90, 2);
  fill(Theme.WHITE); noStroke(); rect(x + sidePad, infoY, width - sidePad*2, 90, 8);
    fill(Theme.DARK_GRAY); textAlign(LEFT, TOP); textSize(Theme.NORMAL_SIZE);
  text("Resumen de Incendios", x + sidePad + 15, infoY + 14);
    TrafficStats stats = dataProvider.getStats();
    fill(Theme.MEDIUM_GRAY); textSize(Theme.SMALL_SIZE);
  text("Zonas con incendio: " + stats.zonasPanico, x + sidePad + 15, infoY + 34);
  text("Promedio ppm: " + stats.gasPromedio, x + sidePad + 15, infoY + 48);
  text("Infracciones: " + stats.infracciones, x + sidePad + 15, infoY + 62);
    JSONObject cur = dataProvider.getCurrentData();
  text("Última act.: " + cur.getString("ts"), x + sidePad + 260, infoY + 34);
  text("Rangos: Normal<180 | Mod 180-200 | Alto 200-250 | Crítico>250", x + sidePad + 260, infoY + 48);
  }
}

// Gráfico de tendencia (reutiliza lógica de SmokeChart con nuevo título)
class FireTrendChart {
  float x, y, width, height; DataProvider dataProvider; Text titleText; ArrayList<Float> history; int maxPoints = 20;
  FireTrendChart(float x, float y, float width, float height, DataProvider dataProvider) {
    this.x=x; this.y=y; this.width=width; this.height=height; this.dataProvider=dataProvider;
    titleText = new Text("Tendencia Promedio MQ-02", x + 20, y + 20, Theme.DARK_GRAY, Theme.NORMAL_SIZE);
    history = new ArrayList<Float>();
    for (int i=0;i<maxPoints;i++) history.add(random(150,200));
  }
  void render() {
    drawSoftShadow(x, y, width, height, 2);
    fill(Theme.WHITE); noStroke(); rect(x, y, width, height, 6);
    titleText.render(); update(); drawRefs(); drawLine(); drawLegend();
  }
  void update() {
    TrafficStats s = dataProvider.getStats(); history.add((float)s.gasPromedio); if (history.size()>maxPoints) history.remove(0);
  }
  void drawRefs() {
    stroke(Theme.MEDIUM_GRAY); strokeWeight(1);
    float chartX=x+40, chartY=y+40, chartW=width-80, chartH=height-80;
    int[] lv={150,180,200,250,300};
    for (int v:lv){ float lineY=chartY+chartH - map(v,150,300,0,chartH); line(chartX,lineY,chartX+chartW,lineY); fill(Theme.MEDIUM_GRAY); textAlign(RIGHT,CENTER); textSize(Theme.TINY_SIZE); text(v+" ppm", chartX-5,lineY);} noStroke();
  }
  void drawLine() {
    if (history.size()<2) return; float chartX=x+40, chartY=y+40, chartW=width-80, chartH=height-80;
    stroke(Theme.PRIMARY_BLUE); strokeWeight(2); noFill(); beginShape();
    for(int i=0;i<history.size();i++){ float val=history.get(i); float px=chartX+map(i,0,maxPoints-1,0,chartW); float py=chartY+chartH - map(val,150,300,0,chartH); vertex(px,py);} endShape();
    fill(Theme.PRIMARY_BLUE); noStroke();
    for(int i=0;i<history.size();i++){ float val=history.get(i); float px=chartX+map(i,0,maxPoints-1,0,chartW); float py=chartY+chartH - map(val,150,300,0,chartH); ellipse(px,py,4,4);}  }
  void drawLegend(){ float ly=y+height-25; fill(Theme.GREEN); rect(x+40,ly,15,10); fill(Theme.DARK_GRAY); textAlign(LEFT,CENTER); textSize(Theme.TINY_SIZE); text("Normal", x+60, ly+5); fill(Theme.ORANGE); rect(x+120,ly,15,10); fill(Theme.DARK_GRAY); text("Alto", x+140, ly+5); fill(Theme.RED); rect(x+180,ly,15,10); fill(Theme.DARK_GRAY); text("Crítico", x+200, ly+5);}  
}

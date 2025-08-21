// Pantalla principal del dashboard con vista general del sistema

class DashboardScreen extends Screen {
  private DataProvider dataProvider;
  private ArrayList<InfoCard> summaryCards;
  // Eliminado TrafficOverviewChart
  private Text statusText;
  // Mini cards adicionales
  private InfoCard sismoMiniCard;
  // NUEVO: 4 botones de pánico individuales
  private ArrayList<InfoCard> panicButtonCards;
  // Layout refs
  private float panicRowY;
  
  DashboardScreen(float x, float y, float width, float height, DataProvider dataProvider) {
    super("Dashboard Principal", x, y, width, height);
    this.dataProvider = dataProvider;
    
    initializeComponents();
  }
  
  void initializeComponents() {
    summaryCards = new ArrayList<InfoCard>();
  panicButtonCards = new ArrayList<InfoCard>();
    
    // Posicionamiento para tarjetas resumen
    float cardY = y + 80;
    float cardSpacing = Theme.CARD_WIDTH + 20;
    
    // Tarjetas de resumen general
    InfoCard semaforosCard = new InfoCard("Semáforos Verdes", "0", Theme.GREEN, 
                                         x + 20, cardY);
    summaryCards.add(semaforosCard);
    
    InfoCard infraccionesCard = new InfoCard("Infracciones", "0", Theme.ORANGE, 
                                           x + 20 + cardSpacing, cardY);
    summaryCards.add(infraccionesCard);
    
    InfoCard panicoCard = new InfoCard("Zonas Pánico", "0", Theme.RED, 
                                      x + 20 + cardSpacing * 2, cardY);
    summaryCards.add(panicoCard);
    
    InfoCard gasCard = new InfoCard("Gas Promedio", "0 ppm", Theme.PRIMARY_BLUE, 
                                   x + 20 + cardSpacing * 3, cardY);
    summaryCards.add(gasCard);
    
  // Mini card solo de sismo debajo de las tarjetas principales
  float miniY = cardY + Theme.CARD_HEIGHT + 30;
  sismoMiniCard = new InfoCard("Sismo", "Todo normal", Theme.ORANGE, x + 20, miniY);
  sismoMiniCard.setSize( (Theme.CARD_WIDTH*1.3), 80);

  // Fila de 4 botones de pánico independientes (más compactos)
  panicRowY = miniY + 95; // debajo de mini card sismo
  float panicCardWidth = (width - 40 - 3*18 - 40) / 4; // distribuir mejor (dejando margen lateral extra)
  for (int i = 0; i < 4; i++) {
    InfoCard pCard = new InfoCard("P" + (i+1), "Normal", Theme.GREEN, x + 20 + i * (panicCardWidth + 18), panicRowY);
    pCard.setSize(panicCardWidth, 80);
    panicButtonCards.add(pCard);
  }

  // Texto de estado del sistema (ajustado más abajo)
  statusText = new Text("Sistema Operativo", x + 20, panicRowY + 110, Theme.GREEN, Theme.LARGE_SIZE);
  }
  
  void renderContent() {
    // Shake visual si hay sismo activo
    boolean shaking = false;
    float dx = 0, dy = 0;
    try {
      JSONObject sismo = dataProvider.getSismoData();
      if (sismo.getInt("activo") == 1) {
        float mag = max(3, min(7, sismo.getFloat("magnitud")));
        float amp = map(mag, 3, 7, 1, 6);
        dx = random(-amp, amp);
        dy = random(-amp, amp);
        shaking = true;
      }
    } catch(Exception e) {}
    if (shaking) pushMatrix();
    if (shaking) translate(dx, dy);
    // Actualizar datos
    updateSummaryCards();
    
    // Renderizar tarjetas
    for (InfoCard card : summaryCards) {
      card.render();
    }
  // Actualizar y render mini cards
  updateMiniCards();
  sismoMiniCard.render();
    // Render panic buttons (estilo custom)
    updatePanicButtonsCards();
    renderPanicButtonsRow();
    
    // Estado del sistema
    renderSystemStatus();
    
    // Información de tiempo real
    renderRealTimeInfo();

  // Panel de alertas (sismos y botón de pánico)
  renderAlertsPanel();
    if (shaking) popMatrix();
  }

  // Manejo de clic (ya no hay acciones de envío; pantalla solo visual)
  void handleMousePressed(float mx, float my) { }
  
  void updateSummaryCards() {
    TrafficStats stats = dataProvider.getStats();
    
    summaryCards.get(0).updateValue(str(stats.semaforosVerdes));
    summaryCards.get(1).updateValue(str(stats.infracciones));
    summaryCards.get(2).updateValue(str(stats.zonasPanico));
    summaryCards.get(3).updateValue(stats.gasPromedio + " ppm");
  }
  
  void updateMiniCards() {
    // Sismo
    JSONObject sismo = dataProvider.getSismoData();
    boolean activo = sismo.getInt("activo") == 1;
    if (activo) {
      float mag = sismo.getFloat("magnitud");
      String origen = sismo.hasKey("origen") ? sismo.getString("origen") : "";
      sismoMiniCard.updateValue("M" + nf(mag,1,1) + " (" + origen + ")");
    } else {
      sismoMiniCard.updateValue("Todo normal");
    }
  // (Se elimina el mini card de pánico global)
  }

  // NUEVO: actualizar estado de los 4 botones
  void updatePanicButtonsCards() {
    JSONObject buttons = dataProvider.getPanicButtonsData();
    for (int i = 0; i < panicButtonCards.size(); i++) {
      InfoCard c = panicButtonCards.get(i);
      String id = "PB" + (i+1);
      if (buttons.hasKey(id)) {
        JSONObject btn = buttons.getJSONObject(id);
        int act = btn.getInt("activo");
        if (act == 1) {
          c.updateValue("Activado");
          c.cardColor = Theme.RED;
          c.valueText.setColor(Theme.RED);
        } else {
          c.updateValue("Normal");
          c.cardColor = Theme.GREEN;
          c.valueText.setColor(Theme.GREEN);
        }
      }
    }
  }

  // NUEVO: renderizado visual mejorado para los 4 botones de pánico
  void renderPanicButtonsRow() {
    textAlign(LEFT, TOP);
    for (int i = 0; i < panicButtonCards.size(); i++) {
      InfoCard c = panicButtonCards.get(i);
      float cx = c.x;
      float cy = c.y;
      float cw = c.width;
      float ch = c.height;
      boolean active = c.cardColor == Theme.RED;

      // Sombra
      drawSoftShadow(cx, cy, cw, ch, 2);

      // Fondo (gradiente simple simulado con dos capas)
      noStroke();
      if (active) {
        // Capa base roja oscura
        fill(230,60,60); rect(cx, cy, cw, ch, 14);
        // Capa superior translúcida para brillo
        fill(255,255,255,35); rect(cx, cy, cw, ch*0.55, 14,14,0,0);
      } else {
        fill(255); rect(cx, cy, cw, ch, 14);
        fill(0,0,0,10); rect(cx, cy, cw, ch*0.45, 14,14,0,0);
      }

      // Borde
      stroke(active ? color(255,90,90) : color(220));
      strokeWeight(active ? 2 : 1);
      noFill();
      rect(cx, cy, cw, ch, 14);
      noStroke();

      // Título (arriba)
      fill(active ? 255 : 60);
  textSize(11); // título más pequeño
  text(c.title, cx + 10, cy + 8);

      // Icono central
      float iconY = cy + ch/2 - 4;
      float iconX = cx + cw/2;
      if (active) {
        float pulse = 1 + (sin(millis()*0.025f)+1)*0.4f; // pulso más sutil
        fill(255,90,90,90); ellipse(iconX, iconY, 38*pulse, 38*pulse);
        fill(255); ellipse(iconX, iconY, 26,26);
        fill(230,60,60); textAlign(CENTER, CENTER); textSize(14); text("!", iconX, iconY+1);
      } else {
        fill(242); ellipse(iconX, iconY, 30,30);
        fill(100); textAlign(CENTER, CENTER); textSize(11); text("PB", iconX, iconY+1);
      }

      // Estado (abajo)
  textAlign(CENTER, TOP);
  textSize(active ? 13 : 11);
  fill(active ? 255 : 80);
  text(c.value, iconX, cy + ch - 26);
  // Sub-etiqueta
  textSize(9);
  fill(active ? 255 : 140);
  text(active ? "Botón" : "Disponible", iconX, cy + ch - 14);
    }
  }
  
  void renderSystemStatus() {
    TrafficStats stats = dataProvider.getStats();
    
    // Determinar estado del sistema
    String systemStatus = "Sistema Operativo";
    color statusColor = Theme.GREEN;
    
    if (stats.zonasPanico > 0 || stats.gasPromedio > 250) {
      systemStatus = "¡EMERGENCIA ACTIVA!";
      statusColor = Theme.RED;
    } else if (stats.infracciones > 3 || stats.gasPromedio > 200) {
      systemStatus = "Estado de Alerta";
      statusColor = Theme.ORANGE;
    }
    
    statusText.setContent(systemStatus);
    statusText.setColor(statusColor);
    statusText.render();
  }
  
  void renderRealTimeInfo() {
  // Panel de información en tiempo real (subido para no chocar con borde)
  float infoY = y + height - 110; // pequeño ajuste
    
    drawSoftShadow(x + 20, infoY, width - 40, 80, 2);
    fill(Theme.WHITE);
    noStroke();
    rect(x + 20, infoY, width - 40, 80, 5);
    
    fill(Theme.DARK_GRAY);
    textAlign(LEFT, TOP);
    textSize(Theme.NORMAL_SIZE);
    text("Estado Actual del Sistema", x + 35, infoY + 15);
    
    // Información detallada
    JSONObject currentData = dataProvider.getCurrentData();
    TrafficStats stats = dataProvider.getStats();
    
    fill(Theme.MEDIUM_GRAY);
    textSize(Theme.SMALL_SIZE);
    
    String infoLine1 = "Semáforos: " + stats.semaforosRojos + " rojos, " + 
                      stats.semaforosVerdes + " verdes, " + 
                      stats.semaforosAmarillos + " amarillos";
    text(infoLine1, x + 35, infoY + 40);
    
    String infoLine2 = "Monitoreo: " + stats.zonasPanico + " zonas pánico, " + 
                      stats.infracciones + " infracciones, " + 
                      "Gas: " + stats.gasPromedio + " ppm";
    text(infoLine2, x + 35, infoY + 55);
    
    // Timestamp
    fill(Theme.MEDIUM_GRAY);
    textAlign(RIGHT, TOP);
    text("Última actualización: " + currentData.getString("ts"), 
         x + width - 25, infoY + 40);
  }

  // --- Panel de Alertas ---
  void renderAlertsPanel() {
  // Posicionar fila de alertas: debajo de los botones de pánico con nuevo layout
  float baseY = panicRowY + 80 + 30; // altura botón (80) + margen
  // Evitar que se acerque demasiado al panel de info realtime
  float minGapBottom = 140; // espacio necesario para info realtime + margen
  float maxYForAlerts = y + height - minGapBottom;
  if (baseY > maxYForAlerts) baseY = maxYForAlerts;
  // Si el espacio es muy reducido, reducir altura de cada card
  JSONObject sismo = dataProvider.getSismoData();
  JSONObject panico = dataProvider.getPanicoData();

    boolean sismoActivo = sismo.getInt("activo") == 1;
    float magnitud = sismo.getFloat("magnitud");
  // (Se omite listado de zonas afectadas: la fila de botones ya lo representa)
  // Construir mensajes (cada uno será una card) solo sismo u otros futuros
    ArrayList<String> alerts = new ArrayList<String>();
  if (sismoActivo) alerts.add("SISMO M" + nf(magnitud,1,1));
    if (alerts.size() == 0) alerts.add("Sin alertas");
    // Si solo hay 'Sin alertas' no dibujar panel para limpiar el espacio
    if (alerts.size() == 1 && alerts.get(0).startsWith("Sin")) {
      return;
    }

    int cardCount = alerts.size();
    float totalWidth = width - 40;
    float gap = 15;
    float cardWidth = (totalWidth - gap * (cardCount - 1)) / cardCount;
    float cardHeight = 80;
    if (baseY + cardHeight > y + height - 120) {
      cardHeight = max(60, (y + height - 120) - baseY);
    }
    float startX = x + 20;

    textAlign(LEFT, TOP);
    textSize(12);

    for (int i = 0; i < cardCount; i++) {
      String msg = alerts.get(i);
      color baseColor = Theme.GREEN;
      if (msg.startsWith("SISMO")) baseColor = Theme.ORANGE;
  // (sin card de zonas)
      if (msg.startsWith("Sin")) baseColor = Theme.MEDIUM_GRAY;

      float cx = startX + i * (cardWidth + gap);
      // Sombra
      drawSoftShadow(cx, baseY, cardWidth, cardHeight, 2);
      // Card fondo
      fill(Theme.WHITE);
      noStroke();
  rect(cx, baseY, cardWidth, cardHeight, 6);
      // Banda superior
      fill(baseColor);
      rect(cx, baseY, cardWidth, 8, 6,6,0,0);
      // Contenido
      fill(baseColor);
      textSize(14);
  float contentTop = baseY + 14;
  text(msg, cx + 12, contentTop);

      // Detalle adicional si aplica
      fill(Theme.DARK_GRAY);
      textSize(11);
      float lineY = contentTop + 24;
      if (msg.startsWith("SISMO") && sismoActivo) {
        text("Magnitud estable", cx + 12, lineY);
      }
    }
  }
}

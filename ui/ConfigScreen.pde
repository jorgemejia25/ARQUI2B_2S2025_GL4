// Pantalla de configuración del sistema

class ConfigScreen extends Screen {
  private DataProvider dataProvider;
  private ArrayList<Button> configButtons;
  // Layout dinámico
  private float buttonsPanelY;
  private float buttonsPanelHeight;
  private float configPanelsY;
  // Botones identificados
  private Button toggleModeBtn;
  private Button resetBtn;
  private Button aboutBtn;
  
  ConfigScreen(float x, float y, float width, float height, DataProvider dataProvider) {
    super("Configuración del Sistema", x, y, width, height);
    this.dataProvider = dataProvider;
    
    initializeComponents();
  }
  
  void initializeComponents() {
  configButtons = new ArrayList<Button>();
  float buttonWidth = 240;
  float buttonHeight = 44;
  float buttonSpacing = 18;

  // Botón de toggle modo (label dinámico en render)
  toggleModeBtn = new Button("Modo: ", 0, 0, buttonWidth, buttonHeight, Theme.PRIMARY_BLUE, Theme.WHITE);
  resetBtn = new Button("Reiniciar Datos", 0, 0, buttonWidth, buttonHeight, Theme.ORANGE, Theme.WHITE);
  aboutBtn = new Button("Acerca del Sistema", 0, 0, buttonWidth, buttonHeight, Theme.MEDIUM_GRAY, Theme.WHITE);
  configButtons.add(toggleModeBtn);
  configButtons.add(resetBtn);
  configButtons.add(aboutBtn);

  // Calcular layout base
  buttonsPanelY = y + 80 + 260 + 25; // debajo panel info
  buttonsPanelHeight = 30 + 30 + (configButtons.size()) * buttonHeight + (configButtons.size() - 1) * buttonSpacing + 20;
  configPanelsY = buttonsPanelY + buttonsPanelHeight + 30;
  }
  
  void renderContent() {
    // Información del sistema
    renderSystemInfo();
  // Panel de botones organizado
  renderButtonsPanel();
    
  // Config y manual
  renderConfigInfo();
  renderUserManual();
  }
  
  void renderSystemInfo() {
    // Panel de información del sistema
    float infoY = y + 80;
    float panelWidth = width - 100;
  float panelHeight = 260;
    
    drawSoftShadow(x + 50, infoY, panelWidth, panelHeight, 2);
    fill(Theme.WHITE);
    noStroke();
    rect(x + 50, infoY, panelWidth, panelHeight, 5);
    
    // Línea de título
    fill(Theme.PRIMARY_BLUE);
    rect(x + 50, infoY, panelWidth, 30, 5);
    
    fill(Theme.WHITE);
    textAlign(LEFT, CENTER);
    textSize(Theme.NORMAL_SIZE);
    text("Información del Sistema", x + 65, infoY + 15);
    
    // Información detallada
    fill(Theme.DARK_GRAY);
    textAlign(LEFT, TOP);
    textSize(Theme.SMALL_SIZE);
    
    String[] infoLines = {
      "• Semáforos monitoreados: 10 unidades (S1-S10)",
      "• Paradas con sensores: 6 ubicaciones (P1-P6)", 
      "• Zonas de monitoreo de gas: 2 áreas (Z1-Z2)",
  "• Ciclo semáforo (rojo→verde): " + dataProvider.getSemaforoCycle() + " ms",
      "• Estado de comunicación: " + (dataProvider.isSimulationEnabled() ? "Simulación activa" : "Real/Serial"),
      "• Última reinicialización: " + getCurrentTime(),
      "• Versión del sistema: 1.0.0",
      "• Fuente datos: " + dataProvider.getLastSource(),
      "• Total updates: " + dataProvider.getUpdateCount()
    };
    
    for (int i = 0; i < infoLines.length; i++) {
      text(infoLines[i], x + 65, infoY + 45 + i * 20);
    }
    // Estado dentro del panel
    fill(Theme.RED);
    textSize(Theme.SMALL_SIZE);
    textAlign(LEFT, BOTTOM);
  text("Estado: OK", x + 65, infoY + panelHeight - 10);
  }
  
  void renderConfigInfo() {
    // Panel de configuraciones actuales
  float configY = configPanelsY;
    float panelWidth = (width - 120) / 2;
    
    drawSoftShadow(x + 50, configY, panelWidth, 180, 2);
    fill(Theme.WHITE);
    noStroke();
    rect(x + 50, configY, panelWidth, 180, 5);
    
  // Título en rojo
  fill(Theme.RED);
    textAlign(LEFT, TOP);
    textSize(Theme.NORMAL_SIZE);
    text("Configuraciones Activas", x + 65, configY + 20);
    
  // Contenido en rojo
  fill(Theme.RED);
    textSize(Theme.SMALL_SIZE);
    
    String[] configLines = {
      "Modo: " + (dataProvider.isSimulationEnabled()?"Simulación":"Serial"),
      "Auto-update: " + (dataProvider.isSimulationEnabled()?"Simulado":"Serial"),
      "Botones pánico: 4 activos",
      "Infracciones: Monitoreadas",
      "Incendios: MQ-02 activo",
      "Sismo: Sensor virtual"
    };
    
    for (int i = 0; i < configLines.length; i++) {
      text("• " + configLines[i], x + 65, configY + 50 + i * 18);
    }
  }
  
  void renderUserManual() {
    // Manual de uso rápido
    float manualX = x + 70 + (width - 120) / 2;
  float manualY = configPanelsY;
    float panelWidth = (width - 120) / 2;
    
    drawSoftShadow(manualX, manualY, panelWidth, 180, 2);
    fill(Theme.WHITE);
    noStroke();
    rect(manualX, manualY, panelWidth, 180, 5);
    
  // Título en rojo
  fill(Theme.RED);
    textAlign(LEFT, TOP);
    textSize(Theme.NORMAL_SIZE);
    text("Controles Rápidos", manualX + 15, manualY + 20);
    
  // Contenido en rojo
  fill(Theme.RED);
    textSize(Theme.SMALL_SIZE);
    
    String[] controlLines = {
      "R - Forzar refresh",
      "U - Tick simulado",
      "M - Modo (tecla)",
      "C - Estado consola",
      "H - Ayuda",
      "",
      "Pantallas:",
      "Dashboard / Incendios / Semáforos / Distancias"
    };
    
    for (int i = 0; i < controlLines.length; i++) {
      text(controlLines[i], manualX + 15, manualY + 50 + i * 15);
    }
  }

  // Panel organizado de botones de configuración
  void renderButtonsPanel() {
    float panelX = x + 50;
    float panelWidth = width - 100;
    drawSoftShadow(panelX, buttonsPanelY, panelWidth, buttonsPanelHeight, 2);
    fill(Theme.WHITE);
    noStroke();
  rect(panelX, buttonsPanelY, panelWidth, buttonsPanelHeight, 5);
    // Título
    fill(Theme.PRIMARY_BLUE);
    rect(panelX, buttonsPanelY, panelWidth, 30, 5,5,0,0);
    fill(Theme.WHITE);
    textAlign(LEFT, CENTER);
    textSize(Theme.NORMAL_SIZE);
    text("Acciones de Configuración", panelX + 15, buttonsPanelY + 15);
    // Layout interno
    float innerX = panelX + 30;
    float innerY = buttonsPanelY + 50;
    float buttonSpacingY = 18;
    for (int i = 0; i < configButtons.size(); i++) {
      Button b = configButtons.get(i);
      // Label dinámico para toggle
      if (b == toggleModeBtn) {
        b.setLabel("Cambiar a: " + (dataProvider.isSimulationEnabled()?"Serial":"Simulación"));
      }
      b.setSize(240, 44);
      float bx = innerX;
      float by = innerY + i * (b.h + buttonSpacingY);
      b.setPosition(bx, by);
      b.render();
    }
  }
  
  void handleMousePressed(float mx, float my) {
    for (Button b : configButtons) {
      if (mx >= b.x && mx <= b.x + b.w && my >= b.y && my <= b.y + b.h) {
        if (b == toggleModeBtn) {
          // Toggle simulación/serial
          if (dataProvider.isSimulationEnabled()) {
            // Intentar ir a serial real (si serial no está habilitado avisar via println)
            if (dataProvider.isSerialMode()) {
              dataProvider.setSimulationEnabled(false);
              println("[Config] Cambio a modo Serial Real.");
            } else {
              println("[Config] No hay puerto serial; permanece en simulación.");
            }
          } else {
            dataProvider.setSimulationEnabled(true);
            println("[Config] Cambio a modo Simulación.");
          }
        } else if (b == resetBtn) {
          dataProvider.forceUpdate();
          println("[Config] Datos simulados regenerados.");
        } else if (b == aboutBtn) {
          println("[Config] Sistema ARQUI2 - Demo v1.0");
        }
      }
    }
  }
}

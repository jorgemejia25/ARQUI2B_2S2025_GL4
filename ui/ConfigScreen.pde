// Pantalla de configuración del sistema

class ConfigScreen extends Screen {
  private DataProvider dataProvider;
  private ArrayList<Button> configButtons;
  private Text statusText;
  private Text infoText;
  
  ConfigScreen(float x, float y, float width, float height, DataProvider dataProvider) {
    super("Configuración del Sistema", x, y, width, height);
    this.dataProvider = dataProvider;
    
    initializeComponents();
  }
  
  void initializeComponents() {
    configButtons = new ArrayList<Button>();
    
    float buttonY = y + 100;
    float buttonWidth = 200;
    float buttonHeight = 40;
    float buttonSpacing = 20;
    
    // Botones de configuración
    Button intervalButton = new Button("Cambiar Intervalo", x + 50, buttonY, buttonWidth, buttonHeight);
    configButtons.add(intervalButton);
    
    Button resetButton = new Button("Reiniciar Datos", x + 50, buttonY + buttonHeight + buttonSpacing, 
                                   buttonWidth, buttonHeight, Theme.ORANGE, Theme.WHITE);
    configButtons.add(resetButton);
    
    Button exportButton = new Button("Exportar Configuración", x + 50, 
                                   buttonY + (buttonHeight + buttonSpacing) * 2, 
                                   buttonWidth, buttonHeight, Theme.PRIMARY_BLUE, Theme.WHITE);
    configButtons.add(exportButton);
    
    Button aboutButton = new Button("Acerca del Sistema", x + 50, 
                                  buttonY + (buttonHeight + buttonSpacing) * 3, 
                                  buttonWidth, buttonHeight, Theme.MEDIUM_GRAY, Theme.WHITE);
    configButtons.add(aboutButton);
    
    // Textos informativos
    statusText = new Text("Sistema funcionando correctamente", x + 300, buttonY + 50, 
                         Theme.GREEN, Theme.NORMAL_SIZE);
    
    infoText = new Text("", x + 50, y + 350, Theme.DARK_GRAY, Theme.SMALL_SIZE);
    infoText.setAlignment(LEFT, TOP);
  }
  
  void renderContent() {
    // Información del sistema
    renderSystemInfo();
    
    // Botones de configuración
    for (Button button : configButtons) {
      button.render();
    }
    
    // Estado del sistema
    statusText.render();
    
    // Información adicional
    renderConfigInfo();
    
    // Manual de usuario
    renderUserManual();
  }
  
  void renderSystemInfo() {
    // Panel de información del sistema
    float infoY = y + 80;
    float panelWidth = width - 100;
    float panelHeight = 200;
    
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
      "• Zonas de monitoreo de gas: 3 áreas (Z1-Z3)",
      "• Intervalo de actualización: 2000 ms",
      "• Estado de comunicación: Simulación activa",
      "• Última reinicialización: " + getCurrentTime(),
      "• Versión del sistema: 1.0.0"
    };
    
    for (int i = 0; i < infoLines.length; i++) {
      text(infoLines[i], x + 65, infoY + 45 + i * 20);
    }
  }
  
  void renderConfigInfo() {
    // Panel de configuraciones actuales
    float configY = y + 300;
    float panelWidth = (width - 120) / 2;
    
    drawSoftShadow(x + 50, configY, panelWidth, 180, 2);
    fill(Theme.WHITE);
    noStroke();
    rect(x + 50, configY, panelWidth, 180, 5);
    
    fill(Theme.DARK_GRAY);
    textAlign(LEFT, TOP);
    textSize(Theme.NORMAL_SIZE);
    text("Configuraciones Activas", x + 65, configY + 20);
    
    fill(Theme.MEDIUM_GRAY);
    textSize(Theme.SMALL_SIZE);
    
    String[] configLines = {
      "Modo: Simulación",
      "Auto-update: Activado",
      "Alertas de pánico: Activadas",
      "Detección de infracciones: Activa",
      "Log de eventos: Habilitado",
      "Nivel de debug: Normal"
    };
    
    for (int i = 0; i < configLines.length; i++) {
      text("• " + configLines[i], x + 65, configY + 50 + i * 18);
    }
  }
  
  void renderUserManual() {
    // Manual de uso rápido
    float manualX = x + 70 + (width - 120) / 2;
    float manualY = y + 300;
    float panelWidth = (width - 120) / 2;
    
    drawSoftShadow(manualX, manualY, panelWidth, 180, 2);
    fill(Theme.WHITE);
    noStroke();
    rect(manualX, manualY, panelWidth, 180, 5);
    
    fill(Theme.DARK_GRAY);
    textAlign(LEFT, TOP);
    textSize(Theme.NORMAL_SIZE);
    text("Controles Rápidos", manualX + 15, manualY + 20);
    
    fill(Theme.MEDIUM_GRAY);
    textSize(Theme.SMALL_SIZE);
    
    String[] controlLines = {
      "R - Actualizar datos",
      "U - Actualización manual",
      "C - Ver datos en consola",
      "Click - Navegar entre pantallas",
      "",
      "Navegación:",
      "• Dashboard: Vista general",
      "• Monitoreo Humo: Calidad aire",
      "• Tráfico: Estado semáforos"
    };
    
    for (int i = 0; i < controlLines.length; i++) {
      text(controlLines[i], manualX + 15, manualY + 50 + i * 15);
    }
  }
}

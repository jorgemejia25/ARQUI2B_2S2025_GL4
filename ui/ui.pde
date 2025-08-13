// Sistema Inteligente de Seguridad y Gestión de Tráfico Urbano
// Layout base modular - Arquitectura por componentes

// Componentes de layout
TopBar topBar;
SideBar sideBar;
MainContent mainContent;

// Sistema de datos y pantallas
DataProvider dataProvider;
ScreenManager screenManager;

// Overlay de bienvenida (nativo Processing)
boolean showWelcome = true;

void setup() {
  size(1200, 800);
  
  // Inicializar sistema de datos
  dataProvider = new DataProvider();
  
  // Crear componentes de layout
  createLayout();
  
  // Crear sistema de pantallas
  createScreenSystem();
}

void createScreenSystem() {
  screenManager = new ScreenManager();
  
  // Área para las pantallas (área de contenido principal)
  float screenX = Theme.SIDE_BAR_WIDTH;
  float screenY = Theme.TOP_BAR_HEIGHT;
  float screenWidth = width - Theme.SIDE_BAR_WIDTH;
  float screenHeight = height - Theme.TOP_BAR_HEIGHT;
    // Crear todas las pantallas
  DashboardScreen dashboardScreen = new DashboardScreen(screenX, screenY, screenWidth, screenHeight, dataProvider);
  SmokeMonitorScreen smokeScreen = new SmokeMonitorScreen(screenX, screenY, screenWidth, screenHeight, dataProvider);
  SemaforosScreen semaforosScreen = new SemaforosScreen(screenX, screenY, screenWidth, screenHeight, dataProvider);
  ConfigScreen configScreen = new ConfigScreen(screenX, screenY, screenWidth, screenHeight, dataProvider);
    // Agregar pantallas al gestor en el orden correcto (debe coincidir con ScreenManager)
  screenManager.addScreen(dashboardScreen);  // 0: Dashboard
  screenManager.addScreen(smokeScreen);      // 1: Monitoreo Humo  
  screenManager.addScreen(semaforosScreen);  // 2: Semáforos
  screenManager.addScreen(configScreen);     // 3: Tráfico (temporal)
  screenManager.addScreen(configScreen);     // 4: Configuración
  
  // Activar pantalla inicial (Dashboard)
  screenManager.setActiveScreen(0);
}

void createLayout() {
  // Barra superior
  topBar = new TopBar(0, 0, width, Theme.TOP_BAR_HEIGHT);
  
  // Barra lateral
  sideBar = new SideBar(0, Theme.TOP_BAR_HEIGHT, Theme.SIDE_BAR_WIDTH, height - Theme.TOP_BAR_HEIGHT);
  
  // Área de contenido principal (ahora manejada por ScreenManager)
  float contentX = Theme.SIDE_BAR_WIDTH;
  float contentY = Theme.TOP_BAR_HEIGHT;
  float contentWidth = width - Theme.SIDE_BAR_WIDTH;
  float contentHeight = height - Theme.TOP_BAR_HEIGHT;
  
  mainContent = new MainContent(contentX, contentY, contentWidth, contentHeight);
}

void draw() {
  background(Theme.LIGHT_GRAY);
  
  // Renderizar layout base
  topBar.render();
  sideBar.render();
  
  // Renderizar pantalla activa
  screenManager.renderActiveScreen();

  // Overlay de bienvenida
  if (showWelcome) {
    // Sombreado de fondo
    noStroke();
    fill(0, 160);
    rect(0, 0, width, height);

    // Ventana emergente centrada
    float boxW = 420;
    float boxH = 160;
    float boxX = (width - boxW) / 2;
    float boxY = (height - boxH) / 2;
    fill(255);
    stroke(Theme.BORDER_COLOR);
    rect(boxX, boxY, boxW, boxH, 10);

    // Texto
    fill(Theme.TEXT_COLOR);
    textAlign(CENTER, CENTER);
    textSize(Theme.TITLE_SIZE - 6);
    text("Hola, bienvenido", boxX + boxW/2, boxY + boxH/2 - 15);
    textSize(Theme.SMALL_SIZE);
    fill(Theme.DARK_GRAY);
    text("Haz clic para continuar", boxX + boxW/2, boxY + boxH/2 + 25);
  }
}

void mousePressed() {
  // Si el overlay está activo, lo cerramos y no propagamos el clic
  if (showWelcome) {
    showWelcome = false;
    return;
  }

  // Manejar eventos de clic en sidebar para navegación
  sideBar.handleClick(mouseX, mouseY);
  
  // Manejar clicks en scrollbar si estamos en pantalla de semáforos
  Screen currentScreen = screenManager.getActiveScreen();
  if (currentScreen instanceof SemaforosScreen) {
    SemaforosScreen semaforosScreen = (SemaforosScreen) currentScreen;
    semaforosScreen.handleMousePressed(mouseX, mouseY);
  }
  
  // Cambiar pantalla según selección del sidebar
  int selectedIndex = sideBar.getSelected();
  if (selectedIndex != screenManager.getCurrentScreenIndex()) {
    screenManager.setActiveScreen(selectedIndex);
  }
}

void keyPressed() {
  // Controles de debug y funcionalidades
  if (key == 'r' || key == 'R') {
    println("Layout reset");
    dataProvider.forceUpdate();
  }
  
  if (key == 'u' || key == 'U') {
    // Actualización manual de datos
    dataProvider.forceUpdate();
    println("Datos actualizados manualmente");
  }
  
  if (key == 'c' || key == 'C') {
    // Mostrar información del sistema
    println("\n=== ESTADO DEL SISTEMA ===");
    println("Pantalla activa: " + screenManager.getCurrentScreenName());
    println("Índice de pantalla: " + screenManager.getCurrentScreenIndex());
    println("Total de pantallas: " + screenManager.getScreenCount());
    println("========================\n");
  }
  
  // Navegación rápida con teclas numéricas
  if (key >= '1' && key <= '4') {
    int screenIndex = key - '1';
    screenManager.setActiveScreen(screenIndex);
  }
}

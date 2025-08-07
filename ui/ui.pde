// Sistema Inteligente de Seguridad y Gestión de Tráfico Urbano
// Layout base modular - Arquitectura por componentes

// Componentes de layout
TopBar topBar;
SideBar sideBar;
MainContent mainContent;

// Sistema de datos y pantallas
DataProvider dataProvider;
ScreenManager screenManager;

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
  
  ConfigScreen configScreen = new ConfigScreen(screenX, screenY, screenWidth, screenHeight, dataProvider);
  
  // Agregar pantallas al gestor en el orden correcto
  screenManager.addScreen(dashboardScreen);  // 0: Dashboard
  screenManager.addScreen(smokeScreen);      // 1: Monitoreo Humo
  screenManager.addScreen(configScreen);     // Configuración
  
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
}

void mousePressed() {
  // Manejar eventos de clic en sidebar para navegación
  sideBar.handleClick(mouseX, mouseY);
  
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

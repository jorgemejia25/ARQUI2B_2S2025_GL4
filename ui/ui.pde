// Sistema Inteligente de Seguridad y Gestión de Tráfico Urbano
// Layout base modular - Arquitectura por componentes
import processing.serial.*;

// Componentes de layout
TopBar topBar;
SideBar sideBar;
MainContent mainContent;

// Sistema de datos y pantallas
DataProvider dataProvider;
ScreenManager screenManager;

// Overlay de bienvenida (nativo Processing)
boolean showWelcome = true;

// Serial
Serial serialPort;
int serialBaud = 115200;
boolean serialConnected = false;

void setup() {
  size(1200, 800);
  
  // Inicializar sistema de datos
  dataProvider = new DataProvider();
  initSerial();
  
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
  IncendiosScreen incendiosScreen = new IncendiosScreen(screenX, screenY, screenWidth, screenHeight, dataProvider);
  SemaforosScreen semaforosScreen = new SemaforosScreen(screenX, screenY, screenWidth, screenHeight, dataProvider);
  DistanceScreen distanceScreen = new DistanceScreen(screenX, screenY, screenWidth, screenHeight, dataProvider);
  ConfigScreen configScreen = new ConfigScreen(screenX, screenY, screenWidth, screenHeight, dataProvider);

    // Agregar pantallas al gestor en el orden correcto (debe coincidir con ScreenManager)
  screenManager.addScreen(dashboardScreen);  // 0: Dashboard
  screenManager.addScreen(incendiosScreen);  // 1: Incendios  
  screenManager.addScreen(semaforosScreen);  // 2: Semáforos
  screenManager.addScreen(distanceScreen);   // 3: Distancias
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
  readSerial();
  
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
  if (currentScreen instanceof DashboardScreen) {
    DashboardScreen ds = (DashboardScreen) currentScreen;
    ds.handleMousePressed(mouseX, mouseY);
  }
  if (currentScreen instanceof ConfigScreen) {
    ((ConfigScreen)currentScreen).handleMousePressed(mouseX, mouseY);
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
  
  // NUEVO: Intercambiar entre datos simulados y reales
  if (key == 'm' || key == 'M') {
    dataProvider.toggleDataMode();
    println("Modo cambiado a: " + dataProvider.getCurrentMode());
  }
  
  // NUEVO: Forzar simulación ON/OFF
  if (key == 's' || key == 'S') {
    dataProvider.setSimulationEnabled(!dataProvider.isSimulationEnabled());
    println("Simulación: " + (dataProvider.isSimulationEnabled() ? "ACTIVADA" : "DESACTIVADA"));
  }
  
  // NUEVO: Reset timeout de serial (intentar reconectar)
  if (key == 't' || key == 'T') {
    dataProvider.forceSerialReconnection();
    println("Timeout de serial reseteado");
  }
  
  if (key == 'c' || key == 'C') {
    // Mostrar información detallada del sistema
    println("\n=== ESTADO DEL SISTEMA ===");
    println("Pantalla activa: " + screenManager.getCurrentScreenName());
    println("Índice de pantalla: " + screenManager.getCurrentScreenIndex());
    println("Total de pantallas: " + screenManager.getScreenCount());
    println("Serial conectado: " + serialConnected);
    println("========================\n");
    
    // NUEVO: Estado detallado del DataProvider
    println(dataProvider.getDetailedStatus());
    println("");
  }
  
  // NUEVO: Ayuda de controles
  if (key == 'h' || key == 'H') {
    println("\n=== CONTROLES DISPONIBLES ===");
    println("R - Reset y actualización forzada");
    println("U - Actualizar datos simulados");
    println("M - Intercambiar modo (Simulado ↔ Real)");
    println("S - Activar/Desactivar simulación");
    println("T - Reset timeout serial");
    println("C - Mostrar estado del sistema");
    println("H - Mostrar esta ayuda");
  println("1-5 - Cambiar pantalla directamente");
    println("==============================\n");
  }
  
  // Navegación rápida con teclas numéricas
  if (key >= '1' && key <= '5') {
    int screenIndex = key - '1';
    screenManager.setActiveScreen(screenIndex);
  }
  // (Entrada de intervalo eliminada)
}

// --- Serial ---
void initSerial() {
  try {
    String[] ports = Serial.list();
    if (ports == null || ports.length == 0) {
      println("[Serial] No se encontraron puertos. Modo simulado activo.");
      dataProvider.setSerialMode(false);
      return;
    }

    // Heurística: priorizar puertos típicos de Arduino en macOS y Linux
    String chosen = null;
    for (String p : ports) {
      String lp = p.toLowerCase();
      if (lp.contains("usbmodem") || lp.contains("usbserial") || lp.contains("ttyacm") || lp.contains("ttyusb")) {
        chosen = p;
        break;
      }
    }
    if (chosen == null) {
      // Si no encontramos coincidencia, elegimos el último puerto disponible
      chosen = ports[ports.length - 1];
    }

    println("[Serial] Abriendo puerto: " + chosen + " @ " + serialBaud + " baudios");
    serialPort = new Serial(this, chosen, serialBaud);
    serialPort.clear();
    serialConnected = true;
    dataProvider.setSerialMode(true);
  } catch (Exception ex) {
    println("[Serial] Error al inicializar: " + ex.getMessage());
    serialConnected = false;
    dataProvider.setSerialMode(false);
  }
}

void readSerial() {
  if (!serialConnected || serialPort == null) return;
  try {
    while (serialPort.available() > 0) {
      String line = serialPort.readStringUntil('\n');
      if (line == null) break;
      line = line.trim();
      if (line.length() == 0) continue;
      // Solo procesar JSON (evitar logs que no son JSON)
      if (!line.startsWith("{")) {
        continue;
      }
      JSONObject json = parseJSONObject(line);
      if (json != null) {
        dataProvider.setExternalData(json);
        println("[Serial] JSON aplicado. ts=" + dataProvider.getLastTimestamp() + ", updates=" + dataProvider.getUpdateCount());
      }
    }
  } catch (Exception ex) {
    println("[Serial] Error de lectura: " + ex.getMessage());
  }
}

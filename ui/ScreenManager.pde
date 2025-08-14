// Gestor de pantallas para navegación entre diferentes vistas

class ScreenManager {
  private ArrayList<Screen> screens;
  private int currentScreenIndex = 0;
  private String[] screenNames = {"Dashboard", "Monitoreo Humo", "Tráfico", "Pánico", "Configuración"};
  
  ScreenManager() {
    screens = new ArrayList<Screen>();
  }
  
  void addScreen(Screen screen) {
    screens.add(screen);
  }
  
  void setActiveScreen(int index) {
    if (index >= 0 && index < screens.size()) {
      // Desactivar pantalla actual
      if (currentScreenIndex >= 0 && currentScreenIndex < screens.size()) {
        screens.get(currentScreenIndex).setActive(false);
      }
      
      // Activar nueva pantalla
      currentScreenIndex = index;
      screens.get(currentScreenIndex).setActive(true);
      
      println("Pantalla cambiada a: " + screenNames[index]);
    }
  }
  
  void setActiveScreen(String screenName) {
    for (int i = 0; i < screenNames.length; i++) {
      if (screenNames[i].equals(screenName)) {
        setActiveScreen(i);
        break;
      }
    }
  }
  
  void renderActiveScreen() {
    if (currentScreenIndex >= 0 && currentScreenIndex < screens.size()) {
      screens.get(currentScreenIndex).render();
    }
  }
  
  
  Screen getActiveScreen() {
    if (currentScreenIndex >= 0 && currentScreenIndex < screens.size()) {
      return screens.get(currentScreenIndex);
    }
    return null;
  }
  
  int getCurrentScreenIndex() {
    return currentScreenIndex;
  }
  
  String getCurrentScreenName() {
    if (currentScreenIndex >= 0 && currentScreenIndex < screenNames.length) {
      return screenNames[currentScreenIndex];
    }
    return "";
  }
  
  String[] getScreenNames() {
    return screenNames;
  }
  
  int getScreenCount() {
    return screens.size();
  }
}
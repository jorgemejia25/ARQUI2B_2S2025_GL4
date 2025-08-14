// Barra lateral de navegación

class SideBar {
  private float x, y, width, height;
  private ArrayList<MenuItem> menuItems;
  private int selectedIndex = 0;
  
  SideBar(float x, float y, float width, float height) {
    this.x = x;
    this.y = y;
    this.width = width;
    this.height = height;
    
    // Inicializar elementos del menú
    initializeMenu();
  }
  
  private void initializeMenu() {
    menuItems = new ArrayList<MenuItem>();
    
    // Opciones del menú principal correspondientes a las pantallas
    String[] menuLabels = {
      "Dashboard", 
      "Monitoreo Humo", 
<<<<<<< Updated upstream

=======
      "Distancias",
      "Pánico",
>>>>>>> Stashed changes
      "Configuración"

    };
    
    float itemHeight = 50;
    float startY = y + Theme.MARGIN;
    
    for (int i = 0; i < menuLabels.length; i++) {
      float itemY = startY + i * (itemHeight + 5);
      MenuItem item = new MenuItem(menuLabels[i], 
                                 x + 10, 
                                 itemY, 
                                 width - 20, 
                                 itemHeight,
                                 i == selectedIndex);
      menuItems.add(item);
    }
  }
  
  void render() {
    // Fondo de la barra lateral
    fill(Theme.WHITE);
    noStroke();
    rect(x, y, width, height);
    
    // Sombra derecha
    drawVerticalShadow(x + width, y, height, 3);
    
    // Renderizar elementos del menú
    for (MenuItem item : menuItems) {
      item.render();
    }
    
    // Línea divisoria derecha
    stroke(Theme.MEDIUM_GRAY);
    strokeWeight(1);
    line(x + width - 1, y, x + width - 1, y + height);
    noStroke();
  }
  
  void handleClick(float mouseX, float mouseY) {
    // Verificar si el clic está dentro de la barra lateral
    if (mouseX >= x && mouseX <= x + width && 
        mouseY >= y && mouseY <= y + height) {
      
      // Verificar qué elemento fue clickeado
      for (int i = 0; i < menuItems.size(); i++) {
        MenuItem item = menuItems.get(i);
        if (item.isClicked(mouseX, mouseY)) {
          // Actualizar selección
          setSelected(i);
          break;
        }
      }
    }
  }
  
  void setSelected(int index) {
    if (index >= 0 && index < menuItems.size()) {
      // Desactivar elemento anterior
      menuItems.get(selectedIndex).setSelected(false);
      
      // Activar nuevo elemento
      selectedIndex = index;
      menuItems.get(selectedIndex).setSelected(true);
      
      println("Menu item selected: " + index);
    }
  }
  
  int getSelected() {
    return selectedIndex;
  }
}
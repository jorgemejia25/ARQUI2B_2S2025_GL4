// Área principal de contenido - Layout flexible

class MainContent {
  private float x, y, width, height;
  private ArrayList<Component> components;
  
  MainContent(float x, float y, float width, float height) {
    this.x = x;
    this.y = y;
    this.width = width;
    this.height = height;
    
    // Inicializar lista de componentes
    components = new ArrayList<Component>();
    
    // Agregar algunos componentes de ejemplo (vacíos por ahora)
    initializeExampleComponents();
  }
  
  private void initializeExampleComponents() {
    // Área de contenido con padding
    float contentX = x + Theme.MARGIN;
    float contentY = y + Theme.MARGIN;
    float contentWidth = width - Theme.MARGIN * 2;
    float contentHeight = height - Theme.MARGIN * 2;
    
    // Ejemplo: área para un dashboard futuro
    ContentArea dashboardArea = new ContentArea(
      "Dashboard Principal", 
      contentX, 
      contentY, 
      contentWidth, 
      200
    );
    components.add(dashboardArea);
    
    // Ejemplo: área para gráficos
    ContentArea chartsArea = new ContentArea(
      "Gráficos y Análisis", 
      contentX, 
      contentY + 220, 
      contentWidth, 
      180
    );
    components.add(chartsArea);
    
    // Ejemplo: área para tabla de datos
    ContentArea dataArea = new ContentArea(
      "Datos en Tiempo Real", 
      contentX, 
      contentY + 420, 
      contentWidth, 
      150
    );
    components.add(dataArea);
  }
  
  void render() {
    // Fondo del área principal
    fill(Theme.LIGHT_GRAY);
    noStroke();
    rect(x, y, width, height);
    
    // Renderizar todos los componentes
    for (Component component : components) {
      component.render();
    }
  }
  
  void handleClick(float mouseX, float mouseY) {
    // Verificar si el clic está dentro del área principal
    if (mouseX >= x && mouseX <= x + width && 
        mouseY >= y && mouseY <= y + height) {
      
      // Propagar evento a componentes hijos
      for (Component component : components) {
        if (component instanceof Clickable) {
          ((Clickable) component).handleClick(mouseX, mouseY);
        }
      }
    }
  }
  
  // Métodos para gestionar componentes dinámicamente
  void addComponent(Component component) {
    components.add(component);
  }
  
  void removeComponent(Component component) {
    components.remove(component);
  }
  
  void clearComponents() {
    components.clear();
  }
  
  ArrayList<Component> getComponents() {
    return components;
  }
}

// Interfaces para arquitectura modular

// Interfaz base para todos los componentes
interface Component {
  void render();
}

// Interfaz para componentes que pueden ser clickeados
interface Clickable {
  void handleClick(float mouseX, float mouseY);
  boolean isClicked(float mouseX, float mouseY);
}

// Interfaz para componentes que se pueden actualizar
interface Updatable {
  void update();
  void setData(Object data);
}

// Interfaz para componentes con estado
interface Stateful {
  void setState(String state);
  String getState();
}

// Interfaz para componentes que pueden ser redimensionados
interface Resizable {
  void resize(float width, float height);
  float getWidth();
  float getHeight();
}

// Interfaz para componentes posicionables
interface Positionable {
  void setPosition(float x, float y);
  float getX();
  float getY();
}

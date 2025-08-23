// Utilidades para dibujar elementos con sombras y efectos

// Dibujar sombra suave
void drawSoftShadow(float x, float y, float w, float h, int depth) {
  for(int i = depth; i >= 0; i--) {
    fill(0, 0, 0, 15 - i * 3);
    rect(x + i, y + i, w, h);
  }
}

// Dibujar sombra horizontal (para barras)
void drawHorizontalShadow(float x, float y, float w, int depth) {
  for(int i = 0; i < depth; i++) {
    fill(0, 0, 0, 15 - i * 5);
    rect(x, y + i, w, 1);
  }
}

// Dibujar sombra vertical (para barras laterales)
void drawVerticalShadow(float x, float y, float h, int depth) {
  for(int i = 0; i < depth; i++) {
    fill(0, 0, 0, 10 - i * 3);
    rect(x + i, y, 1, h);
  }
}

// Formatear tiempo con ceros a la izquierda
String formatTime(int value) {
  return nf(value, 2);
}

// Obtener tiempo actual formateado
String getCurrentTime() {
  return hour() + ":" + formatTime(minute()) + ":" + formatTime(second());
}

// Formatear números grandes
String formatNumber(int number) {
  if (number >= 1000) {
    return nf((float)number / 1000, 1, 1) + "K";
  }
  return str(number);
}

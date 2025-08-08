int contador = 1;
String data = "Fáima Cerezo - 202300434";

void setup() {
  size(500, 400);
  frameRate(1);   
}

void draw() {
  background(255); 

  
  if (contador <= 25) {
    fill(171, 237, 133); 
  } else {
    fill(237, 148, 133); 
  }

  
  float tamano = map(contador, 1, 50, 20, 200); 

  
  ellipse(width/2, height/2, tamano, tamano);

  fill(0); 
  textSize(32);
  textAlign(CENTER, CENTER);
  text(contador, width / 2, height - 50);
  
  fill(0);
  textSize(16);
  textAlign(CENTER, CENTER);
  text(data, width / 2, height - 20);

  contador++;

  if (contador > 50) {
    contador = 1;
  }
}
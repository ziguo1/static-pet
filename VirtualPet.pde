// I don't want to talk about this code and the cat

void setup() {
  size(512, 512);
  smooth();
}

void draw() {

  color furColor = color(243, 145, 80);
  color furColorBorder = color(185, 103, 48);

  // body
  fill(furColor);
  stroke(furColorBorder);
  
  drawLegs(256, 256);
  drawTail(256, 256);
  
  ellipse(256, 256, 256, 128);
  
  circle(384, 192, 128);

  fill(color(0));
  stroke(color(0));
  circle(384, 192, 4);
  drawEyes(384, 192);
  drawEars(384, 192);

  noFill();
  strokeWeight(4);
  int mouthRadius = 80;
  arc(384, 192, mouthRadius, mouthRadius, radians(10), radians(170));
}

void drawEyes(float centerX, float centerY) {
  circle(centerX - 20, centerY - 16, 8);
  circle(centerX + 20, centerY - 16, 8);
}

void drawEars(float centerX, float centerY) {
  float yLevel = centerY - 55f;
  float angle = radians(40);
  
  color furColor = color(227, 172, 176);
  color furColorBorder = color(185, 103, 48);

  fill(furColor);
  stroke(furColorBorder);
  
  {
     float xMed = centerX - 50;
     pushMatrix();
     translate(xMed, yLevel);
     rotate(-angle);
     triangle(0, -10, -10, 10, 10, 10);
     popMatrix();
  }
  
  {
     float xMed = centerX + 50;
     pushMatrix();
     translate(xMed, yLevel);
     rotate(angle);
     triangle(0, -10, -10, 10, 10, 10);
     popMatrix();
  }
}

void drawLegs(int centerX, int centerY) {
  color furColor = color(243, 145, 80);
  color furColorBorder = color(185, 103, 48);

  fill(furColor);
  stroke(furColorBorder);
  
  int yOffset = 20;
  
  rect(centerX - 110, centerY + yOffset - 20, 20, 120);
  rect(centerX - 80, centerY + yOffset, 25, 130);
  
  rect(centerX + 100, centerY + yOffset - 20, 20, 120);
  rect(centerX + 65, centerY + yOffset, 25, 130);
}


void drawTail(int centerX, int centerY) {
  float angle = radians(120);
  
  color furColor = color(243, 145, 80);
  color furColorBorder = color(185, 103, 48);

  
  fill(furColor);
  stroke(furColorBorder);
  
  pushMatrix();
  translate(centerX - 60, centerY - 20);
  rotate(angle);
  rect(0, 0, 25, 120);
  popMatrix();
}



// comment this block out if you want this to run in the desktop  

String pleaseDoNotTypeThisCharacterSequenceInTheBrowserTrust = "whatlol";
const sequence = pleaseDoNotTypeThisCharacterSequenceInTheBrowserTrust, link = "aHR0cHM6Ly93d3cueW91dHViZS5jb20vd2F0Y2g/dj1mX1d1UmZ1TVhRdw==" ;
let pressedChars = "";

addEventListener("keypress", function(key) {
  pressedChars += key.key;
  if (pressedChars.length > sequence.length) {
    pressedChars = pressedChars.slice(-sequence.length);
  }
  if (pressedChars === sequence) {
    window.open(atob(link), "_blank");
    pressedChars = ""; // Reset the pressed characters
  }
});

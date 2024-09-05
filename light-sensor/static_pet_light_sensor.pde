import processing.serial.*;
import cc.arduino.*;
Arduino arduino;

ArrayList<String> fetchArduinoTTYs() {
  var ret = new ArrayList<String>(); // yes this is legal java 9 code
  for (String file : Arduino.list()) {
    if (file.contains("COM") || file.contains("LPT") || file.contains("/dev/tty")) {
      if (!file.toLowerCase().contains("bluetooth") && !file.toLowerCase().contains("debug")) {
        ret.add(file);
      }
    }
  }
  return ret;
}

void setup() {
   String dev;
   {
      var ttys = fetchArduinoTTYs();
      if (ttys.size() < 1) {
        System.err.println("Could not find a suitable Arduino device. Exiting.");
        System.exit(1);
      }
      dev = ttys.get(0);
   }
  arduino = new Arduino(this, dev, 57600);
  
  size(512, 512);
  smooth();
}

void draw() {

  color furColor;
  color furColorBorder;
  int brightness = Math.max(Math.round(arduino.analogRead(5)) / 2, 30);
  
  {
    furColor = color(243, 145, 80);
    furColorBorder = color(185, 103, 48);
    background(75 + brightness, 112 + brightness, 121 + brightness);
  }

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
  drawEyes(384, 192, brightness);
  drawEars(384, 192, brightness);

  noFill();
  strokeWeight(4);
  int mouthRadius = 80;
  arc(384, 192, mouthRadius, mouthRadius, radians(10), radians(170));
}

void drawEyes(float centerX, float centerY, int colorLevel) {
  System.out.println(colorLevel);
  pushMatrix();
  if (colorLevel < 50) {
    noFill();
    arc(centerX - 20, centerY - 16, 8, 8, radians(200), radians(340));
    arc(centerX + 20, centerY - 16, 8, 8, radians(200), radians(340));
  } else {
    circle(centerX - 20, centerY - 16, 8);
    circle(centerX + 20, centerY - 16, 8);
  }
  popMatrix();
}

void drawEars(float centerX, float centerY, int colorLevel) {
  float yLevel = centerY - 55f;
  float angle = radians(40);
  pushMatrix();
  
  color furColor = color(245, 146, 177);
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
  popMatrix();
}

void drawLegs(int centerX, int centerY) {
  //color furColor = color(243, 145, 80);
  //color furColorBorder = color(185, 103, 48);

  //fill(furColor);
  //stroke(furColorBorder);
  
  int yOffset = 20;
  
  rect(centerX - 110, centerY + yOffset - 20, 20, 120);
  rect(centerX - 80, centerY + yOffset, 25, 130);
  
  rect(centerX + 100, centerY + yOffset - 20, 20, 120);
  rect(centerX + 65, centerY + yOffset, 25, 130);
}


void drawTail(int centerX, int centerY) {
  float angle = radians(120);
  
  //color furColor = color(243, 145, 80);
  //color furColorBorder = color(185, 103, 48);

  
  //fill(furColor);
  //stroke(furColorBorder);
  
  pushMatrix();
  translate(centerX - 60, centerY - 20);
  rotate(angle);
  rect(0, 0, 25, 120);
  popMatrix();
}

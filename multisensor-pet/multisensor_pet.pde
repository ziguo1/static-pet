import processing.serial.*;
import cc.arduino.*;
import java.lang.reflect.*;

Arduino arduino;
AdafruitPlayground np;

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
  np = new AdafruitPlayground(arduino);
  np.setPixelBrightness(10);

  size(512, 512);
  smooth();
}

void draw() {

  color furColor;
  color furColorBorder;
  int brightness = Math.max(Math.round(arduino.analogRead(5)) / 2, 30);
  boolean comfortable = isComfortable();
  boolean shouldSpeak = arduino.analogRead(1) > 100 || arduino.analogRead(6) > 100;
  

  {
    final int MOODY_BRIGHTNESS_MOD = -100;
    if (!comfortable) brightness += MOODY_BRIGHTNESS_MOD;

    furColor = color(243, 145, 80);
    furColorBorder = color(185, 103, 48);
    background(75 + brightness, 112 + brightness, 121 + brightness);
    
    if (shouldSpeak) {
      np.setPixelColor(0, color(255, 0, 0));
      np.setPixelColor(9, color(255, 0, 0));
      np.playTone((int) (Math.random() * 2000) + 2000);
    } else {
      np.setPixelColor(0, color(0, 0, 0));
      np.setPixelColor(9, color(0, 0, 0));
      np.stopTone();
    }
    
    for (int i = 2; i < 8; i++) {
      np.setPixelColor(i, color(75 + (brightness * 2), 112 + (brightness * 2), 121 + (brightness * 2)));
    }
     np.updatePixels();
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

  if (shouldSpeak) {
    fill(furColorBorder);
    circle(384, 220, 16);
  } else {
    if (comfortable) arc(384, 192, mouthRadius, mouthRadius, radians(10), radians(170));
    else arc(384, 250, mouthRadius, mouthRadius, radians(210), radians(330));
  }
}

// this class is (probably) not thread-safe
// some bad things will happen when you use this in a thread/concurrent environment
public static class AdafruitPlayground {
    private Serial serial;

    public static Serial getSerialFromArduino(Arduino a) {
        try {
            Field sf = a.getClass().getDeclaredField("serial");
            sf.setAccessible(true);
            Serial serial = (Serial) sf.get(a);
            return serial;
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }

    public AdafruitPlayground(Serial serial) {
        this.serial = serial;
        setPixelBrightness(100); // NeoPixels are at 20% brightness by default
    }
    
    public AdafruitPlayground(Arduino arduino) {
      this.serial = AdafruitPlayground.getSerialFromArduino(arduino);
      setPixelBrightness(100);
    }

    private static final byte CP_COMMAND = 0x40;

    // This method sends an SysEx Adafruit Playground unique
    // command message -- only use this if you know what you're doing!
    public void writeCommand(byte[] message) {
        // Begin SysEx message
        serial.write(0xF0);
        serial.write(CP_COMMAND);
        serial.write(message);
        serial.write(0xF7);
    }
    
    // ==== BUZZER ====
    
    // frequency = tone in hertz/hz (0-16383); duration = time in ms
    // quick note: to convert from seconds to ms, multiply your time in
    //    seconds by 1,000
    public void playTone(int frequency, int duration) {
      if (frequency < 0 || frequency > 16383) throw new IllegalArgumentException("Bad frequency range!");
      else if (duration < 0 || duration > 16383) throw new IllegalArgumentException("Bad duration range!");
      
      // I'd love to use shorts but Processing hates me
      int freq = frequency & 0x3FFF, dur = duration & 0x3FF;
      
      byte upperFreq = (byte) ((freq >> 7) & 0x7F), lowerFreq = (byte) (freq & 0x7F),
        upperDur = (byte) ((dur >> 7) & 0x7F), lowerDur = (byte) (dur & 0x7F); 
        
      writeCommand(new byte[] { 0x20, lowerFreq, upperFreq, lowerDur, upperDur });
    }
    
    // this will play the tone indefinitely until stopped by stopTone()
    public void playTone(int frequency) {
      playTone(frequency, 0);
    }
    
    
    // Stops the current tone being played on the Circuit Playground.
    public void stopTone() {
      writeCommand(new byte[] { 0x21 });
    }
    
    // ==== NEOPIXELS ====
    
    // You have to call this function every time you want your LED changes
    // to actually show up on the Circuit Playground.
    public void updatePixels() {
        writeCommand(new byte[] { 0x11 }); // CP_PIXEL_SHOW command
    }

    public void clearPixels() {
        writeCommand(new byte[] { 0x12 }); // CP_PIXEL_CLEAR command
    }

    public void setPixelBrightness(int brightness) {
        brightness = Math.min(brightness, 100);
        writeCommand(new byte[] { 0x13, (byte) brightness }); // CP_PIXEL_BRIGHTNESS command
    }
     
     // A note on the pixels: the pixel ID passed must be between 0-9, where
     // 0 is the first NeoPixel to the left of the microUSB port, and 9 is the first
     // NeoPixel to the right of the microUSB port.
    public void setPixelColor(int pixelId, int clr) {
        if (pixelId < 0 || pixelId > 9) {
            throw new IllegalArgumentException("pixelId must be between 0-9");
        }

        int r = (clr >> 16) & 0xFF;
        int g = (clr >> 8) & 0xFF;
        int b = clr & 0xFF;

        // Encode color into 7-bit bytes
        byte b1 = (byte) (pixelId & 0x7F);
        byte b2 = (byte) ((r >> 1) & 0x7F);
        byte b3 = (byte) (((r & 0x01) << 6) | ((g >> 2) & 0x3F));
        byte b4 = (byte) (((g & 0x03) << 5) | ((b >> 3) & 0x1F));
        byte b5 = (byte) ((b & 0x07) << 4);

        writeCommand(new byte[] { 0x10, b1, b2, b3, b4, b5 }); // CP_PIXEL_SET command
    }
}


void drawEyes(float centerX, float centerY, int colorLevel) {
  pushMatrix();
  strokeWeight(5);
  if (colorLevel < 50) {
    noFill();
    arc(centerX - 20, centerY - 16, 8, 8, radians(10), radians(170));
    arc(centerX + 20, centerY - 16, 8, 8, radians(10), radians(170));
  } else {
    circle(centerX - 20, centerY - 16, 8);
    circle(centerX + 20, centerY - 16, 8);
  }
  popMatrix();
}

boolean isComfortable() {
  int volume = arduino.analogRead(4);
  int temp = arduino.analogRead(0);

  if (volume > 380 || temp > 600) return false;
  else return true;
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

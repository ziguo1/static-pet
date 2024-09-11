# Static Pet: Multisensor Pet
*...well, not really static anymore*

This revision adds on to the light sensor assignment, adding in the ability for the cat to "talk" by pressing the buttons of the Adafruit Circuit Playground.
## Features
* Talking!
  - Press any one of the 2 buttons on the Circuit Playground to make the cat "talk" (aka chirp).
* Temperature and sound level sensing
  - Upon reaching an upper temperature or sound level, the cat will frown and become "sad".
  - This was actually way too hard to get working correctly due to the nature of the onboard temperature and sound sensor. I wasn't able to get this to demonstrate correctly, but the code for this still exists in the .pde file.
* NeoPixels
  - The bottom half of the Circuit Playground's NeoPixels now also display and represent the background color/overall emotion! (bright = happy, and dim = sad)
     - I also couldn't get the color changing part to show up on my phone's recording :(
  -  When talking, the top 2 NeoPixels will turn red.

## How?
I wrote my own wrapper class that sends the corresponding commands for sound and NeoPixel control to the Circuit Playground.
```java
// This class is not thread-safe; bad stuff will happen when you use this
// in an environment with concurrency present! You can *technically* read
// from the on-board accelerometer too, but I didn't feel like coding that
// in (unless you want me to lol, same goes for capacitive touch). Doing so 
// would raise some seriously difficult to circument race conditions that can 
// only be resolved by using Mixins or runtime code injection. - Eddie :D
// Documentation: https://cdn-learn.adafruit.com/downloads/pdf/circuit-playground-firmata.pdf
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
```

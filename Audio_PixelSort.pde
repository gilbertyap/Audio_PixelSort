//Created by Gilbert Yap July 12, 2014
//Modified by Gilbert Yap June 8-9 2015, created threshold map detection, reduced draw time, June 10 2015 added music and music-triggered sorts
//Sorts an image in HSB, Asendorf style
import ddf.minim.*;
import ddf.minim.analysis.*;

Minim minim;
AudioPlayer song;
FFT fft;

PImage img;
float brightThreshBase = 255.0;
float brightnessThresh;
float brightnessThreshVer;
float horizontalTrigger = 8.5;
float verticalTrigger = 0.22;

void setup() {
  img = loadImage("eoe_cover.jpg");
  size(img.width, img.height);
  colorMode(HSB);
  noStroke();
  frameRate(24);
  
  minim = new Minim(this);
  song = minim.loadFile("Test4.mp3", 1024);
  song.play();
  fft = new FFT(song.bufferSize(), song.sampleRate());
}

void draw() {
  int [] pixelHSB = new int [img.width*img.height];
  int [] pixelThreshMap = new int [img.width*img.height];
  int [] pixelThreshMapVer = new int [img.width*img.height];
  
  fft.forward(song.mix); //perform forward FFT
  brightThreshBase = random(215.0, 255.0); // vary threshold for variety in sort
  brightnessThresh = brightThreshBase - (fft.getBand(int(random(25,32)))/2); //change threshhold based on fft of low band, log to make spectrum more even?
  brightnessThreshVer = (brightThreshBase) - fft.getBand(int(random(350, 420)))*30.0; //multiplier added to create even detection level, consider using log??
  image(img, 0, 0); //load image and pixels
  loadPixels();
  
/********************** CRAZY STUFF HAPPENS HERE */
  for (int i = 0; i < width*height; i++) {
    pixelThreshMap[i] = 0; //set all values in array to 0
    pixelThreshMapVer[i] = 0;
  }

  for (int i = 0; i < height; i++) { //columns
    for (int j = 0; j < width; j++) { //rows
      if (brightness(pixels[(i*width)+j]) > brightnessThresh) { //brightness check
        pixelThreshMap[(i*width)+j] = 1; //sets a 1 in Threshold map for pixels that are greater than threshold
      }
      
      if (brightness(pixels[(i*width)+j]) > brightnessThreshVer) { //brightness check
        pixelThreshMapVer[(i*width)+j] = 1; //sets a 1 in vertical Threshold map for pixels that are greater than threshold
      }

      if (j == (width-1)) { //if the pixel to the left is 1 and so is current, set left as 0 (want farthest right pixel for sorting)
        for (int k = 1; k < width; k++) {
          if (pixelThreshMap[((i*width)+k)] == 1) {
            pixelThreshMap[((i*width)+k)-1] = 0; //set previous pixel as 0;
          }
        }
        
        for (int k = 1; k < width; k++) { //if the pixel above is 1 and so is current, set above to 0 (want farthest pixel down)
          if (pixelThreshMapVer[((i*width)+k)] == 1) {
            pixelThreshMapVer[((i*width)+k)] = 1;
            for (int m = 1; m < i; m++) {
              pixelThreshMapVer[(((m)*width)+k)] = 0;
            }
          }
        }
      }
    }
  }

  for (int i = 0; i < height; i++) { //columns
    for (int j = 0; j < width; j++) { //rows
      if (pixelThreshMap[(i*width)+j] == 1 && pixelThreshMapVer[(i*width)+j] != 1 && (fft.getBand(12) >= horizontalTrigger)) { //horizontal check, checks low band to sort horizontally
        sortRow(i, j);
      }
      if (pixelThreshMap[(i*width)+j] == 1 && pixelThreshMapVer[(i*width)+j] == 1 && (fft.getBand(int(random(375, 420))) >= verticalTrigger)) { //vertical, check high band to sort veritcally
        sortCol(i, j);
      }
    }
  }
  /************************** END CRAZY STUFF */
  updatePixels();
  saveFrame("frames/frame#######.jpg");
  
  if(!song.isPlaying()) {
    stop();
    noLoop();
  }
}

void sortRow(int _x, int _y) { //sorting horizontally
  int len = _y; //length to the edge
  color [] unSortColors = new color [len];
  color [] sortColors = new color [len];

  for (int i = 0; i < len; i++) {
    unSortColors[i] = pixels[(_x*width) + i]; // assign row to be sorted to new array
  }

  sortColors = sort(unSortColors); // sorts array

  for (int i = 0; i < len; i++) {
    pixels[(_x*(width)) + i] = sortColors[i]; //new pixels now matach sorted array
  }
}

void sortCol(int _x, int _y) { //sorting vertically
  int len = _x;
  color [] unSortColors = new color [len];
  color [] sortColors = new color [len];
  
  for (int i = 0; i < len; i++) {
    unSortColors[i] = pixels[(i*width)+_y];
  }
  
  sortColors = sort(unSortColors);
  
  for (int i = 0; i < len; i++) {
    pixels[(i*width)+_y] = sortColors[i];
  }
}


import peasyGradients.colorSpaces.*;
import peasyGradients.gradient.*;
import peasyGradients.*;
import peasyGradients.utilities.*;
import peasyGradients.utilities.fastLog.*;
import net.jafama.*;
import ddf.minim.*;
import ddf.minim.analysis.*;
import java.util.Arrays;

boolean treeEnable = true;
Minim minim;
AudioSample music;
AudioPlayer musicPlayer;
PeasyGradients renderer;
LSystem lsys;
Turtle turtle;
color backgroundColor = color(200);
//color(254, 253, 223)

int randomPN(){    //random create 1 and -1
  int returnNum = 1;
  float generator;
  generator = random(1);
  if(generator>0.5){
    returnNum = 1;
  }
  else{
    returnNum = -1;
  }
  return returnNum;
}

float[] levelWeight(AudioSample source,float start,float end){
  int innerClipNum = 5;
  float[] levelWeightFinal = new float[innerClipNum];
  float averageLevel = 0;
  float[] leftSamples = source.getChannel(AudioSample.LEFT);
  float[] rightSamples = source.getChannel(AudioSample.RIGHT);
  float [] samplesVal = new float[rightSamples.length];
  for (int i=0; i <rightSamples.length; i++) {
    samplesVal[i] = leftSamples[i]+ rightSamples[i];
  }
  for(int i=0;i<innerClipNum;i++){
    averageLevel = 0;
    for(int j=(int)(start*(samplesVal.length-1)+(end-start)*(samplesVal.length-1)/innerClipNum*i);j<(int)(start*(samplesVal.length-1)+(end-start)*(samplesVal.length-1)/innerClipNum*(i+1));j++){
      if(j>=samplesVal.length){
        break;
      }
      averageLevel += samplesVal[j];
    }
    averageLevel /= samplesVal.length/innerClipNum;
    levelWeightFinal[i] = abs(averageLevel-0.00001);
  }
  return levelWeightFinal;
}

void treeInitialize(){
  Rule[] ruleset = new Rule[1];
  ruleset[0] = new Rule('F', "FF+[+F-F-F]-[-F+F+F]");
  lsys = new LSystem("F", ruleset);
  turtle = new Turtle(lsys.getSentence(), height/3, radians(random(18,30)*randomPN()));
}

float[][] audioCut(){    //to cut the audio file into random clips with controlled length
  int cutRandomNum = int(width/1000);
  int clipNum = int(random(cutRandomNum/3,cutRandomNum));
  //println("The Amount of Clips: "+clipNum);
  float[][] cutFinal = new float[clipNum][2];
  for(int i = 0; i < clipNum ; i++){
    cutFinal[i][0] = random(1);
    cutFinal[i][1] = cutFinal[i][0]+random(0.25,0.5);
    //println(cutFinal[i][0]," ",cutFinal[i][1]);
    cutFinal[i][0] *= width;
    cutFinal[i][1] *= width;
    if(cutFinal[i][1]>width){i--;}    //to avoid Shan ranging out of the canvas
  }
  return cutFinal;    //return the start and the end point in one array
}

public class ShanshuiObj{
  public int layer;  //Shan's Layer from 0 to 1024
  
  public ShanshuiObj(int layer){
    this.layer = layer;
  }
  
  public void setLayer(int layer){
    this.layer = layer;
  }
  
  public int getLayer(){
    return this.layer;
  }
}

class Shan extends ShanshuiObj{
  float start,end;
  float[][] dots = new float[5][2];
  public Shan(int layer,float start,float end,float[] weights){
    super(layer);
    this.start = start;
    this.end = end;
    for(int i = 0; i < weights.length; i++){
      dots[i][0]= (this.end-this.start)/5*i+start;
      dots[i][1]= abs(weights[i]*1000000);
    }
  }
  
  public void drawShan(){
    //fill(5,20);
    strokeWeight(0);
    float treePossi = 0;//it was originally set to 0.3
    Gradient QingLv = new Gradient(color(181, 23, 158,random(120,255)),color(76, 201, 240,random(80,210)));
    //Gradient QingLv = new Gradient(color(47,138,205,255),color(138,165,108,140));    //gradient color
    float baseLineY = height/2.2+random(-height/4,height/4);
    float[][] dotsFinal = new float[dots.length+2][2];
    float[] maxCal = new float [dots.length];
    for(int i=0;i<dots.length;i++){
      dotsFinal[i+1]=dots[i];
      maxCal[i]=dots[i][1];    //store all the y coordinates in dots[][] to get the max y
    }
    float heightMax = max(maxCal);
    dotsFinal[0][0] = start; 
    dotsFinal[0][1] = baseLineY+heightMax/2+random(0,height/250);
    dotsFinal[dotsFinal.length-1][0] = end;
    dotsFinal[dotsFinal.length-1][1] = dotsFinal[0][1]+random(-5,5);
    PGraphics QingLvBackground,ShanMask;
    QingLvBackground = createGraphics(width,height);
    renderer.setRenderTarget(QingLvBackground);
    renderer.linearGradient(QingLv, PI/2);
    ShanMask = createGraphics(width,height);
    ShanMask.beginDraw();
    ShanMask.beginShape();
    ShanMask.vertex(dotsFinal[0][0],dotsFinal[0][1]);
    for(int i=1;i<dotsFinal.length;i++){
        ShanMask.curveVertex(dotsFinal[i][0],dotsFinal[i][1]);
    }
    ShanMask.curveVertex(dotsFinal[dotsFinal.length-1][0],dotsFinal[dotsFinal.length-1][1]);
    ShanMask.endShape();
    ShanMask.endDraw();
    ShanMask.fill(250);
    ShanMask.loadPixels();
    QingLvBackground.mask(ShanMask);
    tint(255, 100);
    image(QingLvBackground,0,0);
    
    if(treeEnable == true && random(1)<treePossi){
      int treeNum = round(random(1,8));
      float treePosPointer = random(start,end);
      for(int t = 1;t<=treeNum;t++){
        Tree tree = new Tree(0,treePosPointer,dotsFinal[0][1]-random(height*0.1));
        treePosPointer+=randomPN()*random(height*0.02,height*0.04)*round(random(1));
        tree.drawTree();
      }
    }
  }
}

class Tree extends ShanshuiObj{
  float x,y;//(x,y) refers to the root of the tree
  public Tree(int layer,float x,float y){
    super(layer);
    this.x = x;
    this.y = y;
  }
  
  public void drawTree(){
    push();
    translate(this.x, this.y);
    scale(random(0.08,0.2));
    treeInitialize();
    int counter = 0;
    while (counter < round(random(2.5,4))) {
      pushMatrix();
      lsys.generate();
      turtle.setToDo(lsys.getSentence());
      turtle.changeLen(0.5);
      popMatrix();
      push();
      translate(0,0);
      rotate(-PI/2);
      turtle.render();
      counter++;
      pop();
    }
  pop();
  }
}


void mousePressed() {
  noLoop();
}


void mouseReleased() {
  loop();
}


void keyPressed() {
  if (key == CODED) {
    if (keyCode == ESC) {
      exit();
    }
  }
  if(key == ' '){
    saveFrame("ShanshuiTape_#####.png");
  }
}

void setup(){
  size(8268,543);
  frameRate(1);
  renderer = new PeasyGradients(this);
  surface.setLocation(0,0);
  background(backgroundColor);
  noStroke();
  minim = new Minim(this);
  music = minim.loadSample("music.mp3",2048);
}

void draw(){
  //Trees' Part
  treeInitialize();
  
  //Shans' Part
  float[][] cutPoints = audioCut();    //return in cutPoints[start][end]
  background(backgroundColor);
  Shan[] ShanList = new Shan[cutPoints.length];
  for(int cutReader = 0; cutReader < cutPoints.length; cutReader++){
    ShanList[cutReader] = new Shan(round(random(0,1024)),cutPoints[cutReader][0],cutPoints[cutReader][1],levelWeight(music,cutPoints[cutReader][0]/width,cutPoints[cutReader][1]/width));
  }
  
  //draw Shans layer by layer
  for(int i = 0;i<1025;i++){
    for(int ShanReader = 0; ShanReader<ShanList.length;ShanReader++){
      if(ShanList[ShanReader].getLayer()==i){
        ShanList[ShanReader].drawShan();
      }
    }
  }
  saveFrame("ShanshuiTape_#####.png");
}

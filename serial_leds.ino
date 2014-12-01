int relay1 = 5; 
int relay2 = 6; 
int relay3 = 7; 

int const RED_MASK = 0b001;
int const GREEN_MASK = 0b010;
int const BLUE_MASK = 0b100;

boolean redLit = false;
boolean greenLit = false;
boolean blueLit = false;

// the setup routine runs once when you press reset:
void setup()  { 
  pinMode(relay1, OUTPUT);
  pinMode(relay2, OUTPUT);
  pinMode(relay3, OUTPUT);
  
  Serial.begin(9600);
} 

// the loop routine runs over and over again forever:
void loop()  { 

  if (Serial.available() > 0) {
    int incomingByte = Serial.read();
    // bit-mask the incoming byte to work out which lights should be on
    redLit = (incomingByte & RED_MASK) ? true : false;
    greenLit = (incomingByte & GREEN_MASK) ? true : false;
    blueLit = (incomingByte & BLUE_MASK) ? true : false;
  }
  
  if (redLit) {
    digitalWrite(relay1, HIGH);
  } else {
    digitalWrite(relay1, LOW);
  }
  
  if (greenLit) {
    digitalWrite(relay2, HIGH);
  } else {
    digitalWrite(relay2, LOW);
  }
  
  if (blueLit) {
    digitalWrite(relay3, HIGH);
  } else {
    digitalWrite(relay3, LOW);
  }
}

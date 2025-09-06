const uint8_t pinServo = 10;

int usFromAngle(int deg) {
  return map(constrain(deg,0,180), 0, 180, 500, 2500); // 0–180° -> 500–2500us
}

void servoPulse(int t_high_us) {
  const int T = 20000; 
  digitalWrite(pinServo, HIGH);
  delayMicroseconds(t_high_us);
  digitalWrite(pinServo, LOW);
  delayMicroseconds(T - t_high_us);
}


void setServoAngle(int angle_deg) {
  int us = usFromAngle(angle_deg);
  servoPulse(us);
}


void setup() {
  pinMode(pinServo, OUTPUT);
  digitalWrite(pinServo, LOW);
  Serial.begin(9600);
  Serial.println("READY. Send angle 0-180, e.g. 120");
}


void loop() {
  if (Serial.available()) {
    String line = Serial.readStringUntil('\n');
    line.trim();  
    int angle = line.toInt();
    if (angle >= 0 && angle <= 180){
      setServoAngle(angle);
      int pulse = usFromAngle(angle);
      Serial.print("Servo has been set to "); Serial.print(angle);
      Serial.print(", Pulse: ");Serial.println(pulse);

      }else{
      Serial.println("Input angle out of range (0-180)");
    }

  }
}
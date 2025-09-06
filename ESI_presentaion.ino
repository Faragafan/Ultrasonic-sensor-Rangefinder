/* --------------------------------------------------------------------------
   Ultrasonic Rangefinder + Servo Scanner (Arduino)

   Description:
   - Controls a servo to sweep an HC-SR04 from a start angle to an end angle and back.
   - At each angle, takes N distance readings (configurable), applies calibration,
     and outputs 10 raw slots + 1 mean for plotting.

   Modes (via hardware button):
   - currentMode = 0 -> "MODE 1": step = 10°
   - currentMode = 1 -> "MODE 2": step = 20°

   Output Format (Serial per line):
   mode, angle, r1, r2, ... , r10, mean   (meters)
-------------------------------------------------------------------------- */

const uint8_t trig_pin     = 7;   // Trigger pin for ultrasonic sensor
const uint8_t echo_pin     = 8;   // Echo pin for ultrasonic sensor
const uint8_t pinServo     = 10;  // Servo control pin
const uint8_t stop_button  = 4;   // Emergency stop button
const uint8_t mode_button  = 3;   // Mode toggle button
const uint8_t ledGreen = 13;
const uint8_t ledRed = 12;
const uint8_t ledYellow = 11;
const uint8_t ledBlue = 9;

const int startAngle = 30;        // Sweep start angle (deg)
const int endAngle   = 150;       // Sweep end angle (deg)

int incrementAngle       = 10;    // Angle step size (deg), updated by mode
const int samplesPerAngle = 10;   // Number of distance samples per angle

bool emergency_stop   = false;    // Emergency stop flag
int  currentMode      = 0;        // 0 = Mode 1, 1 = Mode 2

// Flags for button edge detection
bool stop_WasPressed  = false;
bool mode_WasPressed  = false;

int stop_buttonstate  = 0;        // Current stop button state
int mode_buttonstate  = 0;        // Current mode button state

/* ---------------- Ultrasonic Sensor ---------------- */
// Send a 10 µs trigger pulse to the ultrasonic sensor
void sendTrig() {
  digitalWrite(trig_pin, LOW);
  digitalWrite(trig_pin, HIGH);
  delayMicroseconds(10);
  digitalWrite(trig_pin, LOW);
}

// Measure echo pulse duration (µs) with timeout
unsigned long measureEcho(unsigned long timeout_us = 30000UL) {
  sendTrig();
  return pulseIn(echo_pin, HIGH, timeout_us);
}

// Convert echo time to one-way distance in cm; return NAN if timeout
float readDistanceCm() {
  unsigned long echo = measureEcho();
  if (echo == 0) return NAN;
  return echo * 0.0343f * 0.5f;  // speed of sound conversion
}

// Apply linear calibration (cm -> meters)
float sensorCalibration(float meas_cm){
  return (1.049396f * meas_cm - 0.673890f) / 100.0f;
}

/* ---------------- Servo Control ---------------- */
// Map angle (0..180) to pulse width (500..2500 µs)
int usFromAngle(int deg) {
  return map(constrain(deg, 0, 180), 0, 180, 500, 2500);
}

// Send one 20 ms servo frame with HIGH duration = t_high_us
void servoPulse(int t_high_us) {
  const int T = 20000; // 20 ms period
  digitalWrite(pinServo, HIGH);
  delayMicroseconds(t_high_us);
  digitalWrite(pinServo, LOW);
  delayMicroseconds(T - t_high_us);
}

// Move servo to a given angle by sending one pulse frame
void setServoAngle(int angle_deg) {
  int us = usFromAngle(angle_deg);
  servoPulse(us);
}

/* ---------------- Scanning & Data ---------------- */
// Collect distance samples at a given angle
// Fill up to 10 raw readings, mean stored at slot 11 (index 10)
void scanAtAngle(int angle_deg, float out[11]) {
  for (int i = 0; i < 11; ++i) out[i] = 0; // reset buffer

  setServoAngle(angle_deg);
  delay(10); // allow servo to settle

  int cnt = 0;
  float sum = 0.0f;

  int n = samplesPerAngle;
  if (n > 10) n = 10; // only 10 raw slots available

  for (int i = 0; i < n; ++i) {
    float d_m = sensorCalibration(readDistanceCm());
    out[i] = d_m;  // store raw reading
    if (isfinite(d_m) && d_m > 0.0f) {
      sum += d_m;
      cnt++;
    }
    delay(20); // spacing between measurements
  }
  out[10] = (cnt > 0) ? (sum / cnt) : NAN; // average
}

// Send one formatted scan result line over Serial
void sendAngleBlock(int angle_deg, const float a[11], int currentMode) {
  Serial.print(!currentMode ? 1 : 2); // mode identifier
  Serial.print(',');
  Serial.print(angle_deg);
  for (int i = 0; i < 11; i++) {
    Serial.print(',');
    Serial.print(a[i], 2);
  }
  Serial.println();
}

/* ---------------- Mode Control ---------------- */
// Check stop button; toggle emergency_stop on rising edge
void stop_checkButton() {
  stop_buttonstate = digitalRead(stop_button);
  if (!stop_WasPressed && (stop_buttonstate == HIGH)) {
    stop_WasPressed = true;
    emergency_stop  = !emergency_stop;
  }
  if (stop_buttonstate == LOW) {
    stop_WasPressed = false;
  }
}

// Stop all outputs immediately
void stop_all(){
  digitalWrite(trig_pin, LOW);
  digitalWrite(pinServo, LOW);
  digitalWrite(ledRed, HIGH);
  digitalWrite(ledGreen, LOW);
}

// Check mode button; toggle currentMode on rising edge
void mode_checkButton() {
  mode_buttonstate = digitalRead(mode_button);
  if (!mode_WasPressed && (mode_buttonstate == HIGH)) {
    mode_WasPressed = true;
    currentMode = !currentMode; // toggle mode
  }
  if (mode_buttonstate == LOW) {
    mode_WasPressed = false;
  }
}

/* ---------------- Setup ---------------- */
void setup() {
  pinMode(trig_pin, OUTPUT);
  pinMode(echo_pin, INPUT);
  pinMode(pinServo, OUTPUT);
  pinMode(stop_button, INPUT);
  pinMode(mode_button, INPUT);
  pinMode(ledGreen, OUTPUT);
  pinMode(ledRed, OUTPUT);
  pinMode(ledYellow, OUTPUT);
  pinMode(ledBlue, OUTPUT);

  digitalWrite(trig_pin, LOW);
  digitalWrite(pinServo, LOW);
  Serial.begin(9600);

}


unsigned long lastStepTime = 0;
const unsigned long stepInterval = 500; // ms

void loop() {
  stop_checkButton();
  mode_checkButton();
  incrementAngle = (!currentMode ? 10 : 20);

  static int ang = startAngle;
  static int direction = 1;           // 1 = forward, -1 = backward
  static bool repeatBoundary = false; // track whether we need to repeat
  static bool firstCycle = true;      // startup flag

  if (!emergency_stop) {
    digitalWrite(ledGreen, HIGH);
    digitalWrite(ledRed, LOW);
    if (millis() - lastStepTime >= stepInterval) {
      lastStepTime = millis();
      if (currentMode){
        digitalWrite(ledYellow, HIGH);
        digitalWrite(ledBlue, LOW);
      } else {
        digitalWrite(ledYellow, LOW);
        digitalWrite(ledBlue, HIGH);
      }
      float buf[11];
      scanAtAngle(ang, buf);
      sendAngleBlock(ang, buf, currentMode);
      
      if (ang == startAngle || ang == endAngle) {
        if (firstCycle) {
          firstCycle = false;
        } 
        else if (!repeatBoundary) {
          repeatBoundary = true;
          return;  
        } 
        else {
          repeatBoundary = false;
          direction = -direction;
        }
      }

      ang += direction * incrementAngle;

      if (ang < startAngle) ang = startAngle;
      if (ang > endAngle)   ang = endAngle;
    }
  } else {
    stop_all();
  }
}

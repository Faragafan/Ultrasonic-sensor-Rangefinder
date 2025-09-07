const uint8_t trig_pin = 7;
const uint8_t echo_pin = 8;
const int N = 30;

// Send a 10 µs trigger pulse
void sendTrig() {
  digitalWrite(trig_pin, HIGH);
  delayMicroseconds(10);      // 10 µs pulse
  digitalWrite(trig_pin, LOW);
}

// Measure echo pulse width in microseconds (returns 0 on timeout)
unsigned long measureEcho(int timeout = 30000) {
  sendTrig();
  unsigned long echo = pulseIn(echo_pin, HIGH, timeout);
  return echo; 
}

float readDistanceCM() {
  unsigned long echo = measureEcho();
  if (echo == 0) return NAN;
  return echo * 0.0343f * 0.5f;  
}

void sampleAtFixedDistance() {
  float sum = 0, sum2 = 0;
  int count = 0;

  for (int i = 0; i < N; ++i) {
    float d = readDistanceCM();   
    if (isnan(d) || d <= 0) { i--; continue; } 
    sum  += d;
    sum2 += d*d;
    count++;
    delay(40); 
  }

  float mean = sum / count;
  float var  = sum2 / count - mean*mean;
  float sd   = (var > 0) ? sqrt(var) : 0;

  Serial.print("n="); Serial.print(count);
  Serial.print(", mean(cm)="); Serial.print(mean, 3);
  Serial.print(", sd(cm)="); Serial.println(sd, 3);
}

void setup() {
  pinMode(trig_pin, OUTPUT);
  pinMode(echo_pin, INPUT);
  Serial.begin(9600);
  digitalWrite(trig_pin,LOW);
}

// Note: Only take the mean (cm) whenever sd(cm) is below the tolerance: 0.050
void loop() {
  sampleAtFixedDistance();
  delay(500); 
}
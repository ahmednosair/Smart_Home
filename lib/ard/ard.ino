#include<SoftwareSerial.h>
//SoftwareSerial mySUART(2, 3);
int flameSensor = 9;
int isFlame = HIGH;
int oldIsFlame = isFlame;
int gasSensor = 2;
int isGas = HIGH;
int oldIsGas = isGas;
int buzzer = 11;
int tempPin = A0;
double temp;
long lastFeedback = -70000;
const double tempConv =  0.48828125;
String buff;
void setup()
{
  Serial.begin(9600);
  pinMode(flameSensor, INPUT);
  pinMode(gasSensor, INPUT);
  pinMode(buzzer, OUTPUT);

}

void sendSensorReadings() {
  lastFeedback = millis();
  String msg = "";
  msg.concat("sensor#Temperature#");
  msg.concat((int)round(temp));
  msg.concat("°C\n");
  msg.concat("sensor#Flame#");
  msg.concat(isFlame == LOW ? "YES\n" : "NO\n");
  msg.concat("sensor#Gas#");
  msg.concat(isGas == LOW ? "YES\n" : "NO\n");
  Serial.print(msg);
}

void loop()
{
  oldIsFlame = isFlame;
  isFlame = digitalRead(flameSensor);
  oldIsGas = isGas;
  isGas = digitalRead(gasSensor);
  temp = analogRead(A0) * tempConv;
  if ((isFlame == LOW && oldIsFlame == HIGH) || (isGas == LOW && oldIsGas == HIGH))
  {
    tone(buzzer, 2000);
    sendSensorReadings();
  }
  if ((isFlame == HIGH && oldIsFlame == LOW) || (isGas == HIGH && oldIsGas == LOW))
  {
    noTone(buzzer);
    sendSensorReadings();
  }
  if (millis() - lastFeedback > 60000) {
    sendSensorReadings();
  }

  while (Serial.available() > 0)
  {
    if (Serial.read() == '*') {
      sendSensorReadings();
    }
  }
}

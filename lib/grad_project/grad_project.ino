#include <FS.h> //this needs to be first, or it all crashes and burns...
#include <ESP8266WiFi.h>
#include <WiFiManager.h>
#ifdef ESP32
#include <SPIFFS.h>
#endif
#include <ArduinoJson.h> //https://github.com/bblanchon/ArduinoJson*/
#include <DoubleResetDetector.h>

// Number of seconds after reset during which a
// subseqent reset will be considered a double reset.
#define DRD_TIMEOUT 10

// RTC Memory Address for the DoubleResetDetector to use
#define DRD_ADDRESS 0

DoubleResetDetector drd(DRD_TIMEOUT, DRD_ADDRESS);

char room[41];
char wifiName[51] = {0};
char wifiPass[64] = {0};
char dev_1[31] ;
char dev_2[31] ;
char dev_3[31] ;
char dev_4[31] ;
const int dev_1_manual =  15; //D8
const int dev_2_manual = 14; //D5
const int dev_3_manual = 4; //D2
const int dev_4_manual = 16; //D0
long last_push_1 = 0;
long last_push_2 = 0;
long last_push_3 = 0;
long last_push_4 = 0;
const int dev_1_pin = 5; // D1
bool dev_1_state = false;
const int dev_2_pin = 0; // D3
bool dev_2_state = false;
const int dev_3_pin = 12; // D6
bool dev_3_state = false;
const int dev_4_pin = 13; // D7
bool dev_4_state = false;


const int MAX_CLIENTS = 10;
const int MAX_SENSORS = 10;
int n_clients = 0;
String sensorNames[MAX_SENSORS];
String sensorValues[MAX_SENSORS];
int n_sensors = 0;

WiFiClient *clients[MAX_CLIENTS] = {NULL};

WiFiServer wifiServer(55555);

// flag for saving data
bool needConf = false;
void loadJsonConf() {
  Serial.println("mounting FS...");
  if (SPIFFS.begin())
  {
    Serial.println("mounted file system");
    if (SPIFFS.exists("/config.json"))
    {
      File configFile = SPIFFS.open("/config.json", "r");
      if (configFile)
      {
        size_t size = configFile.size();
        std::unique_ptr<char[]> buf(new char[size]);
        configFile.readBytes(buf.get(), size);
#if defined(ARDUINOJSON_VERSION_MAJOR) && ARDUINOJSON_VERSION_MAJOR >= 6
        DynamicJsonDocument json(1024);
        auto deserializeError = deserializeJson(json, buf.get());
        if (!deserializeError)
        {
#else
        DynamicJsonBuffer jsonBuffer;
        JsonObject &json = jsonBuffer.parseObject(buf.get());
        if (json.success())
        {
#endif
          if (json["room"])
          {
            strcpy(room, json["room"]);
          } else {
            needConf = true;
          }
          if (json["wifiName"])
          {
            strcpy(wifiName, json["wifiName"]);
          } else {
            needConf = true;
          }
          if (json["wifiPass"])
          {
            strcpy(wifiPass, json["wifiPass"]);
          } else {
            needConf = true;
          }
          if (json["dev_1"])
          {
            strcpy(dev_1, json["dev_1"]);
          } else {
            needConf = true;
          }
          if (json["dev_2"])
          {
            strcpy(dev_2, json["dev_2"]);
          } else {
            needConf = true;
          }
          if (json["dev_3"])
          {
            strcpy(dev_3, json["dev_3"]);
          } else {
            needConf = true;
          }
          if (json["dev_4"])
          {
            strcpy(dev_4, json["dev_4"]);
          } else {
            needConf = true;
          }
          if (json["dev_1_state"]) {
            dev_1_state = (strcmp(json["dev_1_state"], "1") == 0);
          }
          if (json["dev_2_state"]) {
            dev_2_state = (strcmp(json["dev_2_state"], "1") == 0);
          }
          if (json["dev_3_state"]) {
            dev_3_state = (strcmp(json["dev_3_state"], "1") == 0);
          }
          if (json["dev_4_state"]) {
            dev_4_state = (strcmp(json["dev_4_state"], "1") == 0);
          }
        }
        else
        {
          needConf = true;
          Serial.println("failed to load json config");
        }
      }
    }
  }
  else
  {
    needConf = true;
    Serial.println("failed to mount FS");
  }
}
void setup()
{
  Serial.begin(9600);
  pinMode(dev_1_pin, OUTPUT);
  pinMode(dev_2_pin, OUTPUT);
  pinMode(dev_3_pin, OUTPUT);
  pinMode(dev_4_pin, OUTPUT);
  pinMode(dev_1_manual, INPUT);
  pinMode(dev_2_manual, INPUT);
  pinMode(dev_3_manual, INPUT);
  pinMode(dev_4_manual, INPUT);

  loadJsonConf();
  if (drd.detectDoubleReset()) {
    Serial.println("REST button pushed");
    clearConf();
    delay(1000);
    ESP.restart();
  }
  digitalWrite(dev_1_pin, dev_1_state);
  digitalWrite(dev_2_pin, dev_2_state);
  digitalWrite(dev_3_pin, dev_3_state);
  digitalWrite(dev_4_pin, dev_4_state);
  if (needConf)
  {
    WiFi.mode(WIFI_AP_STA);
    if (WiFi.softAP("Smart Home Module", "12345678") == true)
    {
      Serial.println(WiFi.softAPIP());
      wifiServer.begin();
      while (1)
      {
        drd.loop();
        if (digitalRead(dev_1_manual) == HIGH && millis() - last_push_1 > 500) {
          last_push_1 = millis();
          dev_1_state = !dev_1_state;
          digitalWrite(dev_1_pin, dev_1_state);
        }
        if (digitalRead(dev_2_manual) == HIGH && millis() - last_push_2 > 500) {
          last_push_2 = millis();
          dev_2_state = !dev_2_state;
          digitalWrite(dev_2_pin, dev_2_state);
        }
        if (digitalRead(dev_3_manual) == HIGH && millis() - last_push_3 > 500) {
          last_push_3 = millis();
          dev_3_state = !dev_3_state;
          digitalWrite(dev_3_pin, dev_3_state);
        }
        if (digitalRead(dev_4_manual) == HIGH && millis() - last_push_4 > 500) {
          last_push_4 = millis();
          dev_4_state = !dev_4_state;
          digitalWrite(dev_4_pin, dev_4_state);
        }
        WiFiClient client = wifiServer.available();
        if (client)
        {
          while (client.connected())
          {
            String msg = "";
            while (client.available() > 0)
            {
              char c = client.read();
              if (c == '\n')
              {
                break;
              }
              msg += c;
            }
            if (msg.length() > 0)
            {
              Serial.println(msg);
              client.stop();
              String tmp;
              int sep1 = msg.indexOf("#");
              if (sep1 > 40) {
                break;
              }
              strcpy(room, msg.substring(0, sep1).c_str());
              int sep2 = msg.indexOf("#", sep1 + 1);
              if (sep2 - sep1 - 1 > 50) {
                break;
              }
              strcpy(wifiName, msg.substring(sep1 + 1, sep2).c_str());
              int sep3 = msg.indexOf("#", sep2 + 1);
              if (sep3 - sep2 - 1 > 63) {
                break;
              }
              strcpy(wifiPass, msg.substring(sep2 + 1, sep3).c_str());
              int sep4 = msg.indexOf("#", sep3 + 1);
              if (sep4 - sep3 - 1 > 30) {
                break;
              }
              strcpy(dev_1, msg.substring(sep3 + 1, sep4).c_str());
              int sep5 = msg.indexOf("#", sep4 + 1);
              if (sep5 - sep4 - 1 > 30) {
                break;
              }
              strcpy(dev_2, msg.substring(sep4 + 1, sep5).c_str());
              int sep6 = msg.indexOf("#", sep5 + 1);
              if (sep6 - sep5 - 1 > 30) {
                break;
              }
              strcpy(dev_3, msg.substring(sep5 + 1, sep6).c_str());
              int sep7 = msg.indexOf("#", sep6 + 1);
              if (sep7 - sep6 - 1 > 30) {
                break;
              }
              strcpy(dev_4, msg.substring(sep6 + 1, sep7).c_str());
#if defined(ARDUINOJSON_VERSION_MAJOR) && ARDUINOJSON_VERSION_MAJOR >= 6
              DynamicJsonDocument json(1024);
#else
              DynamicJsonBuffer jsonBuffer;
              JsonObject &json = jsonBuffer.createObject();
#endif
              json["room"] = room;
              json["wifiName"] = wifiName;
              json["wifiPass"] = wifiPass;
              json["dev_1"] = dev_1;
              json["dev_2"] = dev_2;
              json["dev_3"] = dev_3;
              json["dev_4"] = dev_4;
              File configFile = SPIFFS.open("/config.json", "w");
              if (!configFile)
              {
                Serial.println("failed to open config file for writing");
              }

#if defined(ARDUINOJSON_VERSION_MAJOR) && ARDUINOJSON_VERSION_MAJOR >= 6
              serializeJson(json, Serial);
              serializeJson(json, configFile);
#else
              json.printTo(Serial);
              json.printTo(configFile);
#endif
              configFile.close();

              goto configured;
            }
          }
        }
      }
    }
    else
    {
      Serial.println("Unable to Create Access Point");
    }
  }
configured: WiFi.mode(WIFI_STA);
  WiFi.begin(wifiName, wifiPass);
  int retries = 200;
  while ((WiFi.status() != WL_CONNECTED && (retries || !needConf)))
  {
    drd.loop();
    retries--;
    delay(100);
  }
  //Inform the user whether the timeout has occured, or the ESP8266 is connected to the internet
  if (WiFi.status() == WL_CONNECTED) //WiFi has succesfully Connected
  {
    Serial.print("Successfully connected to ");
    Serial.println(wifiName);
    Serial.print("IP Address: ");
    Serial.println(WiFi.localIP());
  } else {
    if (needConf) {
      clearConf();
    }
    ESP.restart();
  }
  unsigned long lastReq = millis();
  Serial.write('*');
  while (n_sensors < 3) {
    drd.loop();
    if (millis() - lastReq > 200) {
      lastReq = millis();
      Serial.write('*');
    }
    handleArduino();
  }
  wifiServer.begin();
}

void addClient(WiFiClient client) {
  if (n_clients >= MAX_CLIENTS) {
    return;
  }
  clients[n_clients] = new WiFiClient(client);
  n_clients++;
}

void removeClient(int index) {
  if (index >= n_clients) {
    return;
  }
  delete clients[index];
  clients[index] = NULL;
  for (int i = index; i + 1 < n_clients; i++) {
    clients[i] = clients[i + 1];
  }
  n_clients--;
}

void updateClients(String deviceName, bool newState, int origin) {
  String command = newState ? "ON" : "OFF" ;
  for (int i = 0 ; i < n_clients ; i++) {
    if (i != origin) {
      clients[i]->write(("device#" + deviceName + "#" + command + "\n").c_str());
    }
  }
}



bool handleClient(int index) {
  if (!clients[index]->connected()) {
    removeClient(index);
    return false;
  }
  String command = "";
  while (clients[index]->available() > 0) {
    char c = clients[index]->read();
    if (c == '\n') {
      break;
    }
    command += c;
  }
  if (command.length() <= 0) {
    return true;
  }
  int value;
  int sep = command.indexOf('#');
  if (command.substring(sep + 1) == "ON") {
    value = HIGH;
  } else if (command.substring(sep + 1) == "OFF") {
    value = LOW;
  }
  String device = command.substring(0, sep);
  if (strcmp(device.c_str(), dev_1) == 0) {
    dev_1_state = value;
    clients[index]->write("OK\n");
    updateClients(device, value, index);
    digitalWrite(dev_1_pin, value);
  } else if (strcmp(device.c_str(), dev_2) == 0) {
    dev_2_state = value;
    clients[index]->write("OK\n");
    updateClients(device, value, index);
    digitalWrite(dev_2_pin, value);
  } else if (strcmp(device.c_str(), dev_3) == 0) {
    dev_3_state = value;
    clients[index]->write("OK\n");
    updateClients(device, value, index);
    digitalWrite(dev_3_pin, value);
  } else if (strcmp(device.c_str(), dev_4) == 0) {
    dev_4_state = value;
    clients[index]->write("OK\n");
    updateClients(device, value, index);
    digitalWrite(dev_4_pin, value);
  }
  return true;

}

String initializeSensors() {
  String msg = "";
  for (int i = 0 ; i < n_sensors ; i++) {
    msg.concat(sensorNames[i]);
    msg.concat("#");

  }
  for (int i = 0 ; i < n_sensors ; i++) {
    msg.concat(sensorValues[i]);
    msg.concat("#");
  }
  return msg;
}

String initializeClient() {
  String msg;
  msg.concat(room);
  msg.concat("#");
  msg.concat(dev_1);
  msg.concat("#");
  msg.concat(dev_2);
  msg.concat("#");
  msg.concat(dev_3);
  msg.concat("#");
  msg.concat(dev_4);
  msg.concat("#");
  msg.concat(dev_1_state ? "ON#" : "OFF#");
  msg.concat(dev_2_state ? "ON#" : "OFF#");
  msg.concat(dev_3_state ? "ON#" : "OFF#");
  msg.concat(dev_4_state ? "ON#" : "OFF#");
  msg.concat("$");
  msg.concat(initializeSensors());
  msg.concat("\n");
  return msg;
}

void clearConf() {
  WiFiManager wm;
  wm.resetSettings();
  memset(wifiName, 0, 51);
  memset(wifiPass, 0, 51);
  WiFi.disconnect();

#if defined(ARDUINOJSON_VERSION_MAJOR) && ARDUINOJSON_VERSION_MAJOR >= 6
  DynamicJsonDocument json(1024);
#else
  DynamicJsonBuffer jsonBuffer;
  JsonObject &json = jsonBuffer.createObject();
#endif
  File configFile = SPIFFS.open("/config.json", "w");
  if (!configFile)
  {
    Serial.println("failed to open config file for writing");
  }
  json["dev_1_state"] = dev_1_state ? "1" : "0";
  json["dev_2_state"] = dev_2_state ? "1" : "0";
  json["dev_3_state"] = dev_3_state ? "1" : "0";
  json["dev_4_state"] = dev_4_state ? "1" : "0";
#if defined(ARDUINOJSON_VERSION_MAJOR) && ARDUINOJSON_VERSION_MAJOR >= 6
  serializeJson(json, configFile);
#else
  json.printTo(configFile);
#endif
  configFile.close();
}

int findSensorIndex(String sensorName) {
  for (int i = 0 ; i < n_sensors ; i++) {
    if (sensorNames[i].equals(sensorName)) {
      return i;
    }
  }
  return -1;
}
void sendSensorsReading(String f) {
  for (int i = 0; i < n_clients; i++) {
    if (!clients[i]->connected()) {
      removeClient(i);
      i--;
      continue;
    }
    clients[i]->write(f.c_str());
  }
}
void handleArduino() {
  while (Serial.available() > 0)
  {
    String arduinoBuff = Serial.readStringUntil('\n');
    int sep1 = arduinoBuff.indexOf("#");
    if (strcmp("sensor", arduinoBuff.substring(0, sep1).c_str()) == 0) {
      int sep2 = arduinoBuff.indexOf("#", sep1 + 1);
      String sensorName = arduinoBuff.substring(sep1 + 1, sep2);
      int indx = findSensorIndex(sensorName.c_str());
      if (indx == -1) {
        if (n_sensors == MAX_SENSORS) {
          return;
        }
        indx = n_sensors++;
        sensorNames[indx] = sensorName;
      }
      int sep3 = arduinoBuff.indexOf("#", sep2 + 1);
      sensorValues[indx] =  arduinoBuff.substring(sep2 + 1, sep3).c_str();
    }
    arduinoBuff.concat('\n');
    sendSensorsReading(arduinoBuff);
  }
}

void loop() {
  drd.loop();
  handleArduino();
  if (digitalRead(dev_1_manual) == HIGH && millis() - last_push_1 > 500) {
    last_push_1 = millis();
    dev_1_state = !dev_1_state;
    updateClients(String(dev_1), dev_1_state, -1);
    digitalWrite(dev_1_pin, dev_1_state);
  }
  if (digitalRead(dev_2_manual) == HIGH && millis() - last_push_2 > 500) {
    last_push_2 = millis();
    dev_2_state = !dev_2_state;
    updateClients(String(dev_2), dev_2_state, -1);
    digitalWrite(dev_2_pin, dev_2_state);
  }
  if (digitalRead(dev_3_manual) == HIGH && millis() - last_push_3 > 500) {
    last_push_3 = millis();
    dev_3_state = !dev_3_state;
    updateClients(String(dev_3), dev_3_state, -1);
    digitalWrite(dev_3_pin, dev_3_state);
  }
  if (digitalRead(dev_4_manual) == HIGH && millis() - last_push_4 > 500) {
    last_push_4 = millis();
    dev_4_state = !dev_4_state;
    updateClients(String(dev_4), dev_4_state, -1);
    digitalWrite(dev_4_pin, dev_4_state);
  }
  WiFiClient client = wifiServer.available();
  if (client) {
    Serial.println("New client!");
    addClient(client);
    client.write(initializeClient().c_str());
  }
  for (int i = 0; i < n_clients; i++) {
    if (!handleClient(i)) {
      i--;
    }

  }


}

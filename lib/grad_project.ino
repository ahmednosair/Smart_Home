#include <FS.h> //this needs to be first, or it all crashes and burns...
#include <ESP8266WiFi.h>
#include <WiFiManager.h>
#ifdef ESP32
#include <SPIFFS.h>
#endif
#include <ArduinoJson.h> //https://github.com/bblanchon/ArduinoJson*/

char room[41];
char wifiName[51] = {0};
char wifiPass[51] = {0};
char dev_1[31] ;
char dev_2[31] ;
char dev_3[31] ;
char dev_4[31] ;
const int dev_1_pin = 5; // D1
bool dev_1_state = false;
const int dev_2_pin = 4; // D2
bool dev_2_state = false;
const int dev_3_pin = 14; // D5
bool dev_3_state = false;
const int dev_4_pin = 12; // D6
bool dev_4_state = false;
const int rst = 13; // D7
float temperatureC;
const int MAX_CLIENTS = 10;
int n_clients = 0;
unsigned long lastReadingTime;

WiFiClient *clients[MAX_CLIENTS] = {NULL};

WiFiServer wifiServer(80);

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
  Serial.begin(115200);
  loadJsonConf();
  if (needConf)
  {
    WiFi.mode(WIFI_AP_STA);
    if (WiFi.softAP("Smart Home Module", "12345678") == true)
    {
      Serial.println(WiFi.softAPIP());
      wifiServer.begin();
      while (1)
      {
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
              int sep1 = msg.indexOf("#");
              strcpy(room, msg.substring(0, sep1).c_str());
              int sep2 = msg.indexOf("#", sep1 + 1);
              strcpy(wifiName, msg.substring(sep1 + 1, sep2).c_str());
              int sep3 = msg.indexOf("#", sep2 + 1);
              strcpy(wifiPass, msg.substring(sep2 + 1, sep3).c_str());
              int sep4 = msg.indexOf("#", sep3 + 1);
              strcpy(dev_1, msg.substring(sep3 + 1, sep4).c_str());
              int sep5 = msg.indexOf("#", sep4 + 1);
              strcpy(dev_2, msg.substring(sep4 + 1, sep5).c_str());
              int sep6 = msg.indexOf("#", sep5 + 1);
              strcpy(dev_3, msg.substring(sep5 + 1, sep6).c_str());
              int sep7 = msg.indexOf("#", sep6 + 1);
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
  Serial.print("Connecting to ");
  Serial.print(wifiName);
  Serial.print(wifiPass);
  Serial.println("...");
  //Wait for WiFi to connect for a maximum timeout of 10 seconds
  int retries = 200;
  while (WiFi.status() != WL_CONNECTED && retries)
  {
    Serial.print(".");
    retries--;
    delay(100);
  }

  Serial.println();
  //Inform the user whether the timeout has occured, or the ESP8266 is connected to the internet
  if (WiFi.status() == WL_CONNECTED) //WiFi has succesfully Connected
  {
    Serial.print("Successfully connected to ");
    Serial.println(wifiName);
    Serial.print("IP Address: ");
    Serial.println(WiFi.localIP());
  } else {
    Serial.print("Unable to Connect to ");
    Serial.println(wifiName);
    clearConf();
    ESP.restart();
  }
  pinMode(dev_1_pin, OUTPUT);
  pinMode(dev_2_pin, OUTPUT);
  pinMode(dev_3_pin, OUTPUT);
  pinMode(dev_4_pin, OUTPUT);
  pinMode(rst, INPUT);
  digitalWrite(dev_1_pin, dev_1_state);
  digitalWrite(dev_2_pin, dev_2_state);
  digitalWrite(dev_3_pin, dev_3_state);
  digitalWrite(dev_4_pin, dev_4_state);
  lastReadingTime = millis();
  sendSensorsReading();
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
  Serial.println("client removed, index: ");
  Serial.println(index);
  n_clients--;
}

void updateClients(String deviceName, bool newState) {
  String command = newState ? "ON" : "OFF" ;
  for (int i = 0 ; i < n_clients ; i++) {
    clients[i]->write(("device#" + deviceName + "#" + command + "\n").c_str());
  }
}

void sendSensorsReading() {

  unsigned int total = 0;
  for (int n = 0; n < 32; n++ ) {
    total += analogRead (A0);
  }
  float reading = total / 32.0;
  temperatureC = reading / 3.2226;
  Serial.println(temperatureC);
  for (int i = 0; i < n_clients; i++) {
    if (!clients[i]->connected()) {
      removeClient(i);
      i--;
      continue;
    }
    clients[i]->write((String("sensor#") + "Temperature#" + temperatureC + "\n").c_str());
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
  Serial.println(command);
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
    updateClients(device, value);
    digitalWrite(dev_1_pin, value);
  } else if (strcmp(device.c_str(), dev_2) == 0) {
    dev_2_state = value;
    updateClients(device, value);
    digitalWrite(dev_2_pin, value);
  } else if (strcmp(device.c_str(), dev_3) == 0) {
    dev_3_state = value;
    updateClients(device, value);
    digitalWrite(dev_3_pin, value);
  } else if (strcmp(device.c_str(), dev_4) == 0) {
    dev_4_state = value;
    updateClients(device, value);
    digitalWrite(dev_4_pin, value);
  }
  return true;

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
  msg.concat("Temperature#");
  msg.concat(String(temperatureC) + "#");
  msg.concat("\n");
  Serial.println(msg);
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

#if defined(ARDUINOJSON_VERSION_MAJOR) && ARDUINOJSON_VERSION_MAJOR >= 6
  serializeJson(json, configFile);
#else
  json.printTo(configFile);
#endif
  configFile.close();
}

void loop() {
  if (digitalRead(rst) == 1)
  {
    Serial.println("REST button pushed");
    clearConf();
    delay(1000);
    ESP.restart();
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
  if (millis() - lastReadingTime > 60000) {
    sendSensorsReading();
    lastReadingTime = millis();
  }


}

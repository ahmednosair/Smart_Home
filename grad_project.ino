#include <ESP8266WiFi.h>
#include <WiFiManager.h>
#include <FS.h>                   //this needs to be first, or it all crashes and burns...
#ifdef ESP32
#include <SPIFFS.h>
#endif
#include <ArduinoJson.h>          //https://github.com/bblanchon/ArduinoJson

char room[40];
char static_ip[16] = "192.168.1.50";
char static_gw[16] = "192.168.1.1";
char static_sn[16] = "255.255.255.0";
const int light_1 = 5; //D1
bool light_1_state = false;
const int light_2 = 4; //D2
bool light_2_state = false;
const int fan_1 = 14; //D5
bool fan_1_state = false;
const int fan_2 = 12; //D6
bool fan_2_state = false;
const int rst = 13; //D7
float temperatureC ;
const int MAX_CLIENTS = 10;
int n_clients = 0;
unsigned long lastReadingTime;


WiFiClient *clients[MAX_CLIENTS] = { NULL };

WiFiServer wifiServer(80);




//flag for saving data
bool shouldSaveConfig = false;

//callback notifying us of the need to save config
void saveConfigCallback () {
  Serial.println("Should save config");
  shouldSaveConfig = true;
}

void setup() {
  // put your setup code here, to run once:
  Serial.begin(115200);
  Serial.println();
  Serial.println("mounting FS...");

  if (SPIFFS.begin()) {
    Serial.println("mounted file system");
    if (SPIFFS.exists("/config.json")) {
      Serial.println("reading config file");
      File configFile = SPIFFS.open("/config.json", "r");
      if (configFile) {
        Serial.println("opened config file");
        size_t size = configFile.size();
        std::unique_ptr<char[]> buf(new char[size]);

        configFile.readBytes(buf.get(), size);
#if defined(ARDUINOJSON_VERSION_MAJOR) && ARDUINOJSON_VERSION_MAJOR >= 6
        DynamicJsonDocument json(1024);
        auto deserializeError = deserializeJson(json, buf.get());
        serializeJson(json, Serial);
        if ( ! deserializeError ) {
#else
        DynamicJsonBuffer jsonBuffer;
        JsonObject& json = jsonBuffer.parseObject(buf.get());
        json.printTo(Serial);
        if (json.success()) {
#endif
          Serial.println("\nparsed json");
          if (json["room"])
            strcpy(room, json["room"]);
        } else {
          Serial.println("failed to load json config");
        }
      }
    }
  } else {
    Serial.println("failed to mount FS");
  }
  Serial.println(room);

  WiFiManagerParameter custom_room("room", "enter room name", room, 40);
  WiFiManager wifiManager;
  wifiManager.setSaveConfigCallback(saveConfigCallback);
  wifiManager.addParameter(&custom_room);
  wifiManager.setMinimumSignalQuality();

  if (!wifiManager.autoConnect("AutoConnectAP", "password")) {
    Serial.println("failed to connect and hit timeout");
    delay(3000);
    //reset and try again, or maybe put it to deep sleep
    ESP.restart();
    delay(5000);
  }

  Serial.println("connected...yeey :)");
  strcpy(room, custom_room.getValue());

  if (shouldSaveConfig) {
    Serial.println("saving config");
#if defined(ARDUINOJSON_VERSION_MAJOR) && ARDUINOJSON_VERSION_MAJOR >= 6
    DynamicJsonDocument json(1024);
#else
    DynamicJsonBuffer jsonBuffer;
    JsonObject& json = jsonBuffer.createObject();
#endif
    json["room"] = room;
    File configFile = SPIFFS.open("/config.json", "w");
    if (!configFile) {
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
  }

  delay(1000);

  Serial.println(WiFi.localIP());

  wifiServer.begin();
  pinMode(light_1, OUTPUT);
  pinMode(light_2, OUTPUT);
  pinMode(fan_1, OUTPUT);
  pinMode(fan_2, OUTPUT);
  pinMode(rst, INPUT);
  digitalWrite(light_1, light_1_state);
  digitalWrite(light_2, light_2_state);
  digitalWrite(fan_1, fan_1_state);
  digitalWrite(fan_2, fan_2_state);
  lastReadingTime = millis();
  sendSensorsReading();
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
  if (device == "Light 1") {
    light_1_state = value;
    updateClients(device, value);
    digitalWrite(light_1, value);
  } else if (device == "Light 2") {
    light_2_state = value;
    updateClients(device, value);
    digitalWrite(light_2, value);
  } else if (device == "Fan 1") {
    fan_1_state = value;
    updateClients(device, value);
    digitalWrite(fan_1, value);
  } else if (device == "Fan 2") {
    fan_2_state = value;
    updateClients(device, value);
    digitalWrite(fan_2, value);
  }
  return true;

}


String initializeClient() {
  String msg;
  msg.concat(room);
  msg.concat("#Light 1#Light 2#Fan 1#Fan 2#");
  msg.concat(light_1_state ? "ON#" : "OFF#");
  msg.concat(light_2_state ? "ON#" : "OFF#");
  msg.concat(fan_1_state ? "ON#" : "OFF#");
  msg.concat(fan_2_state ? "ON#" : "OFF#");
  msg.concat("$");
  msg.concat("Temperature#");
  msg.concat(String(temperatureC) + "#");
  msg.concat("\n");
  Serial.println(msg);
  return msg;

}

void loop() {
  if (digitalRead(rst) == 1)
  {
    Serial.println("HII RESSSTT");
    WiFiManager wm;
    wm.resetSettings();
    ESP.restart();
    delay(200);
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

  delay(100);
}

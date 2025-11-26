#include "Websocket_Config.h"

Websocket_Config::Websocket_Config(const char* ssid, const char* password) : _ssid(ssid), _password(password), _webSocket(81), _hasWriteRequest(false) {}

void Websocket_Config::init() {
  WiFi.softAP(_ssid, _password);
  Serial.println("Access Point started");
  Serial.println(WiFi.softAPIP());
  
  _webSocket.begin();
  _webSocket.onEvent([this](uint8_t num, WStype_t type, uint8_t * payload, size_t length) {
    this->onWebSocketEvent(num, type, payload, length);
  });
}

void Websocket_Config::loop() {
  _webSocket.loop();
}

void Websocket_Config::broadcastUID(String uid) {
  String message = "{\"action\":\"rfid_scan\",\"serial_no\":\"" + uid + "\"}";
  _webSocket.broadcastTXT(message);
}

bool Websocket_Config::hasWriteRequest() {
  return _hasWriteRequest;
}

String Websocket_Config::getWriteData() {
  return _writeData;
}

void Websocket_Config::clearWriteRequest() {
  _hasWriteRequest = false;
  _writeData = "";
}

void Websocket_Config::onWebSocketEvent(uint8_t num, WStype_t type, uint8_t * payload, size_t length) {
  switch(type) {
    case WStype_DISCONNECTED:
      Serial.printf("[%u] Disconnected!\n", num);
      break;
    case WStype_CONNECTED:
      Serial.printf("[%u] Connected from %s\n", num, _webSocket.remoteIP(num).toString().c_str());
      break;
    case WStype_TEXT:
      String message = String((char*)payload);
      // Parse JSON
      if (message.indexOf("\"action\":\"write_tag\"") != -1) {
        int start = message.indexOf("\"data\":\"") + 8;
        int end = message.indexOf("\"", start);
        if (start != -1 && end != -1) {
          _writeData = message.substring(start, end);
          _hasWriteRequest = true;
          Serial.println("Write request received: " + _writeData);
        }
      }
      break;
  }
}
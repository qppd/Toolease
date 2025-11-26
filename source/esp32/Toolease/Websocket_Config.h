#ifndef WEBSOCKET_CONFIG_H
#define WEBSOCKET_CONFIG_H

#include <WiFi.h>
#include <WebSocketsServer.h>
#include <Arduino.h>

class Websocket_Config {
public:
  Websocket_Config(const char* ssid, const char* password);
  void init();
  void loop();
  void broadcastUID(String uid);
  bool hasWriteRequest();
  String getWriteData();
  void clearWriteRequest();
private:
  const char* _ssid;
  const char* _password;
  WebSocketsServer _webSocket;
  String _writeData;
  bool _hasWriteRequest;
  void onWebSocketEvent(uint8_t num, WStype_t type, uint8_t * payload, size_t length);
};

#endif
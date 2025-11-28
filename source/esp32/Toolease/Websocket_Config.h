#ifndef WEBSOCKET_CONFIG_H
#define WEBSOCKET_CONFIG_H

#include <WiFi.h>
#include <ArduinoWebsockets.h>
#include <Arduino.h>

using namespace websockets;

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
  WebsocketsServer _webSocket;
  String _writeData;
  bool _hasWriteRequest;
  void onWebSocketMessage(WebsocketsClient &client, WebsocketsMessage message);
  void onWebSocketEvent(WebsocketsClient &client, WebsocketsEvent event, String data);
  std::vector<WebsocketsClient*> _clients;
};

#endif
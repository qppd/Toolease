#ifndef WEBSOCKET_CONFIG_H
#define WEBSOCKET_CONFIG_H

#include <Arduino.h>
#include <WiFi.h>
#include <AsyncTCP.h>
#include <ESPAsyncWebServer.h>

class Websocket_Config {
public:
  Websocket_Config(const char* ssid, const char* password);
  void init();
  void loop();
  void broadcastUID(String uid);
  void sendMessage(String message);
  bool hasScanRequest();
  void clearScanRequest();
  bool hasWriteRequest();
  String getWriteData();
  void clearWriteRequest();
  
private:
  const char* _ssid;
  const char* _password;
  AsyncWebServer _server;
  AsyncWebSocket _webSocket;
  String _writeData;
  bool _hasWriteRequest;
  bool _hasScanRequest;
  unsigned long _lastPingTime;
  void onWebSocketEvent(AsyncWebSocket *server, AsyncWebSocketClient *client, AwsEventType type, void *arg, uint8_t *data, size_t len);
  static void onWebSocketEventStatic(AsyncWebSocket *server, AsyncWebSocketClient *client, AwsEventType type, void *arg, uint8_t *data, size_t len);
};

#endif

#include "Websocket_Config.h"
#include <vector>

using namespace websockets;

Websocket_Config::Websocket_Config(const char* ssid, const char* password)
    : _ssid(ssid), _password(password), _hasWriteRequest(false) {}

void Websocket_Config::init() {
    WiFi.softAP(_ssid, _password);
    Serial.println("Access Point started");
    Serial.println(WiFi.softAPIP());

    _webSocket.listen(81);
    // No onEvent or onMessage for server; handled in loop
}

void Websocket_Config::loop() {
    _webSocket.poll();
    // Check for new messages from clients
    for (auto client : _clients) {
        if (client && client->available()) {
            WebsocketsMessage message = client->readBlocking();
            String data = message.data();
            Serial.println("[WebSocket] Message received: " + data);
            // Parse JSON
            if (data.indexOf("\"action\":\"write_tag\"") != -1) {
                int start = data.indexOf("\"data\":\"") + 8;
                int end = data.indexOf("\"", start);
                if (start != -1 && end != -1) {
                    _writeData = data.substring(start, end);
                    _hasWriteRequest = true;
                    Serial.println("Write request received: " + _writeData);
                }
            }
        }
    }
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

// Remove onWebSocketEvent and onWebSocketMessage, now handled in loop()
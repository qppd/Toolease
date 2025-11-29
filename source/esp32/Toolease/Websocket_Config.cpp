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
    Serial.println("WebSocket server started on port 81");
}

void Websocket_Config::loop() {
    // Accept new clients
    WebsocketsClient newClient = _webSocket.accept();
    if (newClient.available()) {
        newClient.onMessage([this](WebsocketsClient& client, WebsocketsMessage message) {
            this->onWebSocketMessage(client, message);
        });
        newClient.onEvent([this](WebsocketsClient& client, WebsocketsEvent event, String data) {
            this->onWebSocketEvent(client, event, data);
        });
        _clients.push_back(newClient);
        Serial.println("New WebSocket client connected");
    }

    // Poll existing clients and remove disconnected ones
    for (auto it = _clients.begin(); it != _clients.end(); ) {
        if (it->available()) {
            it->poll();
            ++it;
        } else {
            Serial.println("WebSocket client disconnected");
            it = _clients.erase(it);
        }
    }
}

void Websocket_Config::onWebSocketMessage(WebsocketsClient &client, WebsocketsMessage message) {
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

void Websocket_Config::onWebSocketEvent(WebsocketsClient &client, WebsocketsEvent event, String data) {
    if (event == WebsocketsEvent::ConnectionClosed) {
        Serial.println("WebSocket connection closed");
    }
}

void Websocket_Config::broadcastUID(String uid) {
    String message = "{\"action\":\"rfid_scan\",\"uid\":\"" + uid + "\"}";
    for (auto& client : _clients) {
        if (client.available()) {
            client.send(message);
        }
    }
    Serial.println("Broadcasted UID: " + uid);
}
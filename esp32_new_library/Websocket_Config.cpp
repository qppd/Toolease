#include "Websocket_Config.h"

// Static instance pointer for callback
static Websocket_Config* instance = nullptr;

Websocket_Config::Websocket_Config(const char* ssid, const char* password)
    : _ssid(ssid), _password(password), _server(80), _webSocket("/ws"), 
      _hasWriteRequest(false), _hasScanRequest(false), _lastPingTime(0) {
    instance = this;
}

void Websocket_Config::init() {
    // Configure WiFi for better stability
    WiFi.mode(WIFI_AP);
    WiFi.setTxPower(WIFI_POWER_19_5dBm); // Maximum power for better connection
    
    // Configure AP with specific settings for stability
    WiFi.softAPConfig(
        IPAddress(192, 168, 4, 1),   // IP
        IPAddress(192, 168, 4, 1),   // Gateway
        IPAddress(255, 255, 255, 0)  // Subnet
    );
    
    WiFi.softAP(_ssid, _password, 1, 0, 4); // Channel 1, not hidden, max 4 connections
    delay(500); // Give WiFi time to fully initialize
    
    Serial.println("Access Point started");
    Serial.print("IP Address: ");
    Serial.println(WiFi.softAPIP());

    // Setup WebSocket
    _webSocket.onEvent(onWebSocketEventStatic);
    _server.addHandler(&_webSocket);
    
    // Start server
    _server.begin();
    Serial.println("WebSocket server started on port 80 at /ws");
    Serial.println("Connect to: ws://192.168.4.1/ws");
}

void Websocket_Config::loop() {
    unsigned long currentTime = millis();
    
    // Clean up disconnected clients (handled automatically by AsyncWebSocket)
    _webSocket.cleanupClients();
    
    // Send ping to keep connections alive (every 10 seconds)
    if (currentTime - _lastPingTime > 10000) {
        if (_webSocket.count() > 0) {
            _webSocket.pingAll();
            Serial.println("[WS] Sent ping to all clients. Total: " + String(_webSocket.count()));
        }
        _lastPingTime = currentTime;
    }
}

void Websocket_Config::onWebSocketEventStatic(AsyncWebSocket *server, AsyncWebSocketClient *client, AwsEventType type, void *arg, uint8_t *data, size_t len) {
    if (instance) {
        instance->onWebSocketEvent(server, client, type, arg, data, len);
    }
}

void Websocket_Config::onWebSocketEvent(AsyncWebSocket *server, AsyncWebSocketClient *client, AwsEventType type, void *arg, uint8_t *data, size_t len) {
    switch (type) {
        case WS_EVT_CONNECT:
            Serial.printf("[WS] Client #%u connected from %s\n", client->id(), client->remoteIP().toString().c_str());
            Serial.println("[WS] Total clients: " + String(server->count()));
            // Send welcome message
            client->text("CONNECTED");
            Serial.println("[WS] Sent CONNECTED message");
            break;
            
        case WS_EVT_DISCONNECT:
            Serial.printf("[WS] Client #%u disconnected\n", client->id());
            Serial.println("[WS] Total clients: " + String(server->count()));
            break;
            
        case WS_EVT_DATA:
            {
                AwsFrameInfo *info = (AwsFrameInfo*)arg;
                if (info->final && info->index == 0 && info->len == len && info->opcode == WS_TEXT) {
                    data[len] = 0; // Null-terminate
                    String message = (char*)data;
                    Serial.println("[WS] Received: " + message);
                    
                    // Handle SCAN_RFID command
                    if (message == "SCAN_RFID" || message.indexOf("SCAN_RFID") != -1) {
                        _hasScanRequest = true;
                        Serial.println("[WS] Scan request acknowledged");
                    }
                    // Handle WRITE_RFID command
                    else if (message.startsWith("WRITE_RFID:")) {
                        _writeData = message.substring(11); // Remove "WRITE_RFID:" prefix
                        _hasWriteRequest = true;
                        Serial.println("[WS] Write request: " + _writeData);
                    }
                    // Handle JSON format (legacy support)
                    else if (message.indexOf("\"action\":\"write_tag\"") != -1) {
                        int start = message.indexOf("\"data\":\"") + 8;
                        int end = message.indexOf("\"", start);
                        if (start != -1 && end != -1) {
                            _writeData = message.substring(start, end);
                            _hasWriteRequest = true;
                            Serial.println("[WS] Write request (JSON): " + _writeData);
                        }
                    }
                }
            }
            break;
            
        case WS_EVT_PONG:
            Serial.printf("[WS] Pong received from client #%u\n", client->id());
            break;
            
        case WS_EVT_ERROR:
            Serial.printf("[WS] Error from client #%u\n", client->id());
            break;
    }
}

void Websocket_Config::broadcastUID(String uid) {
    // Send UID directly to all connected clients
    _webSocket.textAll(uid);
    Serial.println("[WS] Broadcasted UID to " + String(_webSocket.count()) + " client(s): " + uid);
}

void Websocket_Config::sendMessage(String message) {
    _webSocket.textAll(message);
    Serial.println("[WS] Sent message to " + String(_webSocket.count()) + " client(s): " + message);
}

bool Websocket_Config::hasScanRequest() {
    return _hasScanRequest;
}

void Websocket_Config::clearScanRequest() {
    _hasScanRequest = false;
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

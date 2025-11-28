#include "Rfid_Config.h"
#include "Websocket_Config.h"

const char* ssid = "ESP32_RFID";
const char* password = "password123";

Rfid_Config rfid(5, 22); // SS_PIN 5, RST_PIN 22 for ESP32
Websocket_Config ws(ssid, password);

void setup() {
  Serial.begin(115200);
  ws.init();
  rfid.init();
  Serial.println("RFID and WebSocket systems initialized.");
  Serial.println("Available commands:");
  Serial.println("  test - Send test RFID scan");
  Serial.println("  scan <uid> - Send specific UID scan");
}

void loop() {
  ws.loop();
  rfid.read();
  String uid = rfid.getLastUID();
  if (uid != "") {
    ws.broadcastUID(uid);
    rfid.clearLastUID();
  }
  
  // Handle write requests from Flutter
  if (ws.hasWriteRequest()) {
    String data = ws.getWriteData();
    if (rfid.writeData(data)) {
      Serial.println("Write successful");
      // Optionally send confirmation back to Flutter
      ws.broadcastUID("write_success:" + data);
    } else {
      Serial.println("Write failed");
      ws.broadcastUID("write_failed");
    }
    ws.clearWriteRequest();
  }
  
  // Handle serial commands for testing
  if (Serial.available()) {
    String command = Serial.readStringUntil('\n');
    command.trim();
    if (command == "test") {
      ws.broadcastUID("test123456");
      Serial.println("Sent test RFID scan: test123456");
    } else if (command.startsWith("scan ")) {
      String testUid = command.substring(5);
      ws.broadcastUID(testUid);
      Serial.println("Sent RFID scan: " + testUid);
    } else if (command == "w") {
      rfid.writeStringToTag("mylabel", "Hello Tag! Just a random text!");
    } else if (command == "s") {
      rfid.readStringSizeFromTag("mylabel");
    } else if (command == "r") {
      rfid.readStringFromTag("mylabel");
    } else {
      Serial.println("Unknown command. Available: test, scan <uid>, w, s, r");
    }
  }
  
  delay(1000);
}
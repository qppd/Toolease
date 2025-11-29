#include <EasyMFRC522.h>
#include "Rfid_Config.h"
#include "Websocket_Config.h"

const char* ssid = "ESP32_RFID";
const char* password = "password123";

Rfid_Config rfid(5, 21); // SS_PIN 5, RST_PIN 21 for ESP32
Websocket_Config ws(ssid, password);

void setup() {
  Serial.begin(115200);
  rfid.init();
  ws.init();
 
  Serial.println("RFID and WebSocket systems initialized.");
  Serial.println("ESP32 is ready to scan RFID tags.");
}
                       
void loop() {
  ws.loop(); // Handle WebSocket connections and messages

  // Check for RFID tag
  if (rfid.detectTag()) {
    Serial.println("RFID tag detected!");
    String uid = rfid.getUID();
    Serial.println("UID: " + uid);
    ws.broadcastUID(uid);
    rfid.unselectTag();
    delay(1000); // Prevent multiple reads
  }

  // Check for write request from WebSocket
  if (ws.hasWriteRequest()) {
    String writeData = ws.getWriteData();
    Serial.println("Processing write request: " + writeData);
    // Assume writeData is in format "label:data"
    int colonIndex = writeData.indexOf(':');
    if (colonIndex != -1) {
      String label = writeData.substring(0, colonIndex);
      String data = writeData.substring(colonIndex + 1);
      if (rfid.detectTag()) {
        int result = rfid.writeFile(label, data);
        if (result >= 0) {
          Serial.println("Data written successfully to tag.");
        } else {
          Serial.println("Error writing to tag: " + String(result));
        }
        rfid.unselectTag();
      } else {
        Serial.println("No tag detected for writing.");
      }
    }
    ws.clearWriteRequest();
  }

  delay(100); // Small delay to prevent overwhelming the loop
}
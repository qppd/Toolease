/**
 * ToolEase RFID Scanner - ESP32 Firmware
 * 
 * Uses EasyMFRC522 library for reading/writing RFID tags
 * Communicates with Flutter app via WiFi WebSocket
 * 
 * Hardware Setup:
 * - ESP32 DevKit
 * - RC522 RFID Module
 * 
 * Pin Layout:
 * MFRC522      ESP32
 * SDA(SS)      GPIO 5
 * SCK          GPIO 18
 * MOSI         GPIO 23
 * MISO         GPIO 19
 * RST          GPIO 21
 * 3.3V         3.3V
 * GND          GND
 */

#include <EasyMFRC522.h>
#include "Rfid_Config.h"
#include "Websocket_Config.h"

// WiFi credentials - ESP32 creates an Access Point
const char* ssid = "ToolEase_RFID";
const char* password = "toolease123";

// Initialize RFID and WebSocket
Rfid_Config rfid(5, 21); // SS_PIN 5, RST_PIN 21 for ESP32
Websocket_Config ws(ssid, password);

// State management
bool scanRequested = false;
bool writeRequested = false;
String writeLabel = "";
String writeData = "";
unsigned long lastScanTime = 0;
const unsigned long SCAN_COOLDOWN = 1000; // 1 second cooldown between scans

void setup() {
  Serial.begin(115200);
  delay(100);
  
  Serial.println("\n\n=================================");
  Serial.println("ToolEase RFID Scanner v3.0 (WiFi)");
  Serial.println("=================================");
  
  // Initialize RFID
  rfid.init();
  Serial.println("[OK] RFID reader initialized");
  
  // Initialize WiFi and WebSocket
  ws.init();
  Serial.println("[OK] WebSocket server started");
  
  Serial.println("=================================");
  Serial.println("System ready. Waiting for WebSocket connection...");
  Serial.println("=================================\n");
}

void loop() {
  // Handle WebSocket communication
  ws.loop();

  // Check for scan request from Flutter app
  if (ws.hasScanRequest()) {
    scanRequested = true;
    ws.clearScanRequest();
    Serial.println("[CMD] Scan request received from app");
  }

  // Check for write request from Flutter app
  if (ws.hasWriteRequest()) {
    String writeCommand = ws.getWriteData();
    Serial.println("[CMD] Write request received: " + writeCommand);
    
    // Parse write command: "label:data"
    int colonIndex = writeCommand.indexOf(':');
    if (colonIndex != -1) {
      writeLabel = writeCommand.substring(0, colonIndex);
      writeData = writeCommand.substring(colonIndex + 1);
      writeRequested = true;
    } else {
      Serial.println("[ERROR] Invalid write command format");
      ws.sendMessage("WRITE_ERROR");
    }
    ws.clearWriteRequest();
  }

  // Handle RFID scanning
  if (scanRequested) {
    handleRFIDScan();
  }

  // Handle RFID writing
  if (writeRequested) {
    handleRFIDWrite();
  }

  // Auto-scan mode (optional - for testing)
  // Uncomment below to enable continuous scanning without app request
  /*
  if (!scanRequested && millis() - lastScanTime > 3000) {
    if (rfid.detectTag()) {
      String uid = rfid.getUID();
      Serial.println("[AUTO] Tag detected: " + uid);
      ws.broadcastUID(uid);
      rfid.unselectTag();
      lastScanTime = millis();
    }
  }
  */

  delay(50); // Small delay to prevent overwhelming the loop
}

/**
 * Handle RFID tag scanning
 * Waits for tag, reads UID, and sends to Flutter app
 */
void handleRFIDScan() {
  unsigned long scanStartTime = millis();
  const unsigned long SCAN_TIMEOUT = 20000; // 20 seconds timeout

  Serial.println("[SCAN] Waiting for RFID tag...");

  while (millis() - scanStartTime < SCAN_TIMEOUT) {
    if (rfid.detectTag()) {
      String uid = rfid.getUID();
      
      if (uid.length() > 0) {
        Serial.println("[SUCCESS] Tag scanned: " + uid);
        ws.broadcastUID(uid); // Send to Flutter app
        rfid.unselectTag();
        scanRequested = false;
        lastScanTime = millis();
        return;
      }
    }
    
    ws.loop(); // Keep WebSocket alive during scan
    delay(100);
  }

  // Timeout reached
  Serial.println("[TIMEOUT] No tag detected within timeout period");
  ws.sendMessage("TIMEOUT");
  scanRequested = false;
}

/**
 * Handle RFID tag writing (optional feature)
 * Waits for tag, writes data, and confirms
 */
void handleRFIDWrite() {
  unsigned long writeStartTime = millis();
  const unsigned long WRITE_TIMEOUT = 15000; // 15 seconds timeout

  Serial.println("[WRITE] Waiting for RFID tag to write...");
  Serial.println("[WRITE] Label: " + writeLabel);
  Serial.println("[WRITE] Data: " + writeData);

  while (millis() - writeStartTime < WRITE_TIMEOUT) {
    if (rfid.detectTag()) {
      Serial.println("[WRITE] Tag detected, writing data...");
      
      int result = rfid.writeFile(writeLabel, writeData);
      
      if (result >= 0) {
        Serial.println("[SUCCESS] Data written successfully");
        ws.sendMessage("WRITE_SUCCESS");
      } else {
        Serial.println("[ERROR] Failed to write data. Error code: " + String(result));
        ws.sendMessage("WRITE_ERROR");
      }
      
      rfid.unselectTag();
      writeRequested = false;
      return;
    }
    
    ws.loop(); // Keep WebSocket alive during write
    delay(100);
  }

  // Timeout reached
  Serial.println("[TIMEOUT] No tag detected for writing");
  ws.sendMessage("WRITE_ERROR");
  writeRequested = false;
}
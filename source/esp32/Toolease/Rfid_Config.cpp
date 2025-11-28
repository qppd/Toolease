#include "Rfid_Config.h"
#include <SPI.h>

Rfid_Config::Rfid_Config(byte ss_pin, byte rst_pin) : ss_pin(ss_pin), rst_pin(rst_pin), mfrc522(ss_pin, rst_pin) {}

void Rfid_Config::init() {
  SPI.begin();
  mfrc522.init();
}

void Rfid_Config::read() {
  if (mfrc522.detectTag()) {
    byte uid[10];
    byte uidLength = mfrc522.getUid(uid);
    String uidStr = "";
    for (byte i = 0; i < uidLength; i++) {
      if (i > 0) uidStr += ":";
      if (uid[i] < 0x10) uidStr += "0";
      uidStr += String(uid[i], HEX);
    }
    uidStr.toUpperCase();
    lastUID = uidStr;
    Serial.println("Card UID: " + lastUID);
    mfrc522.unselectMifareTag();
  }
}

String Rfid_Config::getLastUID() {
  return lastUID;
}

void Rfid_Config::clearLastUID() {
  lastUID = "";
}

bool Rfid_Config::writeData(String data) {
  // Write to block 4 with label "mylabel" (as in the official example)
  int result = mfrc522.writeFile(4, "mylabel", (byte*)data.c_str(), data.length() + 1);
  if (result >= 0) {
    Serial.println("Data written to tag: " + data);
    return true;
  } else {
    Serial.println("Write failed, error code: " + String(result));
    return false;
  }
}

void Rfid_Config::writeStringToTag(const String& label, const String& value) {
  int stringSize = value.length() + 1;
  int result = mfrc522.writeFile(1, label.c_str(), (byte*)value.c_str(), stringSize);
  if (result >= 0) {
    Serial.print("Successfully written to the tag, ending in block ");
    Serial.println(result);
  } else {
    Serial.print("Error writing to the tag: ");
    Serial.println(result);
  }
}

int Rfid_Config::readStringSizeFromTag(const String& label) {
  int result = mfrc522.readFileSize(1, label.c_str());
  if (result >= 0) {
    Serial.print("Size of data chunk found in the tag: ");
    Serial.print(result);
    Serial.println(" bytes");
  } else {
    Serial.print("Error reading the tag (size): ");
    Serial.println(result);
  }
  return result;
}

String Rfid_Config::readStringFromTag(const String& label) {
  char stringBuffer[100];
  int result = mfrc522.readFile(1, label.c_str(), (byte*)stringBuffer, 100);
  stringBuffer[99] = 0;
  if (result >= 0) {
    Serial.print("String data retrieved: ");
    Serial.print(stringBuffer);
    Serial.print(" (bytes: ");
    Serial.print(result);
    Serial.println(")");
    return String(stringBuffer);
  } else {
    Serial.print("Error reading the tag (data): ");
    Serial.println(result);
    return "";
  }
}
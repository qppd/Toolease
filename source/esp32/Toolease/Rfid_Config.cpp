#include "Rfid_Config.h"
#include &lt;SPI.h&gt;

Rfid_Config::Rfid_Config(byte ss_pin, byte rst_pin) : ss_pin(ss_pin), rst_pin(rst_pin), mfrc522(ss_pin, rst_pin) {}

void Rfid_Config::init() {
  SPI.begin();
  mfrc522.PCD_Init();
}

void Rfid_Config::read() {
  if (mfrc522.PICC_IsNewCardPresent() && mfrc522.PICC_ReadCardSerial()) {
    lastUID = "";
    for (byte i = 0; i < mfrc522.uid.size; i++) {
      if (mfrc522.uid.uidByte[i] < 0x10) lastUID += "0";
      lastUID += String(mfrc522.uid.uidByte[i], HEX);
    }
    Serial.println("Card UID: " + lastUID);
    mfrc522.PICC_HaltA();
  }
}

String Rfid_Config::getLastUID() {
  return lastUID;
}

void Rfid_Config::clearLastUID() {
  lastUID = "";
}

bool Rfid_Config::writeData(String data) {
  if (!mfrc522.PICC_IsNewCardPresent() || !mfrc522.PICC_ReadCardSerial()) {
    return false;
  }

  MFRC522::MIFARE_Key key;
  for (byte i = 0; i < 6; i++) key.keyByte[i] = 0xFF; // Default key

  MFRC522::StatusCode status;
  status = mfrc522.PCD_Authenticate(MFRC522::PICC_CMD_MF_AUTH_KEY_A, 4, &key, &(mfrc522.uid));
  if (status != MFRC522::STATUS_OK) {
    Serial.println("Authentication failed");
    mfrc522.PICC_HaltA();
    return false;
  }

  byte buffer[16] = {0};
  data.getBytes(buffer, 16);

  status = mfrc522.MIFARE_Write(4, buffer, 16);
  if (status != MFRC522::STATUS_OK) {
    Serial.println("Write failed");
    mfrc522.PICC_HaltA();
    return false;
  }

  Serial.println("Data written to tag: " + data);
  mfrc522.PICC_HaltA();
  return true;
}
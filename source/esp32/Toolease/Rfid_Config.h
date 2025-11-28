#ifndef RFID_CONFIG_H
#define RFID_CONFIG_H

#include <EasyMFRC522.h>
#include <Arduino.h>

class Rfid_Config {
public:
  Rfid_Config(byte ss_pin, byte rst_pin);
  void init();
  void read();
  String getLastUID();
  void clearLastUID();
  bool writeData(String data);
  void writeStringToTag(const String& label, const String& value);
  int readStringSizeFromTag(const String& label);
  String readStringFromTag(const String& label);
private:
  EasyMFRC522 mfrc522;
  byte ss_pin, rst_pin;
  String lastUID;
};

#endif
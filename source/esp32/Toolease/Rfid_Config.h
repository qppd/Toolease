#ifndef RFID_CONFIG_H
#define RFID_CONFIG_H

#include &lt;MFRC522.h&gt;
#include &lt;Arduino.h&gt;

class Rfid_Config {
public:
  Rfid_Config(byte ss_pin, byte rst_pin);
  void init();
  void read();
  String getLastUID();
  void clearLastUID();
  bool writeData(String data);
private:
  MFRC522 mfrc522;
  byte ss_pin, rst_pin;
  String lastUID;
};

#endif
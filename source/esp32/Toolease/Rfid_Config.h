#ifndef RFID_CONFIG_H
#define RFID_CONFIG_H

#include <EasyMFRC522.h>
#include <Arduino.h>

class Rfid_Config {
public:
    Rfid_Config(int ssPin, int rstPin);
    void init();
    bool detectTag();
    String getUID();
    int writeFile(String label, String data);
    String readFile(String label);
    int getFileSize(String label);
    void unselectTag();
private:
    EasyMFRC522 _rfid;
    int _block = 1; // default block
};

#endif

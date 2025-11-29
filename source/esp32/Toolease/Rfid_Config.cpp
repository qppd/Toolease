#include "Rfid_Config.h"

Rfid_Config::Rfid_Config(int ssPin, int rstPin) : _rfid(ssPin, rstPin) {}

void Rfid_Config::init() {
    _rfid.init();
}

bool Rfid_Config::detectTag() {
    return _rfid.detectTag();
}

String Rfid_Config::getUID() {
    String uid = "";
    for (byte i = 0; i < _rfid.mfrc522.uid.size; i++) {
        if (_rfid.mfrc522.uid.uidByte[i] < 0x10) uid += "0";
        uid += String(_rfid.mfrc522.uid.uidByte[i], HEX);
    }
    uid.toUpperCase();
    return uid;
}

int Rfid_Config::writeFile(String label, String data) {
    int dataSize = data.length() + 1; // include null terminator
    char buffer[dataSize];
    data.toCharArray(buffer, dataSize);
    return _rfid.writeFile(_block, label.c_str(), (byte*)buffer, dataSize);
}

String Rfid_Config::readFile(String label) {
    const int maxSize = 100;
    char buffer[maxSize];
    int result = _rfid.readFile(_block, label.c_str(), (byte*)buffer, maxSize);
    if (result >= 0) {
        buffer[maxSize - 1] = '\0'; // safety
        return String(buffer);
    } else {
        return "";
    }
}

int Rfid_Config::getFileSize(String label) {
    return _rfid.readFileSize(_block, label.c_str());
}

void Rfid_Config::unselectTag() {
    _rfid.unselectMifareTag();
}

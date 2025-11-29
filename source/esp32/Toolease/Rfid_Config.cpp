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
    for (byte i = 0; i < _rfid.getMFRC522()->uid.size; i++) {
        if (_rfid.getMFRC522()->uid.uidByte[i] < 0x10) uid += "0";
        uid += String(_rfid.getMFRC522()->uid.uidByte[i], HEX);
    }
    uid.toUpperCase();
    return uid;
}

int Rfid_Config::writeFile(String label, String data) {
    int stringSize = data.length();
    char stringBuffer[stringSize + 1];
    strcpy(stringBuffer, data.c_str());
    return _rfid.writeFile(_block, label.c_str(), (byte*)stringBuffer, stringSize + 1);
}

String Rfid_Config::readFile(String label) {
    const int MAX_STRING_SIZE = 100;
    char stringBuffer[MAX_STRING_SIZE];
    int result = _rfid.readFile(_block, label.c_str(), (byte*)stringBuffer, MAX_STRING_SIZE);
    if (result >= 0) {
        stringBuffer[MAX_STRING_SIZE - 1] = '\0';
        return String(stringBuffer);
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

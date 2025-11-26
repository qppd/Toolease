# Toolease

A comprehensive RFID-based tool leasing system built on ESP32 microcontroller with WebSocket communication capabilities. This project enables efficient tool management and tracking through RFID technology, providing real-time communication with client applications.

## Description

Toolease is an IoT solution designed for tool leasing and management operations. The system utilizes ESP32 boards equipped with MFRC522 RFID readers to scan and manage tool identification tags. Communication is handled through WebSocket protocol, allowing seamless integration with mobile applications or web interfaces for real-time tool tracking, borrowing, and returning operations.

## Features

- **RFID Reading and Writing**: Support for reading RFID tags and writing data to compatible cards
- **WebSocket Communication**: Real-time bidirectional communication with client applications
- **WiFi Connectivity**: Built-in access point and station modes for flexible networking
- **Serial Command Interface**: Testing and debugging capabilities through serial commands
- **Modular Architecture**: Separated RFID and WebSocket configurations for easy maintenance
- **Cross-Platform Compatibility**: Designed to work with various client applications (Flutter, web, etc.)

## Hardware Requirements

- ESP32 development board
- MFRC522 RFID reader module
- RFID cards/tags (MIFARE Classic compatible)
- Power supply (USB or appropriate voltage source)
- Connecting wires and breadboard (for prototyping)

## Software Requirements

- Arduino IDE 1.8.0 or later
- ESP32 board support package for Arduino IDE
- Required Arduino libraries:
  - MFRC522 (by Miguel Balboa)
  - WebSockets (by Markus Sattler)
  - WiFi
  - Arduino core for ESP32

## Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/qppd/Toolease.git
   cd Toolease
   ```

2. **Install Arduino IDE and ESP32 support:**
   - Download and install Arduino IDE from https://www.arduino.cc/en/software
   - Add ESP32 board support following the official guide: https://docs.espressif.com/projects/arduino-esp32/en/latest/installing.html

3. **Install required libraries:**
   - Open Arduino IDE
   - Go to Sketch > Include Library > Manage Libraries
   - Search for and install:
     - "MFRC522" by Miguel Balboa
     - "WebSockets" by Markus Sattler

4. **Configure the project:**
   - Open `source/esp32/Toolease/Toolease.ino` in Arduino IDE
   - Modify WiFi credentials if needed (default: SSID "ESP32_RFID", password "password123")
   - Adjust pin configurations in the code if your hardware setup differs

5. **Upload to ESP32:**
   - Select your ESP32 board in Tools > Board
   - Choose the correct COM port in Tools > Port
   - Click Upload button

## Usage

### Basic Operation

1. Power on the ESP32 device
2. The device will create a WiFi access point (default: "ESP32_RFID")
3. Connect to the access point or ensure the device is on the same network
4. Use a WebSocket client to connect to the device (default port: 81)

### WebSocket Communication

The system uses WebSocket protocol for communication. Connect to `ws://<ESP32_IP>:81`

#### Message Types

- **RFID Scan Broadcast:**
  ```json
  {
    "type": "rfid_scan",
    "uid": "ABC123456789"
  }
  ```

- **Write Request:**
  ```json
  {
    "action": "write",
    "data": "tool_data_here"
  }
  ```

- **Write Response:**
  ```json
  {
    "action": "write_success",
    "data": "tool_data_here"
  }
  ```

### Serial Commands (for testing)

Connect to the ESP32 via serial monitor (115200 baud) and use these commands:

- `test` - Send a test RFID scan message
- `scan <uid>` - Send a specific UID scan message

## Project Structure

```
Toolease/
├── LICENSE
├── README.md
├── models/
├── source/
│   └── esp32/
│       └── Toolease/
│           ├── Toolease.ino          # Main Arduino sketch
│           ├── Rfid_Config.cpp       # RFID module implementation
│           ├── Rfid_Config.h         # RFID module header
│           ├── Websocket_Config.cpp  # WebSocket module implementation
│           └── Websocket_Config.h    # WebSocket module header
└── wiring/
```

## Development

### Code Style

- Follow Arduino coding conventions
- Use meaningful variable and function names
- Include comments for complex logic
- Maintain consistent indentation (2 spaces)

### Testing

- Use serial commands for basic functionality testing
- Implement WebSocket client for integration testing
- Test RFID reading/writing with actual hardware

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contact

- **Email:** quezon.province.pd@gmail.com
- **GitHub:** https://github.com/qppd
- **Portfolio:** https://sajed-mendoza.onrender.com
- **Facebook:** https://facebook.com/qppd.dev
- **Facebook Page:** https://facebook.com/QUEZONPROVINCEDEVS

## Acknowledgments

- ESP32 community for excellent documentation and support
- Arduino framework developers
- Contributors to MFRC522 and WebSockets libraries
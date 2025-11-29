
# Toolease

A comprehensive RFID-based tool leasing and inventory management system combining Flutter mobile application with ESP32 microcontroller for real-time tool tracking and management. Designed for educational institutions, workshops, and industrial environments requiring efficient equipment borrowing and inventory control.

---

## Table of Contents

- [Overview](#overview)
- [Key Features](#key-features)
- [System Architecture](#system-architecture)
- [Hardware Components](#hardware-components)
- [Software Components](#software-components)
- [Database Schema](#database-schema)
- [Installation & Setup](#installation--setup)
- [Configuration](#configuration)
- [Operation Guide](#operation-guide)
- [API & Communication](#api--communication)
- [Features in Detail](#features-in-detail)
- [Testing & Validation](#testing--validation)
- [Troubleshooting](#troubleshooting)
- [Project Structure](#project-structure)
- [Future Enhancements](#future-enhancements)
- [Contributing](#contributing)
- [Support & Contact](#support--contact)
- [License](#license)

---

## Overview

Toolease is an integrated IoT solution for tool leasing and inventory management that combines:

- **Flutter Mobile App**: User-friendly interface for students and administrators
- **ESP32 Microcontroller**: Hardware interface for RFID scanning
- **Real-time WebSocket Communication**: Seamless data exchange between mobile app and hardware
- **SQLite Database**: Local data persistence with Drift ORM
- **Comprehensive Reporting**: PDF generation for inventory and transaction reports

The system enables educational institutions and workshops to efficiently manage tool borrowing, track inventory in real-time, and maintain detailed records of equipment usage and condition.

---

## Key Features

### Core Functionality
- **Student Registration & Management**: Register students with ID, name, year level, and section
- **Storage Organization**: Create and manage multiple storage locations for tools
- **Item Inventory Management**: Add, edit, and organize tools with quantity tracking
- **RFID Tag Assignment**: Assign RFID tags to individual item units for automated tracking
- **Borrowing System**: Multi-storage, multi-item borrowing with real-time availability checking
- **Return Processing**: Condition-based return tracking (good, damaged, lost) for each item unit
- **Real-time Synchronization**: WebSocket-based communication between mobile app and RFID hardware

### Administrative Features
- **Admin Dashboard**: Real-time statistics and system overview
- **User Management**: Student registration and profile management
- **Inventory Control**: Comprehensive item and storage management
- **Transaction Records**: Complete borrowing history with archiving capabilities
- **Reporting System**: Generate PDF reports for inventory status and usage analytics
- **System Settings**: Configurable feature toggles and kiosk mode

### Hardware Integration
- **RFID Reading/Writing**: MFRC522-based tag detection and data storage
- **WiFi Connectivity**: Access Point and Station modes for flexible networking
- **WebSocket Server**: Real-time bidirectional communication
- **Serial Debugging**: Command-line interface for testing and diagnostics

### User Experience
- **Kiosk Mode**: Lockdown interface for public use scenarios
- **Biometric Authentication**: Local authentication for admin access
- **Responsive Design**: Optimized for tablets and mobile devices
- **Offline Operation**: Local database ensures functionality without internet
- **User Manuals**: Built-in help system for students and administrators

---

## System Architecture

```
┌─────────────────┐    WebSocket    ┌─────────────────┐
│   Flutter App   │◄──────────────►│     ESP32       │
│   (Mobile)      │                │  (Hardware)     │
│                 │                │                 │
│ • Student UI    │                │ • RFID Reader   │
│ • Admin UI      │                │ • MFRC522       │
│ • Database      │                │ • WiFi AP       │
│ • WebSocket     │                │ • WebSocket     │
│   Client        │                │   Server        │
└─────────────────┘                └─────────────────┘
         │                                 │
         │                                 │
         ▼                                 ▼
┌─────────────────┐               ┌─────────────────┐
│   SQLite DB     │               │   RFID Tags     │
│   (Drift ORM)   │               │   (MIFARE)      │
│                 │               │                 │
│ • Students      │               │ • UID Reading   │
│ • Items         │               │ • Data Storage  │
│ • BorrowRecords │               │ • Tag Writing  │
│ • Settings      │               │                 │
└─────────────────┘               └─────────────────┘
```

### Data Flow
1. **Registration**: Students register via mobile app → Stored in local SQLite
2. **Item Setup**: Admin adds items and assigns RFID tags → ESP32 writes tag data
3. **Borrowing**: Student selects items → App checks availability → RFID scan confirms
4. **Tracking**: ESP32 detects RFID tags → Broadcasts UID → App processes transaction
5. **Returns**: Student returns items → Condition assessment → Database update

---

## Hardware Components

### ESP32 Development Board
- **Microcontroller**: ESP32-WROOM-32
- **WiFi**: 802.11 b/g/n (2.4GHz)
- **Bluetooth**: v4.2 BR/EDR and BLE
- **GPIO Pins**: 36 total (configurable)
- **Power**: 5V USB or 3.3V regulated

### RFID Module (MFRC522)
- **Protocol**: MIFARE Classic 1K/4K, NTAG, etc.
- **Frequency**: 13.56 MHz
- **Communication**: SPI interface
- **Range**: Up to 10cm (depending on antenna)
- **Data Storage**: 1KB per tag (MIFARE Classic 1K)

### Power Supply
- **Input**: 5V USB or battery pack
- **Current**: 500mA minimum
- **Backup**: Optional battery for portability

---

## Software Components

### Flutter Application
- **Framework**: Flutter 3.8.1+
- **State Management**: Riverpod 2.6.1
- **Database**: Drift ORM 2.28.1
- **UI Components**: Material Design 3
- **Platform Support**: Android, iOS, Windows

### ESP32 Firmware
- **IDE**: Arduino IDE 1.8.0+
- **Core**: ESP32 Arduino Core
- **Libraries**:
  - EasyMFRC522 (RFID handling)
  - WebSockets (communication)
  - WiFi (networking)

### Key Dependencies
```yaml
# Flutter Dependencies
drift: ^2.28.1
flutter_riverpod: ^2.6.1
kiosk_mode: ^0.7.0
local_auth: ^2.3.0
pdf: ^3.11.1
permission_handler: ^12.0.1
```

---

## Database Schema

### Core Tables

#### Students
```sql
CREATE TABLE students (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  student_id TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  year_level TEXT NOT NULL,
  section TEXT NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

#### Storages
```sql
CREATE TABLE storages (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  description TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

#### Items
```sql
CREATE TABLE items (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  description TEXT,
  storage_id INTEGER REFERENCES storages(id),
  total_quantity INTEGER DEFAULT 0,
  available_quantity INTEGER DEFAULT 0,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

#### ItemUnits
```sql
CREATE TABLE item_units (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  item_id INTEGER REFERENCES items(id),
  serial_no TEXT NOT NULL,
  status TEXT NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

#### BorrowRecords
```sql
CREATE TABLE borrow_records (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  borrow_id TEXT UNIQUE NOT NULL,
  student_id INTEGER REFERENCES students(id),
  status TEXT NOT NULL,
  borrowed_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  returned_at DATETIME
);
```

#### BorrowItems & Conditions
```sql
CREATE TABLE borrow_items (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  borrow_record_id INTEGER REFERENCES borrow_records(id),
  item_id INTEGER REFERENCES items(id),
  quantity INTEGER NOT NULL,
  return_condition TEXT
);

CREATE TABLE borrow_item_conditions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  borrow_item_id INTEGER REFERENCES borrow_items(id),
  quantity_unit INTEGER NOT NULL,
  condition TEXT NOT NULL
);
```

### Supporting Tables
- **Settings**: App configuration and feature toggles
- **Tags**: Item categorization system

---

## Installation & Setup

### Prerequisites
- **Flutter SDK**: 3.8.1 or higher
- **Dart SDK**: 3.0.0 or higher
- **Android Studio/VS Code**: With Flutter extensions
- **Arduino IDE**: 1.8.0+ with ESP32 support
- **Git**: Version control system

### Flutter App Setup

1. **Clone Repository**:
   ```bash
   git clone https://github.com/qppd/Toolease.git
   cd Toolease/source/flutter/Toolease
   ```

2. **Install Dependencies**:
   ```bash
   flutter pub get
   ```

3. **Generate Database Code**:
   ```bash
   flutter pub run build_runner build
   ```

4. **Configure Launcher Icons** (Optional):
   ```bash
   flutter pub run flutter_launcher_icons
   ```

5. **Build and Run**:
   ```bash
   flutter run
   ```

### ESP32 Setup

1. **Install Arduino IDE** and ESP32 Board Support
2. **Install Libraries**:
   - EasyMFRC522 by pablo-sampaio
   - WebSockets by Markus Sattler
3. **Open Project**: `source/esp32/Toolease/Toolease.ino`
4. **Configure Pins**: Adjust RFID pin assignments if needed
5. **Upload Firmware**: Select ESP32 board and upload

### Hardware Assembly

1. **Connect MFRC522 to ESP32**:
   ```
   MFRC522    ESP32
   SDA(SS) -> GPIO5
   SCK      -> GPIO18
   MOSI     -> GPIO23
   MISO     -> GPIO19
   RST      -> GPIO21
   3.3V     -> 3.3V
   GND      -> GND
   ```

2. **Power Supply**: Connect USB or regulated power
3. **Antenna**: Ensure MFRC522 antenna is clear of obstructions

---

## Configuration

### Flutter App Settings
- **Kiosk Mode**: Enable/disable lockdown interface
- **Feature Toggles**: Control availability of registration, borrowing, returns
- **Authentication**: Configure biometric requirements
- **Network Settings**: WebSocket server configuration

### ESP32 Configuration
- **WiFi Credentials**: SSID and password for Access Point
- **RFID Pins**: GPIO assignments for MFRC522
- **WebSocket Port**: Default 81
- **Debug Level**: Serial output verbosity

### Database Initialization
The app automatically creates and migrates the database on first run. Default settings include:
- Kiosk mode disabled
- All features enabled
- Default admin credentials (if applicable)

---

## Operation Guide

### For Students

1. **Registration**:
   - Tap "Register Student"
   - Enter student ID, name, year level, section
   - Submit registration

2. **Borrowing Items**:
   - Tap "Borrow Items"
   - Enter student ID
   - Select storage locations
   - Choose items and quantities
   - Confirm borrowing

3. **Returning Items**:
   - Tap "Return Items"
   - Enter student ID
   - Select borrowed items
   - Assess condition of each item
   - Confirm return

### For Administrators

1. **Access Admin Panel**:
   - Tap "Admin Panel" from home screen
   - Authenticate with biometrics or PIN

2. **Manage System**:
   - View real-time statistics
   - Manage students, items, storages
   - Assign RFID tags to items
   - Generate reports
   - Configure system settings

### RFID Workflow

1. **Tag Assignment**:
   - Admin selects item unit
   - Places RFID tag near reader
   - App writes item data to tag

2. **Borrowing**:
   - Student selects items in app
   - Scans RFID tag to confirm
   - Transaction recorded

3. **Returns**:
   - Student returns items
   - RFID scan verifies return
   - Condition assessment recorded

---

## API & Communication

### WebSocket Protocol

#### ESP32 → Flutter Messages
```json
{
  "action": "rfid_scan",
  "uid": "A1:B2:C3:D4:E5:F6"
}
```

#### Flutter → ESP32 Messages
```json
{
  "action": "write_tag",
  "data": "item_id:unit_id"
}
```

### Database API

#### Key Operations
- **CRUD Operations**: Full Create, Read, Update, Delete for all entities
- **Transaction Management**: Atomic borrowing/return operations
- **Real-time Queries**: Live data updates via Riverpod providers
- **Search & Filtering**: Advanced querying capabilities

### Serial Commands (ESP32)

```
test          - Send test RFID scan
scan <uid>    - Send specific UID scan
help          - Display available commands
```

---

## Features in Detail

### Student Management
- **Registration**: Unique student ID validation
- **Profile Management**: Update student information
- **Borrowing History**: Track all transactions per student
- **Access Control**: Student ID verification for transactions

### Inventory Management
- **Multi-level Organization**: Storages → Items → Units
- **Quantity Tracking**: Total vs available quantities
- **RFID Integration**: Tag assignment and validation
- **Status Monitoring**: Track item conditions and availability

### Borrowing System
- **Multi-storage Selection**: Borrow from multiple locations
- **Quantity Selection**: Specify quantities per item
- **Real-time Validation**: Check availability before confirmation
- **Transaction IDs**: Unique borrow identifiers
- **Due Date Tracking**: Optional due date management

### Return Processing
- **Condition Assessment**: Good/Damaged/Lost per unit
- **Bulk Returns**: Process multiple items simultaneously
- **Damage Reporting**: Detailed condition tracking
- **Late Fee Calculation**: Optional penalty system

### RFID Integration
- **Tag Reading**: Automatic UID detection and broadcasting
- **Data Writing**: Store item/unit information on tags
- **Validation**: Verify tag data matches expected items
- **Error Handling**: Graceful handling of read/write failures

### Reporting & Analytics
- **Inventory Reports**: Current stock levels and locations
- **Usage Reports**: Borrowing patterns and frequency
- **Student Reports**: Individual borrowing history
- **System Reports**: Overall system utilization
- **PDF Export**: Professional report generation

### Security & Access Control
- **Biometric Authentication**: Fingerprint/Face ID for admin access
- **Kiosk Mode**: Prevent unauthorized system access
- **Session Management**: Automatic logout on inactivity
- **Audit Trail**: Complete transaction logging

---

## Testing & Validation

### Unit Testing
```bash
flutter test
```

### Integration Testing
- **RFID Communication**: Test tag reading/writing
- **WebSocket Connection**: Validate real-time messaging
- **Database Operations**: Verify data persistence
- **UI Workflows**: End-to-end user journey testing

### Hardware Testing
- **RFID Range**: Test reading distance and reliability
- **Power Consumption**: Monitor battery life
- **Network Stability**: Test WiFi connection reliability
- **Concurrent Users**: Multi-device simultaneous operation

### Validation Checklist
- [ ] Student registration and lookup
- [ ] Item creation and RFID assignment
- [ ] Borrowing workflow completion
- [ ] Return processing with conditions
- [ ] Report generation and export
- [ ] Admin dashboard functionality
- [ ] Settings configuration
- [ ] Kiosk mode operation

---

## Troubleshooting

### Common Issues

#### RFID Problems
- **No Tag Detected**: Check wiring, power, and tag type
- **Read Errors**: Clean tag surface, check antenna alignment
- **Write Failures**: Ensure tag is MIFARE Classic format

#### Network Issues
- **WebSocket Disconnection**: Check WiFi signal strength
- **Connection Refused**: Verify ESP32 IP and port
- **Slow Response**: Check network congestion

#### App Issues
- **Database Errors**: Clear app data and restart
- **UI Freezing**: Check device resources and restart
- **Permission Denied**: Grant required permissions

#### Hardware Issues
- **ESP32 Not Responding**: Check power supply and reset
- **MFRC522 Not Working**: Verify SPI connections
- **WiFi AP Not Visible**: Check antenna and power

### Debug Tools
- **Serial Monitor**: ESP32 debugging output
- **Flutter DevTools**: App performance analysis
- **Database Inspector**: View SQLite data
- **Network Tools**: WebSocket traffic monitoring

---

## Project Structure

```
Toolease/
├── LICENSE
├── README.md
├── models/                          # 3D printable parts
│   ├── *.png                        # Render images
│   └── *.gcode                      # Print files
├── source/
│   ├── esp32/
│   │   └── Toolease/
│   │       ├── Toolease.ino         # Main firmware
│   │       ├── Rfid_Config.h/.cpp   # RFID handling
│   │       └── Websocket_Config.h/.cpp # Network comms
│   └── flutter/
│       └── Toolease/
│           ├── lib/
│           │   ├── main.dart        # App entry point
│           │   ├── core/            # Design system
│           │   ├── models/          # Data models
│           │   ├── providers/       # State management
│           │   ├── database/        # Drift database
│           │   ├── services/        # Business logic
│           │   ├── screens/         # UI screens
│           │   └── shared/          # Reusable components
│           ├── test/                # Unit tests
│           ├── android/             # Android config
│           ├── ios/                 # iOS config
│           └── pubspec.yaml         # Dependencies
└── wiring/                          # Hardware diagrams
```

---

## Future Enhancements

### Short Term
- [ ] Cloud synchronization for multi-device support
- [ ] Barcode/QR code integration alongside RFID
- [ ] Advanced search and filtering capabilities
- [ ] Email/SMS notifications for due dates
- [ ] Bulk import/export functionality

### Medium Term
- [ ] User roles and permissions system
- [ ] Maintenance scheduling and tracking
- [ ] Cost tracking and budgeting features
- [ ] Mobile app for students (companion to kiosk)
- [ ] Advanced analytics and reporting

### Long Term
- [ ] Multi-location support with centralized management
- [ ] Integration with existing LMS systems
- [ ] AI-powered predictive maintenance
- [ ] AR-based item identification
- [ ] Blockchain-based transaction verification

---

## Contributing

We welcome contributions to Toolease! Please follow these guidelines:

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/YourFeature`)
3. **Commit** changes (`git commit -m 'Add YourFeature'`)
4. **Push** to branch (`git push origin feature/YourFeature`)
5. **Open** a Pull Request

### Development Setup
```bash
# Clone and setup
git clone https://github.com/qppd/Toolease.git
cd Toolease/source/flutter/Toolease
flutter pub get
flutter pub run build_runner build

# Run tests
flutter test

# Code formatting
flutter format .
```

### Code Standards
- Follow Flutter/Dart best practices
- Use Riverpod for state management
- Implement proper error handling
- Add unit tests for new features
- Update documentation

---

## Support & Contact

### Developer Information
- **Developer**: Quezon Province Provincial Developer
- **Email**: quezon.province.pd@gmail.com
- **Portfolio**: [sajed-mendoza.onrender.com](https://sajed-mendoza.onrender.com)
- **GitHub**: [qppd](https://github.com/qppd)

### Community
- **Facebook**: [qppd.dev](https://facebook.com/qppd.dev)
- **Facebook Page**: [QUEZONPROVINCEDEVS](https://facebook.com/QUEZONPROVINCEDEVS)

### Documentation
- **User Manual**: Built into the Flutter app
- **API Docs**: Inline code documentation
- **Hardware Guide**: Wiring diagrams and assembly instructions

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## Acknowledgments

- **ESP32 Community**: Excellent documentation and support
- **Flutter Team**: Outstanding cross-platform framework
- **Drift ORM**: Powerful Dart database solution
- **MFRC522 Contributors**: Reliable RFID implementation
- **Open Source Libraries**: WebSockets, Riverpod, and more

---

*Built with ❤️ for educational institutions and workshops worldwide*
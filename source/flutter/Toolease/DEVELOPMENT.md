# DEVELOPMENT.md

## ToolEase Inventory Management System - Development Documentation

**Project Name**: ToolEase
**Platform**: Android Tablet (Kiosk Application)
**Framework**: Flutter 3.x
**Language**: Dart
**Database**: SQLite with Drift ORM
**State Management**: Riverpod (Provider Pattern)
**Target Deployment**: Android tablets in kiosk mode

---

## Table of Contents

1. [System Overview](#system-overview)
2. [Development Architecture](#development-architecture)
3. [Database Design](#database-design)
4. [Development Process](#development-process)
5. [Feature Implementation](#feature-implementation)
6. [Build and Deployment](#build-and-deployment)
7. [Testing Strategy](#testing-strategy)
8. [Technical Specifications](#technical-specifications)

---

## 1. System Overview

### 1.1 Purpose

ToolEase is an inventory management kiosk application designed to streamline the borrowing and returning process of items for students in an educational or organizational setting. The system provides:

- **Public Access**: Students can register, borrow items, and return items
- **Admin Access**: Single administrator can manage inventory, view records, and configure system
- **Real-time Tracking**: Live inventory status with quantity management
- **Condition Monitoring**: Track item conditions (good, damaged, lost)

### 1.2 Key Requirements

- **Kiosk Mode Operation**: Run as a locked-down kiosk on Android tablets
- **Offline Capability**: Full functionality without internet connection
- **Single Admin Authentication**: Device PIN/password-based admin access
- **Real-time Updates**: Immediate UI updates across all screens
- **PDF Report Generation**: Export records and reports

---

## 2. Development Architecture

### 2.1 Clean Architecture Pattern

The application follows Clean Architecture principles with clear separation of concerns:

```
┌─────────────────────────────────────────┐
│         Presentation Layer              │
│    (UI Screens, Widgets, Providers)     │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│         Business Logic Layer            │
│    (Services, Use Cases, Validators)    │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│          Data Layer                     │
│   (Database, Models, Repositories)      │
└─────────────────────────────────────────┘
```

### 2.2 Directory Structure

```
lib/
├── core/                      # Design system and core utilities
│   ├── colors.dart           # Color palette
│   ├── spacing.dart          # Spacing constants
│   ├── theme.dart            # Material theme configuration
│   └── typography.dart       # Text styles
│
├── database/                 # Data persistence layer
│   ├── tables.dart          # Drift table definitions
│   ├── database.dart        # Database class
│   └── database.g.dart      # Generated database code
│
├── models/                   # Data models and DTOs
│   ├── student.dart
│   ├── item.dart
│   ├── borrow_record.dart
│   └── quantity_condition.dart
│
├── providers/                # State management
│   ├── database_provider.dart
│   ├── item_provider.dart
│   ├── student_provider.dart
│   └── settings_provider.dart
│
├── screens/                  # UI screens
│   ├── home/                # Home screen
│   ├── register/            # Student registration
│   ├── borrow/              # Borrowing workflow
│   ├── return/              # Return workflow
│   └── admin/               # Admin dashboard and management
│
├── services/                 # Business logic services
│   ├── database_service.dart
│   ├── auth_service.dart
│   ├── kiosk_service.dart
│   └── pdf_service.dart
│
├── shared/widgets/          # Reusable UI components
│   ├── app_card.dart
│   ├── action_card.dart
│   ├── custom_button.dart
│   └── loading_overlay.dart
│
└── utils/                   # Utility functions
    ├── validators.dart
    ├── formatters.dart
    └── constants.dart
```

### 2.3 State Management Architecture

**Riverpod Provider Pattern:**

```dart
// Provider hierarchy
┌─────────────────────────┐
│  DatabaseProvider       │  (Singleton)
└───────────┬─────────────┘
            │
     ┌──────┴──────┐
     ▼             ▼
┌─────────┐   ┌─────────┐
│ Student │   │  Item   │  (StreamProviders)
│Provider │   │Provider │
└─────────┘   └─────────┘
     │             │
     └──────┬──────┘
            ▼
    ┌───────────────┐
    │ BorrowRecord  │
    │   Provider    │
    └───────────────┘
```

---

## 3. Database Design

### 3.1 Entity-Relationship Diagram

```
┌─────────────┐
│  Students   │
└──────┬──────┘
       │
       │ 1:N
       │
┌──────▼──────────┐
│ BorrowRecords   │
└──────┬──────────┘
       │
       │ 1:N
       │
┌──────▼──────────┐      N:1    ┌──────────┐
│  BorrowItems    │◄─────────────┤  Items   │
└──────┬──────────┘              └────┬─────┘
       │                              │
       │ 1:N                       N:1│
       │                              │
┌──────▼──────────────┐         ┌────▼─────┐
│ BorrowItemConditions│         │ Storages │
└─────────────────────┘         └──────────┘
```

### 3.2 Database Tables

#### Students Table
```dart
class Students extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get studentId => text().unique()();
  TextColumn get firstName => text()();
  TextColumn get lastName => text()();
  TextColumn get course => text()();
  IntColumn get yearLevel => integer()();
  TextColumn get section => text()();
  DateTimeColumn get createdAt => dateTime()();
}
```

#### Items Table
```dart
class Items extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  IntColumn get totalQuantity => integer()();
  IntColumn get availableQuantity => integer()();
  IntColumn get storageId => integer().references(Storages, #id)();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}
```

#### BorrowRecords Table
```dart
class BorrowRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get borrowId => text().unique()();
  IntColumn get studentId => integer().references(Students, #id)();
  DateTimeColumn get borrowDate => dateTime()();
  DateTimeColumn get dueDate => dateTime()();
  DateTimeColumn get returnDate => dateTime().nullable()();
  TextColumn get status => text()(); // 'borrowed', 'returned'
  DateTimeColumn get createdAt => dateTime()();
}
```

#### BorrowItems Table
```dart
class BorrowItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get borrowRecordId => integer().references(BorrowRecords, #id)();
  IntColumn get itemId => integer().references(Items, #id)();
  IntColumn get quantityBorrowed => integer()();
  DateTimeColumn get createdAt => dateTime()();
}
```

#### BorrowItemConditions Table (Quantity Tracking)
```dart
class BorrowItemConditions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get borrowItemId => integer().references(BorrowItems, #id)();
  TextColumn get condition => text()(); // 'good', 'damaged', 'lost'
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}
```

### 3.3 Database Code Generation

The system uses Drift ORM for type-safe database operations:

```bash
# Generate database code
flutter packages pub run build_runner build --delete-conflicting-outputs
```

**Generated Files:**
- `lib/database/database.g.dart` - Database implementation
- Query methods, data access objects (DAOs)
- Type-safe SQL query builders

---

## 4. Development Process

### 4.1 Initial Setup and Planning

**Phase 1: Requirements Analysis**
- Identified core user workflows (register, borrow, return)
- Defined admin requirements (authentication, management)
- Determined kiosk mode constraints
- Established offline-first architecture

**Phase 2: Technology Selection**
- **Flutter**: Cross-platform framework with excellent UI capabilities
- **Drift**: Type-safe SQLite ORM for offline data persistence
- **Riverpod**: Modern provider pattern for state management
- **local_auth**: Biometric/PIN authentication for admin access

### 4.2 Development Workflow

```
1. Feature Planning
   ↓
2. Database Schema Design
   ↓
3. Model Creation
   ↓
4. Service Layer Implementation
   ↓
5. Provider Setup
   ↓
6. UI Screen Development
   ↓
7. Integration Testing
   ↓
8. User Acceptance Testing
```

### 4.3 Git Workflow

```bash
# Development branch strategy
master (production-ready code)
  ↓
feature/* (new features)
bugfix/* (bug fixes)
hotfix/* (urgent production fixes)
```

### 4.4 Code Generation Commands

```bash
# Install dependencies
flutter pub get

# Generate database code
flutter packages pub run build_runner build

# Clean and regenerate
flutter clean
flutter pub get
flutter packages pub run build_runner build --delete-conflicting-outputs

# Analyze code quality
flutter analyze

# Run tests
flutter test
```

---

## 5. Feature Implementation

### 5.1 Student Registration Flow

**Implementation Steps:**

1. **UI Design**: Create registration form with validation
2. **Service Method**: `DatabaseService.registerStudent()`
3. **Provider Integration**: StudentProvider with AsyncValue
4. **Error Handling**: Validate unique student ID, required fields

```dart
// Service Layer
Future<Student> registerStudent(StudentRegistrationData data) async {
  // Validate student ID uniqueness
  final existing = await (select(students)
    ..where((s) => s.studentId.equals(data.studentId)))
    .getSingleOrNull();

  if (existing != null) {
    throw Exception('Student ID already exists');
  }

  // Insert new student
  final studentId = await into(students).insert(
    StudentsCompanion.insert(
      studentId: data.studentId,
      firstName: data.firstName,
      lastName: data.lastName,
      course: data.course,
      yearLevel: data.yearLevel,
      section: data.section,
      createdAt: DateTime.now(),
    ),
  );

  return await getStudent(studentId);
}
```

### 5.2 Borrow Workflow Implementation

**Borrow ID Generation:**
```dart
// Format: 25XXXXX (year + sequential number)
Future<String> generateBorrowId() async {
  final year = DateTime.now().year % 100; // Last 2 digits
  final count = await (select(borrowRecords)).get().then((r) => r.length);
  final sequence = (count + 1).toString().padLeft(5, '0');
  return '$year$sequence'; // e.g., "2500001"
}
```

**Multi-Item Borrowing:**
1. Create BorrowRecord with generated borrowId
2. Insert multiple BorrowItems
3. Create individual QuantityConditions for each unit
4. Update item availableQuantity
5. Use database transaction for atomicity

```dart
Future<BorrowRecord> createBorrowRecord({
  required int studentId,
  required List<BorrowItemData> items,
  required DateTime dueDate,
}) async {
  return await transaction(() async {
    // 1. Create borrow record
    final borrowId = await generateBorrowId();
    final recordId = await into(borrowRecords).insert(
      BorrowRecordsCompanion.insert(
        borrowId: borrowId,
        studentId: studentId,
        borrowDate: DateTime.now(),
        dueDate: dueDate,
        status: 'borrowed',
        createdAt: DateTime.now(),
      ),
    );

    // 2. Create borrow items and conditions
    for (final itemData in items) {
      final borrowItemId = await into(borrowItems).insert(
        BorrowItemsCompanion.insert(
          borrowRecordId: recordId,
          itemId: itemData.itemId,
          quantityBorrowed: itemData.quantity,
          createdAt: DateTime.now(),
        ),
      );

      // 3. Create individual conditions for each unit
      for (int i = 0; i < itemData.quantity; i++) {
        await into(borrowItemConditions).insert(
          BorrowItemConditionsCompanion.insert(
            borrowItemId: borrowItemId,
            condition: 'good',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
      }

      // 4. Update item quantity
      final item = await getItem(itemData.itemId);
      await (update(items)..where((i) => i.id.equals(itemData.itemId)))
        .write(ItemsCompanion(
          availableQuantity: Value(item.availableQuantity - itemData.quantity),
          updatedAt: Value(DateTime.now()),
        ));
    }

    return await getBorrowRecord(recordId);
  });
}
```

### 5.3 Return Workflow with Condition Tracking

**Per-Unit Condition Selection:**
- Student selects condition for each borrowed unit
- Conditions: Good, Damaged, Lost
- UI shows individual checkboxes for quantity tracking

```dart
Future<void> returnBorrowRecord({
  required int recordId,
  required Map<int, List<String>> itemConditions, // borrowItemId -> conditions
}) async {
  await transaction(() async {
    // 1. Update borrow record status
    await (update(borrowRecords)..where((r) => r.id.equals(recordId)))
      .write(BorrowRecordsCompanion(
        status: const Value('returned'),
        returnDate: Value(DateTime.now()),
      ));

    // 2. Update conditions and item quantities
    for (final entry in itemConditions.entries) {
      final borrowItemId = entry.key;
      final conditions = entry.value;

      // Get condition records
      final conditionRecords = await (select(borrowItemConditions)
        ..where((c) => c.borrowItemId.equals(borrowItemId)))
        .get();

      // Update each condition
      for (int i = 0; i < conditions.length; i++) {
        await (update(borrowItemConditions)
          ..where((c) => c.id.equals(conditionRecords[i].id)))
          .write(BorrowItemConditionsCompanion(
            condition: Value(conditions[i]),
            updatedAt: Value(DateTime.now()),
          ));
      }

      // 3. Update item quantities
      final borrowItem = await getBorrowItem(borrowItemId);
      final item = await getItem(borrowItem.itemId);

      final goodCount = conditions.where((c) => c == 'good').length;

      // Only good items restore available quantity
      await (update(items)..where((i) => i.id.equals(borrowItem.itemId)))
        .write(ItemsCompanion(
          availableQuantity: Value(item.availableQuantity + goodCount),
          updatedAt: Value(DateTime.now()),
        ));
    }
  });
}
```

### 5.4 Item Restoration Feature

**Lost/Damaged Item Recovery:**

```dart
// Restore lost items (marked as replaced)
Future<void> restoreLostItemsToStock(List<int> conditionIds) async {
  await transaction(() async {
    for (final conditionId in conditionIds) {
      // 1. Get condition and related item
      final condition = await getCondition(conditionId);
      final borrowItem = await getBorrowItem(condition.borrowItemId);
      final item = await getItem(borrowItem.itemId);

      // 2. Update condition to good
      await (update(borrowItemConditions)
        ..where((c) => c.id.equals(conditionId)))
        .write(BorrowItemConditionsCompanion(
          condition: const Value('good'),
          updatedAt: Value(DateTime.now()),
        ));

      // 3. Restore to available quantity (NOT total)
      await (update(items)..where((i) => i.id.equals(borrowItem.itemId)))
        .write(ItemsCompanion(
          availableQuantity: Value(item.availableQuantity + 1),
          updatedAt: Value(DateTime.now()),
        ));
    }
  });
}

// Restore damaged items (marked as repaired)
Future<void> restoreDamagedItemsToStock(List<int> conditionIds) async {
  // Same logic as restoreLostItemsToStock
  // Updates availableQuantity only, not totalQuantity
}
```

### 5.5 Admin Authentication

**Device PIN/Password Authentication:**

```dart
import 'package:local_auth/local_auth.dart';

class AuthService {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> authenticateAdmin() async {
    try {
      final canAuthenticate = await _auth.canCheckBiometrics ||
                             await _auth.isDeviceSupported();

      if (!canAuthenticate) {
        return false;
      }

      return await _auth.authenticate(
        localizedReason: 'Authenticate to access admin features',
        options: const AuthenticationOptions(
          useErrorDialogs: true,
          stickyAuth: true,
        ),
      );
    } catch (e) {
      return false;
    }
  }
}
```

### 5.6 Kiosk Mode Implementation

**Android Kiosk Service:**

```dart
class KioskService {
  static const platform = MethodChannel('com.toolease/kiosk');

  Future<void> enableKioskMode() async {
    try {
      await platform.invokeMethod('enableKioskMode');
    } catch (e) {
      print('Failed to enable kiosk mode: $e');
    }
  }

  Future<void> disableKioskMode() async {
    try {
      await platform.invokeMethod('disableKioskMode');
    } catch (e) {
      print('Failed to disable kiosk mode: $e');
    }
  }
}
```

**Android Native Code (MainActivity.kt):**

```kotlin
class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.toolease/kiosk"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "enableKioskMode" -> {
                        enableKioskMode()
                        result.success(null)
                    }
                    "disableKioskMode" -> {
                        disableKioskMode()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun enableKioskMode() {
        window.decorView.systemUiVisibility = (
            View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
            or View.SYSTEM_UI_FLAG_FULLSCREEN
            or View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
        )
    }
}
```

### 5.7 Real-time Provider Updates

**Provider Invalidation for Dashboard Updates:**

```dart
// After database operations, invalidate providers
await databaseService.restoreLostItemsToStock(selectedIds);

// Invalidate providers for real-time updates
ref.invalidate(itemsProvider);
ref.invalidate(borrowRecordsProvider);
ref.invalidate(dashboardStatsProvider);
```

---

## 6. Build and Deployment

### 6.1 Build Configuration

**android/app/build.gradle:**

```gradle
android {
    compileSdkVersion 34

    defaultConfig {
        applicationId "com.toolease.app"
        minSdkVersion 21
        targetSdkVersion 34
        versionCode 1
        versionName "1.0.0"
    }

    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            shrinkResources true
        }
    }
}
```

### 6.2 Build Commands

```bash
# Development build
flutter run

# Release APK
flutter build apk --release

# App Bundle (for Play Store)
flutter build appbundle --release

# Split APKs by ABI
flutter build apk --split-per-abi --release
```

### 6.3 Release Preparation

1. **Update Version**: Increment version in `pubspec.yaml`
2. **Run Tests**: `flutter test`
3. **Code Analysis**: `flutter analyze`
4. **Build Release**: `flutter build apk --release`
5. **Test APK**: Install and test on physical device
6. **Sign APK**: Use Android signing keys
7. **Deploy**: Transfer to tablet devices

### 6.4 Kiosk Deployment Setup

**Device Configuration:**

1. Enable Developer Options
2. Enable USB Debugging
3. Install APK via ADB:
   ```bash
   adb install app-release.apk
   ```
4. Set ToolEase as launcher app
5. Configure device as single-app kiosk
6. Disable system navigation (if supported)

**MDM Configuration (Optional):**
- Deploy via Mobile Device Management
- Configure kiosk restrictions
- Set auto-start on boot
- Disable app uninstallation

---

## 7. Testing Strategy

### 7.1 Unit Tests

```dart
// Test database operations
test('Should register student with unique ID', () async {
  final service = DatabaseService();
  final student = await service.registerStudent(
    StudentRegistrationData(
      studentId: '2024-001',
      firstName: 'John',
      lastName: 'Doe',
      course: 'BSIT',
      yearLevel: 1,
      section: 'A',
    ),
  );

  expect(student.studentId, '2024-001');
});

// Test borrow ID generation
test('Should generate correct borrow ID format', () async {
  final service = DatabaseService();
  final borrowId = await service.generateBorrowId();
  expect(borrowId, matches(r'^\d{7}$')); // Format: YYXXXXX
});
```

### 7.2 Integration Tests

```dart
// Test complete borrow workflow
testWidgets('Should complete borrow workflow', (tester) async {
  await tester.pumpWidget(MyApp());

  // Navigate to borrow screen
  await tester.tap(find.text('Borrow Items'));
  await tester.pumpAndSettle();

  // Select student
  await tester.tap(find.text('Search Student'));
  await tester.enterText(find.byType(TextField), '2024-001');
  await tester.pump();

  // Select items
  await tester.tap(find.text('Add Item'));
  // ... complete workflow

  // Verify success
  expect(find.text('Borrowed Successfully'), findsOneWidget);
});
```

### 7.3 Manual Testing Checklist

- [ ] Student registration with duplicate ID prevention
- [ ] Item borrowing with quantity updates
- [ ] Return workflow with condition tracking
- [ ] Lost/damaged item restoration
- [ ] Admin authentication
- [ ] Kiosk mode activation/deactivation
- [ ] PDF report generation
- [ ] Dashboard real-time updates
- [ ] Settings persistence
- [ ] Offline functionality

---

## 8. Technical Specifications

### 8.1 Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter

  # State Management
  flutter_riverpod: ^2.4.9

  # Database
  drift: ^2.14.0
  sqlite3_flutter_libs: ^0.5.18
  path_provider: ^2.1.1
  path: ^1.8.3

  # Authentication
  local_auth: ^2.1.7

  # UI Components
  intl: ^0.18.1

  # PDF Generation
  pdf: ^3.10.7
  printing: ^5.11.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.6
  drift_dev: ^2.14.0
```

### 8.2 Performance Optimizations

- **Database Indexing**: Indexes on frequently queried columns
- **Lazy Loading**: Load data on demand, not upfront
- **Provider Caching**: Cache provider results when appropriate
- **Image Optimization**: Compress and cache images
- **Code Splitting**: Lazy load admin screens

### 8.3 Security Measures

- **SQL Injection Prevention**: Use parameterized queries (Drift handles this)
- **Input Validation**: Validate all user inputs
- **Authentication**: Device-level PIN/biometric for admin
- **Data Privacy**: No sensitive data logging
- **Secure Storage**: SQLite database with proper permissions

### 8.4 System Requirements

**Development Environment:**
- Flutter SDK 3.16.0 or higher
- Dart SDK 3.2.0 or higher
- Android Studio / VS Code
- Android SDK (API 21-34)

**Target Device:**
- Android 5.0 (API 21) or higher
- Minimum 2GB RAM
- 100MB storage space
- Touch screen support

### 8.5 Known Limitations

- **Single Admin**: Only one admin account supported
- **Offline Only**: No cloud synchronization
- **Android Only**: No iOS version
- **Single Device**: No multi-device sync
- **Manual Backup**: No automatic database backup

---

## 9. Maintenance and Support

### 9.1 Database Backup

```dart
// Backup database file
Future<void> backupDatabase() async {
  final dbPath = await getDatabasePath();
  final backupPath = '${dbPath}_backup_${DateTime.now().millisecondsSinceEpoch}';
  await File(dbPath).copy(backupPath);
}
```

### 9.2 Common Issues and Solutions

**Issue: Database generation fails**
```bash
# Solution
flutter clean
flutter pub get
flutter packages pub run build_runner build --delete-conflicting-outputs
```

**Issue: Kiosk mode not working**
- Check device permissions
- Verify MDM configuration
- Test on different Android version

**Issue: Provider not updating**
- Ensure provider invalidation after database changes
- Check for circular dependencies
- Verify AsyncValue handling

### 9.3 Future Enhancements

- [ ] Cloud synchronization
- [ ] Multi-device support
- [ ] Barcode scanning for items
- [ ] Email notifications
- [ ] Advanced reporting
- [ ] iOS version
- [ ] Multi-admin support
- [ ] Photo documentation for conditions
- [ ] QR code student identification

---

## 10. Development Team Notes

### 10.1 Code Style Guidelines

- Follow Dart style guide
- Use meaningful variable names
- Document complex business logic
- Keep functions small and focused
- Use const constructors when possible
- Implement proper error handling

### 10.2 Git Commit Guidelines

```
feat: Add item restoration feature
fix: Correct quantity update logic
docs: Update DEVELOPMENT.md
refactor: Simplify borrow service
test: Add unit tests for student registration
```

### 10.3 Code Review Checklist

- [ ] Code follows style guidelines
- [ ] No hardcoded values
- [ ] Proper error handling
- [ ] Database transactions used correctly
- [ ] Providers invalidated after updates
- [ ] No breaking changes to database schema
- [ ] Tests updated/added
- [ ] Documentation updated

---

## Conclusion

This document provides a comprehensive overview of the ToolEase development process, architecture, and implementation details. It serves as a reference for developers, stakeholders, and documentation purposes.

**Project Status**: Production Ready
**Last Updated**: 2025-11-18
**Version**: 1.0.0

For questions or support, refer to the README.md and CLAUDE.md files.

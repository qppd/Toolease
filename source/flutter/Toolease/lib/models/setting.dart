class Setting {
  final int id;
  final String key;
  final String value;
  final DateTime updatedAt;

  const Setting({
    required this.id,
    required this.key,
    required this.value,
    required this.updatedAt,
  });

  Setting copyWith({
    int? id,
    String? key,
    String? value,
    DateTime? updatedAt,
  }) {
    return Setting(
      id: id ?? this.id,
      key: key ?? this.key,
      value: value ?? this.value,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// Predefined setting keys for screen access control
class SettingKeys {
  static const String enableRegister = 'enable_register_screen';
  static const String enableBorrow = 'enable_borrow_screen';
  static const String enableReturn = 'enable_return_screen';
  static const String enableKioskMode = 'enable_kiosk_mode';
}
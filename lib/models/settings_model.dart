class Settings {
  final String category;
  final String key;
  final String value;
  Settings({required this.category, required this.key, required this.value});

  Map<String, dynamic> toMap() => {'category': category, 'key': key, 'value': value};

  factory Settings.fromMap(Map<String, dynamic> map) {
    final note = Settings(
      category: map['category'],
      key: map['key'],
      value: map['value'],
    );
    return note;
  }
}

class SettingsCategory {
  final String category;
  final List<KeyValue> settings;

  SettingsCategory({required this.category, required this.settings});
}

class KeyValue {
  final String key;
  final String value;

  KeyValue({required this.key, required this.value});
}

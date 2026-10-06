class Config {
  final int? id;
  final String category;
  final String key;
  final String value;
  Config({this.id, required this.category, required this.key, required this.value});

  Map<String, dynamic> toMap() => {'id': id, 'category': category, 'key': key, 'value': value};

  factory Config.fromMap(Map<String, dynamic> map) {
    final note = Config(id: map['id'], category: map['category'], key: map['key'], value: map['value']);
    return note;
  }
}

class ConfigSettings {
  final String category;
  final List<KeyValue> settings;

  ConfigSettings({required this.category, required this.settings});
}

class KeyValue {
  final String key;
  final String value;

  KeyValue({required this.key, required this.value});
}

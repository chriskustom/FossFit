import 'package:flutter/foundation.dart';
import 'package:fossfit/app/utils/constants.dart';
import 'package:fossfit/db/db_constants.dart';
import 'package:fossfit/db/models/features/config_model.dart';
import 'package:sqflite/sqflite.dart';

class ConfigRepository extends ChangeNotifier {
  final Database db;
  final Map<String, Map<String, String>> _settingCache = {};
  static String tableName = TableName.config.name;
  ConfigRepository(this.db);

  //region settings
  Future<void> loadAll() async {
    final settingRows = await db.query(tableName);

    _settingCache.clear();

    for (final row in settingRows) {
      final category = row['category'] as String;
      final key = row['key'] as String;
      final value = row['value'] as String;

      _settingCache.putIfAbsent(category, () => {});
      _settingCache[category]![key] = value;
    }

    notifyListeners();
  }

  int getInt(ConfigCategory category, String key) => int.tryParse(getSetting(category, key)) ?? 0;
  double getDouble(ConfigCategory category, String key) => double.tryParse(getSetting(category, key)) ?? 0.0;
  bool isEnabled(ConfigCategory category, String key) => getSetting(category, key) == '1';
  String getSetting(ConfigCategory category, String key) => _settingCache[category.name]?[key] ?? '';

  List<KeyValue> getSettingsByCategory(ConfigCategory category) {
    return List.unmodifiable((_settingCache[category.name] ?? {}).entries.map((kv) => KeyValue(key: kv.key, value: kv.value)).toList());
  }

  List<ConfigSettings> get settingsAsList {
    return _settingCache.entries.map((categoryEntry) {
      final settings = categoryEntry.value.entries.map((kv) => KeyValue(key: kv.key, value: kv.value)).toList();
      return ConfigSettings(category: categoryEntry.key, settings: settings);
    }).toList();
  }

  Future<void> setSetting({required ConfigCategory category, required String key, required String value}) async {
    final success = await db.update(
      tableName,
      {'category': category.name, 'key': key, 'value': value},
      where: 'category = ? AND key = ?',
      whereArgs: [category.name, key],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    if (success != 1) {
      final config = Config(category: category.name, key: key, value: value);
      await db.insert(tableName, config.toMap());
    }
    _settingCache.putIfAbsent(category.name, () => {});
    _settingCache[category.name]![key] = value;

    notifyListeners();
  }

  //endregion
}

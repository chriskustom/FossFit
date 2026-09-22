import 'package:flutter/foundation.dart';
import 'package:fossfit/models/constants.dart';
import 'package:fossfit/models/settings_model.dart';
import 'package:sqflite/sqflite.dart';

class SettingsRepository extends ChangeNotifier {
  final Database db;
  final Map<String, Map<String, String>> _settingCache = {};
  static const String tableName = 'settings';
  SettingsRepository(this.db);

  //region settings
  Future<void> loadAll() async {
    final settingRows = await db.query(
      tableName,
    );

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

//Any
  bool isEnabled({required String key}) => getSetting(key: key) == '1';

  String getSetting({required String key}) {
    return _settingCache.values.map((settings) => settings[key]).whereType<String>().firstOrNull ?? '';
  }

  double getDouble({required String key}) => double.tryParse(getSetting(key: key)) ?? 0.0;

  int getInt({required String key}) => int.tryParse(getSetting(key: key)) ?? 0;

  //ByCategory
  double getDoubleByCategory({required SettingCategory category, required String key}) =>
      double.tryParse(getSettingByCategory(category: category.name, key: key)) ?? 0.0;
  int getInteByCategory({required SettingCategory category, required String key}) =>
      int.tryParse(getSettingByCategory(category: category.name, key: key)) ?? 0;
  bool isEnabledByCategory({required SettingCategory category, required String key}) =>
      getSettingByCategory(category: category.name, key: key) == '1';
  String getSettingByCategory({required String category, required String key}) {
    return _settingCache[category]?[key] ?? '';
  }

  Map<String, String> getSettingsByCategory(String category) {
    return Map.unmodifiable(_settingCache[category] ?? {});
  }

  List<SettingsCategory> get settingsAsList {
    return _settingCache.entries.map((categoryEntry) {
      final settings = categoryEntry.value.entries.map((kv) => KeyValue(key: kv.key, value: kv.value)).toList();
      return SettingsCategory(category: categoryEntry.key, settings: settings);
    }).toList();
  }

  Future<void> setSetting({
    required String category,
    required String key,
    required String value,
  }) async {
    final success = await db.update(
      tableName,
      {'category': category, 'key': key, 'value': value},
      where: 'category = ? AND key = ? and type = ?',
      whereArgs: [category, key],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    if (success != 1) {
      final config = Settings(
        category: category,
        key: key,
        value: value,
      );
      await db.insert(tableName, config.toMap());
    }
    _settingCache.putIfAbsent(category, () => {});
    _settingCache[category]![key] = value;

    notifyListeners();
  }
  //endregion
}

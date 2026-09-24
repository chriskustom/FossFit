import 'dart:io';

import 'package:fossfit/db/database_migrations.dart';
import 'package:fossfit/db/db_constants.dart';
import 'package:fossfit/db/repositories/settings_repository.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;
  static const dbFileName = 'fossfit.sqlite';
  static const backupPrefix = 'fossfit';

  //region Initialise DB
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, dbFileName);

    return await _openDb(path);
  }

  Future<Database> _openDb(String path) async => await openDatabase(
        path,
        version: kDatabaseSchemaVersion,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (db, version) async => _onCreate(db, version),
        onUpgrade: (db, oldVersion, newVersion) async => _runMigrations(db, oldVersion, newVersion),
      );

  void _onCreate(Database db, int version) async {
    await db.execute('PRAGMA foreign_keys = ON');
    await db.execute('PRAGMA user_version = $kDatabaseSchemaVersion;');

    await db.execute('''
      CREATE TABLE gym_sets (
        body_weight REAL NOT NULL DEFAULT 0.0,
        cardio INTEGER NOT NULL DEFAULT 0 CHECK (cardio IN (0, 1)), 
        category TEXT NULL,
        created INTEGER NOT NULL,
        distance REAL NOT NULL DEFAULT 0.0,
        duration REAL NOT NULL DEFAULT 0.0,
        hidden INTEGER NOT NULL DEFAULT 0 CHECK (hidden IN (0, 1)), 
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        image TEXT NULL,
        incline INTEGER NULL,
        name TEXT NOT NULL,
        notes TEXT NULL,
        plan_id INTEGER NULL,
        reps REAL NOT NULL,
        rest_ms INTEGER NULL,
        unit TEXT NOT NULL,
        weight REAL NOT NULL
      );
      ''');

    await db.execute('''
      CREATE TABLE plans (
        days TEXT NOT NULL,
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        sequence INTEGER NULL,
        title TEXT NULL
      );
      ''');

    await db.execute('''
      CREATE TABLE plan_exercises (
        enabled INTEGER NOT NULL CHECK(enabled IN (0, 1)),
        timers INTEGER NOT NULL DEFAULT 1 CHECK(timers IN (0, 1)),
        exercise TEXT NOT NULL,
        id INTEGER NOT NULL,
        max_sets INTEGER,
        plan_id INTEGER NOT NULL,
        warmup_sets INTEGER,
        sequence INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY(id AUTOINCREMENT),
        FOREIGN KEY(exercise) REFERENCES gym_sets(name),
        FOREIGN KEY(plan_id) REFERENCES plans(id)
      );
      ''');
    await db.execute('''
      CREATE TABLE settings (
          id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
          group_history INTEGER NOT NULL CHECK (group_history IN (0, 1)),
          alarm_sound TEXT NOT NULL,
          automatic_backups INTEGER NOT NULL DEFAULT 0 CHECK (automatic_backups IN (0, 1)), 
          backup_path TEXT NULL,
          cardio_unit TEXT NOT NULL,
          curve_lines INTEGER NOT NULL CHECK (curve_lines IN (0, 1)), 
          curve_smoothness REAL NULL,
          duration_estimation INTEGER NOT NULL DEFAULT 1 CHECK (duration_estimation IN (0, 1)), 
          enable_sound INTEGER NOT NULL DEFAULT 1 CHECK (enable_sound IN (0, 1)), 
          explained_permissions INTEGER NOT NULL CHECK (explained_permissions IN (0, 1)), 
          long_date_format TEXT NOT NULL,
          max_sets INTEGER NOT NULL,
          notifications INTEGER NOT NULL DEFAULT 1 CHECK (notifications IN (0, 1)), 
          peek_graph INTEGER NOT NULL DEFAULT 0 CHECK (peek_graph IN (0, 1)), 
          plan_trailing TEXT NOT NULL,
          rep_estimation INTEGER NOT NULL DEFAULT 0 CHECK (rep_estimation IN (0, 1)), 
          rest_timers INTEGER NOT NULL CHECK (rest_timers IN (0, 1)), 
          short_date_format TEXT NOT NULL,
          show_body_weight INTEGER NOT NULL DEFAULT 1 CHECK (show_body_weight IN (0, 1)), 
          show_categories INTEGER NOT NULL DEFAULT 1 CHECK (show_categories IN (0, 1)), 
          show_images INTEGER NOT NULL DEFAULT 1 CHECK (show_images IN (0, 1)), 
          show_notes INTEGER NOT NULL DEFAULT 1 CHECK (show_notes IN (0, 1)),
          show_global_progress INTEGER NOT NULL DEFAULT 1 CHECK (show_global_progress IN (0, 1)), 
          show_units INTEGER NOT NULL CHECK (show_units IN (0, 1)),
          strength_unit TEXT NOT NULL,
          system_colors INTEGER NOT NULL CHECK (system_colors IN (0, 1)), 
          tabs TEXT NOT NULL DEFAULT 'HistoryPage,PlansPage,GraphsPage,TimerPage',
          theme_mode TEXT NOT NULL,
          timer_duration INTEGER NOT NULL,
          vibrate INTEGER NOT NULL CHECK (vibrate IN (0, 1)), 
          warmup_sets INTEGER NULL,
          scrollable_tabs INTEGER NOT NULL DEFAULT 1 CHECK (scrollable_tabs IN (0, 1)), 
          stats_panel INTEGER NOT NULL DEFAULT 1 CHECK (stats_panel IN (0, 1))
      );
      ''');

    await db.execute('''
      INSERT INTO settings
      (alarm_sound, automatic_backups, backup_path, cardio_unit, curve_lines, curve_smoothness, duration_estimation, enable_sound, explained_permissions, group_history, id, long_date_format, max_sets, notifications, peek_graph, plan_trailing, rep_estimation, rest_timers, short_date_format, show_body_weight, show_categories, show_images, show_notes, show_global_progress, show_units, strength_unit, system_colors, tabs, theme_mode, timer_duration, vibrate, warmup_sets, scrollable_tabs, stats_panel)
      VALUES('', 1, '', 'km', 1, 0.10870564027905905, 0, 0, 1, 1, 1, 'EEE, dd.MM.yyyy H:mm', 3, 0, 0, 'reorder', 0, 0, 'd/M/yy', 0, 1, 1, 1, 0, 1, 'kg', 1, 'HistoryPage,PlansPage,GraphsPage,SettingsPage', 'system', 120000, 1, 0, 0, 1);
      ''');

    await db.execute('''
      CREATE INDEX gym_sets_name_created ON gym_sets(name, created);
      ''');

    await _runMigrations(db, 0, version);
  }

  final migrations = <int, Future<void> Function(Database)>{
    2: migrateToV2,
  };

  Future<void> _runMigrations(Database db, int from, int to) async {
    for (final version in migrations.keys.toList()..sort()) {
      if (version > from && version <= to) {
        await migrations[version]!(db);
      }
    }
  }

  //endregion

  //region reset
  Future<void> resetApp() async {
    if (_database == null) return;

    await _database!.execute('DELETE FROM plans;');
    await _database!.execute('DELETE FROM gym_sets;');
    await _database!.execute('DELETE FROM settings;');
    await _database!.execute('DELETE FROM plan_exercises;');
  }

  // endregion

  //region backup
  Future<bool> backupDatabaseWithTimestamp(String backupDirPath) async {
    try {
      final dbDir = await getDatabasesPath();
      final dbPath = join(dbDir, dbFileName);

      if (backupDirPath.isEmpty) return false;

      final dbFile = File(dbPath);
      if (!await dbFile.exists()) return false;

      final timestamp = DateTime.now().toIso8601String().replaceAll(RegExp(r'[:\-]'), '').split('.').first;
      final backupFileName = '${backupPrefix}_$timestamp.db';
      final backupFilePath = join(backupDirPath, backupFileName);

      await dbFile.copy(backupFilePath);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> cleanupOldBackups(String backupDirPath) async {
    final backupDir = Directory(backupDirPath);
    final backupFiles = backupDir
        .listSync()
        .whereType<File>()
        .where((f) => basename(f.path).startsWith('${backupPrefix}_') && f.path.endsWith('.db'))
        .toList();

    backupFiles.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));

    for (var i = 2; i < backupFiles.length; i++) {
      try {
        await backupFiles[i].delete();
      } catch (_) {}
    }
  }

  DateTime? _getLastBackupDate(String backupDirPath) {
    final dir = Directory(backupDirPath);
    if (!dir.existsSync()) return null;

    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => basename(f.path).startsWith('${backupPrefix}_') && f.path.endsWith('.db'))
        .toList();

    if (files.isEmpty) return null;

    files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));

    return files.first.statSync().modified;
  }

  Future<void> checkBackup(SettingsRepository repo) async {
    final backup = repo.getSettingByCategory(category: 'backup', key: 'backup');
    if (backup.isEmpty || backup == '0') return;

    final backupDir = repo.getSettingByCategory(category: 'backup', key: 'directory');
    if (backupDir.isEmpty) return;

    final lastBackup = _getLastBackupDate(backupDir);
    if (lastBackup == null) {
      backupDatabaseWithTimestamp(backupDir);
      return;
    }

    final backupFreq = 1;
    final now = DateTime.now();
    final difference = now.difference(lastBackup).inDays;

    if (difference >= backupFreq) {
      backupDatabaseWithTimestamp(backupDir);
    }
    cleanupOldBackups(backupDir);
  }

  //endregion

  //region import
  Future<String> importDatabase(String importedPath) async {
    try {
      final dbDir = await getDatabasesPath();
      final targetPath = join(dbDir, dbFileName);
      final tempPath = join(dbDir, 'temp_import.db');

      final currentDb = await database;
      final currentVersion = await _getUserVersion(currentDb);
      await currentDb.close();

      // 1️⃣ Validate imported version
      final importedDb = await openDatabase(importedPath, readOnly: true);
      final importedVersion = await _getUserVersion(importedDb);
      await importedDb.close();

      if (importedVersion > currentVersion) {
        throw Exception('Backup was created with a newer app version ($importedVersion)');
      }

      // 2️⃣ Copy to temp location first
      final tempFile = File(tempPath);
      if (await tempFile.exists()) {
        await tempFile.delete();
      }

      await File(importedPath).copy(tempPath);

      // 3️⃣ Open temp DB with proper version (this triggers migrations)
      final migratedDb = await _openDb(tempPath);
      await migratedDb.close();

      // 4️⃣ Replace live DB only AFTER successful migration
      final targetFile = File(targetPath);
      if (await targetFile.exists()) {
        await targetFile.delete();
      }

      await File(tempPath).rename(targetPath);

      // 5️⃣ Reopen normally
      _database = await _openDb(targetPath);

      return 'Database imported and migrated successfully';
    } catch (e) {
      return 'Failed to import database: $e';
    }
  }

  Future<int> _getUserVersion(Database db) async {
    final result = await db.rawQuery('PRAGMA user_version;');
    return result.first.values.first as int;
  }

  //endregion
}

import 'dart:io';

import 'package:fossfit/app/utils/constants.dart';
import 'package:fossfit/db/database_migrations.dart';
import 'package:fossfit/db/db_constants.dart';
import 'package:fossfit/db/repositories/config_reposity.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;
  static const dbFileName = 'fossfit.db';
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
        CREATE TABLE exercises(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          type INTEGER NOT NULL DEFAULT 1,
          category TEXT,
          description TEXT,
          image BLOB,
          default_sets INTEGER NOT NULL DEFAULT 3,
          default_unit TEXT NOT NULL DEFAULT 'kg',
          created INTEGER NOT NULL DEFAULT (unixepoch('subsecond') * 1000) 
        )
      ''');

    await db.execute('''
        CREATE TABLE sets(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          reps INTEGER NOT NULL DEFAULT 0,
          weight REAL NOT NULL DEFAULT 0.0,
          unit TEXT,
          note TEXT,
          body_weight REAL,
          exercise_id INTEGER NOT NULL,
          plan_id INTEGER,
          created INTEGER NOT NULL DEFAULT (unixepoch('subsecond') * 1000),
          FOREIGN KEY (exercise_id) REFERENCES exercises(id)       
          )
      ''');

    await db.execute('''
        CREATE INDEX sets_exercise_id_created
        ON sets(exercise_id, created);
      ''');

    await db.execute('''
        CREATE TABLE cardio(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          duration INTEGER NOT NULL DEFAULT 0,
          distance REAL NOT NULL DEFAULT 0.0,
          distance_unit TEXT NOT NULL DEFAULT 'km',
          incline REAL,
          pace REAL,
          note TEXT,
          exercise_id INTEGER NOT NULL,
          plan_id INTEGER,
          created INTEGER NOT NULL DEFAULT (unixepoch('subsecond') * 1000),
          FOREIGN KEY (exercise_id) REFERENCES exercises(id)       
          )
      ''');
    await db.execute('''
        CREATE INDEX cardio_exercise_id_created
        ON cardio(exercise_id, created);
      ''');
    await db.execute('''
      CREATE TABLE plans(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT,
          days TEXT,
          sequence INTEGER,
          created INTEGER NOT NULL DEFAULT (unixepoch('subsecond') * 1000)
      )
      ''');

    await db.execute('''
      CREATE TABLE plan_exercises (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        plan_id INTEGER NOT NULL,
        exercise_id INTEGER NOT NULL,
        sequence INTEGER,
        max_sets INTEGER,
        created INTEGER NOT NULL DEFAULT (unixepoch('subsecond') * 1000),
        FOREIGN KEY(exercise_id) REFERENCES exercises(id),
        FOREIGN KEY(plan_id) REFERENCES plans(id),
        UNIQUE(plan_id, exercise_id)
      );
      ''');

    await db.execute('''
        CREATE TABLE config(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          category TEXT,
          key TEXT,
          value TEXT
        )
      ''');

    await _defaultSettings(db);
    await _defaultExercises(db);
    await _defaultPlans(db);
    await _runMigrations(db, 0, version);
  }

  final migrations = <int, Future<void> Function(Database)>{
    //2: migrateToV2,
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
    await _database!.execute('PRAGMA foreign_keys = OFF');
    await _database!.transaction(((txn) async {
      await txn.execute('DELETE FROM sets;');
      await txn.execute('DELETE FROM plans;');
      await txn.execute('DELETE FROM plan_exercises;');
      await txn.execute('DELETE FROM exercises;');
      await txn.execute('DELETE FROM config;');
    }));
    await _database!.execute('PRAGMA foreign_keys = ON');
    await _defaultSettings(_database!);
    await _defaultExercises(_database!);
  }

  Future<void> _defaultSettings(Database db) async {
    await db.execute('''
      INSERT INTO config (category, "key", value) VALUES
          ('formats','font','Lato'),
          ('formats','font_size','14'),
          ('formats','short_date_format','d/M/yy'),
          ('formats','long_date_format','EEE, dd.MM.yyyy H:mm a'),
          ('formats','start_of_week','monday'),
          ('appearance','haptics','1'),
          ('appearance','theme','system'),
          ('appearance','system_colours','1'),
          ('appearance','color','4281559659'),
          ('appearance','curve_lines','1'),
          ('appearance','curve_smoothness','0.1'),
          ('tabs','tabs','Strength,Plans,Cardio,Exercises,Calendar'),
          ('backup','backup','0'),
          ('backup','frequency','14'),
          ('backup','directory',''),
          ('workouts','group_history','1'),
          ('workouts','show_units','1'),
          ('workouts','show_categories','1'),
          ('workouts','show_notes','1'),
          ('workouts','show_bodyweight','1'),
          ('workouts','show_stats','1'),
          ('workouts','show_images','1'),          
          ('timers','enabled','0'),
          ('timers','vibrate','0'),
          ('timers','enable_sound','0'),
          ('timers','alarm_sound','');
          ''');
  }

  Future<void> _defaultExercises(Database db) async {
    await db.transaction((txn) async {
      final batch = txn.batch();

      for (final exercise in defaultStrengthExercises) {
        batch.insert('exercises', {'name': exercise.$1, 'category': exercise.$2, 'type': exercise.$3});
      }

      await batch.commit(noResult: true);
    });
    await db.transaction((txn) async {
      final batch = txn.batch();

      for (final exercise in defaultCardioExercises) {
        batch.insert('exercises', {'name': exercise.$1, 'type': exercise.$2, 'default_unit': 'km'});
      }

      await batch.commit(noResult: true);
    });
  }

  Future<void> _defaultPlans(Database db) async {
    await db.transaction((txn) async {
      txn.execute('''
          INSERT INTO plans (name,days,sequence) VALUES
          ('Chest', 'monday',0),
          ('Back', 'wednesday',1),
          ('Legs', 'friday',2)
      ''');

      await txn.execute('''
          INSERT INTO plan_exercises (
            plan_id,
            exercise_id,
            sequence,
            max_sets
          )
          SELECT
            plan_id,
            exercise_id,
            sequence,
            max_sets
          FROM (
            SELECT
              p.id AS plan_id,
              e.id AS exercise_id,
              ROW_NUMBER() OVER (
                PARTITION BY p.id
                ORDER BY RANDOM()
              ) AS sequence,
              e.default_sets AS max_sets
            FROM plans p
            JOIN exercises e
              ON e.category = p.name
          )
          WHERE sequence <= 5;
        ''');
    });
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

    final files = dir.listSync().whereType<File>().where((f) => basename(f.path).startsWith('${backupPrefix}_') && f.path.endsWith('.db')).toList();

    if (files.isEmpty) return null;

    files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));

    return files.first.statSync().modified;
  }

  Future<void> checkBackup(ConfigRepository repo) async {
    final backup = repo.getSetting(.backup, 'backup');
    if (backup.isEmpty || backup == '0') return;

    final backupDir = repo.getSetting(.backup, 'directory');
    if (backupDir.isEmpty) return;

    final lastBackup = _getLastBackupDate(backupDir);
    if (lastBackup == null) {
      backupDatabaseWithTimestamp(backupDir);
      return;
    }

    final backupFreq = int.tryParse(repo.getSetting(.backup, 'frequency')) ?? 14;
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
    var isSqlite = importedPath.endsWith('sqlite');
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

      ///old flexify db. Reset version to allow migrations
      if (!isSqlite && importedVersion > currentVersion) {
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
      if (isSqlite) {
        await migratedDb.execute('PRAGMA foreign_keys = OFF');
        await importSqliteFile(migratedDb);
        await migratedDb.execute('PRAGMA foreign_keys = ON');
        await migratedDb.execute('PRAGMA user_version = $kDatabaseSchemaVersion;');
        _defaultSettings(migratedDb);
      }
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

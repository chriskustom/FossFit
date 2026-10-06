import 'package:fossfit/app/utils/constants.dart';
import 'package:sqflite/sqflite.dart';

Future<void> importSqliteFile(Database db) async {
  await db.transaction((txn) async {
    await txn.execute('''
        CREATE TABLE exercises(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          category TEXT,
          description TEXT,
          image BLOB,
          default_sets INTEGER NOT NULL DEFAULT 3,
          default_unit TEXT NOT NULL DEFAULT 'kg',
          default_rest INTEGER,
          created INTEGER NOT NULL DEFAULT (unixepoch('subsecond') * 1000) 
        );
      ''');
    //Insert all existing user exercises from gym sets
    await txn.execute('''
    INSERT INTO exercises (name, category)
    SELECT
      gs.name,
      gs.category     
    FROM gym_sets gs
    WHERE gs.name <> 'Weight'
      AND gs.id IN (
        SELECT MIN(gs2.id)
        FROM gym_sets gs2
        WHERE gs2.name <> 'Weight'
        GROUP BY gs2.name
      );
  ''');
    //insert any unique exercises from plan exercsies
    await txn.execute('''
    INSERT INTO exercises (name, category, image)
    SELECT
      pe.exercise,
      NULL,
      NULL
    FROM plan_exercises pe
    WHERE NOT EXISTS (
        SELECT 1
        FROM exercises e
        WHERE e.name = pe.exercise
      )
    GROUP BY pe.exercise;
  ''');
    //if nothing exists, populate with defaults
    final exerciseCount = Sqflite.firstIntValue(await txn.rawQuery('SELECT COUNT(*) FROM exercises')) ?? 0;

    if (exerciseCount == 0) {
      final batch = txn.batch();

      for (final exercise in defaultExercises) {
        batch.insert('exercises', {'name': exercise.$1, 'category': exercise.$2});
      }

      await batch.commit(noResult: true);
    }
    await txn.execute('''
        CREATE TABLE sets(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          reps INTEGER NOT NULL DEFAULT 0,
          weight REAL NOT NULL DEFAULT 0.0,
          unit TEXT,
          note TEXT,
          rest INTEGER,
          body_weight REAL,
          exercise_id INTEGER NOT NULL,
          plan_id INTEGER,
          created INTEGER NOT NULL DEFAULT (unixepoch('subsecond') * 1000),
          FOREIGN KEY (exercise_id) REFERENCES exercises(id)       
          );
      ''');
    //insert existing gymsets into new gymsets with exercsie id
    await txn.execute('''
        INSERT INTO sets (
          id,
          reps,
          weight,
          unit,
          note,
          rest,
          body_weight,
          exercise_id,
          plan_id,
          created
        )
        SELECT
          gs.id,
          gs.reps,
          gs.weight,
          gs.unit,
          gs.notes,
          gs.rest_ms,
          gs.body_weight,
          e.id,
          gs.plan_id,
          gs.created * 1000
        FROM gym_sets gs
        INNER JOIN exercises e ON e.name = gs.name;
      ''');
    //drop, rename and index
    await txn.execute('DROP TABLE gym_sets;');
    //Plans
    await txn.execute('''
        CREATE INDEX sets_exercise_id_created
        ON sets(exercise_id, created);
      ''');

    await txn.execute('''
      CREATE TABLE plans_new(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT,
          days TEXT,
          sequence INTEGER,
          created INTEGER NOT NULL DEFAULT (unixepoch('subsecond') * 1000)
      );
      ''');
    await txn.execute('''
        INSERT INTO plans_new (
          id,
          name,
          days,
          sequence
        )
        SELECT
          p.id,
          p.title,
          p.days,
          p.sequence
        FROM plans p;
      ''');

    await txn.execute('DROP TABLE plans;');
    await txn.execute('ALTER TABLE plans_new RENAME TO plans;');

    //create new plan exercises table with exercise id
    await txn.execute('''
        CREATE TABLE plan_exercises_new (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        plan_id INTEGER NOT NULL,
        exercise_id INTEGER NOT NULL,
        sequence INTEGER,
        max_sets INTEGER,
        rest INTEGER,
        created INTEGER NOT NULL DEFAULT (unixepoch('subsecond') * 1000),
        FOREIGN KEY(exercise_id) REFERENCES exercises(id),
        FOREIGN KEY(plan_id) REFERENCES plans(id),
        UNIQUE(plan_id, exercise_id)
      );
      ''');
    //insert plan exercises into new table with exercise id
    await txn.execute('''
        INSERT INTO plan_exercises_new (
          id,
          plan_id,
          exercise_id,
          sequence,
          max_sets
        )
        SELECT
          pe.id,
          pe.plan_id,
          e.id,
          pe.sequence,
          COALESCE(CAST(pe.max_sets AS INTEGER), 3)
        FROM plan_exercises pe
        INNER JOIN exercises e ON e.name = pe.exercise
        WHERE pe.enabled;
      ''');
    //drop and rename
    await txn.execute('DROP TABLE plan_exercises;');
    await txn.execute('ALTER TABLE plan_exercises_new RENAME TO plan_exercises;');

    await txn.execute('''
        CREATE TABLE config(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          category TEXT,
          key TEXT,
          value TEXT
        )
      ''');
    await txn.execute('DROP TABLE settings;');
  });
}

Future<void> migrateToV2(Database db) async {
  await db.transaction((txn) async {
    await txn.execute('''
    INSERT INTO config (category, "key", value) VALUES
          ('timers','auto_start','0');
          ''');
  });
}

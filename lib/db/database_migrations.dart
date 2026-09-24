import 'package:fossfit/models/constants.dart';
import 'package:sqflite/sqflite.dart';

///Drop settings, re-create settings as key value
///Create exercises table and link existing with table
Future<void> migrateToV2(Database db) async {
  await db.transaction((txn) async {
    await txn.execute('''
        ALTER TABLE settings RENAME TO settings_old;
    ''');
    await txn.execute('''
        CREATE TABLE settings (
          category TEXT NOT NULL,
          key TEXT NOT NULL,
          value TEXT,
          PRIMARY KEY (category, key)
        );
    ''');
    await txn.execute('''
  INSERT INTO settings (category, key, value)      
    SELECT 'appearance', 'theme_mode', COALESCE(CAST(theme_mode AS TEXT), '') FROM settings_old
    UNION ALL
    SELECT 'appearance', 'system_colors', COALESCE(CAST(system_colors AS TEXT), '') FROM settings_old
    UNION ALL
    SELECT 'appearance', 'show_images', COALESCE(CAST(show_images AS TEXT), '') FROM settings_old
    UNION ALL
    SELECT 'appearance', 'show_global_progress', COALESCE(CAST(show_global_progress AS TEXT), '') FROM settings_old
    UNION ALL
    SELECT 'appearance', 'stats_panel', COALESCE(CAST(stats_panel AS TEXT), '') FROM settings_old
    UNION ALL
    SELECT 'appearance', 'peek_graph', COALESCE(CAST(peek_graph AS TEXT), '') FROM settings_old
    UNION ALL
    SELECT 'appearance', 'curve_lines', COALESCE(CAST(curve_lines AS TEXT), '') FROM settings_old
    UNION ALL
    SELECT 'appearance', 'curve_smoothness', COALESCE(CAST(curve_smoothness AS TEXT), '') FROM settings_old

    UNION ALL
    SELECT 'data', 'automatic_backups', COALESCE(CAST(automatic_backups AS TEXT), '') FROM settings_old
    UNION ALL
    SELECT 'data', 'backup_path', COALESCE(CAST(backup_path AS TEXT), '') FROM settings_old

    UNION ALL
    SELECT 'formats', 'strength_unit', COALESCE(CAST(strength_unit AS TEXT), '') FROM settings_old
    UNION ALL
    SELECT 'formats', 'cardio_unit', COALESCE(CAST(cardio_unit AS TEXT), '') FROM settings_old
    UNION ALL
    SELECT 'formats', 'long_date_format', COALESCE(CAST(long_date_format AS TEXT), '') FROM settings_old
    UNION ALL
    SELECT 'formats', 'short_date_format', COALESCE(CAST(short_date_format AS TEXT), '') FROM settings_old

    UNION ALL
    SELECT 'plans', 'warmup_sets', COALESCE(CAST(warmup_sets AS TEXT), '') FROM settings_old
    UNION ALL
    SELECT 'plans', 'max_sets', COALESCE(CAST(max_sets AS TEXT), '') FROM settings_old
    UNION ALL
    SELECT 'plans', 'plan_trailing', COALESCE(CAST(plan_trailing AS TEXT), '') FROM settings_old

    UNION ALL
    SELECT 'tabs', 'tabs', COALESCE(CAST(tabs AS TEXT), '') FROM settings_old
    UNION ALL
    SELECT 'tabs', 'scrollable_tabs', COALESCE(CAST(scrollable_tabs AS TEXT), '') FROM settings_old

    UNION ALL
    SELECT 'timers', 'rest_timers', COALESCE(CAST(rest_timers AS TEXT), '') FROM settings_old
    UNION ALL
    SELECT 'timers', 'vibrate', COALESCE(CAST(vibrate AS TEXT), '') FROM settings_old
    UNION ALL
    SELECT 'timers', 'enable_sound', COALESCE(CAST(enable_sound AS TEXT), '') FROM settings_old
    UNION ALL
    SELECT 'timers', 'timer_duration', COALESCE(CAST(timer_duration AS TEXT), '') FROM settings_old
    UNION ALL
    SELECT 'timers', 'alarm_sound', COALESCE(CAST(alarm_sound AS TEXT), '') FROM settings_old

    UNION ALL
    SELECT 'workouts', 'group_history', COALESCE(CAST(group_history AS TEXT), '') FROM settings_old
    UNION ALL
    SELECT 'workouts', 'show_units', COALESCE(CAST(show_units AS TEXT), '') FROM settings_old
    UNION ALL
    SELECT 'workouts', 'show_body_weight', COALESCE(CAST(show_body_weight AS TEXT), '') FROM settings_old
    UNION ALL
    SELECT 'workouts', 'show_categories', COALESCE(CAST(show_categories AS TEXT), '') FROM settings_old
    UNION ALL
    SELECT 'workouts', 'show_notes', COALESCE(CAST(show_notes AS TEXT), '') FROM settings_old
    UNION ALL
    SELECT 'workouts', 'notifications', COALESCE(CAST(notifications AS TEXT), '') FROM settings_old
    UNION ALL
    SELECT 'workouts', 'rep_estimation', COALESCE(CAST(rep_estimation AS TEXT), '') FROM settings_old
    UNION ALL
    SELECT 'workouts', 'duration_estimation', COALESCE(CAST(duration_estimation AS TEXT), '') FROM settings_old

    UNION ALL
    SELECT 'system', 'explained_permissions', COALESCE(CAST(explained_permissions AS TEXT), '') FROM settings_old;
''');

    await txn.execute('DROP TABLE settings_old');
  });
  await db.transaction((txn) async {
    //Create exercises table
    await txn.execute('''
    CREATE TABLE exercises (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL UNIQUE,
      cardio INTEGER NOT NULL CHECK (cardio IN (0, 1)),
      category TEXT NULL,
      image TEXT NULL
    );
  ''');
    //insert 'Weight' as a default
    await txn.execute('''
    INSERT INTO exercises (name, cardio, category, image)
    VALUES ('Weight', 0, NULL, NULL);
  ''');
    //Insert all existing user exercises from gym sets
    await txn.execute('''
    INSERT INTO exercises (name, cardio, category, image)
    SELECT
      gs.name,
      gs.cardio,
      gs.category,
      gs.image
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
    INSERT INTO exercises (name, cardio, category, image)
    SELECT
      pe.exercise,
      0,
      NULL,
      NULL
    FROM plan_exercises pe
    WHERE pe.exercise <> 'Weight'
      AND NOT EXISTS (
        SELECT 1
        FROM exercises e
        WHERE e.name = pe.exercise
      )
    GROUP BY pe.exercise;
  ''');
    //if only weight exists in exercises, populate with defaults
    final exerciseCount = Sqflite.firstIntValue(
          await txn.rawQuery('SELECT COUNT(*) FROM exercises'),
        ) ??
        0;

    if (exerciseCount == 1) {
      final batch = txn.batch();

      for (final exercise in defaultExercises) {
        batch.insert('exercises', {
          'name': exercise.$1,
          'cardio': exercise.$2,
          'category': exercise.$3,
          'image': exercise.$4,
        });
      }

      await batch.commit(noResult: true);
    }
    //create new gymset with exercise_id
    await txn.execute('''
        CREATE TABLE gym_sets_new (
          id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
          body_weight REAL NOT NULL DEFAULT 0.0,
          created INTEGER NOT NULL,
          distance REAL NOT NULL DEFAULT 0.0,
          duration REAL NOT NULL DEFAULT 0.0,
          hidden INTEGER NOT NULL DEFAULT 0 CHECK (hidden IN (0, 1)),
          incline INTEGER NULL,
          exercise_id INTEGER NOT NULL,
          notes TEXT NULL,
          plan_id INTEGER NULL,
          reps REAL NOT NULL,
          rest_ms INTEGER NULL,
          unit TEXT NOT NULL,
          weight REAL NOT NULL,
          FOREIGN KEY (exercise_id) REFERENCES exercises(id)
        );
      ''');
    //insert existing gymsets into new gymsets with exercsie id
    await txn.execute('''
        INSERT INTO gym_sets_new (
          id,
          body_weight,
          created,
          distance,
          duration,
          hidden,
          incline,
          exercise_id,
          notes,
          plan_id,
          reps,
          rest_ms,
          unit,
          weight
        )
        SELECT
          gs.id,
          gs.body_weight,
          gs.created * 1000,
          gs.distance,
          gs.duration,
          gs.hidden,
          gs.incline,
          e.id,
          gs.notes,
          gs.plan_id,
          gs.reps,
          gs.rest_ms,
          gs.unit,
          gs.weight
        FROM gym_sets gs
        INNER JOIN exercises e ON e.name = gs.name;
      ''');
    //drop, rename and index
    await txn.execute('DROP TABLE gym_sets;');
    await txn.execute('ALTER TABLE gym_sets_new RENAME TO gym_sets;');
    await txn.execute('''
        CREATE INDEX gym_sets_exercise_id_created
        ON gym_sets(exercise_id, created);
      ''');

    //create new plan exercises table with exercise id
    await txn.execute('''
        CREATE TABLE plan_exercises_new (
          id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
          enabled INTEGER NOT NULL CHECK(enabled IN (0, 1)),
          timers INTEGER NOT NULL DEFAULT 1 CHECK(timers IN (0, 1)),
          max_sets INTEGER,
          plan_id INTEGER NOT NULL,
          warmup_sets INTEGER,
          sequence INTEGER NOT NULL DEFAULT 0,
          exercise_id INTEGER NOT NULL,
          FOREIGN KEY(exercise_id) REFERENCES exercises(id),
          FOREIGN KEY(plan_id) REFERENCES plans(id)
        );
      ''');
    //insert plan exercises into new table with exercise id
    await txn.execute('''
        INSERT INTO plan_exercises_new (
          id,
          enabled,
          timers,
          max_sets,
          plan_id,
          warmup_sets,
          sequence,
          exercise_id
        )
        SELECT
          pe.id,
          pe.enabled,
          pe.timers,
          pe.max_sets,
          pe.plan_id,
          pe.warmup_sets,
          pe.sequence,
          e.id
        FROM plan_exercises pe
        INNER JOIN exercises e ON e.name = pe.exercise;
      ''');
    //drop and rename
    await txn.execute('DROP TABLE plan_exercises;');
    await txn.execute(
      'ALTER TABLE plan_exercises_new RENAME TO plan_exercises;',
    );
  });
}

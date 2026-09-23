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
          SELECT 'appearance', 'theme_mode', CAST(theme_mode AS TEXT) FROM settings_old
          UNION ALL
          SELECT 'appearance', 'system_colors', CAST(system_colors AS TEXT) FROM settings_old
          UNION ALL
          SELECT 'appearance', 'show_images', CAST(show_images AS TEXT) FROM settings_old
          UNION ALL
          SELECT 'appearance', 'show_global_progress', CAST(show_global_progress AS TEXT) FROM settings_old
          UNION ALL
          SELECT 'appearance', 'stats_panel', CAST(stats_panel AS TEXT) FROM settings_old
          UNION ALL
          SELECT 'appearance', 'peek_graph', CAST(peek_graph AS TEXT) FROM settings_old
          UNION ALL
          SELECT 'appearance', 'curve_lines', CAST(curve_lines AS TEXT) FROM settings_old
          UNION ALL
          SELECT 'appearance', 'curve_smoothness', CAST(curve_smoothness AS TEXT) FROM settings_old

          UNION ALL
          SELECT 'data', 'automatic_backups', CAST(automatic_backups AS TEXT) FROM settings_old
          UNION ALL
          SELECT 'data', 'backup_path', CAST(backup_path AS TEXT) FROM settings_old

          UNION ALL
          SELECT 'formats', 'strength_unit', CAST(strength_unit AS TEXT) FROM settings_old
          UNION ALL
          SELECT 'formats', 'cardio_unit', CAST(cardio_unit AS TEXT) FROM settings_old
          UNION ALL
          SELECT 'formats', 'long_date_format', CAST(long_date_format AS TEXT) FROM settings_old
          UNION ALL
          SELECT 'formats', 'short_date_format', CAST(short_date_format AS TEXT) FROM settings_old

          UNION ALL
          SELECT 'plans', 'warmup_sets', CAST(warmup_sets AS TEXT) FROM settings_old
          UNION ALL
          SELECT 'plans', 'max_sets', CAST(max_sets AS TEXT) FROM settings_old
          UNION ALL
          SELECT 'plans', 'plan_trailing', CAST(plan_trailing AS TEXT) FROM settings_old

          UNION ALL
          SELECT 'tabs', 'tabs', CAST(tabs AS TEXT) FROM settings_old
          UNION ALL
          SELECT 'tabs', 'scrollable_tabs', CAST(scrollable_tabs AS TEXT) FROM settings_old

          UNION ALL
          SELECT 'timers', 'rest_timers', CAST(rest_timers AS TEXT) FROM settings_old
          UNION ALL
          SELECT 'timers', 'vibrate', CAST(vibrate AS TEXT) FROM settings_old
          UNION ALL
          SELECT 'timers', 'enable_sound', CAST(enable_sound AS TEXT) FROM settings_old
          UNION ALL
          SELECT 'timers', 'timer_duration', CAST(timer_duration AS TEXT) FROM settings_old
          UNION ALL
          SELECT 'timers', 'alarm_sound', CAST(alarm_sound AS TEXT) FROM settings_old

          UNION ALL
          SELECT 'workouts', 'group_history', CAST(group_history AS TEXT) FROM settings_old
          UNION ALL
          SELECT 'workouts', 'show_units', CAST(show_units AS TEXT) FROM settings_old
          UNION ALL
          SELECT 'workouts', 'show_body_weight', CAST(show_body_weight AS TEXT) FROM settings_old
          UNION ALL
          SELECT 'workouts', 'show_categories', CAST(show_categories AS TEXT) FROM settings_old
          UNION ALL
          SELECT 'workouts', 'show_notes', CAST(show_notes AS TEXT) FROM settings_old
          UNION ALL
          SELECT 'workouts', 'notifications', CAST(notifications AS TEXT) FROM settings_old
          UNION ALL
          SELECT 'workouts', 'rep_estimation', CAST(rep_estimation AS TEXT) FROM settings_old
          UNION ALL
          SELECT 'workouts', 'duration_estimation', CAST(duration_estimation AS TEXT) FROM settings_old

          UNION ALL
          SELECT 'system', 'explained_permissions', CAST(explained_permissions AS TEXT) FROM settings_old;

    ''');
    await txn.execute('DROP TABLE settings_old');
  });
  await db.transaction((txn) async {
// 1. Create the new exercises table.
    await txn.execute('''
    CREATE TABLE exercises (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL UNIQUE,
      cardio INTEGER NOT NULL CHECK (cardio IN (0, 1)),
      category TEXT NULL,
      image TEXT NULL
    );
  ''');

    // 2. Insert the special "Weight" exercise first.
    await txn.execute('''
    INSERT INTO exercises (name, cardio, category, image)
    VALUES ('Weight', 0, NULL, NULL);
  ''');

    // 3. Populate exercises from gym_sets.
    // DISTINCT names are guaranteed by the UNIQUE constraint.
    // Exclude "Weight" because it already exists.
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

    // 4. Add exercises which only exist in plan_exercises.
    // Only insert names that don't already exist in exercises.
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

    // 4. Rebuild gym_sets with exercise_id instead of name/category.
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
          gs.created,
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

    await txn.execute('DROP TABLE gym_sets;');
    await txn.execute('ALTER TABLE gym_sets_new RENAME TO gym_sets;');

    // 5. Recreate the gym_sets index, now that name no longer exists.
    await txn.execute('''
        CREATE INDEX gym_sets_exercise_id_created
        ON gym_sets(exercise_id, created);
      ''');

    // 6. Rebuild plan_exercises without exercise.
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

    await txn.execute('DROP TABLE plan_exercises;');
    await txn.execute(
      'ALTER TABLE plan_exercises_new RENAME TO plan_exercises;',
    );
  });
}

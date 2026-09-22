import 'package:sqflite/sqflite.dart';

///Drop settings, re-create settings as key value
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
}

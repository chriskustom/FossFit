import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:fossfit/app/app.dart';
import 'package:fossfit/db/database_helper.dart';
import 'package:fossfit/db/failed_migrations_page.dart';
import 'package:fossfit/db/repositories/exercise_repository.dart';
import 'package:fossfit/db/repositories/gym_sets_repository.dart';
import 'package:fossfit/db/repositories/plan_exercises_repository.dart';
import 'package:fossfit/db/repositories/plans_repository.dart';
import 'package:fossfit/db/repositories/settings_repository.dart';
import 'package:fossfit/timer/timer_state.dart';
import 'package:platform_detail/platform_detail.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

final rootScaffoldMessenger = GlobalKey<ScaffoldMessengerState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb || PlatformDetail.isDesktop) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  tz.initializeTimeZones();

  try {
    final timezoneInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(
      tz.getLocation(timezoneInfo.identifier),
    );
  } catch (_) {
    tz.setLocalLocation(
      tz.getLocation('UTC'),
    );
  }

  final dbHelper = DatabaseHelper();
  final db = await dbHelper.database;

  final settingsRepo = SettingsRepository(db);

  try {
    await settingsRepo.loadAll();
  } catch (error) {
    runApp(
      FailedMigrationsPage(error: error),
    );
    return;
  }

  await dbHelper.checkBackup(settingsRepo);

  runApp(
    appProviders(
      db,
      settingsRepo,
    ),
  );
}

final MethodChannel androidChannel = const MethodChannel(
  'com.kustom.fossfit/android',
);

Widget appProviders(
  Database db,
  SettingsRepository repo,
) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<ExercisesRepository>(
        create: (_) => ExercisesRepository(db)..loadAll(),
      ),
      ChangeNotifierProvider<GymSetsRepository>(
        create: (_) => GymSetsRepository(db)..loadAll(),
      ),
      ChangeNotifierProvider<PlansRepository>(
        create: (_) => PlansRepository(db)..loadAll(),
      ),
      ChangeNotifierProvider<PlanExercisesRepository>(
        create: (_) => PlanExercisesRepository(db)..loadAll(),
      ),
      ChangeNotifierProvider<SettingsRepository>.value(
        value: repo,
      ),
      ChangeNotifierProvider<TimerState>(
        create: (_) => TimerState(),
      ),
    ],
    child: const App(),
  );
}

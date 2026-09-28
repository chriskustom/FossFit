//import 'package:ettanotes/services/app_lock/app_lock_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:fossfit/app/features/search/global_search_controller.dart';
import 'package:fossfit/app/services/notifications/notification_service_desktop.dart';
import 'package:fossfit/app/shell/app.dart';
import 'package:fossfit/db/database_helper.dart';
import 'package:fossfit/db/repositories/config_reposity.dart';
import 'package:fossfit/db/repositories/exercise_repository.dart';
import 'package:fossfit/db/repositories/gymsets_repository.dart';
import 'package:fossfit/db/repositories/plan_exercises_repository.dart';
import 'package:fossfit/db/repositories/plan_repository.dart';
import 'package:platform_detail/platform_detail.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

Future main() async {
  if (kIsWeb || PlatformDetail.isDesktop) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  try {
    final timezoneInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));
  } catch (_) {
    tz.setLocalLocation(tz.getLocation('UTC'));
  }

  final dbHelper = DatabaseHelper();
  final Database db = await dbHelper.database;
  final settingsRepo = ConfigRepository(db);
  await settingsRepo.loadAll();
  // Run backup
  await dbHelper.checkBackup(settingsRepo);

  await NotificationService.instance.init();

  if (!kIsWeb && !PlatformDetail.isDesktop) {
    await NotificationService.instance.restoreAllNotifications();
    await NotificationService.instance.getLaunchNotification();
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ExercisesRepository>(create: (_) => ExercisesRepository(db)..loadAll()),
        ChangeNotifierProvider<GymSetsRepository>(create: (_) => GymSetsRepository(db)..loadAll()),
        ChangeNotifierProvider<PlansRepository>(create: (_) => PlansRepository(db)..loadAll()),
        ChangeNotifierProvider<PlanExercisesRepository>(create: (_) => PlanExercisesRepository(db)..loadAll()),
        ChangeNotifierProvider<ConfigRepository>.value(value: settingsRepo),
        ChangeNotifierProvider(create: (_) => GlobalSearchController()),
      ],
      child: App(),
    ),
  );
}

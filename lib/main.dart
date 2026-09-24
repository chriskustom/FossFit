import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:fossfit/db/database_helper.dart';
import 'package:fossfit/db/failed_migrations_page.dart';
import 'package:fossfit/db/repositories/exercise_repository.dart';
import 'package:fossfit/db/repositories/gym_sets_repository.dart';
import 'package:fossfit/db/repositories/plan_exercises_repository.dart';
import 'package:fossfit/db/repositories/plans_repository.dart';
import 'package:fossfit/db/repositories/settings_repository.dart';
import 'package:fossfit/home_page.dart';
import 'package:fossfit/models/constants.dart';
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

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsRepo = context.watch<SettingsRepository>();

    final light = ColorScheme.fromSeed(
      seedColor: Colors.deepPurple,
    );

    final dark = ColorScheme.fromSeed(
      seedColor: Colors.deepPurple,
      brightness: Brightness.dark,
    );

    final themeName = settingsRepo
            .getSettingByCategory(
              category: SettingCategory.appearance.name,
              key: 'theme_mode',
            )
            .isEmpty
        ? 'system'
        : settingsRepo.getSettingByCategory(
            category: SettingCategory.appearance.name,
            key: 'theme_mode',
          );

    final themeMode = ThemeMode.values.byName(
      themeName,
    );

    final dynamicColours = settingsRepo.isEnabledByCategory(
      category: SettingCategory.appearance,
      key: 'system_colors',
    );

    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        final brightness = MediaQuery.platformBrightnessOf(
          context,
        );

        final currentBrightness =
            themeMode == ThemeMode.dark || (themeMode == ThemeMode.system && brightness == Brightness.dark)
                ? Brightness.dark
                : Brightness.light;

        SystemChrome.setSystemUIOverlayStyle(
          SystemUiOverlayStyle(
            statusBarIconBrightness: currentBrightness == Brightness.dark ? Brightness.light : Brightness.dark,
            systemNavigationBarIconBrightness:
                currentBrightness == Brightness.dark ? Brightness.light : Brightness.dark,
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: Colors.transparent,
          ),
        );

        return MaterialApp(
          scaffoldMessengerKey: rootScaffoldMessenger,
          title: 'FossFit',
          theme: ThemeData(
            colorScheme: dynamicColours ? lightDynamic : light,
            fontFamily: 'Roboto',
            useMaterial3: true,
            inputDecorationTheme: const InputDecorationTheme(
              floatingLabelBehavior: FloatingLabelBehavior.always,
            ),
          ),
          darkTheme: ThemeData(
            colorScheme: dynamicColours ? darkDynamic : dark,
            fontFamily: 'Roboto',
            useMaterial3: true,
            inputDecorationTheme: const InputDecorationTheme(
              floatingLabelBehavior: FloatingLabelBehavior.always,
            ),
          ),
          themeMode: themeMode,
          home: const HomePage(),
        );
      },
    );
  }
}

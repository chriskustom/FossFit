import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fossfit/calendar/calendar_page.dart';
import 'package:fossfit/db/repositories/settings_repository.dart';
import 'package:fossfit/graph/graphs_page.dart';
import 'package:fossfit/models/constants.dart';
import 'package:fossfit/plan/plans_page.dart';
import 'package:fossfit/services/navigation_service.dart';
import 'package:fossfit/sets/workout_page.dart';
import 'package:fossfit/settings/settings_page.dart';
import 'package:fossfit/timer/timer_page.dart';
import 'package:fossfit/widgets/app_snack_bar.dart';
import 'package:provider/provider.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  @override
  void initState() {
    super.initState();
  }

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

        final currentBrightness = themeMode == ThemeMode.dark ||
                (themeMode == ThemeMode.system && brightness == Brightness.dark)
            ? Brightness.dark
            : Brightness.light;

        SystemChrome.setSystemUIOverlayStyle(
          SystemUiOverlayStyle(
            statusBarIconBrightness: currentBrightness == Brightness.dark
                ? Brightness.light
                : Brightness.dark,
            systemNavigationBarIconBrightness:
                currentBrightness == Brightness.dark
                    ? Brightness.light
                    : Brightness.dark,
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: Colors.transparent,
          ),
        );

        return FutureBuilder<void>(
          future: settingsRepo.loadAll(),
          builder: (ctx, snapshot) {
            // if (snapshot.connectionState != ConnectionState.done) {
            //   return const MaterialApp(
            //     home:
            //         Scaffold(body: Center(child: CircularProgressIndicator())),
            //   );
            // }
            return MaterialApp(
              navigatorKey: NavigationService.navigatorKey,
              scaffoldMessengerKey: AppSnackBar.messengerKey,
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
              home: WorkoutPage(),
              onGenerateRoute: (settings) {
                Widget page;
                final pageName = settings.name == '/' ? '/home' : settings.name;
                final navRoute = NavRoute.fromRoute(pageName);

                switch (navRoute) {
                  case NavRoute.workouts:
                    page = const WorkoutPage();
                    break;
                  case NavRoute.plans:
                    page = const PlansPage();
                    break;
                  case NavRoute.calendar:
                    page = const CalendarPage();
                    break;
                  case NavRoute.graphs:
                    page = const GraphsPage();
                    break;
                  case NavRoute.timer:
                    page = const TimerPage();
                    break;
                  case NavRoute.settings:
                    page = const SettingsPage();
                    break;
                }
                return PageRouteBuilder(
                  settings: settings,
                  transitionDuration: const Duration(milliseconds: 220),
                  reverseTransitionDuration: const Duration(
                    milliseconds: 180,
                  ),
                  pageBuilder: (context, animation, secondaryAnimation) => page,
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    return FadeTransition(
                      opacity: CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOut,
                      ),
                      child: child,
                    );
                  },
                );
              },
              supportedLocales: const [Locale('en')],
            );
          },
        );
      },
    );
  }
}

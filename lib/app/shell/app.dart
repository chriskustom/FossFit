import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:fossfit/app/features/calendar/calendar_page.dart';
import 'package:fossfit/app/features/exercises/exercises_page.dart';
import 'package:fossfit/app/features/plans/plans_page.dart';
import 'package:fossfit/app/features/workout/workout_page.dart';
import 'package:fossfit/app/services/navigation_service.dart';
import 'package:fossfit/app/settings/settings_page.dart';
import 'package:fossfit/app/theme/theme.dart';
import 'package:fossfit/app/utils/constants.dart';
import 'package:fossfit/app/widgets/app_snack_bar.dart';
import 'package:fossfit/db/repositories/config_reposity.dart';
import 'package:provider/provider.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return const _AppView();
  }
}

class _AppView extends StatelessWidget {
  const _AppView();

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        return Selector<ConfigRepository, _AppSettings>(
          selector: (_, repo) => _AppSettings(
            theme: repo.getSetting(.appearance, 'theme'),
            font: repo.getSetting(.formats, 'font'),
            fontSize: double.tryParse(repo.getSetting(.formats, 'font_size')) ?? 16,
            color: int.tryParse(repo.getSetting(.appearance, 'color')),
            systemColors: repo.isEnabled(.appearance, 'system_colours'),
          ),
          builder: (context, settings, _) {
            final mode = ThemeMode.values.byName(settings.theme.isEmpty ? 'system' : settings.theme);

            return MaterialApp(
              navigatorKey: NavigationService.navigatorKey,
              scaffoldMessengerKey: AppSnackBar.messengerKey,

              theme: AppTheme.light(
                fontFamily: settings.font,
                fontSize: settings.fontSize,
                seedColor: settings.color,
                sysColours: settings.systemColors,
                dynamic: lightDynamic,
              ),

              darkTheme: AppTheme.dark(
                fontFamily: settings.font,
                fontSize: settings.fontSize,
                seedColor: settings.color,
                sysColours: settings.systemColors,
                dynamic: darkDynamic,
              ),

              themeMode: mode,

              home: const WorkoutPage(),

              onGenerateRoute: (settings) {
                Widget page;

                final pageName = settings.name == '/' ? '/workout' : settings.name;

                final navRoute = NavRoute.fromRoute(pageName);

                switch (navRoute) {
                  case NavRoute.workout:
                    page = const WorkoutPage();
                    break;
                  case NavRoute.plans:
                    page = const PlansPage();
                    break;
                  case NavRoute.exercises:
                    page = const ExercisesPage();
                    break;
                  case NavRoute.calendar:
                    page = const CalendarPage();
                    break;
                  case NavRoute.settings:
                    page = const SettingsPage();
                    break;
                }

                return PageRouteBuilder(
                  settings: settings,
                  transitionDuration: const Duration(milliseconds: 220),
                  reverseTransitionDuration: const Duration(milliseconds: 180),
                  pageBuilder: (context, animation, secondaryAnimation) => page,
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    return FadeTransition(
                      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
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

class _AppSettings {
  final String theme;
  final String font;
  final double fontSize;
  final int? color;
  final bool systemColors;

  const _AppSettings({required this.theme, required this.font, required this.fontSize, required this.color, required this.systemColors});

  @override
  bool operator ==(Object other) {
    return other is _AppSettings &&
        other.theme == theme &&
        other.font == font &&
        other.fontSize == fontSize &&
        other.color == color &&
        other.systemColors == systemColors;
  }

  @override
  int get hashCode => Object.hash(theme, font, fontSize, color, systemColors);
}

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fossfit/app/services/navigation_service.dart';
import 'package:fossfit/app/theme/theme.dart';
import 'package:fossfit/app/utils/constants.dart';
import 'package:fossfit/app/widgets/app_snack_bar.dart';
import 'package:fossfit/db/repositories/config_reposity.dart';
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
    final settingsRepo = Provider.of<ConfigRepository>(context, listen: false);

    return FutureBuilder<void>(
      future: settingsRepo.loadAll(),
      builder: (ctx, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const MaterialApp(
            home: Scaffold(body: Center(child: CircularProgressIndicator())),
          );
        }

        return Consumer<ConfigRepository>(
          builder: (c, repo, _) {
            final mode = ThemeMode.values.byName(repo.getSetting(.appearance, 'theme').isEmpty ? 'system' : repo.getSetting(.appearance, 'theme'));
            final font = repo.getSetting(.formats, 'font');
            final fontSize = double.tryParse(repo.getSetting(.formats, 'font_size')) ?? 16;
            final seedColour = int.tryParse(repo.getSetting(.appearance, 'color'));
            final sysColours = repo.isEnabled(.appearance, 'system_colours');
            final home = repo.getSetting(.tabs, 'tabs').split(',').where((t) => !t.startsWith('.')).first.toLowerCase();
            return DynamicColorBuilder(
              builder: (lightDynamic, darkDynamic) {
                final currentBrightness = mode == .dark || (mode == .system && MediaQuery.of(context).platformBrightness == Brightness.dark)
                    ? Brightness.dark
                    : Brightness.light;

                SystemChrome.setSystemUIOverlayStyle(
                  SystemUiOverlayStyle(
                    statusBarIconBrightness: currentBrightness == Brightness.dark ? Brightness.light : Brightness.dark,
                    systemNavigationBarIconBrightness: currentBrightness == Brightness.dark ? Brightness.light : Brightness.dark,
                    statusBarColor: Colors.transparent,
                    systemNavigationBarColor: Colors.transparent,
                  ),
                );
                return MaterialApp(
                  navigatorKey: NavigationService.navigatorKey,
                  scaffoldMessengerKey: AppSnackBar.messengerKey,
                  theme: AppTheme.light(fontFamily: font, fontSize: fontSize, seedColor: seedColour, sysColours: sysColours, dynamic: lightDynamic),
                  darkTheme: AppTheme.dark(fontFamily: font, fontSize: fontSize, seedColor: seedColour, sysColours: sysColours, dynamic: darkDynamic),
                  themeMode: mode,
                  home: NavRoute.values.byName(home).page,
                  onGenerateRoute: (settings) {
                    Widget page;
                    final pageName = settings.name == '/' ? '/$home' : settings.name;
                    final navRoute = NavRoute.fromRoute(pageName, home);
                    page = navRoute.page;
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
      },
    );
  }
}

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:fossfit/db/repositories/exercise_repository.dart';
import 'package:fossfit/db/repositories/gym_sets_repository.dart';
import 'package:fossfit/db/repositories/plans_repository.dart';
import 'package:fossfit/db/repositories/settings_repository.dart';
import 'package:fossfit/models/constants.dart';
import 'package:fossfit/models/nav_page.dart';
import 'package:fossfit/utils/app_haptics.dart';
import 'package:provider/provider.dart';

ValueNotifier<int?> currentNoteId = ValueNotifier(null);
ValueNotifier<int?> currentNotebookId = ValueNotifier(null);
ValueNotifier<int?> currentListId = ValueNotifier(null);
ValueNotifier<int?> currentGoalId = ValueNotifier(null);

class AppShell extends StatefulWidget {
  final Widget body;
  final Widget? floatingActionButton;
  final bool showNavBar;
  final PreferredSizeWidget appBar;

  const AppShell({
    super.key,
    required this.body,
    required this.appBar,
    this.floatingActionButton,
    this.showNavBar = true,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  @override
  void dispose() {
    super.dispose();
  }

  //bool _locked = true;
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bottomNavPages = _getNavPages();

    final currentRoute = ModalRoute.of(context)?.settings.name;
    final selectedIndex = bottomNavPages.indexWhere(
      (p) => p.route == NavRoute.fromRoute(currentRoute),
    );

    return SafeArea(
      bottom: true,
      top: false,
      child: Stack(
        children: [
          Scaffold(
            appBar: widget.appBar,
            body: LayoutBuilder(
              builder: (context, constraints) {
                return ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context).copyWith(
                      dragDevices: {
                        PointerDeviceKind.mouse,
                        PointerDeviceKind.touch,
                        PointerDeviceKind.trackpad,
                      },
                    ),
                    child: widget.body,
                  ),
                );
              },
            ),
            floatingActionButton: widget.floatingActionButton,
            bottomNavigationBar: widget.showNavBar
                ? NavigationBar(
                    backgroundColor: colors.surface,
                    selectedIndex: selectedIndex >= 0 ? selectedIndex : 0,
                    onDestinationSelected: (index) {
                      AppHaptics.tap(context);
                      _navigateIfNeeded(bottomNavPages[index].route);
                    },
                    destinations: bottomNavPages.map((page) {
                      return NavigationDestination(
                        icon: Icon(page.icon),
                        label: page.label,
                      );
                    }).toList(),
                  )
                : null,
          ),
        ],
      ),
    );
  }

  void _navigateIfNeeded(NavRoute target) {
    final currentName = ModalRoute.of(context)?.settings.name;

    if (currentName == target.route) {
      Navigator.of(context).maybePop();
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (target == NavRoute.workouts) {
        // Clear stack and go home
        Navigator.of(context).pushNamedAndRemoveUntil(
          target.route,
          (route) => false, // remove all previous routes
        );
      } else {
        Navigator.of(context).pushNamed(target.route);
      }
    });
  }

  List<NavPage> _getNavPages() {
    final gymSets = context.watch<GymSetsRepository>().gymsets;
    final plans = context.watch<PlansRepository>().plans;
    final exercises = context.watch<ExercisesRepository>().exercises;
    final config = context.watch<SettingsRepository>();
    final pageOrder = config.getSetting(key: 'tabs').split(',');

    final allPages = <String, NavPage>{
      'WorkoutPage': NavPage(
        route: NavRoute.workouts,
        label: 'Workouts',
        icon: Icons.fitness_center,
        items: gymSets,
        enabled: pageOrder.contains('WorkoutPage'),
      ),
      'PlansPage': NavPage(
        route: NavRoute.plans,
        label: 'Plans',
        icon: Icons.calendar_today_rounded,
        items: plans,
        enabled: pageOrder.contains('PlansPage'),
      ),
      'CalendarPage': NavPage(
        route: NavRoute.calendar,
        label: 'Calendar',
        icon: Icons.calendar_month_rounded,
        items: gymSets,
        enabled: pageOrder.contains('CalendarPage'),
      ),
      'GraphsPage': NavPage(
        route: NavRoute.graphs,
        label: 'Graphs',
        icon: Icons.insights_rounded,
        items: exercises,
        enabled: pageOrder.contains('GraphsPage'),
      ),
      'TimerPage': NavPage(
        route: NavRoute.timer,
        label: 'Timer',
        icon: Icons.timer_rounded,
        items: exercises,
        enabled: pageOrder.contains('TimerPage'),
      ),
      'SettingsPage': NavPage(
        route: NavRoute.settings,
        label: 'Settings',
        icon: Icons.settings_rounded,
        items: exercises,
        enabled: pageOrder.contains('SettingsPage'),
      ),
    };

    final orderedPages =
        pageOrder.map((k) => allPages[k]).whereType<NavPage>().toList();

    return orderedPages.where((p) => p.enabled).toList();
  }
}

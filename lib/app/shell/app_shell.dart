import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:fossfit/app/features/search/global_search_controller.dart';
import 'package:fossfit/app/features/search/search_results_page.dart';
import 'package:fossfit/app/services/app_services.dart';
import 'package:fossfit/app/services/notifications/notification_service_mobile.dart';
import 'package:fossfit/app/utils/constants.dart';
import 'package:fossfit/app/utils/nav_page.dart';
import 'package:fossfit/app/widgets/kustom_app_bar.dart';
import 'package:fossfit/db/repositories/config_reposity.dart';
import 'package:provider/provider.dart';

ValueNotifier<int?> currentSetId = ValueNotifier(null);
ValueNotifier<int?> currentPlanId = ValueNotifier(null);
ValueNotifier<int?> currentExerciseId = ValueNotifier(null);

class AppShell extends StatefulWidget {
  final String title;
  final Widget body;
  final Widget? floatingActionButton;
  final List<Object>? actions;
  final Widget? sorting;
  final List<IconButton>? selectActions;
  final bool showSearch;
  final bool showNavBar;

  const AppShell({super.key, required this.title, required this.body, this.floatingActionButton, this.actions, this.sorting, this.selectActions, this.showSearch = true, this.showNavBar = true});

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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _handleLaunchNavigation();
    });
  }

  Future<void> _handleLaunchNavigation() async {
    if (NotificationService.instance.launchNotification != null) {
      await NotificationService.instance.handleLaunchNotification();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final currentRoute = ModalRoute.of(context)?.settings.name;

    return SafeArea(
      bottom: true,
      top: false,
      child: Stack(
        children: [
          Scaffold(
            appBar: KustomAppBar(title: widget.title, actions: widget.actions, sorting: widget.sorting, selectActions: widget.selectActions, showSearch: widget.showSearch),
            body: LayoutBuilder(
              builder: (context, constraints) {
                return ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context).copyWith(dragDevices: {PointerDeviceKind.mouse, PointerDeviceKind.touch, PointerDeviceKind.trackpad}),
                    child: widget.body,
                  ),
                );
              },
            ),
            floatingActionButton: widget.floatingActionButton,
            bottomNavigationBar: widget.showNavBar ? _buildNavigationBar(context, colors) : null,
          ),
          Consumer<GlobalSearchController>(
            builder: (context, ctrl, _) {
              if (!ctrl.overlayVisible) return SizedBox.shrink();

              final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight;

              return Positioned(
                top: topPadding,
                left: 0,
                right: 0,
                bottom: 0,
                child: Material(
                  color: Colors.black.withValues(alpha: 0.5),
                  child: GestureDetector(
                    onTap: AppHaptics.tapWithHaptics(context, ctrl.hideOverlay),
                    child: SearchResultsPage(
                      results: ctrl.results,
                      onItemTap: () {
                        ctrl.hideOverlay();
                      },
                      initialFilter: currentRoute,
                    ),
                  ),
                ),
              );
            },
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
      if (target == NavRoute.workout) {
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

  // void _openSettings() {
  //   Navigator.of(context).maybePop();
  //   WidgetsBinding.instance.addPostFrameCallback((_) {
  //     Navigator.push(context, FadeRoute(page: const SettingsPage()));
  //   });
  // }

  Widget _buildNavigationBar(BuildContext context, ColorScheme colors) {
    return Selector<ConfigRepository, String>(
      selector: (_, config) => config.getSetting(.tabs, 'tabs'),
      builder: (context, tabs, _) {
        final pageOrder = tabs.split(',').where((t) => !t.startsWith('.'));

        final allPages = <String, NavPage>{
          'Plans': NavPage(route: NavRoute.plans, label: 'Plans', icon: Icons.format_list_numbered, enabled: pageOrder.contains('Plans')),
          'Calendar': NavPage(route: NavRoute.calendar, label: 'Calendar', icon: Icons.calendar_month_rounded, enabled: pageOrder.contains('Calendar')),
          'Exercises': NavPage(route: NavRoute.exercises, label: 'Exercises', icon: Icons.list_alt_rounded, enabled: pageOrder.contains('Exercises')),
          'Timer': NavPage(route: NavRoute.timer, label: 'Timer', icon: Icons.timer_rounded, enabled: pageOrder.contains('Timer')),
        };

        final orderedPages = pageOrder.map((k) => allPages[k]).whereType<NavPage>().toList();

        final bottomNavPages = [NavPage(route: NavRoute.workout, label: 'Workout', icon: Icons.fitness_center_rounded, enabled: true), ...orderedPages];

        final currentRoute = ModalRoute.of(context)?.settings.name;
        final selectedIndex = bottomNavPages.indexWhere((p) => p.route == NavRoute.fromRoute(currentRoute));

        return NavigationBar(
          backgroundColor: colors.surface,
          selectedIndex: selectedIndex >= 0 ? selectedIndex : 0,
          onDestinationSelected: (index) {
            AppHaptics.tap(context);
            _navigateIfNeeded(bottomNavPages[index].route);
          },
          destinations: bottomNavPages.map((page) {
            return NavigationDestination(icon: Icon(page.icon), label: page.label);
          }).toList(),
        );
      },
    );
  }
}

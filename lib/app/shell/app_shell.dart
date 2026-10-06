import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:fossfit/app/services/app_services.dart';
import 'package:fossfit/app/utils/constants.dart';
import 'package:fossfit/app/widgets/countdown_timer.dart';
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
  final bool showTimer;

  const AppShell({
    super.key,
    required this.title,
    required this.body,
    this.floatingActionButton,
    this.actions,
    this.sorting,
    this.selectActions,
    this.showSearch = true,
    this.showNavBar = true,
    this.showTimer = true,
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

    return SafeArea(
      bottom: true,
      top: false,
      child: Stack(
        children: [
          Scaffold(
            appBar: KustomAppBar(
              title: widget.title,
              actions: widget.actions,
              sorting: widget.sorting,
              selectActions: widget.selectActions,
              showSearch: widget.showSearch,
            ),
            body: LayoutBuilder(
              builder: (context, constraints) {
                return ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context).copyWith(
                      dragDevices: {PointerDeviceKind.mouse, PointerDeviceKind.touch, PointerDeviceKind.trackpad},
                    ),
                    child: widget.body,
                  ),
                );
              },
            ),
            resizeToAvoidBottomInset: false, // Android keyboard optimization
            floatingActionButton: widget.floatingActionButton,
            bottomNavigationBar: Column(
              mainAxisSize: MainAxisSize.min,
              children: [_buildTimer(), widget.showNavBar ? _buildNavigationBar(context, colors) : SizedBox.shrink()],
            ),
          ),
        ],
      ),
    );
  }

  void _navigateIfNeeded(NavRoute target, NavRoute home) {
    final currentName = ModalRoute.of(context)?.settings.name;
    final normalizedName = currentName == '/' ? home.route : currentName;

    if (normalizedName == target.route) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;

      Navigator.of(context).pushNamedAndRemoveUntil(target.route, (route) {
        final routeName = route.settings.name;
        return routeName == '/' || routeName == home.route;
      });
    });
  }

  Widget _buildTimer() {
    return Padding(padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8), child: CountdownTimer());
  }

  Widget _buildNavigationBar(BuildContext context, ColorScheme colors) {
    return Selector<ConfigRepository, String>(
      selector: (_, config) => config.getSetting(.tabs, 'tabs'),
      builder: (context, tabs, _) {
        final routes = tabs.split(',').map((page) => NavRoute.values.byName(page.toLowerCase())).toList();

        final currentRoute = ModalRoute.of(context)?.settings.name;
        final selectedIndex = routes.indexWhere((page) => page == NavRoute.fromRoute(currentRoute));
        if (routes.length == 1) {
          final page = routes.first;

          return Container(
            height: 80,
            color: colors.surface,
            child: Center(
              child: InkWell(
                onTap: () {
                  AppHaptics.tap(context);
                  _navigateIfNeeded(page, page);
                },
                borderRadius: BorderRadius.circular(24),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(page.icon), Text(page.label)]),
                ),
              ),
            ),
          );
        }
        return NavigationBar(
          backgroundColor: colors.surface,
          selectedIndex: selectedIndex >= 0 ? selectedIndex : 0,
          onDestinationSelected: (index) {
            AppHaptics.tap(context);
            _navigateIfNeeded(routes[index], routes[0]);
          },
          destinations: routes.map((page) {
            return NavigationDestination(icon: Icon(page.icon), label: page.label);
          }).toList(),
        );
      },
    );
  }
}

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:fossfit/app/utils/constants.dart';
import 'package:fossfit/app/widgets/countdown_timer.dart';
import 'package:fossfit/app/widgets/kustom_app_bar.dart';
import 'package:fossfit/app/widgets/kustom_nav_bar.dart';

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

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
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
                    behavior: ScrollConfiguration.of(
                      context,
                    ).copyWith(dragDevices: {PointerDeviceKind.mouse, PointerDeviceKind.touch, PointerDeviceKind.trackpad}),
                    child: widget.body,
                  ),
                );
              },
            ),
            resizeToAvoidBottomInset: false,
            floatingActionButton: widget.floatingActionButton,
            bottomNavigationBar: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CountdownTimer(),
                widget.showNavBar ? KustomNavBar(onTap: (target, home) => _navigateIfNeeded(target, home)) : SizedBox.shrink(),
              ],
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
}

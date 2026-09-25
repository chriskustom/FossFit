import 'package:flutter/material.dart';
import 'package:fossfit/bottom_nav.dart';
import 'package:fossfit/calendar/calendar_page.dart';
import 'package:fossfit/db/repositories/settings_repository.dart';
import 'package:fossfit/graph/graphs_page.dart';
import 'package:fossfit/models/constants.dart';
import 'package:fossfit/plan/plans_page.dart';
import 'package:fossfit/sets/workout_page.dart';
import 'package:fossfit/settings/settings_page.dart';
import 'package:fossfit/timer/timer_page.dart';
import 'package:fossfit/timer/timer_progress_widgets.dart';
import 'package:fossfit/utils.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late final SettingsRepository settings;
  late TabController controller;

  List<String> tabs = [];

  @override
  void initState() {
    super.initState();

    settings = context.read<SettingsRepository>();

    tabs = _readTabs(settings);

    controller = _createController(
      tabs,
      initialIndex: 0,
    );

    settings.addListener(_onSettingsChanged);
  }

  TabController _createController(
    List<String> tabs, {
    required int initialIndex,
  }) {
    return TabController(
      length: tabs.length,
      vsync: this,
      initialIndex: tabs.isEmpty ? 0 : initialIndex.clamp(0, tabs.length - 1),
    );
  }

  List<String> _readTabs(SettingsRepository settings) {
    final value = settings.getSetting(
      key: 'tabs',
    );

    return value
        .split(',')
        .map((tab) => tab.trim())
        .where((tab) => tab.isNotEmpty)
        .toList();
  }

  void _onSettingsChanged() {
    if (!mounted) {
      return;
    }

    _reloadTabs();
  }

  void _reloadTabs() {
    final newTabs = _readTabs(settings);

    if (_sameTabs(tabs, newTabs)) {
      return;
    }

    final oldIndex = controller.index;
    final oldController = controller;

    tabs = newTabs;

    controller = _createController(
      tabs,
      initialIndex: oldIndex,
    );

    oldController.dispose();

    setState(() {});
  }

  bool _sameTabs(
    List<String> a,
    List<String> b,
  ) {
    if (a.length != b.length) {
      return false;
    }

    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }

    return true;
  }

  void hideTab(
    BuildContext context,
    String tab,
  ) {
    final old = settings.getSetting(
      key: 'tabs',
    );

    final currentTabs = old
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();

    if (currentTabs.length == 1) {
      toast("Can't hide everything!");
      return;
    }

    currentTabs.remove(tab);

    settings.setSetting(
      category: SettingCategory.tabs,
      key: 'tabs',
      value: currentTabs.join(','),
    );

    toast(
      '$tab hidden',
      action: SnackBarAction(
        label: 'Undo',
        onPressed: () {
          settings.setSetting(
            category: SettingCategory.tabs,
            key: 'tabs',
            value: old,
          );
        },
      ),
    );
  }

  Widget _buildTab(String tab) {
    switch (tab) {
      case 'WorkoutPage':
        return WorkoutPage(
          tabController: controller,
        );

      case 'PlansPage':
        return PlansPage(
          tabController: controller,
        );

      case 'GraphsPage':
        return GraphsPage(
          tabController: controller,
        );

      case 'TimerPage':
        return const TimerPage();

      case 'SettingsPage':
        return const SettingsPage();

      case 'CalendarPage':
        return CalendarPage(
          tabController: controller,
        );

      default:
        return ErrorWidget(
          "Couldn't build tab content.",
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scrollableTabs = settings.isEnabled(
      key: 'scrollable_tabs',
    );

    return Scaffold(
      resizeToAvoidBottomInset: false,
      extendBodyBehindAppBar: true,
      extendBody: true,
      bottomSheet: const SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 48,
          ),
          child: TimerProgressIndicator(),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            TabBarView(
              key: ValueKey(tabs.join(',')),
              controller: controller,
              physics: scrollableTabs
                  ? const AlwaysScrollableScrollPhysics()
                  : const NeverScrollableScrollPhysics(),
              children: tabs.map(_buildTab).toList(),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: ValueListenableBuilder<double>(
                valueListenable: controller.animation!,
                builder: (
                  context,
                  value,
                  child,
                ) {
                  return BottomNav(
                    tabs: tabs,
                    currentIndex: value.round(),
                    onTap: (index) {
                      if (index < 0 || index >= controller.length) {
                        return;
                      }

                      controller.animateTo(index);
                    },
                    onLongPress: (ctx, tab) {
                      hideTab(ctx, tab);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    settings.removeListener(_onSettingsChanged);
    controller.dispose();
    super.dispose();
  }
}

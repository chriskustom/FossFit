import 'package:flutter/material.dart';
import 'package:fossfit/bottom_nav.dart';
import 'package:fossfit/calendar/calendar_page.dart';
import 'package:fossfit/db/repositories/settings_repository.dart';
import 'package:fossfit/graph/graphs_page.dart';
import 'package:fossfit/models/constants.dart';
import 'package:fossfit/plan/plans_page.dart';
import 'package:fossfit/sets/history_page.dart';
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
  late TabController controller;

  @override
  void initState() {
    super.initState();

    final setting = context.read<SettingsRepository>().getSetting(key: 'tabs');
    final tabs = setting.split(',');
    controller = TabController(length: tabs.length, vsync: this);

    // final info = PackageInfo.fromPlatform();
    // info.then((pkg) async {
    //   final meta = await (oldDb.metadata.select()..limit(1)).getSingleOrNull();
    //   if (meta == null)
    //     return oldDb.metadata.insertOne(
    //       MetadataCompanion(buildNumber: Value(int.parse(pkg.buildNumber))),
    //     );
    //   else
    //     oldDb.metadata.update().write(
    //           MetadataCompanion(
    //             buildNumber: Value(int.parse(pkg.buildNumber)),
    //           ),
    //         );
    //   if (int.parse(pkg.buildNumber) == meta.buildNumber) return null;
    //   if (mounted)
    //     toast(
    //       "New version ${pkg.version}",
    //       action: SnackBarAction(
    //         label: 'Changes',
    //         onPressed: () => Navigator.of(context).push(
    //           MaterialPageRoute(
    //             builder: (context) => const WhatsNew(),
    //           ),
    //         ),
    //       ),
    //     );
    // });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void hideTab(BuildContext context, String tab) {
    final settings = context.read<SettingsRepository>();
    final old = settings.getSetting(key: 'tabs');
    var tabs = old.split(',');

    if (tabs.length == 1) return toast("Can't hide everything!");
    tabs.remove(tab);
    settings.setSetting(
      category: SettingCategory.tabs,
      key: 'tabs',
      value: tabs.join(''),
    );
    toast(
      'Hid $tab',
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

  @override
  Widget build(BuildContext context) {
    final settings = context.read<SettingsRepository>();
    final tabSettings = settings.getSetting(key: 'tabs');

    final tabs = tabSettings.split(',');
    final scrollableTabs = settings.isEnabled(key: 'scrollable_tabs');

    if (tabs.length != controller.length) {
      controller.dispose();
      controller = TabController(length: tabs.length, vsync: this);
      if (controller.index >= tabs.length) controller.index = tabs.length - 1;
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      extendBodyBehindAppBar: true,
      extendBody: true,
      bottomSheet: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48.0),
          child: const TimerProgressIndicator(),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            TabBarView(
              controller: controller,
              physics: scrollableTabs
                  ? const AlwaysScrollableScrollPhysics()
                  : const NeverScrollableScrollPhysics(),
              children: tabs.map((tab) {
                if (tab == 'HistoryPage')
                  return HistoryPage(tabController: controller);
                else if (tab == 'PlansPage')
                  return PlansPage(
                    tabController: controller,
                  );
                else if (tab == 'GraphsPage')
                  return GraphsPage(tabController: controller);
                else if (tab == 'TimerPage')
                  return const TimerPage();
                else if (tab == 'SettingsPage')
                  return const SettingsPage();
                else if (tab == 'CalendarPage')
                  return CalendarPage(
                    tabController: controller,
                  );
                else
                  return ErrorWidget("Couldn't build tab content.");
              }).toList(),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: ValueListenableBuilder(
                valueListenable: controller.animation!,
                builder: (context, value, child) {
                  return BottomNav(
                    tabs: tabs,
                    currentIndex: value.round(),
                    onTap: (index) {
                      controller.animateTo(index);
                    },
                    onLongPress: hideTab,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

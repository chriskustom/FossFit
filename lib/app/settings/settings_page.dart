import 'package:flutter/material.dart';
import 'package:fossfit/app/services/app_services.dart';
import 'package:fossfit/app/settings/appearance_settings_page.dart';
import 'package:fossfit/app/settings/backup_settings_page.dart';
import 'package:fossfit/app/settings/formats_settings_page.dart';
import 'package:fossfit/app/settings/tabs_settings_page.dart';
import 'package:fossfit/app/settings/timer_settings_page.dart';
import 'package:fossfit/app/settings/workout_settings_page.dart';
import 'package:fossfit/app/shell/app_shell.dart';
import 'package:fossfit/app/utils/constants.dart';
import 'package:fossfit/app/utils/fade_route.dart';
import 'package:fossfit/app/utils/utils.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  Map<String, Widget> pages = {
    ConfigCategory.appearance.name: AppearanceSettings(),
    ConfigCategory.backup.name: BackupSettingsPage(),
    ConfigCategory.formats.name: FormatsSettingsPage(),
    ConfigCategory.tabs.name: TabsSettingsPage(),
    ConfigCategory.timers.name: TimerSettingsPage(),
    ConfigCategory.workouts.name: WorkoutSettingsPage(),
  };

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Settings',
      showSearch: false,
      showNavBar: false,
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(12),
              itemCount: pages.entries.length,
              itemBuilder: (ctx, idx) {
                final category = pages.keys.elementAt(idx);
                final page = pages[category]!;
                return ListTile(
                  leading: Transform.scale(
                    scale: iconScale,
                    child: Icon(
                      ConfigCategory.values.byName(category).icon,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  title: Text(category.toTitleCase),
                  onTap: AppHaptics.tapWithHaptics(
                    context,
                    () async => await Navigator.push<ConfigCategory>(context, FadeRoute<ConfigCategory>(page: page)),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

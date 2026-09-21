import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fossfit/about_page.dart';
import 'package:fossfit/database/database.dart';
import 'package:fossfit/settings/appearance_settings.dart';
import 'package:fossfit/settings/data_settings.dart';
import 'package:fossfit/settings/format_settings.dart';
import 'package:fossfit/settings/plan_settings.dart';
import 'package:fossfit/settings/settings_state.dart';
import 'package:fossfit/settings/tab_settings.dart';
import 'package:fossfit/settings/timer_settings.dart';
import 'package:fossfit/settings/workout_settings.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with AutomaticKeepAliveClientMixin {
  final searchCtrl = TextEditingController();

  late final Setting settings;
  late final TextEditingController maxSets;
  late final TextEditingController warmupSets;
  late final TextEditingController minutes;
  late final TextEditingController seconds;

  AudioPlayer? player;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    List<Widget> filtered = [];
    final settings = context.watch<SettingsState>();
    if (searchCtrl.text.isNotEmpty) {
      filtered.addAll(
        getAppearanceSettings(context, searchCtrl.text, settings),
      );
      filtered.addAll(getFormatSettings(searchCtrl.text, settings.value));
      filtered.addAll(
        getWorkoutSettings(
          context,
          searchCtrl.text,
          settings.value,
        ),
      );
      if (player != null)
        filtered.addAll(
          getTimerSettings(
            searchCtrl.text,
            settings.value,
            minutes,
            seconds,
            player!,
            context,
          ),
        );
      filtered.addAll(getDataSettings(searchCtrl.text, settings, context));
      filtered.addAll(
        getPlanSettings(
          searchCtrl.text,
          settings.value,
          maxSets,
          warmupSets,
        ),
      );
    }

    if (filtered.isEmpty)
      filtered = [
        const ListTile(
          title: Text("No settings found"),
        ),
      ];

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          if (!kIsWeb && !Platform.isIOS && !Platform.isMacOS)
            IconButton(
              onPressed: () async {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AboutPage(),
                  ),
                );
              },
              icon: Icon(
                Icons.info_outline_rounded,
              ),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: <Widget>[
            SearchBar(
              hintText: "Search...",
              controller: searchCtrl,
              padding: WidgetStateProperty.all(
                const EdgeInsets.symmetric(horizontal: 16.0),
              ),
              onChanged: (_) {
                setState(() {});
              },
              leading: Icon(
                Icons.search,
              ),
            ),
            const SizedBox(
              height: 8.0,
            ),
            Expanded(
              child: ListView(
                children: searchCtrl.text.isNotEmpty
                    ? filtered
                    : [
                        ListTile(
                          leading: Icon(
                            Icons.color_lens,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          title: const Text("Appearance"),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const AppearanceSettings(),
                            ),
                          ),
                        ),
                        ListTile(
                          leading: Icon(
                            Icons.storage,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          title: const Text("Data management"),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const DataSettings(),
                            ),
                          ),
                        ),
                        ListTile(
                          leading: Icon(
                            Icons.text_format,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          title: const Text("Formats"),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const FormatSettings(),
                            ),
                          ),
                        ),
                        ListTile(
                          leading: Icon(
                            Icons.today,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          title: const Text("Plans"),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const PlanSettings(),
                            ),
                          ),
                        ),
                        ListTile(
                          leading: Icon(
                            Icons.tab,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          title: const Text("Tabs"),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const TabSettings(),
                            ),
                          ),
                        ),
                        ListTile(
                          leading: Icon(
                            Icons.timer,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          title: const Text("Timers"),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const TimerSettings(),
                            ),
                          ),
                        ),
                        ListTile(
                          leading: Icon(
                            Icons.fitness_center,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          title: const Text("Workouts"),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const WorkoutSettings(),
                            ),
                          ),
                        ),
                      ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    maxSets.dispose();
    warmupSets.dispose();
    minutes.dispose();
    seconds.dispose();
    player?.dispose();

    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    settings = context.read<SettingsState>().value;
    maxSets = TextEditingController(text: settings.maxSets.toString());
    warmupSets = TextEditingController(text: settings.warmupSets?.toString());
    minutes = TextEditingController(
      text: Duration(milliseconds: settings.timerDuration).inMinutes.toString(),
    );
    seconds = TextEditingController(
      text: (Duration(milliseconds: settings.timerDuration).inSeconds % 60)
          .toString(),
    );

    if (!kIsWeb) {
      try {
        player = AudioPlayer();
      } catch (e) {
        print('Failed to create AudioPlayer: $e');
        player = null;
      }
    }
  }
}

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:fossfit/app/shell/app_shell.dart';
import 'package:fossfit/app/utils/constants.dart';
import 'package:fossfit/app/utils/utils.dart';
import 'package:fossfit/db/repositories/config_reposity.dart';
import 'package:provider/provider.dart';

class TimerSettingsPage extends StatefulWidget {
  const TimerSettingsPage({super.key});

  @override
  State<TimerSettingsPage> createState() => _TimerSettingsPageState();
}

class _TimerSettingsPageState extends State<TimerSettingsPage> {
  final ConfigCategory category = .timers;
  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: category.name.toTitleCase,
      showSearch: false,
      showNavBar: false,
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          _switch('enabled', Icons.timer_rounded),
          _switch('auto_start', Icons.autorenew_rounded),
          _switch('vibrate', Icons.vibration_rounded),
          _switch('enable_sound', Icons.music_note_rounded),
          _alarmSound(),
        ],
      ),
    );
  }

  Widget _switch(String option, IconData icon) {
    return Selector<ConfigRepository, bool>(
      selector: (_, repo) => repo.isEnabled(category, option),
      builder: (ctx, enabled, _) {
        return ListTile(
          leading: Transform.scale(
            scale: iconScale,
            child: Icon(icon, color: enabled ? Theme.of(context).colorScheme.primary : null),
          ),
          title: Padding(padding: EdgeInsets.only(left: 8), child: Text(option.toTitleCase)),
          trailing: Transform.scale(
            scale: switchScale,
            child: Switch.adaptive(
              value: enabled,
              onChanged: (value) async {
                await context.read<ConfigRepository>().setSetting(category: category, key: option, value: value ? '1' : '0');
              },
            ),
          ),
          onTap: () async {
            await context.read<ConfigRepository>().setSetting(category: category, key: option, value: enabled ? '0' : '1');
          },
        );
      },
    );
  }

  Widget _alarmSound() {
    const key = 'alarm_sound';

    return Selector<ConfigRepository, bool>(
      selector: (_, repo) => repo.isEnabled(category, 'enable_sound'),
      builder: (context, enabled, _) {
        if (!enabled) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.all(4),
          child: Selector<ConfigRepository, String>(
            selector: (_, repo) => repo.getSetting(category, key),
            builder: (context, storedValue, _) {
              return ListTile(
                title: const Text('Alarm sound'),
                subtitle: Row(
                  children: [
                    Expanded(
                      child: Text(
                        storedValue.isNotEmpty ? storedValue : 'No sound file selected. Using default: Argon',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (storedValue.isNotEmpty) ...[
                      IconButton(
                        icon: Transform.scale(scale: iconScale, child: const Icon(Icons.clear_rounded)),
                        onPressed: () async {
                          final repo = context.read<ConfigRepository>();
                          await repo.setSetting(category: category, key: key, value: '');
                        },
                      ),
                      const SizedBox(width: 12),
                    ],
                    IconButton(
                      icon: Transform.scale(scale: iconScale, child: const Icon(Icons.folder)),
                      onPressed: () async {
                        final repo = context.read<ConfigRepository>();
                        final file = await openFile();

                        final path = file?.path;

                        if (path != null && path.isNotEmpty) {
                          await repo.setSetting(category: category, key: key, value: path);
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

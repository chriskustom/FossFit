import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:fossfit/app/shell/app_shell.dart';
import 'package:fossfit/app/utils/constants.dart';
import 'package:fossfit/app/utils/utils.dart';
import 'package:fossfit/db/models/features/config_model.dart';
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
      body: ListView(padding: const EdgeInsets.symmetric(vertical: 16), children: [_options(), _alarmSound()]),
    );
  }

  Padding _options() {
    return Padding(
      padding: EdgeInsets.all(4),
      child: Selector<ConfigRepository, List<KeyValue>>(
        selector: (_, config) => config.getSettingsByCategory(category),
        builder: (context, alloptions, child) {
          final options = alloptions.where((o) => isABool(o.value)).toList();
          return ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: options.length,
            itemBuilder: (_, index) {
              final option = options[index].key;
              return Selector<ConfigRepository, bool>(
                selector: (_, repo) => repo.isEnabled(category, option),
                builder: (ctx, enabled, _) {
                  return ListTile(
                    leading: Transform.scale(
                      scale: iconScale,
                      child: Icon(
                        icons.where((i) => i.$1 == option).first.$2,
                        color: enabled ? Theme.of(context).colorScheme.primary : null,
                      ),
                    ),
                    title: Padding(padding: EdgeInsets.only(left: 8), child: Text(option.toTitleCase)),
                    trailing: Transform.scale(
                      scale: switchScale,
                      child: Switch.adaptive(
                        value: enabled,
                        onChanged: (value) {
                          context.read<ConfigRepository>().setSetting(
                            category: category,
                            key: option,
                            value: value == true ? '1' : '0',
                          );
                          setState(() {});
                        },
                      ),
                    ),
                    onTap: () {
                      context.read<ConfigRepository>().setSetting(
                        category: category,
                        key: option,
                        value: enabled == true ? '0' : '1',
                      );
                      setState(() {});
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  var icons = [
    ('enabled', Icons.timer_rounded),
    ('vibrate', Icons.vibration_rounded),
    ('enable_sound', Icons.music_note_rounded),
  ];

  bool isABool(String input) => ['1', '0', 'true', 'false', 'yes', 'no'].contains(input.trim().toLowerCase());

  Widget _alarmSound() {
    const key = 'alarm_sound';
    if (!context.read<ConfigRepository>().isEnabled(category, 'enable_sound')) return SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Selector<ConfigRepository, String>(
        selector: (_, repo) => repo.getSetting(category, key),
        builder: (context, storedValue, _) {
          return ListTile(
            title: Text('Alarm sound'),
            subtitle: Row(
              children: [
                Expanded(
                  child: Text(
                    storedValue.isNotEmpty ? storedValue : 'No folder selected',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: Transform.scale(scale: iconScale, child: Icon(Icons.folder)),
                  onPressed: () async {
                    final repo = context.read<ConfigRepository>();
                    final file = await openFile();
                    final String? path = file?.path;
                    if (path != null && path.isNotEmpty) {
                      if (!mounted) return;

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
  }
}

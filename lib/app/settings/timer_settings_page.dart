import 'package:file_selector/file_selector.dart';
import 'package:fossfit/app/shell/app_shell.dart';
import 'package:fossfit/app/utils/utils.dart';
import 'package:fossfit/db/models/features/config_model.dart';
import 'package:fossfit/db/repositories/config_reposity.dart';

import 'package:fossfit/app/utils/constants.dart';
import 'package:flutter/material.dart';
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
      body: ListView(padding: const EdgeInsets.symmetric(vertical: 16), children: [_options(), _alarmSound(), _defaultRest()]),
    );
  }

  Padding _options() {
    return Padding(
      padding: EdgeInsets.all(8),
      child: Selector<ConfigRepository, List<KeyValue>>(
        selector: (_, config) => config.getSettingsByCategory(category),
        builder: (context, alloptions, child) {
          final options = alloptions.where((o) => ['enabled', 'enable_sound', 'vibrate'].contains(o.key)).toList();
          return ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: options.length,
            itemBuilder: (_, index) {
              final option = options[index].key;
              return Selector<ConfigRepository, bool>(
                selector: (_, repo) => repo.isEnabled(category, option),
                builder: (ctx, enabled, _) {
                  return Row(
                    key: ValueKey(option),
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(padding: EdgeInsets.only(left: 8), child: Text(option.toTitleCase)),
                      Transform.scale(
                        scale: switchScale,
                        child: Switch.adaptive(
                          value: enabled,
                          onChanged: (value) {
                            context.read<ConfigRepository>().setSetting(category: category, key: option, value: value == true ? '1' : '0');
                          },
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _alarmSound() {
    const key = 'alarm_sound';
    if (!context.read<ConfigRepository>().isEnabled(category, 'enable_sound')) return SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Selector<ConfigRepository, String>(
        selector: (_, repo) => repo.getSetting(category, key),
        builder: (context, storedValue, _) {
          return ListTile(
            title: Text('Alarm sound'),
            subtitle: Row(
              children: [
                Expanded(child: Text(storedValue.isNotEmpty ? storedValue : 'No folder selected', overflow: TextOverflow.ellipsis)),
                IconButton(
                  icon: Icon(Icons.folder),
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

  TextEditingController minutes = TextEditingController();
  TextEditingController seconds = TextEditingController();
  FocusNode secondsFocus = FocusNode();
  Padding _defaultRest() {
    return Padding(
      padding: EdgeInsets.all(8),
      child: Row(
        mainAxisAlignment: .spaceEvenly,
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: 8),
              child: TextField(
                controller: minutes,
                maxLines: 1,
                decoration: InputDecoration(labelText: 'Minutes', hintText: '3'),
                onSubmitted: (value) {
                  secondsFocus.requestFocus();
                  setState(() {});
                },
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: 8),
              child: TextField(
                controller: seconds,
                focusNode: secondsFocus,
                maxLines: 1,
                decoration: InputDecoration(labelText: 'Seconds', hintText: '30'),
                onSubmitted: (value) {},
              ),
            ),
          ),
        ],
      ),
    );
  }
}

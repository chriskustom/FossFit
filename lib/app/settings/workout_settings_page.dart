import 'package:flutter/material.dart';
import 'package:fossfit/app/shell/app_shell.dart';
import 'package:fossfit/app/utils/constants.dart';
import 'package:fossfit/app/utils/utils.dart';
import 'package:fossfit/db/models/features/config_model.dart';
import 'package:fossfit/db/repositories/config_reposity.dart';
import 'package:provider/provider.dart';

class WorkoutSettingsPage extends StatefulWidget {
  const WorkoutSettingsPage({super.key});

  @override
  State<WorkoutSettingsPage> createState() => _WorkoutSettingsPageState();
}

class _WorkoutSettingsPageState extends State<WorkoutSettingsPage> {
  final ConfigCategory category = .workouts;
  List<KeyValue> options = [];
  late ConfigRepository config;
  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    options = context.watch<ConfigRepository>().getSettingsByCategory(category);
  }

  @override
  Widget build(BuildContext context) {
    config = context.watch<ConfigRepository>();
    return AppShell(
      title: category.name.toTitleCase,
      showSearch: false,
      showNavBar: false,
      body: ListView(padding: const EdgeInsets.symmetric(vertical: 16), children: [_options()]),
    );
  }

  Padding _options() {
    return Padding(
      padding: EdgeInsets.all(8),
      child: ListView.builder(
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
                title: Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Text(option.toTitleCase, textAlign: .left),
                ),
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
                    },
                  ),
                ),
                onTap: () {
                  context.read<ConfigRepository>().setSetting(
                    category: category,
                    key: option,
                    value: !enabled == true ? '1' : '0',
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
    ('show_images', Icons.image_rounded),
    ('show_stats', Icons.analytics_outlined),
    ('show_bodyweight', Icons.monitor_weight_rounded),
    ('show_notes', Icons.notes_rounded),
    ('show_categories', Icons.category_rounded),
    ('show_units', Icons.scale_rounded),
    ('group_history', Icons.featured_play_list_rounded),
  ];
}

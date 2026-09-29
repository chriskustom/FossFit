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
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(padding: EdgeInsets.only(left: 8), child: Text('Page')),
              Padding(padding: EdgeInsets.only(left: 8), child: Text('Enabled')),
            ],
          ),
          Divider(),
          ListView.builder(
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
                      Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Text(option.toTitleCase, textAlign: .left),
                      ),
                      Switch(
                        value: enabled,
                        onChanged: (value) {
                          context.read<ConfigRepository>().setSetting(
                            category: category,
                            key: option,
                            value: value == true ? '1' : '0',
                          );
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

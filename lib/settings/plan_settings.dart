import 'package:flutter/material.dart';
import 'package:fossfit/constants.dart';
import 'package:fossfit/db/repositories/settings_repository.dart';
import 'package:fossfit/models/constants.dart';
import 'package:fossfit/utils.dart';
import 'package:provider/provider.dart';

List<Widget> getPlanSettings(
  String term,
  SettingsRepository settings,
  TextEditingController max,
  TextEditingController warmup,
) {
  return [
    if ('warmup sets'.contains(term.toLowerCase()))
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Tooltip(
          message: 'Warmup sets have no rest timers',
          child: TextField(
            controller: warmup,
            decoration: const InputDecoration(
              labelText: 'Warmup sets',
              hintText: '0',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: false),
            onTap: () => selectAll(warmup),
            onChanged: (value) => settings.setSetting(
              category: SettingCategory.plans,
              key: 'warmup_sets',
              value: value.toString(),
            ),
          ),
        ),
      ),
    if ('sets per exercise'.contains(term.toLowerCase()))
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Tooltip(
          message: 'Default # of exercises in a plan',
          child: TextField(
            controller: max,
            decoration: const InputDecoration(
              labelText: 'Sets per exercise (max: 20)',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: false),
            onTap: () => selectAll(max),
            onChanged: (value) {
              if (int.parse(value) > 0 && int.parse(value) <= 20) {
                settings.setSetting(
                  category: SettingCategory.plans,
                  key: 'max_sets',
                  value: value.toString(),
                );
              }
            },
          ),
        ),
      ),
    if ('plan trailing display'.contains(term.toLowerCase()))
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Tooltip(
          message: 'Right side of list displays in Plans + Plan view',
          child: DropdownButtonFormField<PlanTrailing>(
            initialValue: PlanTrailing.values.byName(
              settings
                  .getSetting(key: 'plan_trailing')
                  .replaceFirst('PlanTrailing.', ''),
            ),
            decoration: const InputDecoration(
              labelStyle: TextStyle(),
              labelText: 'Plan trailing display',
            ),
            items: const [
              DropdownMenuItem(
                value: PlanTrailing.reorder,
                child: Row(
                  children: [
                    Text("Re-order"),
                    SizedBox(width: 8),
                    Icon(Icons.menu, size: 18),
                  ],
                ),
              ),
              DropdownMenuItem(
                value: PlanTrailing.count,
                child: Row(
                  children: [
                    Text("Count"),
                    SizedBox(width: 8),
                    Text("(5)"),
                  ],
                ),
              ),
              DropdownMenuItem(
                value: PlanTrailing.percent,
                child: Row(
                  children: [
                    Text("Percent"),
                    SizedBox(width: 8),
                    Text("(50%)"),
                  ],
                ),
              ),
              DropdownMenuItem(
                value: PlanTrailing.ratio,
                child: Row(
                  children: [
                    Text("Ratio"),
                    SizedBox(width: 8),
                    Text("(5 / 10)"),
                  ],
                ),
              ),
              DropdownMenuItem(
                value: PlanTrailing.none,
                child: Text("None"),
              ),
            ],
            onChanged: (value) => settings.setSetting(
              category: SettingCategory.plans,
              key: 'plan_trailing',
              value: value.toString(),
            ),
          ),
        ),
      ),
  ];
}

class PlanSettings extends StatefulWidget {
  const PlanSettings({super.key});

  @override
  State<PlanSettings> createState() => _PlanSettingsRepository();
}

class _PlanSettingsRepository extends State<PlanSettings> {
  late var settings = context.watch<SettingsRepository>();

  late final max =
      TextEditingController(text: settings.getInt(key: 'max_sets').toString());

  late final warmup = TextEditingController(
    text: settings.getInt(key: 'warmup_sets').toString(),
  );

  @override
  Widget build(BuildContext context) {
    settings = context.watch<SettingsRepository>();

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text("Plans"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView(
          children: getPlanSettings('', settings, max, warmup),
        ),
      ),
    );
  }
}

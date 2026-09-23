import 'package:flutter/material.dart';
import 'package:fossfit/db/repositories/settings_repository.dart';
import 'package:fossfit/models/constants.dart';
import 'package:fossfit/widgets/setting_switch.dart';
import 'package:provider/provider.dart';

List<Widget> getWorkoutSettings(
  BuildContext context,
  String term,
  SettingsRepository settings,
) {
  return [
    if ('group history'.contains(term.toLowerCase()))
      SettingSwitch(
        settings: settings,
        category: SettingCategory.workouts,
        keyName: 'group_history',
        title: 'Group history',
        tooltip: 'Combine history entries by day',
        enabledIcon: Icons.expand_more,
        disabledIcon: Icons.expand_more,
      ),
    if ('show units'.contains(term.toLowerCase()))
      SettingSwitch(
        settings: settings,
        category: SettingCategory.workouts,
        keyName: 'show_units',
        title: 'Show units',
        tooltip: 'Show km/mi,kg/lb for graphs/history/plans',
        enabledIcon: Icons.scale_sharp,
        disabledIcon: Icons.scale_sharp,
      ),
    if ('show body weight'.contains(term.toLowerCase()))
      SettingSwitch(
        settings: settings,
        category: SettingCategory.workouts,
        keyName: 'show_body_weight',
        title: 'Show body weight',
        tooltip: 'Enable/disable tracking body weight',
        enabledIcon: Icons.scale_outlined,
        disabledIcon: Icons.scale_outlined,
      ),
    if ('show categories'.contains(term.toLowerCase()))
      SettingSwitch(
        settings: settings,
        category: SettingCategory.workouts,
        keyName: 'show_categories',
        title: 'Show categories',
        tooltip: 'Enable/disable workout categories',
        enabledIcon: Icons.scale_sharp,
        disabledIcon: Icons.scale_sharp,
      ),
    if ('show notes'.contains(term.toLowerCase()))
      SettingSwitch(
        settings: settings,
        category: SettingCategory.workouts,
        keyName: 'show_notes',
        title: 'Show notes',
        tooltip: 'Record details of your lift in a text area',
        enabledIcon: Icons.note_alt_outlined,
        disabledIcon: Icons.note_alt_outlined,
      ),
    if ('notifications'.contains(term.toLowerCase()))
      SettingSwitch(
        settings: settings,
        category: SettingCategory.workouts,
        keyName: 'notifications',
        title: 'Notifications',
        tooltip: 'Write nice messages when a new record is hit',
        enabledIcon: Icons.scale_sharp,
        disabledIcon: Icons.scale_sharp,
      ),
    if ('rep estimation'.contains(term.toLowerCase()))
      SettingSwitch(
        settings: settings,
        category: SettingCategory.workouts,
        keyName: 'rep_estimation',
        title: 'Rep estimation',
        tooltip: 'Try to predict the # of reps you just did',
        enabledIcon: Icons.repeat_outlined,
        disabledIcon: Icons.repeat_outlined,
      ),
    if ('duration estimation'.contains(term.toLowerCase()))
      SettingSwitch(
        settings: settings,
        category: SettingCategory.workouts,
        keyName: 'duration_estimation',
        title: 'Duration estimation',
        tooltip: 'Try predict the duration of your cardio',
        enabledIcon: Icons.access_time,
        disabledIcon: Icons.access_time,
      ),
  ];
}

class WorkoutSettings extends StatefulWidget {
  const WorkoutSettings({super.key});

  @override
  State<WorkoutSettings> createState() => _WorkoutSettingsRepository();
}

class _WorkoutSettingsRepository extends State<WorkoutSettings> {
  late var settings = context.watch<SettingsRepository>();

  late final max =
      TextEditingController(text: settings.getSetting(key: 'max_sets'));
  late final warmup =
      TextEditingController(text: settings.getSetting(key: 'warmup_sets'));

  @override
  Widget build(BuildContext context) {
    settings = context.watch<SettingsRepository>();

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text("Workouts"),
      ),
      body: ListView(
        children: getWorkoutSettings(context, '', settings),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();

    max.dispose();
    warmup.dispose();
  }
}

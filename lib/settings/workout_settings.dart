import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:fossfit/db/repositories/settings_repository.dart';
import 'package:fossfit/main.dart';
import 'package:fossfit/utils.dart';
import 'package:provider/provider.dart';

List<Widget> getWorkoutSettings(
  BuildContext context,
  String term,
  Setting settings,
) {
  return [
    if ('group history'.contains(term.toLowerCase()))
      Tooltip(
        message: 'Combine history entries by day',
        child: ListTile(
          title: const Text('Group history'),
          leading: const Icon(Icons.expand_more),
          onTap: () => oldDb.settings.update().write(
                SettingsCompanion(
                  groupHistory: Value(!settings.groupHistory),
                ),
              ),
          trailing: Switch(
            value: settings.groupHistory,
            onChanged: (value) => oldDb.settings.update().write(
                  SettingsCompanion(
                    groupHistory: Value(value),
                  ),
                ),
          ),
        ),
      ),
    if ('show units'.contains(term.toLowerCase()))
      Tooltip(
        message: 'Show km/mi,kg/lb for graphs/history/plans',
        child: ListTile(
          title: const Text('Show units'),
          leading: const Icon(Icons.scale_sharp),
          onTap: () => oldDb.settings.update().write(SettingsCompanion(showUnits: Value(!settings.showUnits))),
          trailing: Switch(
            value: settings.showUnits,
            onChanged: (value) => oldDb.settings.update().write(SettingsCompanion(showUnits: Value(value))),
          ),
        ),
      ),
    if ('show body weight'.contains(term.toLowerCase()))
      Tooltip(
        message: 'Enable/disable tracking body weight',
        child: ListTile(
          title: const Text('Show body weight'),
          leading: const Icon(Icons.scale_outlined),
          onTap: () => oldDb.settings.update().write(
                SettingsCompanion(
                  showBodyWeight: Value(!settings.showBodyWeight),
                ),
              ),
          trailing: Switch(
            value: settings.showBodyWeight,
            onChanged: (value) => oldDb.settings.update().write(SettingsCompanion(showBodyWeight: Value(value))),
          ),
        ),
      ),
    if ('show categories'.contains(term.toLowerCase()))
      Tooltip(
        message: 'Enable/disable workout categories',
        child: ListTile(
          title: const Text('Show categories'),
          leading: const Icon(Icons.category),
          onTap: () => oldDb.settings.update().write(
                SettingsCompanion(
                  showCategories: Value(!settings.showCategories),
                ),
              ),
          trailing: Switch(
            value: settings.showCategories,
            onChanged: (value) => oldDb.settings.update().write(SettingsCompanion(showCategories: Value(value))),
          ),
        ),
      ),
    if ('show notes'.contains(term.toLowerCase()))
      Tooltip(
        message: 'Record details of your lift in a text area',
        child: ListTile(
          title: const Text('Show notes'),
          leading: const Icon(Icons.note_alt_outlined),
          onTap: () => oldDb.settings.update().write(
                SettingsCompanion(
                  showNotes: Value(!settings.showNotes),
                ),
              ),
          trailing: Switch(
            value: settings.showNotes,
            onChanged: (value) => oldDb.settings.update().write(SettingsCompanion(showNotes: Value(value))),
          ),
        ),
      ),
    if ('notifications'.contains(term.toLowerCase()))
      Tooltip(
        message: 'Write nice messages when a new record is hit',
        child: ListTile(
          title: const Text('Notifications'),
          leading: const Icon(Icons.notifications),
          onTap: () {
            oldDb.settings.update().write(
                  SettingsCompanion(
                    notifications: Value(!settings.notifications),
                  ),
                );
            if (!settings.notifications) toast('Positive messages appear now like this!');
          },
          trailing: Switch(
            value: settings.notifications,
            onChanged: (value) => oldDb.settings.update().write(SettingsCompanion(notifications: Value(value))),
          ),
        ),
      ),
    if ('rep estimation'.contains(term.toLowerCase()))
      Tooltip(
        message: 'Try to predict the # of reps you just did',
        child: ListTile(
          title: const Text('Rep estimation'),
          leading: const Icon(Icons.repeat_outlined),
          onTap: () => oldDb.settings.update().write(
                SettingsCompanion(
                  repEstimation: Value(!settings.repEstimation),
                ),
              ),
          trailing: Switch(
            value: settings.repEstimation,
            onChanged: (value) => oldDb.settings.update().write(SettingsCompanion(repEstimation: Value(value))),
          ),
        ),
      ),
    if ('duration estimation'.contains(term.toLowerCase()))
      Tooltip(
        message: 'Try predict the duration of your cardio',
        child: ListTile(
          title: const Text('Duration estimation'),
          leading: const Icon(Icons.access_time),
          onTap: () => oldDb.settings.update().write(
                SettingsCompanion(
                  durationEstimation: Value(!settings.durationEstimation),
                ),
              ),
          trailing: Switch(
            value: settings.durationEstimation,
            onChanged: (value) => oldDb.settings.update().write(SettingsCompanion(durationEstimation: Value(value))),
          ),
        ),
      ),
  ];
}

class WorkoutSettings extends StatefulWidget {
  const WorkoutSettings({super.key});

  @override
  State<WorkoutSettings> createState() => _WorkoutSettingsState();
}

class _WorkoutSettingsState extends State<WorkoutSettings> {
  late var settings = context.watch<SettingsRepository>();

  late final max = TextEditingController(text: settings.maxSets.toString());
  late final warmup = TextEditingController(text: settings.warmupSets?.toString());

  @override
  Widget build(BuildContext context) {
    settings = context.watch<SettingsState>().value;

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

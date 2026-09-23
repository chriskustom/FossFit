import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/material.dart';
import 'package:fossfit/db/repositories/gym_sets_repository.dart';
import 'package:fossfit/db/repositories/settings_repository.dart';
import 'package:fossfit/main.dart';
import 'package:fossfit/models/constants.dart';
import 'package:fossfit/models/gym_set_model.dart';
import 'package:fossfit/utils.dart';
import 'package:provider/provider.dart';

List<Widget> getTimerSettings(
  String term,
  SettingsRepository settings,
  TextEditingController minCtrl,
  TextEditingController secCtrl,
  AudioPlayer player,
  BuildContext context,
) {
  var restTimers = settings.isEnabled(key: 'rest_timers');
  var vibrate = settings.isEnabled(key: 'vibrate');
  var enableSound = settings.isEnabled(key: 'enable_sound');
  var alarmSound = settings.getSetting(key: 'alarm_sound');
  return [
    if ('rest timers'.contains(term.toLowerCase()))
      Tooltip(
        message: 'Alarm that goes off after completing a set',
        child: ListTile(
          title: const Text('Rest timers'),
          leading: restTimers
              ? const Icon(Icons.timer)
              : const Icon(Icons.timer_outlined),
          onTap: () async {
            final newValue = !restTimers;

            if (newValue) {
              await androidChannel.invokeMethod('requestTimerPermissions');
            }

            await settings.setSetting(
              category: SettingCategory.timers,
              key: 'rest_timers',
              value: newValue ? '1' : '0',
            );
          },
          trailing: Switch(
            value: restTimers,
            onChanged: (value) async {
              if (value) {
                await androidChannel.invokeMethod('requestTimerPermissions');
              }

              await settings.setSetting(
                category: SettingCategory.timers,
                key: 'rest_timers',
                value: value ? '1' : '0',
              );
            },
          ),
        ),
      ),
    if ('vibrate'.contains(term.toLowerCase()))
      Tooltip(
        message: 'Should rest timers vibrate?',
        child: ListTile(
          title: const Text('Vibrate'),
          leading: const Icon(Icons.vibration),
          onTap: () async {
            final newValue = !vibrate;
            await settings.setSetting(
              category: SettingCategory.timers,
              key: 'vibrate',
              value: newValue ? '1' : '0',
            );
            if (newValue) {
              try {
                await androidChannel.invokeMethod('previewVibration');
              } catch (e) {
                print('Failed to trigger preview vibration: $e');
              }
            }
          },
          trailing: Switch(
            value: vibrate,
            onChanged: (value) async {
              await settings.setSetting(
                category: SettingCategory.timers,
                key: 'vibrate',
                value: value ? '1' : '0',
              );
              if (value) {
                try {
                  await androidChannel.invokeMethod('previewVibration');
                } catch (e) {
                  print('Failed to trigger preview vibration: $e');
                }
              }
            },
          ),
        ),
      ),
    if ('enable sound'.contains(term.toLowerCase()))
      Tooltip(
        message: 'Should rest timers play a sound?',
        child: ListTile(
          title: const Text('Enable sound'),
          leading: const Icon(Icons.music_note_outlined),
          onTap: () => settings.setSetting(
            category: SettingCategory.timers,
            key: 'enable_sound',
            value: !enableSound ? '1' : '0',
          ),
          trailing: Switch(
            value: enableSound,
            onChanged: (value) => settings.setSetting(
              category: SettingCategory.timers,
              key: 'enable_sound',
              value: value ? '1' : '0',
            ),
          ),
        ),
      ),
    if ('rest minutes seconds'.contains(term.toLowerCase()))
      Padding(
        padding: const EdgeInsets.all(16),
        child: Tooltip(
          message: 'How long before rest alarms go off?',
          child: material.Column(
            children: [
              material.Row(
                children: [
                  const Icon(Icons.public),
                  const SizedBox(width: 8),
                  Text(
                    "Global default",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'Rest minutes',
                      ),
                      controller: minCtrl,
                      keyboardType: TextInputType.number,
                      onTap: () => selectAll(minCtrl),
                      onChanged: (value) => settings.setSetting(
                        category: SettingCategory.timers,
                        key: 'timer_duration',
                        value: Duration(
                          minutes: int.parse(value),
                          seconds: Duration(
                                milliseconds:
                                    settings.getInt(key: 'timer_duration'),
                              ).inSeconds %
                              60,
                        ).inMilliseconds.toString(),
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 8.0,
                  ),
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'seconds',
                      ),
                      controller: secCtrl,
                      keyboardType: TextInputType.number,
                      onTap: () => selectAll(secCtrl),
                      onChanged: (value) => settings.setSetting(
                        category: SettingCategory.timers,
                        key: 'timer_duration',
                        value: Duration(
                          seconds: int.parse(value),
                          minutes: Duration(
                            milliseconds:
                                settings.getInt(key: 'timer_duration'),
                          ).inMinutes.floor(),
                        ).inMilliseconds.toString(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    if ('alarm sound'.contains(term.toLowerCase()))
      Tooltip(
        message: 'Music to play at the end of a rest timer',
        child: material.Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            TextButton.icon(
              onPressed: () async {
                final result = await FilePicker.pickFile(type: FileType.audio);
                if (result == null || result.path == null) return;
                settings.setSetting(
                  category: SettingCategory.timers,
                  key: 'alarm_sound',
                  value: result.path!,
                );
                player.play(DeviceFileSource(result.path!));
              },
              icon: const Icon(Icons.music_note),
              label: alarmSound.isEmpty
                  ? const Text("Alarm sound")
                  : Text(alarmSound.split('/').last),
            ),
            if (alarmSound.isNotEmpty)
              TextButton.icon(
                onPressed: () {
                  settings.setSetting(
                    category: SettingCategory.timers,
                    key: 'alarm_sound',
                    value: '',
                  );
                },
                label: const Text("Delete"),
                icon: const Icon(Icons.delete),
              ),
          ],
        ),
      ),
  ];
}

class TimerSettings extends StatefulWidget {
  const TimerSettings({super.key});

  @override
  State<TimerSettings> createState() => _TimerSettingsRepository();
}

class _TimerSettingsRepository extends State<TimerSettings> {
  late SettingsRepository settings = context.read<SettingsRepository>();
  late GymSetsRepository gymSetRepository = context.read<GymSetsRepository>();
  late final minCtrl = TextEditingController(
    text: (Duration(milliseconds: settings.getInt(key: 'timer_duration')))
        .inMinutes
        .toString(),
  );
  late final secCtrl = TextEditingController(
    text: ((Duration(milliseconds: settings.getInt(key: 'timer_duration')))
                .inSeconds %
            60)
        .toString(),
  );

  AudioPlayer? player;
  List<GymSet> setsWithCustomTimers = [];
  Map<int, TextEditingController> minuteControllers = {};
  Map<int, TextEditingController> secondControllers = {};

  @override
  void initState() {
    super.initState();

    if (!kIsWeb) {
      try {
        player = AudioPlayer();
      } catch (e) {
        print('Failed to create AudioPlayer: $e');
        player = null;
      }
    }

    _loadExercisesWithCustomTimers();
  }

  Future<void> _loadExercisesWithCustomTimers() async {
    final gymSets = gymSetRepository.gymsets
        .where((set) => set.restMs != null)
        .fold<Map<String, GymSet>>({}, (map, set) {
          map.putIfAbsent(set.exercise!.name, () => set);
          return map;
        })
        .values
        .toList();

    setState(() {
      setsWithCustomTimers = gymSets;

      for (final gymSet in gymSets) {
        final restMs = gymSet.restMs;

        if (restMs != null) {
          final duration = Duration(milliseconds: restMs);

          minuteControllers[gymSet.id!] = TextEditingController(
            text: duration.inMinutes.toString(),
          );

          secondControllers[gymSet.id!] = TextEditingController(
            text: (duration.inSeconds % 60).toString(),
          );
        }
      }
    });
  }

  Future<void> _updateExerciseRestTime(
    GymSet gymSet,
    int? minutes,
    int? seconds,
  ) async {
    Duration? duration;
    final mins = minutes ?? 0;
    final secs = seconds ?? 0;

    if (mins > 0 || secs > 0) {
      duration = Duration(minutes: mins, seconds: secs);
    }
    await gymSetRepository.updateGymSet(
      gymSet.copyWith(duration: duration?.inMilliseconds.toDouble()),
    );

    // If duration is null (both minutes and seconds are 0), remove from list
    if (duration == null) {
      setState(() {
        setsWithCustomTimers.removeWhere((e) => e.id == gymSet.id);
        minuteControllers.remove(gymSet.id);
        secondControllers.remove(gymSet.id);
      });
    }
  }

  Future<void> _removeCustomTimer(GymSet gymSet) async {
    await gymSetRepository.updateGymSet(
      gymSet.copyWith(duration: null),
    );

    setState(() {
      setsWithCustomTimers.removeWhere((e) => e.id == gymSet.id!);
      minuteControllers.remove(gymSet.id!);
      secondControllers.remove(gymSet.id!);
    });
  }

  Widget _buildPerExerciseSection() {
    if (setsWithCustomTimers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: material.Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          material.Row(
            children: [
              const Icon(Icons.fitness_center),
              const SizedBox(width: 8),
              Text(
                "Per-exercise rest times",
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "These exercises have custom rest durations",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.color
                      ?.withAlpha((255 * 0.7).round()),
                ),
          ),
          const SizedBox(height: 16),
          ...setsWithCustomTimers.map((gymSet) {
            if (minuteControllers[gymSet.id!] == null ||
                secondControllers[gymSet.id!] == null) return const SizedBox();
            final minController = minuteControllers[gymSet.id!]!;
            final secController = secondControllers[gymSet.id!]!;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: material.Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    material.Row(
                      children: [
                        Expanded(
                          child: Text(
                            gymSet.exercise!.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _removeCustomTimer(gymSet),
                          tooltip: 'Remove custom timer (use global default)',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              labelText: 'Minutes',
                              border: OutlineInputBorder(),
                            ),
                            controller: minController,
                            keyboardType: TextInputType.number,
                            onTap: () => selectAll(minController),
                            onChanged: (value) {
                              final minutes = int.tryParse(value) ?? 0;
                              final seconds =
                                  int.tryParse(secController.text) ?? 0;
                              _updateExerciseRestTime(
                                gymSet,
                                minutes,
                                seconds,
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              labelText: 'Seconds',
                              border: OutlineInputBorder(),
                            ),
                            controller: secController,
                            keyboardType: TextInputType.number,
                            onTap: () => selectAll(secController),
                            onChanged: (value) {
                              final minutes =
                                  int.tryParse(minController.text) ?? 0;
                              final seconds = int.tryParse(value) ?? 0;
                              _updateExerciseRestTime(
                                gymSet,
                                minutes,
                                seconds,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsRepository>();

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text("Timers"),
      ),
      body: ListView(
        children: player != null
            ? [
                ...getTimerSettings(
                  '',
                  settings,
                  minCtrl,
                  secCtrl,
                  player!,
                  context,
                ),
                _buildPerExerciseSection(),
              ]
            : [
                const ListTile(
                  title: Text("Timer settings"),
                  subtitle: Text("Audio features not available on web"),
                ),
              ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();

    minCtrl.dispose();
    secCtrl.dispose();

    // Dispose of all exercise controllers
    for (final controller in minuteControllers.values) {
      controller.dispose();
    }
    for (final controller in secondControllers.values) {
      controller.dispose();
    }

    player?.stop();
    player?.dispose();
  }
}

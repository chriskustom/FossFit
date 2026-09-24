import 'package:flutter/material.dart' as material;
import 'package:flutter/material.dart';
import 'package:fossfit/db/repositories/settings_repository.dart';
import 'package:fossfit/models/plan_exercise_model.dart';
import 'package:fossfit/utils.dart';
import 'package:provider/provider.dart';

class ExerciseTile extends StatefulWidget {
  final PlanExercise planExercise;
  final Function(PlanExercise) onChange;

  const ExerciseTile({
    super.key,
    required this.onChange,
    required this.planExercise,
  });

  @override
  State<ExerciseTile> createState() => _ExerciseTileState();
}

class _ExerciseTileState extends State<ExerciseTile> {
  late final TextEditingController max;
  late final TextEditingController warmup;

  @override
  void initState() {
    super.initState();

    max = TextEditingController(
      text: widget.planExercise.maxSets.toString(),
    );

    warmup = TextEditingController(
      text: widget.planExercise.warmupSets?.toString() ?? '',
    );
  }

  @override
  void didUpdateWidget(covariant ExerciseTile oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.planExercise.maxSets != widget.planExercise.maxSets) {
      final value = widget.planExercise.maxSets.toString();

      if (max.text != value) {
        max.text = value;
      }
    }

    if (oldWidget.planExercise.warmupSets != widget.planExercise.warmupSets) {
      final value = widget.planExercise.warmupSets?.toString() ?? '';

      if (warmup.text != value) {
        warmup.text = value;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final exercise = widget.planExercise.exercise;

    if (exercise == null) {
      return const SizedBox.shrink();
    }

    return ListTile(
      leading: IconButton(
        icon: const Icon(Icons.settings),
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) {
              bool timers = widget.planExercise.timers ?? true;

              return AlertDialog.adaptive(
                title: Text(exercise.name),
                content: SingleChildScrollView(
                  child: material.Column(
                    children: [
                      Selector<SettingsRepository, int?>(
                        selector: (context, settings) => settings.getInt(key: 'warmup_sets'),
                        builder: (context, value, child) {
                          return TextField(
                            controller: warmup,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: false,
                            ),
                            onTap: () => selectAll(warmup),
                            onChanged: (value) {
                              widget.onChange(
                                widget.planExercise.copyWith(
                                  enabled: true,
                                  warmupSets: int.tryParse(value),
                                ),
                              );
                            },
                            decoration: InputDecoration(
                              labelText: "Warmup sets",
                              border: const OutlineInputBorder(),
                              hintText: (value ?? 0).toString(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      Selector<SettingsRepository, int>(
                        selector: (context, settings) => settings.getInt(key: 'max_sets'),
                        builder: (context, value, child) {
                          return TextField(
                            controller: max,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: false,
                            ),
                            onTap: () => selectAll(max),
                            onChanged: (text) {
                              final parsed = int.tryParse(text);

                              if (parsed == null || parsed <= 0 || parsed > 20) {
                                return;
                              }

                              widget.onChange(
                                widget.planExercise.copyWith(
                                  enabled: true,
                                  maxSets: parsed,
                                ),
                              );
                            },
                            decoration: InputDecoration(
                              labelText: "Working sets (max: 20)",
                              border: const OutlineInputBorder(),
                              hintText: value.toString(),
                            ),
                          );
                        },
                      ),
                      StatefulBuilder(
                        builder: (context, setState) {
                          return ListTile(
                            title: const Text('Rest timers'),
                            trailing: Switch(
                              value: timers,
                              onChanged: (value) {
                                setState(() {
                                  timers = value;
                                });

                                widget.onChange(
                                  widget.planExercise.copyWith(
                                    timers: value,
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    label: const Text("OK"),
                    icon: const Icon(Icons.check),
                  ),
                ],
              );
            },
          );
        },
      ),
      title: Text(exercise.name),
      trailing: Switch(
        value: widget.planExercise.enabled,
        onChanged: (value) {
          widget.onChange(
            widget.planExercise.copyWith(
              enabled: value,
            ),
          );
        },
      ),
      onTap: () {
        widget.onChange(
          widget.planExercise.copyWith(
            enabled: !widget.planExercise.enabled,
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    max.dispose();
    warmup.dispose();
    super.dispose();
  }
}

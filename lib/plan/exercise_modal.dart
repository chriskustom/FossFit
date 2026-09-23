import 'package:flutter/material.dart' as material;
import 'package:flutter/material.dart';
import 'package:fossfit/db/repositories/gym_sets_repository.dart';
import 'package:fossfit/db/repositories/plan_exercises_repository.dart';
import 'package:fossfit/db/repositories/plans_repository.dart';
import 'package:fossfit/db/repositories/settings_repository.dart';
import 'package:fossfit/models/exercise_model.dart';
import 'package:fossfit/models/plan_exercise_model.dart';
import 'package:fossfit/plan/swap_workout.dart';
import 'package:fossfit/sets/edit_set_page.dart';
import 'package:fossfit/timer/timer_state.dart';
import 'package:fossfit/utils.dart';
import 'package:provider/provider.dart';

class ExerciseModal extends StatefulWidget {
  final Exercise exercise;
  final bool hasData;
  final Function() onSelect;
  final Function() onMax;
  final int planId;

  const ExerciseModal({
    super.key,
    required this.exercise,
    required this.hasData,
    required this.onSelect,
    required this.planId,
    required this.onMax,
  });

  @override
  State<ExerciseModal> createState() => _ExerciseModalState();
}

class _ExerciseModalState extends State<ExerciseModal> {
  final max = TextEditingController();
  final warmup = TextEditingController();
  bool timers = true;
  List<PlanExercise> planExercises = [];
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var repo = context.watch<PlanExercisesRepository>();
    var planExercise = repo.planexercises
        .where((p) => p.id == widget.planId && p.exercise == widget.exercise)
        .take(1)
        .first;
    max.text = planExercise.maxSets.toString();
    warmup.text = planExercise.warmupSets?.toString() ?? '';

    timers = planExercise.timers ?? true;
    var setsRepo = context.watch<GymSetsRepository>();
    var gymSets = setsRepo.gymsets;
    return Wrap(
      children: <Widget>[
        ListTile(
          leading: const Icon(Icons.settings),
          title: const Text('Settings'),
          onTap: () async {
            Navigator.pop(context);

            showDialog(
              context: context,
              builder: (context) {
                return AlertDialog.adaptive(
                  title: Text(widget.exercise.name),
                  content: SingleChildScrollView(
                    child: material.Column(
                      children: [
                        Selector<SettingsRepository, int?>(
                          selector: (context, settings) =>
                              settings.getInt(key: 'warmup_sets'),
                          builder: (context, value, child) => TextField(
                            controller: warmup,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: false,
                            ),
                            onTap: () => selectAll(warmup),
                            onChanged: changeWarmup,
                            decoration: InputDecoration(
                              labelText: "Warmup sets",
                              border: const OutlineInputBorder(),
                              hintText: (value ?? 0).toString(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Selector<SettingsRepository, int>(
                          selector: (context, settings) =>
                              settings.getInt(key: 'max_sets'),
                          builder: (context, value, child) => TextField(
                            controller: max,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: false,
                            ),
                            onTap: () => selectAll(max),
                            onChanged: changeMax,
                            decoration: InputDecoration(
                              labelText: "Working sets (max: 20)",
                              border: const OutlineInputBorder(),
                              hintText: value.toString(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        StatefulBuilder(
                          builder: (context, setState) => ListTile(
                            title: const Text('Rest timers'),
                            trailing: Switch(
                              value: timers,
                              onChanged: (value) {
                                setState(() {
                                  timers = value;
                                });
                                changeTimers(value);
                              },
                            ),
                          ),
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
        if (widget.hasData)
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit'),
            onTap: () async {
              Navigator.pop(context);
              final gymSet = gymSets
                  .where((r) => r.exerciseId == (widget.exercise.id))
                  .take(1)
                  .first;
              if (!context.mounted) return;
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditSetPage(gymSet: gymSet),
                ),
              );
              widget.onSelect();
            },
          ),
        if (widget.hasData)
          ListTile(
            leading: const Icon(Icons.undo),
            title: const Text('Undo'),
            onTap: () async {
              Navigator.pop(context);
              final gymSet = gymSets
                  .where((r) => r.exerciseId == (widget.exercise.id))
                  .take(1)
                  .first;
              await setsRepo.deleteGymSetById(gymSet.id!);
              if (!context.mounted) return;
              final planState = context.read<PlansRepository>();
              planState.updateGymCounts(widget.planId);
              widget.onSelect();
              final timerState = context.read<TimerState>();
              timerState.stopTimer();
            },
          ),
        if (!widget.hasData)
          ListTile(
            leading: const Icon(Icons.swap_horiz),
            title: const Text('Swap'),
            onTap: () async {
              Navigator.pop(context);
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SwapWorkout(
                    exercise: widget.exercise,
                    planId: widget.planId,
                  ),
                ),
              );
              if (result == true) {
                widget.onSelect();
              }
            },
          ),
      ],
    );
  }

  void changeTimers(bool value) async {
    var repo = context.read<PlanExercisesRepository>();
    var pe = repo.getPlanExercisesByPlanId(widget.planId);
    await repo.updatePlanExercise(
      pe.where((p) => p.exerciseId == widget.exercise.id).first.copyWith(
            timers: value,
          ),
    );
  }

  void changeMax(String value) async {
    var repo = context.read<PlanExercisesRepository>();
    var pe = repo.getPlanExercisesByPlanId(widget.planId);
    await repo.updatePlanExercise(
      pe.where((p) => p.exerciseId == widget.exercise.id).first.copyWith(
            maxSets: int.tryParse(max.text),
          ),
    );
    widget.onMax();
  }

  void changeWarmup(String value) async {
    var repo = context.read<PlanExercisesRepository>();
    var pe = repo.getPlanExercisesByPlanId(widget.planId);
    await repo.updatePlanExercise(
      pe.where((p) => p.exerciseId == widget.exercise.id).first.copyWith(
            warmupSets: int.tryParse(warmup.text),
          ),
    );
  }
}

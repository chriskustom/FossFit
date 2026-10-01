import 'package:flutter/material.dart';
import 'package:fossfit/app/features/plans/plan/widgets/plan_exercise_tile.dart';
import 'package:fossfit/app/features/workout/widgets/workout_list.dart';
import 'package:fossfit/app/services/features/exercise_services.dart';
import 'package:fossfit/app/services/features/gym_set_services.dart';
import 'package:fossfit/app/services/features/plan_exercise_services.dart';
import 'package:fossfit/app/services/features/plan_services.dart';
import 'package:fossfit/app/shell/app_shell.dart';
import 'package:fossfit/app/widgets/animated_fab.dart';
import 'package:fossfit/app/widgets/countdown_timer.dart';
import 'package:fossfit/db/models/features/gymset_model.dart';
import 'package:fossfit/db/models/features/plan_exercise_model.dart';
import 'package:fossfit/db/repositories/config_reposity.dart';
import 'package:fossfit/db/repositories/exercise_repository.dart';
import 'package:fossfit/db/repositories/plan_exercises_repository.dart';
import 'package:fossfit/db/repositories/plan_repository.dart';
import 'package:provider/provider.dart';

class PlanPage extends StatefulWidget {
  final int planId;
  const PlanPage({super.key, required this.planId});

  @override
  State<PlanPage> createState() => _PlanPageState();
}

class _PlanPageState extends State<PlanPage> {
  List<PlanExercise>? displayPlanExercises;
  final ScrollController scroll = ScrollController();

  final Map<int, ExpansibleController> expanders = {};
  final Map<int, TextEditingController> repControllers = {};
  final Map<int, TextEditingController> weightControllers = {};
  final Map<int, TextEditingController> noteControllers = {};
  final Map<int, TextEditingController> unitControllers = {};

  int expandedIndex = 0;
  int? selectedPlanExerciseId;
  int? selectedExerciseId;
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var config = context.watch<ConfigRepository>();
    var planRepo = context.watch<PlansRepository>();
    var planExRepo = context.watch<PlanExercisesRepository>();
    var exRepo = context.watch<ExercisesRepository>();
    var plan = planRepo.getPlanById(widget.planId);
    var timer = config.isEnabled(.timers, 'enabled');

    final planExercises = displayPlanExercises ?? planExRepo.getPlanExercisesByPlanId(widget.planId);
    selectedPlanExerciseId = selectedPlanExerciseId ?? planExercises.firstOrNull?.id;
    selectedExerciseId = selectedExerciseId ?? planExercises.firstOrNull?.exerciseId;
    return AppShell(
      showNavBar: false,
      title: plan!.name,
      showSearch: false,
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: ReorderableListView.builder(
                scrollController: scroll,
                itemCount: planExercises.length,
                padding: const EdgeInsets.only(bottom: 96, top: 16),
                itemBuilder: (context, index) {
                  final planExercise = planExercises[index];
                  final exercise = exRepo.getExerciseById(planExercise.exerciseId);
                  return PlanExerciseTile(
                    key: Key('${planExercise.id}-${planExercise.exerciseId}'),
                    exercise: exercise!,
                    planId: widget.planId,
                    index: index,
                    expander: expanders.putIfAbsent(planExercise.id!, ExpansibleController.new),
                    reps: repControllers.putIfAbsent(planExercise.id!, TextEditingController.new),
                    weight: weightControllers.putIfAbsent(planExercise.id!, TextEditingController.new),
                    unit: unitControllers.putIfAbsent(planExercise.id!, TextEditingController.new),
                    notes: noteControllers.putIfAbsent(planExercise.id!, TextEditingController.new),
                    onExpansionChanged: (open) {
                      if (open) {
                        if (expandedIndex != index) {
                          expanders.entries
                              .where((c) => c.key != planExercise.id! && c.value.isExpanded)
                              .forEach((c) => c.value.collapse());
                        }
                        selectedPlanExerciseId = planExercise.id;
                        selectedExerciseId = planExercise.exerciseId;
                        expandedIndex = index;
                        debugPrint(
                          'Selected Plan Exercise ID - $selectedExerciseId, '
                          'Selected Exercise - $selectedExerciseId / ${exercise.name}',
                        );
                      }
                      setState(() {});
                    },
                    onFieldSubmitted: () async => await save(),
                    onSwap: () async {
                      Navigator.pop(context);
                      var services = PlanExerciseServices(context: context);
                      var newExerciseId = await services.openSwapExercisePage(
                        context,
                        planExercise.exerciseId,
                        planExercise.planId,
                      );
                      final old = planExRepo.getPlanExerciseByExerciseAndPlan(
                        planExercise.exerciseId,
                        planExercise.planId,
                      );
                      if (old == null) return;
                      await planExRepo.updatePlanExercise(old.copyWith(exerciseId: newExerciseId));
                      planExRepo.loadAll();
                      if (!context.mounted) return;
                    },
                  );
                },
                onReorderItem: (oldIndex, newIndex) async {
                  await planExRepo.reorderPlanExercises(widget.planId, oldIndex, newIndex);
                },
              ),
            ),
          ),
          Padding(padding: const EdgeInsets.only(left: 8, right: 8, bottom: 18), child: CountdownTimer()),
        ],
      ),
      floatingActionButton: AnimatedFab(
        onPressed: () async => await save(),
        label: const Text('Save'),
        icon: const Icon(Icons.save_rounded),
        scroll: scroll,
        height: timer ? 60 : 0,
      ),
      actions: [
        IconButton(tooltip: 'History', icon: const Icon(Icons.history), onPressed: _showHistory),
        IconButton(
          onPressed: () async {
            var services = PlanServices(context: context);
            await services.openAddEdiPlanPage(context, widget.planId);
          },
          icon: Icon(Icons.edit),
        ),
      ],
    );
  }

  Future<void> _showHistory() async {
    final services = GymSetServices(context: context);
    final sets = services.getSetsByExerciseId(selectedExerciseId ?? 0);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.75,
          widthFactor: 0.85,
          child: Material(
            color: Theme.of(context).colorScheme.surface,
            clipBehavior: Clip.antiAlias,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: WorkoutList(sets: sets.take(20).toList()),
          ),
        );
      },
    );
  }

  Future<bool> save({bool nextExercise = false}) async {
    if (selectedPlanExerciseId == null || selectedExerciseId == null) return false;
    final peServices = PlanExerciseServices(context: context);
    final exServices = ExerciseServices(context: context);
    final services = GymSetServices(context: context);

    final lastSets = services.getSetsByExerciseId(selectedExerciseId!, limit: 1);

    final reps = int.tryParse(repControllers[selectedPlanExerciseId!]!.text) ?? 0;
    final weight = double.tryParse(weightControllers[selectedPlanExerciseId!]!.text) ?? 0.0;
    final unit = unitControllers[selectedPlanExerciseId!]!.text;
    final note = noteControllers[selectedPlanExerciseId!]!.text;

    final gymSet = GymSet(
      reps: reps,
      weight: weight,
      exerciseId: selectedExerciseId!,
      note: note,
      unit: unit,
      planId: widget.planId,
      created: DateTime.now(),
      //copied from last set
      bodyWeight: lastSets.firstOrNull?.bodyWeight,
      rest: lastSets.firstOrNull?.rest,
    );
    await services.insertGymSet(gymSet);

    final max =
        peServices.getPlanExerciseById(selectedPlanExerciseId!)?.maxSets ??
        exServices.getExerciseById(selectedExerciseId!)?.defaultSets ??
        3;
    final count = services.getTodaysSetsByExerciseId(selectedExerciseId!, widget.planId).length;
    if (count == max) {
      final keys = expanders.keys.toList();

      final index = keys.indexOf(selectedPlanExerciseId!);

      if (index != -1 && index + 1 < keys.length) {
        final nextKey = keys[index + 1];
        expanders[nextKey]?.expand();
        //expandedIndex = index + 1;
      }
    }
    setState(() {});
    return true;
  }
}

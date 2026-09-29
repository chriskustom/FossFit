import 'package:flutter/material.dart';
import 'package:fossfit/app/features/plans/plan/widgets/plan_exercise_tile.dart';
import 'package:fossfit/app/shell/app_shell.dart';
import 'package:fossfit/app/widgets/fanimated_fab.dart';
import 'package:fossfit/db/models/features/exercise_model.dart';
import 'package:fossfit/db/models/features/plan_exercise_model.dart';
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
  List<Exercise>? displayExercises;
  List<PlanExercise>? displayPlanExercises;
  List<ExercisesInPlan>? displayExercisesInPlan;
  final ScrollController scroll = ScrollController();

  final Map<int, ExpansibleController> controllers = {};

  int? expandedIndex = 0;
  @override
  void initState() {
    super.initState();
  }

  List<ExercisesInPlan> _getPlanExercises(List<PlanExercise> pes, List<Exercise> es) {
    List<ExercisesInPlan> retval = [];
    for (var pe in pes) {
      retval.add(ExercisesInPlan(pe, es.where((e) => e.id == pe.exerciseId).first));
    }
    return retval;
  }

  @override
  Widget build(BuildContext context) {
    var exRepo = context.watch<ExercisesRepository>();
    var planRepo = context.watch<PlansRepository>();
    var planExRepo = context.watch<PlanExercisesRepository>();
    var plan = planRepo.getPlanById(widget.planId);
    final planExercises = displayPlanExercises ?? planExRepo.getPlanExercisesByPlanId(widget.planId);
    final exercises = displayExercises ?? exRepo.getExercisesByIds(planExercises.map((e) => e.exerciseId).toList());
    final exercisesInPlan = displayExercisesInPlan ?? _getPlanExercises(planExercises, exercises);

    return AppShell(
      title: plan!.name != null ? plan.name! : plan.days.replaceAll(',', ', '),
      body: Padding(
        padding: EdgeInsets.all(12),
        child: ReorderableListView.builder(
          scrollController: scroll,
          itemCount: exercisesInPlan.length,
          padding: const EdgeInsets.only(bottom: 96, top: 16),
          itemBuilder: (context, index) {
            final exerciseInPlan = exercisesInPlan[index];
            controllers.putIfAbsent(exerciseInPlan.planExercise.id!, ExpansibleController.new);

            return PlanExerciseTile(
              key: Key(exerciseInPlan.planExercise.id.toString()),
              exerciseId: exerciseInPlan.exercise.id!,
              planId: widget.planId,
              index: index,
              expander: controllers.putIfAbsent(exerciseInPlan.planExercise.id!, ExpansibleController.new),
              onExpansionChanged: (open) {
                if (open) {
                  if (expandedIndex != null && expandedIndex != index) {
                    final previousExercise = planExercises[expandedIndex!];

                    controllers[previousExercise.id]?.collapse();
                  }

                  expandedIndex = index;
                } else if (expandedIndex == index) {
                  expandedIndex = null;
                }

                setState(() {});
              },
            );
          },
          onReorderItem: (oldIndex, newIndex) async {
            //TODO FIX THIS
            final selectedId = planExercises[expandedIndex!].id;

            final expandedId = expandedIndex != null ? planExercises[expandedIndex!].id : null;

            final item = planExercises.removeAt(oldIndex);

            planExercises.insert(newIndex, item);

            for (var i = 0; i < planExercises.length; i++) {
              await planExRepo.updatePlanExercise(planExercises[i].copyWith(sequence: i));
            }

            if (!context.mounted) return;

            expandedIndex = planExercises.indexWhere((exercise) => exercise.id == selectedId);

            if (expandedId != null) {
              final newExpandedIndex = planExercises.indexWhere((exercise) => exercise.id == expandedId);

              expandedIndex = newExpandedIndex == -1 ? null : newExpandedIndex;
            }

            if (expandedIndex != null && expandedId != null) {
              controllers[expandedId]?.expand();
            }
          },
        ),
      ),
      floatingActionButton: AnimatedFab(
        onPressed: () async {
          //TODO Save set
          // var services = GymSetServices(context: context);
          // await services.insertGymSet(await services.openAddEditPage(context, null));
        },
        label: const Text('Add'),
        icon: const Icon(Icons.add),
        scroll: scroll,
      ),
    );
  }
}

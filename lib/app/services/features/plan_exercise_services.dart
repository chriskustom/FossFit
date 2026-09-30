import 'package:flutter/material.dart';
import 'package:fossfit/app/features/plans/plan/swap_plan_exercise.dart';
import 'package:fossfit/db/models/features/plan_exercise_model.dart';
import 'package:fossfit/db/repositories/config_reposity.dart';
import 'package:fossfit/db/repositories/exercise_repository.dart';
import 'package:fossfit/db/repositories/plan_exercises_repository.dart';
import 'package:fossfit/db/repositories/plan_repository.dart';
import 'package:provider/provider.dart';

class PlanExerciseServices {
  final BuildContext context;
  late PlansRepository planRepo;
  late PlanExercisesRepository planExerciseRepo;
  late ExercisesRepository exerciseRepo;
  late ConfigRepository settingsRepo;
  PlanExerciseServices({required this.context}) {
    settingsRepo = context.read<ConfigRepository>();
    planExerciseRepo = context.read<PlanExercisesRepository>();
    planRepo = context.read<PlansRepository>();
    exerciseRepo = context.read<ExercisesRepository>();
  }

  List<PlanExercise> getAllPlanExercises() => planExerciseRepo.planexercises;
  PlanExercise? getPlanExerciseById(int id) => planExerciseRepo.getPlanExerciseById(id);

  Future<int?> openSwapExercisePage(BuildContext context, int exerciseId, int planId) async {
    return await showGeneralDialog<int?>(
      context: context,
      barrierLabel: '',
      barrierDismissible: true,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, anim1, anim2) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            child: SizedBox(
              width: MediaQuery.of(context).size.width,
              height: double.infinity,
              child: SwapPlanExercise(exerciseId: exerciseId, planId: planId),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        final offsetAnimation = Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(anim1);
        return SlideTransition(position: offsetAnimation, child: child);
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:fossfit/app/features/exercises/exercise/add_edit_exercise.dart';
import 'package:fossfit/app/features/exercises/exercise/exercise_page.dart';
import 'package:fossfit/app/widgets/app_snack_bar.dart';
import 'package:fossfit/db/models/features/exercise_model.dart';
import 'package:fossfit/db/models/features/strength_model.dart';
import 'package:fossfit/db/repositories/config_reposity.dart';
import 'package:fossfit/db/repositories/exercise_repository.dart';
import 'package:fossfit/db/repositories/gym_set_repository.dart';
import 'package:fossfit/db/repositories/plan_exercises_repository.dart';
import 'package:provider/provider.dart';

class ExerciseServices {
  final BuildContext context;
  late GymSetRepository gymSetsRepo;
  late ExercisesRepository exerciseRepo;
  late PlanExercisesRepository planExercisesRepo;
  late ConfigRepository settingsRepo;
  ExerciseServices({required this.context}) {
    gymSetsRepo = context.read<GymSetRepository>();
    exerciseRepo = context.read<ExercisesRepository>();
    planExercisesRepo = context.read<PlanExercisesRepository>();
    settingsRepo = context.read<ConfigRepository>();
  }

  List<Exercise> getAllExercises() => exerciseRepo.exercises;

  List<Exercise> getExercisesByPlanId(int planId) =>
      exerciseRepo.exercises.where((e) => planExercisesRepo.getPlanExercisesByPlanId(planId).map((e) => e.exerciseId).contains(e.id)).toList();
  Exercise? getExerciseById(int id) => exerciseRepo.getExerciseById(id);
  Future<Exercise?> openExercisePage(BuildContext context, int exerciseId, List<StrengthData> data) async {
    return await showGeneralDialog<Exercise?>(
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
              child: ExercisePage(exerciseId: exerciseId, initialData: data),
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

  Future<Exercise?> openAddEditExercisePage(BuildContext context, int? exerciseId, String? name) async {
    return await showGeneralDialog<Exercise?>(
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
              child: AddEditExercise(exerciseId: exerciseId, name: name),
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

  Future<Exercise?> addExercise(Exercise? exercise) async {
    if (exercise == null) return null;
    return await exerciseRepo.addExercise(exercise);
  }

  Future<bool> editExercise(Exercise? exercise) async {
    if (exercise == null) return false;
    return await exerciseRepo.updateExercise(exercise);
  }

  Future<bool> updateExercise(Exercise exercise) async {
    return await exerciseRepo.updateExercise(exercise);
  }

  Future<bool> deleteExerciseById(int id) async {
    if (id <= 0) return false;
    final result = await exerciseRepo.deleteExerciseById(id);
    AppSnackBar.success('Deleted');
    return result;
  }

  Future<bool> deleteMultipleExerciseByIds(List<int> ids) async {
    if (ids.isEmpty) return false;
    for (final id in ids) {
      await exerciseRepo.deleteExerciseById(id);
    }
    exerciseRepo.loadAll();
    AppSnackBar.success('Deleted');
    return true;
  }
}

import 'package:flutter/material.dart';
import 'package:fossfit/app/features/exercises/exercise/add_edit_exercise.dart';
import 'package:fossfit/app/features/exercises/exercise/cardio_exercise_page.dart';
import 'package:fossfit/app/features/exercises/exercise/strength_exercise_page.dart';
import 'package:fossfit/app/services/features/gym_set_services.dart';
import 'package:fossfit/app/services/features/plan_exercise_services.dart';
import 'package:fossfit/app/services/features/plan_services.dart';
import 'package:fossfit/app/widgets/app_snack_bar.dart';
import 'package:fossfit/db/models/features/cardio_model.dart';
import 'package:fossfit/db/models/features/exercise_model.dart';
import 'package:fossfit/db/models/features/gymset_model.dart';
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
  Future<Exercise?> openStrengthPage(BuildContext context, int exerciseId, List<StrengthData> data) async {
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
              child: StrengthExercisePage(exerciseId: exerciseId, initialData: data),
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

  Future<Exercise?> openCardioPage(BuildContext context, int exerciseId, List<CardioData> data) async {
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
              child: CardioExercisePage(exerciseId: exerciseId, initialData: data),
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

    var services = GymSetServices(context: context);
    var peServices = PlanExerciseServices(context: context);
    var planServices = PlanServices(context: context);
    //get & delete sets
    var sets = services.getSetsByExerciseId(id);
    await services.deleteMultipleGymSetssByIds(sets.map((g) => g.id!).toSet().toList());

    //get & delete plan exercises
    var planExercises = peServices.getPlanExercisesByExerciseId(id);
    await peServices.deleteMultiplePlanExercisesByIds(planExercises.map((p) => p.id!).toSet().toList());

    //get & delete empty plans
    var emptyPlans = planServices.getEmptyPlans();
    if (emptyPlans.isNotEmpty) {
      await planServices.deleteMultiplePlanByIds(emptyPlans.map((p) => p.id!).toSet().toList());
    }

    //delete exercises
    await exerciseRepo.deleteExerciseById(id);

    final result = await exerciseRepo.deleteExerciseById(id);
    return result;
  }

  Future<bool> deleteExercises(List<int> ids) async {
    if (ids.isEmpty) return false;
    for (final id in ids) {
      await deleteExerciseById(id);
    }
    exerciseRepo.loadAll();
    AppSnackBar.success('Deleted');
    return true;
  }
}

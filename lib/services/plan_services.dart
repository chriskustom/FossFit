import 'package:flutter/material.dart';
import 'package:fossfit/db/repositories/exercise_repository.dart';
import 'package:fossfit/db/repositories/plan_exercises_repository.dart';
import 'package:fossfit/db/repositories/plans_repository.dart';
import 'package:fossfit/db/repositories/settings_repository.dart';
import 'package:fossfit/models/exercise_model.dart';
import 'package:fossfit/models/plan_exercise_model.dart';
import 'package:fossfit/models/plan_model.dart';
import 'package:fossfit/widgets/app_snack_bar.dart';
import 'package:provider/provider.dart';

class PlanServices {
  final BuildContext context;
  late PlansRepository planRepo;
  late PlanExercisesRepository planExerciseRepo;
  late ExercisesRepository exerciseRepo;
  late SettingsRepository settingsRepo;
  PlanServices({required this.context}) {
    planExerciseRepo = context.read<PlanExercisesRepository>();
    planRepo = context.read<PlansRepository>();
    settingsRepo = context.read<SettingsRepository>();
    exerciseRepo = context.read<ExercisesRepository>();
  }
  List<Plan> getAllPlans() => planRepo.plans;
  Plan? getPlanById(int id) => planRepo.getPlanById(id);
  List<PlanCount> getPlanCounts() => planRepo.planCounts;
  Future<Plan?> openAddEditPage(BuildContext context, int? planId) async {
    return await showGeneralDialog<Plan?>(
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
              child: null, //TODO EDIT PLAN PAGE
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

  Future<Plan?> addPlan(Plan? plan) async {
    if (plan == null) return null;
    return await planRepo.insertPlan(plan);
  }

  Future<bool> editPlan(Plan? plan) async {
    if (plan == null) return false;
    return await planRepo.updatePlan(plan);
  }

  Future<bool> updatePlan(Plan plan) async {
    return await planRepo.updatePlan(plan);
  }

  Future<bool> deletePlanById(int id) async {
    if (id <= 0) return false;
    final result = await planRepo.deletePlanById(id);
    AppSnackBar.success('Deleted');
    return result;
  }

  Future<bool> deleteMultiplePlanByIds(List<int> ids) async {
    if (ids.isEmpty) return false;
    for (final id in ids) {
      await planRepo.deletePlanById(id);
    }
    planRepo.loadAll();
    AppSnackBar.success('Deleted');
    return true;
  }

  PlanExerciseList? getExercisesByPlanId(int id) {
    var plan = getPlanById(id);
    if (plan == null) return null;
    var planExercises = planExerciseRepo.getPlanExercisesByPlanId(id);
    var exercises = <PlanExercise, Exercise?>{};
    for (var plan in planExercises) {
      var e = exerciseRepo.getExerciseById(plan.exerciseId);
      exercises.putIfAbsent(plan, () => e);
    }
    return PlanExerciseList(plan: plan, exercises: exercises);
  }
}

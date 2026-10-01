import 'package:flutter/material.dart';
import 'package:fossfit/app/features/plans/plan/add_edit_plan_page.dart';
import 'package:fossfit/app/features/plans/plan/plan_page.dart';
import 'package:fossfit/app/widgets/app_snack_bar.dart';
import 'package:fossfit/db/models/features/plan_model.dart';
import 'package:fossfit/db/repositories/config_reposity.dart';
import 'package:fossfit/db/repositories/exercise_repository.dart';
import 'package:fossfit/db/repositories/plan_exercises_repository.dart';
import 'package:fossfit/db/repositories/plan_repository.dart';
import 'package:provider/provider.dart';

class PlanServices {
  final BuildContext context;
  late PlansRepository planRepo;
  late PlanExercisesRepository planExerciseRepo;
  late ExercisesRepository exerciseRepo;
  late ConfigRepository settingsRepo;
  PlanServices({required this.context}) {
    planExerciseRepo = context.read<PlanExercisesRepository>();
    planRepo = context.read<PlansRepository>();
    settingsRepo = context.read<ConfigRepository>();
    exerciseRepo = context.read<ExercisesRepository>();
  }
  List<Plan> getAllPlans() => planRepo.plans;
  Plan? getPlanById(int id) => planRepo.getPlanById(id);
  List<Plan> getEmptyPlans() => planRepo.plans
      .where((p) => !planExerciseRepo.planexercises.map((pe) => pe.planId).toSet().contains(p.id))
      .toSet()
      .toList();
  Future<Plan?> openPlanPage(BuildContext context, int planId) async {
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
              child: PlanPage(planId: planId),
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

  Future<Plan?> openAddEdiPlanPage(BuildContext context, int? planId) async {
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
              child: AddEditPlanPage(planId: planId),
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
    planRepo.loadAll();
    return result;
  }

  Future<bool> deleteMultiplePlanByIds(List<int> ids) async {
    if (ids.isEmpty) return false;
    await planRepo.deletePlansByIds(ids);
    planRepo.loadAll();
    AppSnackBar.success('Deleted');
    return true;
  }
}

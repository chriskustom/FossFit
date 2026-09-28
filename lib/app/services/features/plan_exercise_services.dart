import 'package:flutter/material.dart';
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
}

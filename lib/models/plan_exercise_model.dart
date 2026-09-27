import 'package:fossfit/models/exercise_model.dart';
import 'package:fossfit/models/plan_model.dart';

class PlanExercise {
  int? id;
  final int exerciseId;
  final bool? timers;
  final bool enabled;
  final int maxSets;
  final int? warmupSets;
  final int? planId;
  final int? sequence;

  PlanExercise({
    this.id,
    this.timers,
    required this.enabled,
    required this.maxSets,
    required this.exerciseId,
    this.warmupSets,
    this.planId,
    this.sequence,
  });

  PlanExercise copyWith({
    int? id,
    bool? timers,
    bool? enabled,
    int? maxSets,
    int? exerciseId,
    int? warmupSets,
    int? planId,
    int? sequence,
    Exercise? exercise,
  }) {
    return PlanExercise(
      id: id ?? this.id,
      timers: timers ?? this.timers,
      enabled: enabled ?? this.enabled,
      maxSets: maxSets ?? this.maxSets,
      exerciseId: exerciseId ?? this.exerciseId,
      warmupSets: warmupSets ?? this.warmupSets,
      planId: planId ?? this.planId,
      sequence: sequence ?? this.sequence,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'timers': timers == true ? 1 : 0,
        'enabled': enabled ? 1 : 0,
        'max_sets': maxSets,
        'exercise_id': exerciseId,
        'warmup_sets': warmupSets,
        'plan_id': planId,
        'sequence': sequence,
      };

  factory PlanExercise.fromMap(Map<String, dynamic> map) {
    return PlanExercise(
      id: map['id'],
      timers: map['timers'] == 1,
      enabled: map['enabled'] == 1,
      maxSets: map['max_sets'],
      exerciseId: map['exercise_id'],
      warmupSets: map['warmup_sets'],
      planId: map['plan_id'],
      sequence: map['sequence'],
    );
  }
}

class PlanExerciseList {
  final Plan plan;
  final Map<PlanExercise, Exercise?> exercises;
  PlanExerciseList({required this.plan, required this.exercises});
}

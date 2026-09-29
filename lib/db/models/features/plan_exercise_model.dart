import 'package:fossfit/db/models/base_model.dart';
import 'package:fossfit/db/models/features/exercise_model.dart';

class PlanExercise extends BaseModel {
  final int planId;
  final int exerciseId;
  final int? sequence;
  final int? maxSets;
  final int? rest;

  PlanExercise({
    super.id,
    required this.planId,
    required this.exerciseId,
    this.sequence,
    this.maxSets,
    this.rest,
    super.created,
  });

  @override
  PlanExercise copyWith({
    int? id,
    int? planId,
    int? exerciseId,
    int? sequence,
    int? maxSets,
    int? rest,
    DateTime? created,
  }) {
    return PlanExercise(
      id: id ?? this.id,
      planId: planId ?? this.planId,
      exerciseId: exerciseId ?? this.exerciseId,
      sequence: sequence ?? this.sequence,
      maxSets: maxSets ?? this.maxSets,
      rest: rest ?? this.rest,
      created: created ?? this.created,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'plan_id': planId,
    'exercise_id': exerciseId,
    'sequence': sequence,
    'max_sets': maxSets,
    'rest': rest,
    'created': created.millisecondsSinceEpoch,
  };

  factory PlanExercise.fromMap(Map<String, dynamic> map) {
    return PlanExercise(
      id: map['id'] as int,
      planId: map['plan_id'] as int,
      exerciseId: map['exercise_id'] as int,
      sequence: map['sequence'] as int?,
      maxSets: map['max_sets'] as int?,
      rest: map['rest'] as int?,
      created: DateTime.fromMillisecondsSinceEpoch((map['created']) as int),
    );
  }
}

class ExercisesInPlan {
  final PlanExercise planExercise;
  final Exercise exercise;
  ExercisesInPlan(this.planExercise, this.exercise);
}

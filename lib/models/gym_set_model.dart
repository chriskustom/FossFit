import 'package:fossfit/models/exercise_model.dart';

class GymSet {
  int? id;
  final double bodyWeight;
  final DateTime created;
  final double reps;
  final String unit;
  final double weight;
  final String? notes;
  final int? planId;
  final int? restMs;
  final int exerciseId;
  GymSet({
    this.id,
    required this.bodyWeight,
    required this.exerciseId,
    required this.created,
    required this.reps,
    required this.unit,
    required this.weight,
    this.notes,
    this.planId,
    this.restMs,
  });

  GymSet copyWith({
    int? id,
    double? bodyWeight,
    DateTime? created,
    double? reps,
    String? unit,
    double? weight,
    String? notes,
    int? planId,
    int? restMs,
    int? exerciseId,
  }) {
    return GymSet(
      id: id ?? this.id,
      bodyWeight: bodyWeight ?? this.bodyWeight,
      created: created ?? this.created,
      reps: reps ?? this.reps,
      unit: unit ?? this.unit,
      weight: weight ?? this.weight,
      notes: notes ?? this.notes,
      planId: planId ?? this.planId,
      restMs: restMs ?? this.restMs,
      exerciseId: exerciseId ?? this.exerciseId,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'body_weight': bodyWeight,
        'created': created.millisecondsSinceEpoch,
        'reps': reps,
        'unit': unit,
        'weight': weight,
        'notes': notes,
        'plan_id': planId,
        'rest_ms': restMs,
        'exercise_id': exerciseId,
      };

  factory GymSet.fromMap(Map<String, dynamic> map) {
    return GymSet(
      id: map['id'] as int?,
      bodyWeight: (map['body_weight'] as num).toDouble(),
      created: DateTime.fromMillisecondsSinceEpoch((map['created'] as num).toInt()),
      reps: (map['reps'] as num).toDouble(),
      unit: map['unit'] as String,
      weight: (map['weight'] as num).toDouble(),
      notes: map['notes'] as String?,
      planId: (map['plan_id'] as num?)?.toInt(),
      restMs: (map['rest_ms'] as num?)?.toInt(),
      exerciseId: (map['exercise_id'] as num).toInt(),
    );
  }
}

class GymSetExercise {
  final GymSet gymSet;
  final Exercise exercise;
  GymSetExercise({required this.gymSet, required this.exercise});
}

class StrengthData {
  final DateTime created;
  final double reps;
  final String unit;
  final double value;
  final String? category;

  StrengthData({
    required this.created,
    required this.reps,
    required this.unit,
    required this.value,
    this.category,
  });
}

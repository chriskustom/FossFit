import 'package:fossfit/db/models/base_model.dart';

class GymSet extends BaseModel {
  final double reps;
  final double weight;
  final String? unit;
  final String? note;
  final double? bodyWeight;
  final int? rest;
  final int? planId;
  final int exerciseId;

  GymSet({
    super.id,
    required this.reps,
    required this.weight,
    this.unit,
    this.note,
    this.bodyWeight,
    this.rest,
    required this.exerciseId,
    this.planId,
    super.created,
  });

  @override
  GymSet copyWith({
    int? id,
    double? reps,
    double? weight,
    String? unit,
    String? note,
    double? bodyWeight,
    int? rest,
    int? exerciseId,
    int? planId,
    DateTime? created,
  }) {
    return GymSet(
      id: id ?? this.id,
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      unit: unit ?? this.unit,
      note: note ?? this.note,
      rest: rest ?? this.rest,
      bodyWeight: bodyWeight ?? this.bodyWeight,
      exerciseId: exerciseId ?? this.exerciseId,
      planId: planId ?? this.planId,
      created: created ?? this.created,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'reps': reps,
    'weight': weight,
    'unit': unit,
    'notes': note,
    'rest_ms': rest,
    'body_weight': bodyWeight,
    'exercise_id': exerciseId,
    'plan_id': planId,
    'created': created.millisecondsSinceEpoch,
  };

  factory GymSet.fromMap(Map<String, dynamic> map) {
    return GymSet(
      id: map['id'] as int?,
      reps: map['reps'] as double,
      weight: map['weight'] as double,
      unit: map['unit'] as String,
      note: map['notes'] as String?,
      rest: map['rest_ms'] as int?,
      bodyWeight: map['body_weight'] as double?,
      exerciseId: map['exercise_id'] as int,
      planId: map['plan_id'] as int?,
      created: DateTime.fromMillisecondsSinceEpoch((map['created'] as num).toInt()),
    );
  }
}

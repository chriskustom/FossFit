import 'package:fossfit/db/models/base_model.dart';

class GymSet extends BaseModel {
  final int reps;
  final double weight;
  final String? unit;
  final String? note;
  final double? bodyWeight;
  final int? planId;
  final int exerciseId;

  GymSet({
    super.id,
    required this.reps,
    required this.weight,
    this.unit,
    this.note,
    this.bodyWeight,
    required this.exerciseId,
    this.planId,
    super.created,
  });

  @override
  GymSet copyWith({
    int? id,
    int? reps,
    double? weight,
    String? unit,
    String? note,
    double? bodyWeight,
    int? exerciseId,
    int? planId,
    DateTime? created,
  }) {
    return GymSet(
      id: id ?? super.id,
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      unit: unit ?? this.unit,
      note: note ?? this.note,
      bodyWeight: bodyWeight ?? this.bodyWeight,
      exerciseId: exerciseId ?? this.exerciseId,
      planId: planId ?? this.planId,
      created: created ?? super.created,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'reps': reps,
    'weight': weight,
    'unit': unit,
    'note': note,
    'body_weight': bodyWeight,
    'exercise_id': exerciseId,
    'plan_id': planId,
    'created': created.millisecondsSinceEpoch,
  };

  factory GymSet.fromMap(Map<String, dynamic> map) {
    return GymSet(
      id: map['id'] as int?,
      reps: map['reps'] as int,
      weight: map['weight'] as double,
      unit: map['unit'] as String,
      note: map['note'] as String?,
      bodyWeight: map['body_weight'] as double?,
      exerciseId: map['exercise_id'] as int,
      planId: map['plan_id'] as int?,
      created: DateTime.fromMillisecondsSinceEpoch((map['created'] as num).toInt()),
    );
  }
}

class StrengthData {
  final DateTime created;
  final double reps;
  final String unit;
  final double value;
  final String? category;

  StrengthData({required this.created, required this.reps, required this.unit, required this.value, this.category});
}

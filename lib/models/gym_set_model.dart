import 'package:fossfit/models/exercise_model.dart';

class GymSet {
  int? id;
  final double? bodyWeight;
  final DateTime created;
  final double? distance;
  final double? duration;
  final bool hidden;
  final double reps;
  final String unit;
  final double weight;
  final int? incline;
  final String? notes;
  final int? planId;
  final int? restMs;
  final int exerciseId;
  final Exercise? exercise;
  GymSet({
    this.id,
    this.bodyWeight,
    required this.exerciseId,
    required this.created,
    this.distance,
    this.duration,
    required this.hidden,
    required this.reps,
    required this.unit,
    required this.weight,
    this.incline,
    this.notes,
    this.planId,
    this.restMs,
    this.exercise,
  });

  GymSet copyWith({
    int? id,
    double? bodyWeight,
    DateTime? created,
    double? distance,
    double? duration,
    bool? hidden,
    double? reps,
    String? unit,
    double? weight,
    int? incline,
    String? notes,
    int? planId,
    int? restMs,
    int? exerciseId,
    Exercise? exercise,
  }) {
    return GymSet(
      id: id ?? this.id,
      bodyWeight: bodyWeight ?? this.bodyWeight,
      created: created ?? this.created,
      distance: distance ?? this.distance,
      duration: duration ?? this.duration,
      hidden: hidden ?? this.hidden,
      reps: reps ?? this.reps,
      unit: unit ?? this.unit,
      weight: weight ?? this.weight,
      incline: incline ?? this.incline,
      notes: notes ?? this.notes,
      planId: planId ?? this.planId,
      restMs: restMs ?? this.restMs,
      exerciseId: exerciseId ?? this.exerciseId,
      exercise: exercise ?? this.exercise,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'body_weight': bodyWeight,
        'created': created.millisecondsSinceEpoch,
        'distance': distance,
        'duration': duration,
        'hidden': hidden ? 1 : 0,
        'reps': reps,
        'unit': unit,
        'weight': weight,
        'incline': incline,
        'notes': notes,
        'plan_id': planId,
        'rest_ms': restMs,
        'exercise_id': exerciseId,
      };

  factory GymSet.fromMap(Map<String, dynamic> map) {
    return GymSet(
      id: map['id'] as int?,
      bodyWeight: (map['body_weight'] as num).toDouble(),
      created:
          DateTime.fromMillisecondsSinceEpoch((map['created'] as num).toInt()),
      distance: (map['distance'] as num).toDouble(),
      duration: (map['duration'] as num).toDouble(),
      hidden: map['hidden'] == 1,
      reps: (map['reps'] as num).toDouble(),
      unit: map['unit'] as String,
      weight: (map['weight'] as num).toDouble(),
      incline: (map['incline'] as num?)?.toInt(),
      notes: map['notes'] as String?,
      planId: (map['plan_id'] as num?)?.toInt(),
      restMs: (map['rest_ms'] as num?)?.toInt(),
      exerciseId: (map['exercise_id'] as num).toInt(),
    );
  }
  factory GymSet.fromJoinedMap(Map<String, dynamic> map) {
    final gymSet = GymSet.fromMap(map);

    final exercise = map['exercise_name'] == null
        ? null
        : Exercise(
            id: (map['exercise_id'] as num).toInt(),
            name: map['exercise_name'] as String,
            cardio: map['exercise_cardio'] == 1,
            category: map['exercise_category'] as String,
            image: map['exercise_image'] as String,
          );

    return gymSet.copyWith(
      exercise: exercise,
    );
  }
}

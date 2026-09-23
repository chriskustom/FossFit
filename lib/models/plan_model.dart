import 'package:fossfit/models/plan_exercise_model.dart';

class Plan {
  int? id;
  final String days;
  final int? sequence;
  final String? title;
  final List<PlanExercise>? exercises;
  Plan({
    this.id,
    required this.days,
    this.sequence,
    required this.title,
    this.exercises,
  });

  Plan copyWith({
    int? id,
    String? days,
    int? sequence,
    String? title,
    List<PlanExercise>? exercises,
  }) {
    return Plan(
      id: id ?? this.id,
      days: days ?? this.days,
      sequence: sequence ?? this.sequence,
      title: title ?? this.title,
      exercises: exercises ?? this.exercises,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'days': days,
        'sequence': sequence,
        'title': title,
      };

  factory Plan.fromMap(Map<String, dynamic> map) {
    return Plan(
      id: map['id'],
      days: map['days'],
      sequence: map['sequence'],
      title: map['title'],
    );
  }
  factory Plan.fromJoinedMap(
    Map<String, dynamic> map, {
    List<PlanExercise>? exercises,
  }) {
    return Plan(
      id: (map['id'] as num?)?.toInt(),
      days: map['days'] as String,
      sequence: (map['sequence'] as num?)?.toInt(),
      title: map['title'] as String?,
      exercises: exercises,
    );
  }
}

import 'package:fossfit/db/models/features/plan_exercise_model.dart';

class Plan {
  int? id;
  final String days;
  final int? sequence;
  final String? name;
  Plan({this.id, required this.days, this.sequence, required this.name});

  Plan copyWith({int? id, String? days, int? sequence, String? name}) {
    return Plan(
      id: id ?? this.id,
      days: days ?? this.days,
      sequence: sequence ?? this.sequence,
      name: name ?? this.name,
    );
  }

  Map<String, dynamic> toMap() => {'id': id, 'days': days, 'sequence': sequence, 'name': name};

  factory Plan.fromMap(Map<String, dynamic> map) {
    return Plan(id: map['id'], days: map['days'], sequence: map['sequence'], name: map['name']);
  }
}

class PlanExercises {
  final Plan plan;
  final List<PlanExercise> exercises;

  PlanExercises(this.plan, this.exercises);
}

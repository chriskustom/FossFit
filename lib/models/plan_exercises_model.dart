class PlanExercises {
  int? id;
  final String exercise;
  final bool timers;
  final bool enabled;
  final int maxsets;
  final int? warmupSets;
  final int? planId;
  final int? sequence;

  PlanExercises({
    this.id,
    required this.timers,
    required this.enabled,
    required this.maxsets,
    required this.exercise,
    this.warmupSets,
    this.planId,
    this.sequence,
  });

  PlanExercises copyWith({
    int? id,
    bool? timers,
    bool? enabled,
    int? maxsets,
    String? exercise,
    int? warmupSets,
    int? planId,
    int? sequence,
  }) {
    return PlanExercises(
      id: id ?? this.id,
      timers: timers ?? this.timers,
      enabled: enabled ?? this.enabled,
      maxsets: maxsets ?? this.maxsets,
      exercise: exercise ?? this.exercise,
      warmupSets: warmupSets ?? this.warmupSets,
      planId: planId ?? this.planId,
      sequence: sequence ?? this.sequence,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'timers': timers ? 1 : 0,
        'enabled': enabled ? 1 : 0,
        'max_sets': maxsets,
        'exercise': exercise,
        'warmup_sets': warmupSets,
        'plan_id': planId,
        'sequence': sequence,
      };

  factory PlanExercises.fromMap(Map<String, dynamic> map) {
    return PlanExercises(
      id: map['id'],
      timers: map['timers'] == 1,
      enabled: map['enabled'] == 1,
      maxsets: map['max_sets'],
      exercise: map['exercise'],
      warmupSets: map['warmup_sets'],
      planId: map['plan_id'],
      sequence: map['sequence'],
    );
  }
}

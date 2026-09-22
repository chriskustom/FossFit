class GymSets {
  int? id;
  final double? bodyWeight;
  final bool cardio;
  final DateTime created;
  final double? distance;
  final double? duration;
  final bool hidden;
  final String name;
  final double reps;
  final String unit;
  final double weight;
  final String? category;
  final String? image;
  final int? incline;
  final String? notes;
  final int? planId;
  final int? restMs;
  GymSets({
    this.id,
    this.bodyWeight,
    required this.cardio,
    required this.created,
    this.distance,
    this.duration,
    required this.hidden,
    required this.name,
    required this.reps,
    required this.unit,
    required this.weight,
    this.category,
    this.image,
    this.incline,
    this.notes,
    this.planId,
    this.restMs,
  });

  GymSets copyWith({
    int? id,
    double? bodyWeight,
    bool? cardio,
    DateTime? created,
    double? distance,
    double? duration,
    bool? hidden,
    String? name,
    double? reps,
    String? unit,
    double? weight,
    String? category,
    String? image,
    int? incline,
    String? notes,
    int? planId,
    int? restMs,
  }) {
    return GymSets(
      id: id ?? this.id,
      bodyWeight: bodyWeight ?? this.bodyWeight,
      cardio: cardio ?? this.cardio,
      created: created ?? this.created,
      distance: distance ?? this.distance,
      duration: duration ?? this.duration,
      hidden: hidden ?? this.hidden,
      name: name ?? this.name,
      reps: reps ?? this.reps,
      unit: unit ?? this.unit,
      weight: weight ?? this.weight,
      category: category ?? this.category,
      image: image ?? this.image,
      incline: incline ?? this.incline,
      notes: notes ?? this.notes,
      planId: planId ?? this.planId,
      restMs: restMs ?? this.restMs,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'body_weight': bodyWeight,
        'cardio': cardio ? 1 : 0,
        'created': created.millisecondsSinceEpoch,
        'distance': distance,
        'duration': duration,
        'hidden': hidden ? 1 : 0,
        'name': name,
        'reps': reps,
        'unit': unit,
        'weight': weight,
        'category': category,
        'image': image,
        'incline': incline,
        'notes': notes,
        'plan_id': planId,
        'rest_ms': restMs,
      };

  factory GymSets.fromMap(Map<String, dynamic> map) {
    return GymSets(
      id: map['id'] as int?,
      bodyWeight: (map['body_weight'] as num).toDouble(),
      cardio: map['cardio'] == 1,
      created: DateTime.fromMillisecondsSinceEpoch((map['created'] as num).toInt()),
      distance: (map['distance'] as num).toDouble(),
      duration: (map['duration'] as num).toDouble(),
      hidden: map['hidden'] == 1,
      name: map['name'] as String,
      reps: (map['reps'] as num).toDouble(),
      unit: map['unit'] as String,
      weight: (map['weight'] as num).toDouble(),
      category: map['category'] as String?,
      image: map['image'] as String?,
      incline: (map['incline'] as num?)?.toInt(),
      notes: map['notes'] as String?,
      planId: (map['plan_id'] as num?)?.toInt(),
      restMs: (map['rest_ms'] as num?)?.toInt(),
    );
  }
}

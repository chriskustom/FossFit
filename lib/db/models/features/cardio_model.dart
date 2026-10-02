import 'package:fossfit/db/models/base_model.dart';

class Cardio extends BaseModel {
  final int duration;
  final double? distance;
  final String distanceUnit;
  final String? pace;
  final double? incline;
  final String? note;
  final int? planId;
  final int exerciseId;

  Cardio({
    super.id,
    required this.duration,
    required this.distance,
    required this.distanceUnit,
    this.pace,
    this.incline,
    this.note,
    required this.exerciseId,
    this.planId,
    super.created,
  });

  @override
  Cardio copyWith({
    int? id,
    int? duration,
    double? distance,
    String? distanceUnit,
    String? pace,
    double? incline,
    String? note,
    double? bodyWeight,
    int? exerciseId,
    int? planId,
    DateTime? created,
  }) {
    return Cardio(
      id: id ?? super.id,
      duration: duration ?? this.duration,
      distance: distance ?? this.distance,
      distanceUnit: distanceUnit ?? this.distanceUnit,
      pace: pace ?? this.pace,
      incline: incline ?? this.incline,
      note: note ?? this.note,
      exerciseId: exerciseId ?? this.exerciseId,
      planId: planId ?? this.planId,
      created: created ?? super.created,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'duration': duration,
    'distance': distance,
    'distance_unit': distanceUnit,
    'pace': pace,
    'incline': incline,
    'note': note,
    'exercise_id': exerciseId,
    'plan_id': planId,
    'created': created.millisecondsSinceEpoch,
  };

  factory Cardio.fromMap(Map<String, dynamic> map) {
    return Cardio(
      id: map['id'] as int?,
      duration: map['duration'] as int,
      distance: map['distance'] as double,
      distanceUnit: map['distance_unit'] as String,
      pace: map['pace'] as String?,
      incline: map['incline'] as double?,
      note: map['note'] as String?,
      exerciseId: map['exercise_id'] as int,
      planId: map['plan_id'] as int?,
      created: DateTime.fromMillisecondsSinceEpoch((map['created'] as num).toInt()),
    );
  }
}

class CardioData {
  final DateTime created;
  final double value;
  final String unit;

  CardioData({required this.created, required this.value, required this.unit});
}

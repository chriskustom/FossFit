import 'package:fossfit/models/gym_set_model.dart';

class Exercise {
  int? id;
  final String name;
  final bool cardio;
  final String? category;
  final String? image;
  Exercise({
    this.id,
    required this.name,
    required this.cardio,
    this.category,
    this.image,
  });

  bool hasImage() => image != null && image != '';

  Exercise copyWith({
    int? id,
    bool? cardio,
    String? name,
    String? category,
    String? image,
  }) {
    return Exercise(
      id: id ?? this.id,
      cardio: cardio ?? this.cardio,
      name: name ?? this.name,
      category: category ?? this.category,
      image: image ?? this.image,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'cardio': cardio ? 1 : 0,
        'name': name,
        'category': category,
        'image': image,
      };

  factory Exercise.fromMap(Map<String, dynamic> map) {
    return Exercise(
      id: map['id'] as int?,
      cardio: map['cardio'] == 1,
      name: map['name'] as String,
      category: map['category'] as String?,
      image: map['image'] as String?,
    );
  }
}

class ExerciseItem {
  final int exerciseId;
  final String name;
  final List<GymSet> sets;
  final DateTime date;

  ExerciseItem({
    required this.exerciseId,
    required this.name,
    required this.sets,
    required this.date,
  });
}

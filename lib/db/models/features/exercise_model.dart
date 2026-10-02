import 'dart:typed_data';

import 'package:fossfit/db/models/base_model.dart';
import 'package:fossfit/db/models/features/cardio_model.dart';
import 'package:fossfit/db/models/features/gymset_model.dart';

class Exercise extends BaseModel {
  final String name;
  final int type;
  final String? category;
  final String? description;
  final Uint8List? image;
  final int? defaultSets;
  final String? defaultUnit;

  Exercise({
    super.id,
    super.created,
    required this.name,
    required this.type,
    this.category,
    this.description,
    this.image,
    this.defaultSets,
    this.defaultUnit,
  });

  bool hasImage() => image != null && image!.isNotEmpty;

  @override
  Exercise copyWith({
    int? id,
    String? name,
    int? type,
    String? category,
    String? description,
    Uint8List? image,
    int? defaultSets,
    String? defaultUnit,
    DateTime? created,
  }) {
    return Exercise(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      category: category ?? this.category,
      description: description ?? this.description,
      image: image ?? this.image,
      defaultSets: defaultSets ?? this.defaultSets,
      defaultUnit: defaultUnit ?? this.defaultUnit,
      created: created ?? this.created,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'type': type,
    'category': category,
    'description': description,
    'default_sets': defaultSets,
    'default_unit': defaultUnit,
    'image': image,
    'created': created.millisecondsSinceEpoch,
  };

  factory Exercise.fromMap(Map<String, dynamic> map) {
    return Exercise(
      id: map['id'] as int?,
      name: map['name'] as String,
      type: map['type'] as int,
      category: map['category'] as String?,
      description: map['description'] as String?,
      image: map['image'] ?? Uint8List(0),
      defaultSets: map['default_sets'] as int?,
      defaultUnit: map['default_unit'] as String?,
      created: DateTime.fromMicrosecondsSinceEpoch((map['created']) as int),
    );
  }
}

class ExerciseSets {
  final Exercise exercise;
  final List<GymSet>? gymSets;
  final List<Cardio>? cardioSets;
  final DateTime date;

  ExerciseSets({required this.exercise, this.gymSets, required this.date, this.cardioSets});
}

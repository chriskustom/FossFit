import 'dart:typed_data';

import 'package:fossfit/db/models/base_model.dart';
import 'package:fossfit/db/models/features/gymset_model.dart';

class Exercise extends BaseModel {
  final String name;
  final String? category;
  final String? description;
  final Uint8List? image;
  final int? defaultSets;
  final int? defaultRest;
  final String? defaultUnit;

  Exercise({
    super.id,
    super.created,
    required this.name,
    this.category,
    this.description,
    this.image,
    this.defaultSets,
    this.defaultRest,
    this.defaultUnit,
  });

  bool hasImage() => image != null && image!.isNotEmpty;

  @override
  Exercise copyWith({
    int? id,
    String? name,
    String? category,
    String? description,
    Uint8List? image,
    int? defaultSets,
    int? defaultRest,
    String? defaultUnit,
    DateTime? created,
  }) {
    return Exercise(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      description: description ?? this.description,
      image: image ?? this.image,
      defaultSets: defaultSets ?? this.defaultSets,
      defaultRest: defaultRest ?? this.defaultRest,
      defaultUnit: defaultUnit ?? this.defaultUnit,
      created: created ?? this.created,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'category': category,
    'description': description,
    'default_sets': defaultSets,
    'default_rest': defaultRest,
    'default_unit': defaultUnit,
    'image': image,
    'created': created.millisecondsSinceEpoch,
  };

  factory Exercise.fromMap(Map<String, dynamic> map) {
    return Exercise(
      id: map['id'] as int?,
      name: map['name'] as String,
      category: map['category'] as String?,
      description: map['description'] as String?,
      image: map['image'] ?? Uint8List(0),
      defaultSets: map['default_sets'] as int?,
      defaultRest: map['default_rest'] as int?,
      defaultUnit: map['default_unit'] as String?,
      created: DateTime.fromMicrosecondsSinceEpoch((map['created']) as int),
    );
  }
}

class ExerciseSets {
  final Exercise exercise;
  final List<GymSet> sets;
  final DateTime date;

  ExerciseSets({required this.exercise, required this.sets, required this.date});
}

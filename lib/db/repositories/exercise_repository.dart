import 'package:flutter/foundation.dart';
import 'package:fossfit/db/db_constants.dart';
import 'package:fossfit/db/models/features/exercise_model.dart';
import 'package:sqflite/sqflite.dart';

class ExercisesRepository extends ChangeNotifier {
  final Database _db;

  List<Exercise> _exercises = [];

  List<Exercise> _cardioExercises = [];
  List<Exercise> _strengthExercises = [];
  ExercisesRepository(this._db);

  List<Exercise> get exercises => List.unmodifiable(_exercises);
  List<Exercise> get cardioExercises => List.unmodifiable(_cardioExercises);
  List<Exercise> get strengthExercises => List.unmodifiable(_strengthExercises);

  // ---------------------------------------------------------------------------
  // Basic CRUD
  // ---------------------------------------------------------------------------

  Future<void> loadAll() async {
    final rows = await _db.query(TableName.exercises.name, orderBy: 'name ASC');

    _exercises = rows.map((r) => Exercise.fromMap(r)).toList();
    _cardioExercises = _exercises.where((e) => e.type == 1).toList();
    _strengthExercises = _exercises.where((e) => e.type == 0).toList();
    notifyListeners();
  }

  Exercise? getExerciseById(int id, {int? type}) {
    if (type != null) return _exercises.where((n) => n.id == id && type == type).firstOrNull;
    return _exercises.where((n) => n.id == id).firstOrNull;
  }

  Exercise? getExerciseByName(String name, {int? type}) {
    if (type != null) return _exercises.where((n) => n.name == name && type == type).firstOrNull;
    return _exercises.where((n) => n.name == name).firstOrNull;
  }

  List<Exercise> getExercisesByIds(List<int> ids) {
    return _exercises.where((n) => ids.contains(n.id)).toList();
  }

  Future<List<String>> getDistinctCategories() async {
    final rows = await _db.query('exercises', columns: ['category'], distinct: true, where: 'category IS NOT NULL', orderBy: 'category ASC');

    final categories = rows.map((row) => row['category'] as String).toList();
    return categories;
  }

  Future<List<String>> getStrengthExerciseNames() async {
    final rows = await _db.query('exercises', columns: ['name'], where: 'type = ?', whereArgs: ['0'], distinct: true, orderBy: 'name ASC');

    final categories = rows.map((row) => row['name'] as String).toList();
    return categories;
  }

  Future<List<String>> getCardioExerciseNames() async {
    final rows = await _db.query('exercises', columns: ['name'], where: 'type = ?', whereArgs: ['1'], distinct: true, orderBy: 'name ASC');

    final categories = rows.map((row) => row['name'] as String).toList();
    return categories;
  }

  Future<Exercise> addExercise(Exercise exercises) async {
    exercises.id = await _db.insert(TableName.exercises.name, exercises.toMap());

    final index = _exercises.indexWhere((e) => e.id == exercises.id);

    if (index >= 0) {
      _exercises[index] = exercises;
    } else {
      _exercises.add(exercises);
    }

    notifyListeners();

    return exercises;
  }

  Future<bool> updateExercise(Exercise? exercises) async {
    if (exercises == null) {
      return false;
    }

    final count = await _db.update(TableName.exercises.name, exercises.toMap(), where: 'id = ?', whereArgs: [exercises.id]);

    if (count <= 0) {
      return false;
    }

    final index = _exercises.indexWhere((e) => e.id == exercises.id);

    if (index >= 0) {
      _exercises[index] = exercises;
    } else {
      _exercises.add(exercises);
    }

    notifyListeners();

    return true;
  }

  Future<void> deleteExercisesByIds(List<int> ids) async {
    for (var id in ids) {
      await deleteExerciseById(id);
    }
  }

  Future<bool> deleteExerciseById(int id) async {
    final exercises = getExerciseById(id);

    if (exercises == null) {
      return false;
    }

    final count = await _db.delete(TableName.exercises.name, where: 'id = ?', whereArgs: [exercises.id]);

    if (count <= 0) {
      return false;
    }

    final index = _exercises.indexWhere((e) => e.id == exercises.id);

    if (index >= 0) {
      _exercises.remove(exercises);
    }

    notifyListeners();

    return true;
  }
}

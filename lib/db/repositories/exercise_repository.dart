import 'package:flutter/foundation.dart';
import 'package:fossfit/db/db_constants.dart';
import 'package:fossfit/models/exercise_model.dart';
import 'package:sqflite/sqflite.dart';

class ExercisesRepository extends ChangeNotifier {
  final Database _db;

  List<Exercise> _exercises = [];

  ExercisesRepository(this._db);

  List<Exercise> get exercises => List.unmodifiable(_exercises);

  // ---------------------------------------------------------------------------
  // Basic CRUD
  // ---------------------------------------------------------------------------

  Future<void> loadAll() async {
    final rows = await _db.query(
      TableName.exercises.name,
      orderBy: 'name ASC',
    );

    _exercises = rows.map((r) => Exercise.fromMap(r)).toList();

    notifyListeners();
  }

  Exercise? getExerciseById(int id) {
    return _exercises.where((n) => n.id == id).firstOrNull;
  }

  Exercise? getExerciseByName(String name) {
    return _exercises.where((n) => n.name == name).firstOrNull;
  }

  List<Exercise> getExercisesByIds(List<int> ids) {
    return _exercises.where((n) => ids.contains(n.id)).toList();
  }

  Future<List<String>> getDistinctCategories() async {
    final rows = await _db.query(
      'exercises',
      columns: ['category'],
      distinct: true,
      where: 'category IS NOT NULL',
      orderBy: 'category ASC',
    );

    final categories = rows.map((row) => row['category'] as String).toList();
    return categories;
  }

  Future<Exercise> addExercise(Exercise exercises) async {
    exercises.id = await _db.insert(
      TableName.exercises.name,
      exercises.toMap(),
    );

    final index = _exercises.indexWhere(
      (e) => e.id == exercises.id,
    );

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

    final count = await _db.update(
      TableName.exercises.name,
      exercises.toMap(),
      where: 'id = ?',
      whereArgs: [exercises.id],
    );

    if (count <= 0) {
      return false;
    }

    final index = _exercises.indexWhere(
      (e) => e.id == exercises.id,
    );

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

    final count = await _db.delete(
      TableName.exercises.name,
      where: 'id = ?',
      whereArgs: [exercises.id],
    );

    if (count <= 0) {
      return false;
    }

    final index = _exercises.indexWhere(
      (e) => e.id == exercises.id,
    );

    if (index >= 0) {
      _exercises.remove(exercises);
    }

    notifyListeners();

    return true;
  }

  Future<void> truncateTable() async {
    await _db.execute('DELETE FROM exercises;');
    await loadAll();
  }
}

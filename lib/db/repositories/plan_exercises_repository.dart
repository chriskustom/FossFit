import 'package:flutter/foundation.dart';
import 'package:fossfit/db/db_constants.dart';
import 'package:fossfit/db/models/features/plan_exercise_model.dart';
import 'package:sqflite/sqflite.dart';

class PlanExercisesRepository extends ChangeNotifier {
  final Database _db;

  List<PlanExercise> _planexercises = [];

  PlanExercisesRepository(this._db);

  List<PlanExercise> get planexercises => List.unmodifiable(_planexercises);

  Future<void> loadAll() async {
    final rows = await _db.query(TableName.planexercises.name, orderBy: 'plan_id ASC, sequence ASC');

    _planexercises = rows.map((r) => PlanExercise.fromMap(r)).toList();

    notifyListeners();
  }

  PlanExercise? getPlanExerciseById(int id) {
    return _planexercises.where((n) => n.id == id).firstOrNull;
  }

  PlanExercise? getPlanExerciseByExerciseAndPlan(int id, int planId) {
    return _planexercises.where((n) => n.exerciseId == id && n.planId == planId).firstOrNull;
  }

  List<PlanExercise> getPlanExercisesByPlanId(int planId) {
    final result = _planexercises.where((n) => n.planId == planId).toList();

    result.sort((a, b) {
      return a.sequence.compareTo(b.sequence);
    });

    return result;
  }

  bool exists(int eId, int pId) => getPlanExerciseByExerciseAndPlan(eId, pId) != null;

  Future<PlanExercise> insertPlanExercise(PlanExercise planExercise) async {
    final id = await _db.insert(TableName.planexercises.name, planExercise.toMap());

    planExercise.id = id;

    final index = _planexercises.indexWhere((e) => e.planId == planExercise.planId && e.exerciseId == planExercise.exerciseId);

    if (index >= 0) {
      _planexercises[index] = planExercise;
    } else {
      _planexercises.add(planExercise);
    }

    //notifyListeners();

    return planExercise;
  }

  Future<bool> reorderPlanExercises(int planId, int oldIndex, int newIndex) async {
    final planExercises = _planexercises.where((e) => e.planId == planId).toList()..sort((a, b) => a.sequence.compareTo(b.sequence));

    if (oldIndex < 0 || oldIndex >= planExercises.length || newIndex < 0 || newIndex >= planExercises.length) {
      return false;
    }

    final moved = planExercises.removeAt(oldIndex);
    planExercises.insert(newIndex, moved);

    final updatedPlanExercises = [for (int i = 0; i < planExercises.length; i++) planExercises[i].copyWith(sequence: i)];

    // Update the in-memory global list.
    final updatedById = {for (final exercise in updatedPlanExercises) exercise.id!: exercise};

    _planexercises = [
      for (final exercise in _planexercises)
        if (updatedById.containsKey(exercise.id)) updatedById[exercise.id]! else exercise,
    ];

    notifyListeners();

    // Persist only this plan's exercises.
    for (final exercise in updatedPlanExercises) {
      await _persistPlanExercise(exercise);
    }

    return true;
  }

  Future<bool> _persistPlanExercise(PlanExercise planExercise) async {
    final count = await _db.update(TableName.planexercises.name, planExercise.toMap(), where: 'id = ?', whereArgs: [planExercise.id]);

    return count > 0;
  }

  Future<bool> updatePlanExercise(PlanExercise? planExercise) async {
    if (planExercise == null) {
      return false;
    }

    if (!await _persistPlanExercise(planExercise)) {
      return false;
    }

    final index = _planexercises.indexWhere((e) => e.planId == planExercise.planId && e.exerciseId == planExercise.exerciseId);

    if (index >= 0) {
      _planexercises[index] = planExercise;
    } else {
      _planexercises.add(planExercise);
    }

    notifyListeners();

    return true;
  }

  Future<bool> deletePlanExerciseByIdAndPlanId(int exerciseId, int planId) async {
    final deleted = await _db.delete(TableName.planexercises.name, where: 'exercise_id = ? AND plan_id = ?', whereArgs: [exerciseId, planId]);

    if (deleted <= 0) {
      return false;
    }

    _planexercises.removeWhere((e) => e.exerciseId == exerciseId && e.planId == planId);

    //notifyListeners();

    return true;
  }

  Future<bool> deleteAllExerciseForPlanById(int planId) async {
    final deleted = await _db.delete(TableName.planexercises.name, where: 'plan_id = ?', whereArgs: [planId]);

    if (deleted <= 0) {
      return false;
    }

    _planexercises.removeWhere((e) => e.planId == planId);

    //notifyListeners();

    return true;
  }

  Future<bool> deleteAllExercisesForPlansByIds(List<int> ids) async {
    if (ids.isEmpty) {
      return false;
    }

    final deleted = await _db.delete(TableName.planexercises.name, where: 'plan_id IN (${List.filled(ids.length, '?').join(',')})', whereArgs: ids);

    if (deleted <= 0) {
      return false;
    }

    _planexercises.removeWhere((e) => ids.contains(e.planId));

    //notifyListeners();

    return true;
  }
}

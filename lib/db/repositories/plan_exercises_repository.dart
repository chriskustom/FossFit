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

  PlanExercise? getPlanExercisesById(int id, int planId) {
    return _planexercises.where((n) => n.exerciseId == id && n.planId == planId).firstOrNull;
  }

  List<PlanExercise> getPlanExercisesByPlanId(int planId) {
    final result = _planexercises.where((n) => n.planId == planId).toList();

    result.sort((a, b) => (a.sequence ?? 0).compareTo(b.sequence ?? 0));

    return result;
  }

  Future<PlanExercise> insertPlanExercise(PlanExercise planExercise) async {
    final id = await _db.insert(TableName.planexercises.name, planExercise.toMap());

    planExercise.id = id;

    final index = _planexercises.indexWhere((e) => e.planId == planExercise.planId && e.exerciseId == planExercise.exerciseId);

    if (index >= 0) {
      _planexercises[index] = planExercise;
    } else {
      _planexercises.add(planExercise);
    }

    notifyListeners();

    return planExercise;
  }

  Future<bool> updatePlanExercise(PlanExercise? planExercise) async {
    if (planExercise == null) {
      return false;
    }

    final updated = await _db.update(TableName.planexercises.name, planExercise.toMap(), where: 'plan_id = ? AND exercise_id = ?', whereArgs: [planExercise.planId, planExercise.exerciseId]);

    if (updated <= 0) {
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

    notifyListeners();

    return true;
  }

  Future<bool> deleteAllExerciseForPlanById(int planId) async {
    final deleted = await _db.delete(TableName.planexercises.name, where: 'plan_id = ?', whereArgs: [planId]);

    if (deleted <= 0) {
      return false;
    }

    _planexercises.removeWhere((e) => e.planId == planId);

    notifyListeners();

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

    notifyListeners();

    return true;
  }
}

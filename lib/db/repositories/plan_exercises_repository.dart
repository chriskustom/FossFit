import 'package:flutter/foundation.dart';
import 'package:fossfit/db/db_constants.dart';
import 'package:fossfit/models/plan_exercises_model.dart';
import 'package:sqflite/sqflite.dart';

class PlanExercisesRepository extends ChangeNotifier {
  final Database _db;
  List<PlanExercises> _planexercises = [];
  PlanExercisesRepository(this._db);

  List<PlanExercises> get planexercises => List.unmodifiable(_planexercises);

  Future loadAll() async {
    final rows = await _db.query(TableName.planexercises.name, orderBy: 'sequence ASC');
    _planexercises = rows.map((r) => PlanExercises.fromMap(r)).toList();
    notifyListeners();
  }

  PlanExercises? getPlanExercisesByName(String name, int planId) =>
      _planexercises.where((n) => n.exercise == name && n.planId == planId).firstOrNull;

  List<PlanExercises> getPlanExercisesByPlanId(int planId) => _planexercises.where((n) => n.planId == planId).toList();

  Future<PlanExercises> addPlanExercises(PlanExercises planexercises) async {
    planexercises.id = await _db.insert(TableName.planexercises.name, planexercises.toMap());

    // Update the cached list
    final index = _planexercises.indexWhere((e) => e.id == planexercises.id);
    if (index >= 0) {
      _planexercises[index] = planexercises;
    } else {
      _planexercises.add(planexercises);
    }
    notifyListeners();
    return planexercises;
  }

  Future<bool> updatePlanExercises(PlanExercises? planexercises) async {
    if (planexercises == null) return false;

    if (await _db.update(
          TableName.planexercises.name,
          planexercises.toMap(),
          where: 'plan_id = ? AND exercise',
          whereArgs: [planexercises.planId, planexercises.exercise],
        ) <=
        0) return false;
    final index =
        _planexercises.indexWhere((e) => e.id == planexercises.planId && e.exercise == planexercises.exercise);
    if (index >= 0) {
      _planexercises[index] = planexercises;
    } else {
      _planexercises.add(planexercises);
    }
    notifyListeners();
    return true;
  }

  Future<bool> deletePlanExerciseByNameAndPlanId(String name, int planId) async {
    final planexercises = getPlanExercisesByName(name, planId);
    if (planexercises == null) return false;
    if (await _db.delete(
          TableName.planexercises.name,
          where: 'name = ? AND plan_id = ?',
          whereArgs: [planexercises.exercise, planexercises.planId],
        ) <=
        0) return false;
    final index =
        _planexercises.indexWhere((e) => e.exercise == planexercises.exercise && e.planId == planexercises.planId);
    if (index >= 0) {
      _planexercises.remove(planexercises);
    }
    notifyListeners();
    return true;
  }

  Future<bool> deleteAllExerciseForPlanById(int planId) async {
    var planExercises = getPlanExercisesByPlanId(planId);

    if (planExercises.isEmpty) return false;

    for (final e in planExercises) {
      await deletePlanExerciseByNameAndPlanId(e.exercise, e.planId!);
    }
    return true;
  }
}

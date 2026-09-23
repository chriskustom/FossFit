import 'package:flutter/foundation.dart';
import 'package:fossfit/db/db_constants.dart';
import 'package:fossfit/models/plan_exercise_model.dart';
import 'package:sqflite/sqflite.dart';

class PlanExercisesRepository extends ChangeNotifier {
  final Database _db;
  List<PlanExercise> _planexercises = [];
  PlanExercisesRepository(this._db);

  List<PlanExercise> get planexercises => List.unmodifiable(_planexercises);

  Future<void> loadAll() async {
    final rows = await _db.rawQuery('''
    SELECT
      plan_exercises.*,

      exercises.id AS exercise_joined_id,
      exercises.name AS exercise_name,
      exercises.cardio AS exercise_cardio,
      exercises.category AS exercise_category,
      exercises.image AS exercise_image

    FROM plan_exercises

    LEFT JOIN exercises
      ON exercises.id = plan_exercises.exercise_id

    ORDER BY plan_exercises.sequence ASC
  ''');

    _planexercises = rows.map((r) => PlanExercise.fromJoinedMap(r)).toList();

    notifyListeners();
  }

  PlanExercise? getPlanExercisesById(int id, int planId) => _planexercises
      .where((n) => n.exerciseId == id && n.planId == planId)
      .firstOrNull;

  List<PlanExercise> getPlanExercisesByPlanId(int planId) =>
      _planexercises.where((n) => n.planId == planId).toList();

  Future<PlanExercise> addPlanExercises(PlanExercise planexercises) async {
    planexercises.id =
        await _db.insert(TableName.planexercises.name, planexercises.toMap());

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

  Future<bool> updatePlanExercise(PlanExercise? planexercises) async {
    if (planexercises == null) return false;

    if (await _db.update(
          TableName.planexercises.name,
          planexercises.toMap(),
          where: 'plan_id = ? AND exercise_id = ?',
          whereArgs: [planexercises.planId, planexercises.exerciseId],
        ) <=
        0) return false;
    final index = _planexercises.indexWhere(
      (e) =>
          e.id == planexercises.planId &&
          e.exerciseId == planexercises.exerciseId,
    );
    if (index >= 0) {
      _planexercises[index] = planexercises;
    } else {
      _planexercises.add(planexercises);
    }
    notifyListeners();
    return true;
  }

  Future<bool> deletePlanExerciseByIdAndPlanId(int id, int planId) async {
    final planexercises = getPlanExercisesById(id, planId);
    if (planexercises == null) return false;
    if (await _db.delete(
          TableName.planexercises.name,
          where: 'exercise_id = ? AND plan_id = ?',
          whereArgs: [planexercises.exerciseId, planexercises.planId],
        ) <=
        0) return false;
    final index = _planexercises.indexWhere(
      (e) =>
          e.exerciseId == planexercises.exerciseId &&
          e.planId == planexercises.planId,
    );
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
      await deletePlanExerciseByIdAndPlanId(e.exerciseId, e.planId!);
    }
    return true;
  }

  Future<bool> deleteAllExercisesForPlansByIds(List<int> ids) async {
    if (ids.isEmpty) return false;
    for (final id in ids) {
      await deleteAllExerciseForPlanById(id);
    }
    return true;
  }
}

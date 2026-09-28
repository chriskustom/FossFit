import 'package:flutter/foundation.dart';
import 'package:fossfit/db/db_constants.dart';
import 'package:fossfit/db/models/features/plan_model.dart';
import 'package:sqflite/sqflite.dart';

class PlanCount {
  final int planId;
  final int total;
  final int maxSets;

  PlanCount({required this.planId, required this.total, required this.maxSets});
}

typedef GymCount = ({int count, String name, int? maxSets, int? restMs, int? warmupSets, bool timers});

class PlansRepository extends ChangeNotifier {
  final Database _db;

  List<Plan> _plans = [];
  final List<PlanCount> _planCounts = [];

  PlansRepository(this._db);

  List<Plan> get plans => List.unmodifiable(_plans);

  List<PlanCount> get planCounts => List.unmodifiable(_planCounts);

  Future<void> loadAll() async {
    final result = await _db.query(TableName.plans.name, orderBy: 'sequence asc');

    _plans = result.map(Plan.fromMap).toList();
    notifyListeners();
  }

  Plan? getPlanById(int id) {
    return _plans.where((n) => n.id == id).firstOrNull;
  }

  List<Plan> getPlansByIds(List<int> ids) {
    return _plans.where((n) => ids.contains(n.id)).toList();
  }

  Future<Plan> insertPlan(Plan plan) async {
    plan.id = await _db.insert(TableName.plans.name, plan.toMap());

    final index = _plans.indexWhere((e) => e.id == plan.id);

    if (index >= 0) {
      _plans[index] = plan;
    } else {
      _plans.add(plan);
    }

    notifyListeners();

    return plan;
  }

  Future<bool> updatePlan(Plan? plan) async {
    if (plan == null) {
      return false;
    }

    final count = await _db.update(TableName.plans.name, plan.toMap(), where: 'id = ?', whereArgs: [plan.id]);

    if (count <= 0) {
      return false;
    }

    final index = _plans.indexWhere((e) => e.id == plan.id);

    if (index >= 0) {
      _plans[index] = plan;
    } else {
      _plans.add(plan);
    }

    notifyListeners();

    return true;
  }

  Future<bool> deletePlansByIds(List<int> ids) async {
    if (ids.isEmpty) {
      return false;
    }

    for (final id in ids) {
      await deletePlanById(id);
    }

    return true;
  }

  Future<bool> deletePlanById(int id) async {
    final plan = getPlanById(id);

    if (plan == null) {
      return false;
    }

    final count = await _db.delete(TableName.plans.name, where: 'id = ?', whereArgs: [id]);

    if (count <= 0) {
      return false;
    }

    _plans.removeWhere((e) => e.id == id);

    notifyListeners();

    return true;
  }

  Future<void> truncateTable() async {
    await _db.execute('DELETE FROM plans;');

    await loadAll();
  }
}

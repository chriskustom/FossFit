import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:fossfit/db/db_constants.dart';
import 'package:fossfit/db/models/features/plan_model.dart';
import 'package:sqflite/sqflite.dart';

typedef GymCount = ({int count, String name, int? maxSets, int? restMs, int? warmupSets, bool timers});

class PlansRepository extends ChangeNotifier {
  final Database _db;

  List<Plan> _plans = [];

  PlansRepository(this._db);

  List<Plan> get plans => List.unmodifiable(_plans);

  Future<void> loadAll() async {
    final result = await _db.query(TableName.plans.name, orderBy: 'sequence asc');

    _plans = result.map(Plan.fromMap).toList();

    _plans.sort((a, b) {
      if (a.sequence == null && b.sequence == null) return 0;
      if (a.sequence == null) return 1; // Nulls go to end
      if (b.sequence == null) return -1;
      return a.sequence!.compareTo(b.sequence!);
    });

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

    _plans.sort((a, b) {
      if (a.sequence == null && b.sequence == null) return 0;
      if (a.sequence == null) return 1; // Nulls go to end
      if (b.sequence == null) return -1;
      return a.sequence!.compareTo(b.sequence!);
    });
    return plan;
  }

  Future<bool> reorderPlans(int oldIndex, int newIndex) async {
    final reordered = List<Plan>.from(_plans);

    final moved = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, moved);

    final updated = [for (int i = 0; i < reordered.length; i++) reordered[i].copyWith(sequence: i)];

    _plans = updated;

    notifyListeners();

    for (final plan in updated) {
      await _persistPlan(plan);
    }

    return true;
  }

  Future<bool> _persistPlan(Plan plan) async {
    final count = await _db.update(TableName.plans.name, plan.toMap(), where: 'id = ?', whereArgs: [plan.id]);

    return count > 0;
  }

  Future<bool> updatePlan(Plan? plan) async {
    if (plan == null) return false;

    if (!await _persistPlan(plan)) {
      return false;
    }

    final index = _plans.indexWhere((e) => e.id == plan.id);

    if (index >= 0) {
      _plans[index] = plan;
    } else {
      _plans.add(plan);
    }

    _plans.sort((a, b) {
      if (a.sequence == null && b.sequence == null) return 0;
      if (a.sequence == null) return 1;
      if (b.sequence == null) return -1;
      return a.sequence!.compareTo(b.sequence!);
    });

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

    _plans.sort((a, b) {
      if (a.sequence == null && b.sequence == null) return 0;
      if (a.sequence == null) return 1; // Nulls go to end
      if (b.sequence == null) return -1;
      return a.sequence!.compareTo(b.sequence!);
    });
    notifyListeners();

    return true;
  }
}

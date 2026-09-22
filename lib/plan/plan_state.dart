import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:fossfit/main.dart';

class PlanCount {
  final int planId;
  final int total;
  final int maxSets;

  PlanCount({required this.planId, required this.total, required this.maxSets});
}

typedef GymCount = ({
  int count,
  String name,
  int? maxSets,
  int? restMs,
  int? warmupSets,
  bool timers,
});

class PlanState extends ChangeNotifier {
  List<Plan> plans = [];
  List<GymCount> gymCounts = [];
  List<PlanCount> planCounts = [];
  List<GymSet> lastSets = [];
  List<PlanExercisesCompanion> exercises = [];

  PlanState() {
    updatePlans(null);
    updatePlanCounts();
    updateDefaults();
  }

  void addExercise(GymSetsCompanion gymSet) {
    exercises.add(
      PlanExercisesCompanion(
        exercise: Value(gymSet.name.value),
        enabled: const Value(true),
      ),
    );
    exercises.sort((a, b) {
      if (a.enabled.value != b.enabled.value) {
        return b.enabled.value ? 1 : -1;
      }

      return a.exercise.value.compareTo(b.exercise.value);
    });
    notifyListeners();
  }

  Future<void> setExercises(PlansCompanion plan) async {
    var query = oldDb.gymSets.selectOnly()
      ..addColumns([oldDb.gymSets.name])
      ..groupBy([oldDb.gymSets.name])
      ..join([
        leftOuterJoin(
          oldDb.planExercises,
          oldDb.planExercises.planId.equals(plan.id.present ? plan.id.value : 0) &
              oldDb.planExercises.exercise.equalsExp(oldDb.gymSets.name),
        ),
      ])
      ..addColumns(oldDb.planExercises.$columns);

    final results = await query.get();

    List<PlanExercisesCompanion> enabled = [];
    List<PlanExercisesCompanion> disabled = [];

    for (final result in results) {
      final pe = PlanExercisesCompanion(
        planId: plan.id,
        id: Value.absentIfNull(result.read(oldDb.planExercises.id)),
        exercise: Value(result.read(oldDb.gymSets.name)!),
        enabled: Value(result.read(oldDb.planExercises.enabled) ?? false),
        maxSets: Value(result.read(oldDb.planExercises.maxSets)),
        warmupSets: Value(result.read(oldDb.planExercises.warmupSets)),
        timers: Value(result.read(oldDb.planExercises.timers) ?? true),
        sequence: Value(result.read(oldDb.planExercises.sequence) ?? 0),
      );
      if (pe.enabled.value)
        enabled.add(pe);
      else
        disabled.add(pe);
    }

    enabled.sort((a, b) => a.sequence.value.compareTo(b.sequence.value));

    exercises = enabled + disabled;
    notifyListeners();
  }

  Future<void> updateDefaults() async {
    final latest = oldDb.gymSets.created.max();
    final sub = Subquery(
      oldDb.select(oldDb.gymSets).join([])
        ..groupBy([oldDb.gymSets.name])
        ..addColumns([oldDb.gymSets.name, latest]),
      'ls',
    );
    final query = oldDb.select(oldDb.gymSets).join(
      [
        innerJoin(
          sub,
          sub.ref(oldDb.gymSets.name).equalsExp(oldDb.gymSets.name) & sub.ref(latest).equalsExp(oldDb.gymSets.created),
          useColumns: false,
        ),
      ],
    );
    final rows = await query.get();
    lastSets = rows.map((rows) => rows.readTable(oldDb.gymSets)).toList();
    notifyListeners();
  }

  void updatePlanCounts() {
    getPlanCounts().then((value) {
      planCounts = value;
      notifyListeners();
    });
  }

  Future<void> updateGymCounts(int planId) {
    return getGymCounts(planId).then((value) {
      gymCounts = value;
      notifyListeners();
    });
  }

  Future<List<PlanCount>> getPlanCounts() async {
    return (oldDb.customSelect(
      """
        SELECT id, SUM(max_sets) AS max_sets,
          SUM(todays_count) AS todays_count FROM (
            SELECT p.id, pe.exercise AS name,
              COALESCE(pe.max_sets, settings.max_sets) AS max_sets,
              COUNT(
                CASE WHEN gs.id IS NOT NULL
                  AND DATE(gs.created, 'unixepoch', 'localtime') = DATE('now', 'localtime')
                  AND gs.hidden = 0
                THEN 1
                END
              ) as todays_count
            FROM plans p
            LEFT JOIN plan_exercises pe ON p.id = pe.plan_id
              AND pe.enabled = true
            LEFT JOIN settings
            LEFT JOIN gym_sets gs ON pe.exercise = gs.name
              AND gs.plan_id = p.id
            GROUP BY pe.exercise, p.id
        )
        GROUP BY id
    """,
      readsFrom: {oldDb.plans, oldDb.gymSets, oldDb.planExercises, oldDb.settings},
    )).get().then((rows) {
      return rows
          .map(
            (row) => PlanCount(
              maxSets: row.read<int>('max_sets'),
              planId: row.read<int>('id'),
              total: row.read<int>('todays_count'),
            ),
          )
          .toList();
    });
  }

  Future<List<GymCount>> getGymCounts(int planId) async {
    final count = CustomExpression<int>(
      """
      COUNT(
        CASE
          WHEN created >= strftime('%s', 'now', 'localtime', '-24 hours')
               AND hidden = 0
               AND gym_sets.plan_id = $planId
          THEN 1
        END
      )
   """,
    );

    final results = await (oldDb.selectOnly(oldDb.planExercises)
          ..addColumns([
            oldDb.gymSets.name,
            count,
            oldDb.planExercises.maxSets,
            oldDb.gymSets.restMs,
            oldDb.planExercises.warmupSets,
            oldDb.planExercises.timers,
          ])
          ..join([
            innerJoin(
              oldDb.gymSets,
              oldDb.gymSets.name.equalsExp(oldDb.planExercises.exercise),
            ),
          ])
          ..where(
            oldDb.planExercises.planId.equals(planId) & oldDb.planExercises.enabled,
          )
          ..groupBy([oldDb.gymSets.name]))
        .get();
    return results
        .map(
          (row) => (
            count: row.read<int>(count)!,
            name: row.read(oldDb.gymSets.name)!,
            maxSets: row.read(oldDb.planExercises.maxSets),
            restMs: row.read(oldDb.gymSets.restMs),
            warmupSets: row.read(oldDb.planExercises.warmupSets),
            timers: row.read(oldDb.planExercises.timers)!,
          ),
        )
        .toList();
  }

  Future<List<Plan>> getPlans() async => await (oldDb.select(oldDb.plans)
        ..orderBy([
          (u) => OrderingTerm(expression: u.sequence),
        ]))
      .get();

  Future<void> updatePlans(List<Plan>? newPlans) async {
    if (newPlans != null)
      plans = newPlans;
    else
      plans = await getPlans();
    notifyListeners();
  }
}

import 'package:flutter/foundation.dart';
import 'package:fossfit/db/db_constants.dart';
import 'package:fossfit/models/gym_sets_model.dart';
import 'package:fossfit/models/plan_exercises_model.dart';
import 'package:fossfit/models/plans_model.dart';
import 'package:sqflite/sqflite.dart';

class PlanCount {
  final int planId;
  final int total;
  final int maxSets;

  PlanCount({
    required this.planId,
    required this.total,
    required this.maxSets,
  });
}

typedef GymCount = ({
  int count,
  String name,
  int? maxSets,
  int? restMs,
  int? warmupSets,
  bool timers,
});

class PlansRepository extends ChangeNotifier {
  final Database _db;

  List<Plan> _plans = [];
  List<GymSets> _lastSets = [];
  List<PlanCount> _planCounts = [];
  List<GymCount> _gymCounts = [];
  List<PlanExercises> _exercises = [];

  PlansRepository(this._db);

  // ---------------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------------

  List<Plan> get plans => List.unmodifiable(_plans);

  List<GymSets> get lastSets => List.unmodifiable(_lastSets);

  List<PlanCount> get planCounts => List.unmodifiable(_planCounts);

  List<GymCount> get gymCounts => List.unmodifiable(_gymCounts);

  List<PlanExercises> get exercises => List.unmodifiable(_exercises);

  // ---------------------------------------------------------------------------
  // Initial loading
  // ---------------------------------------------------------------------------

  Future<void> loadAll() async {
    await updatePlans(null);
    await updatePlanCounts();
    await updateDefaults();
  }

  // ---------------------------------------------------------------------------
  // Exercises
  // ---------------------------------------------------------------------------

  /// Adds an exercise to the current exercise list.
  ///
  /// Equivalent to the old Drift PlanState.addExercise().
  void addExercise(GymSets gymSet) {
    _exercises.add(
      PlanExercises(
        exercise: gymSet.name,
        enabled: true,
        timers: true,
        maxsets: 0,
      ),
    );

    _exercises.sort((a, b) {
      if (a.enabled != b.enabled) {
        return b.enabled ? 1 : -1;
      }

      return a.exercise.compareTo(b.exercise);
    });

    notifyListeners();
  }

  /// Loads all exercises that exist in gym_sets and combines them with
  /// the exercises configured for the supplied plan.
  ///
  /// This is the sqflite equivalent of the old Drift setExercises().
  Future<void> setExercises(Plan plan) async {
    final planId = plan.id ?? 0;

    final results = await _db.rawQuery(
      '''
      SELECT
        gym_sets.name,

        plan_exercises.id,
        plan_exercises.plan_id,
        plan_exercises.exercise,
        plan_exercises.enabled,
        plan_exercises.max_sets,
        plan_exercises.warmup_sets,
        plan_exercises.timers,
        plan_exercises.sequence

      FROM gym_sets

      LEFT JOIN plan_exercises
        ON plan_exercises.plan_id = ?
        AND plan_exercises.exercise = gym_sets.name

      GROUP BY gym_sets.name
      ''',
      [planId],
    );

    final enabled = <PlanExercises>[];
    final disabled = <PlanExercises>[];

    for (final row in results) {
      final exercise = PlanExercises(
        id: row['id'] as int?,
        planId: planId,
        exercise: row['name'] as String,
        enabled: row['enabled'] == 1,
        maxsets: (row['max_sets'] as num?)?.toInt() ?? 0,
        warmupSets: (row['warmup_sets'] as num?)?.toInt(),
        timers: row['timers'] == 1,
        sequence: (row['sequence'] as num?)?.toInt() ?? 0,
      );

      if (exercise.enabled) {
        enabled.add(exercise);
      } else {
        disabled.add(exercise);
      }
    }

    enabled.sort(
      (a, b) => (a.sequence ?? 0).compareTo(
        b.sequence ?? 0,
      ),
    );

    _exercises = [
      ...enabled,
      ...disabled,
    ];

    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Defaults / last sets
  // ---------------------------------------------------------------------------

  /// Gets the most recent GymSets row for each exercise.
  ///
  /// Equivalent to the old Drift updateDefaults().
  Future<void> updateDefaults() async {
    final results = await _db.rawQuery(
      '''
      SELECT gs.*
      FROM gym_sets gs

      INNER JOIN (
        SELECT
          name,
          MAX(created) AS latest

        FROM gym_sets

        GROUP BY name
      ) latest

        ON latest.name = gs.name
        AND latest.latest = gs.created
      ''',
    );

    _lastSets = results.map((row) => GymSets.fromMap(row)).toList();

    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Plan counts
  // ---------------------------------------------------------------------------

  Future<List<PlanCount>> getPlanCounts() async {
    final results = await _db.rawQuery(
      '''
      SELECT
        id,
        SUM(max_sets) AS max_sets,
        SUM(todays_count) AS todays_count

      FROM (
        SELECT
          p.id,
          pe.exercise AS name,

          COALESCE(
            pe.max_sets,
            settings.max_sets
          ) AS max_sets,

          COUNT(
            CASE
              WHEN gs.id IS NOT NULL
                AND DATE(
                  gs.created,
                  'unixepoch',
                  'localtime'
                ) = DATE(
                  'now',
                  'localtime'
                )
                AND gs.hidden = 0
              THEN 1
            END
          ) AS todays_count

        FROM plans p

        LEFT JOIN plan_exercises pe
          ON p.id = pe.plan_id
          AND pe.enabled = 1

        LEFT JOIN settings

        LEFT JOIN gym_sets gs
          ON pe.exercise = gs.name
          AND gs.plan_id = p.id

        GROUP BY
          pe.exercise,
          p.id
      )

      GROUP BY id
      ''',
    );

    return results.map((row) {
      return PlanCount(
        planId: (row['id'] as num).toInt(),
        maxSets: (row['max_sets'] as num?)?.toInt() ?? 0,
        total: (row['todays_count'] as num?)?.toInt() ?? 0,
      );
    }).toList();
  }

  Future<void> updatePlanCounts() async {
    _planCounts = await getPlanCounts();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Gym counts
  // ---------------------------------------------------------------------------

  Future<List<GymCount>> getGymCounts(int planId) async {
    final results = await _db.rawQuery(
      '''
      SELECT
        gym_sets.name,

        COUNT(
          CASE
            WHEN gym_sets.created >=
              strftime(
                '%s',
                'now',
                'localtime',
                '-24 hours'
              )
              AND gym_sets.hidden = 0
              AND gym_sets.plan_id = ?
            THEN 1
          END
        ) AS count,

        plan_exercises.max_sets,
        gym_sets.rest_ms,
        plan_exercises.warmup_sets,
        plan_exercises.timers

      FROM plan_exercises

      INNER JOIN gym_sets
        ON gym_sets.name = plan_exercises.exercise

      WHERE plan_exercises.plan_id = ?
        AND plan_exercises.enabled = 1

      GROUP BY gym_sets.name
      ''',
      [
        planId,
        planId,
      ],
    );

    return results.map((row) {
      return (
        count: (row['count'] as num?)?.toInt() ?? 0,
        name: row['name'] as String,
        maxSets: (row['max_sets'] as num?)?.toInt(),
        restMs: (row['rest_ms'] as num?)?.toInt(),
        warmupSets: (row['warmup_sets'] as num?)?.toInt(),
        timers: row['timers'] == 1,
      );
    }).toList();
  }

  Future<void> updateGymCounts(int planId) async {
    _gymCounts = await getGymCounts(planId);
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Plans
  // ---------------------------------------------------------------------------

  Future<List<Plan>> getPlans() async {
    final rows = await _db.query(
      TableName.plans.name,
      orderBy: 'sequence ASC',
    );

    return rows.map((row) => Plan.fromMap(row)).toList();
  }

  Future<void> updatePlans(List<Plan>? newPlans) async {
    if (newPlans != null) {
      _plans = newPlans;
    } else {
      _plans = await getPlans();
    }

    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Plan CRUD
  // ---------------------------------------------------------------------------

  Plan? getPlanById(int id) {
    return _plans.where((n) => n.id == id).firstOrNull;
  }

  List<Plan> getPlansByIds(List<int> ids) {
    return _plans.where((n) => ids.contains(n.id)).toList();
  }

  Future<Plan> addPlans(Plan plans) async {
    plans.id = await _db.insert(
      TableName.plans.name,
      plans.toMap(),
    );

    final index = _plans.indexWhere(
      (e) => e.id == plans.id,
    );

    if (index >= 0) {
      _plans[index] = plans;
    } else {
      _plans.add(plans);
    }

    notifyListeners();

    return plans;
  }

  Future<bool> updatePlan(Plan? plans) async {
    if (plans == null) {
      return false;
    }

    final count = await _db.update(
      TableName.plans.name,
      plans.toMap(),
      where: 'id = ?',
      whereArgs: [plans.id],
    );

    if (count <= 0) {
      return false;
    }

    final index = _plans.indexWhere(
      (e) => e.id == plans.id,
    );

    if (index >= 0) {
      _plans[index] = plans;
    } else {
      _plans.add(plans);
    }

    notifyListeners();

    return true;
  }

  Future<bool> deletePlansById(int id) async {
    final plans = getPlanById(id);

    if (plans == null) {
      return false;
    }

    final count = await _db.delete(
      TableName.plans.name,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (count <= 0) {
      return false;
    }

    _plans.removeWhere(
      (e) => e.id == id,
    );

    notifyListeners();

    return true;
  }
}

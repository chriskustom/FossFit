import 'package:flutter/foundation.dart';
import 'package:fossfit/db/db_constants.dart';
import 'package:fossfit/models/plan_exercise_model.dart';
import 'package:fossfit/models/plan_model.dart';
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
  List<PlanCount> _planCounts = [];
  List<GymCount> _gymCounts = [];

  PlansRepository(this._db);

  List<Plan> get plans => List.unmodifiable(_plans);

  List<PlanCount> get planCounts => List.unmodifiable(_planCounts);

  List<GymCount> get gymCounts => List.unmodifiable(_gymCounts);

  Future<void> loadAll() async {
    await updatePlans(null);
    await updatePlanCounts();
  }

  Future<List<PlanCount>> getPlanCounts() async {
    final results = await _db.rawQuery('''
      SELECT
        id,
        SUM(max_sets) AS max_sets,
        SUM(todays_count) AS todays_count

      FROM (
        SELECT
          p.id,

          COALESCE(
            pe.max_sets,
            CAST(settings.value AS INTEGER)
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
          ON settings.category = 'plans'
          AND settings.key = 'max_sets'

        LEFT JOIN gym_sets gs
          ON pe.exercise_id =
              gs.exercise_id
          AND gs.plan_id = p.id

        GROUP BY
          pe.exercise_id,
          p.id
      )

      GROUP BY id
    ''');

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

  Future<List<GymCount>> getGymCounts(
    int planId,
  ) async {
    final results = await _db.rawQuery(
      '''
      SELECT
        exercises.name,

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
        MAX(gym_sets.rest_ms) AS rest_ms,
        plan_exercises.warmup_sets,
        plan_exercises.timers

      FROM plan_exercises

      INNER JOIN exercises
        ON exercises.id =
            plan_exercises.exercise_id

      LEFT JOIN gym_sets
        ON gym_sets.exercise_id =
            plan_exercises.exercise_id
        AND gym_sets.plan_id =
            plan_exercises.plan_id

      WHERE plan_exercises.plan_id = ?
        AND plan_exercises.enabled = 1

      GROUP BY
        plan_exercises.exercise_id,
        exercises.name,
        plan_exercises.max_sets,
        plan_exercises.warmup_sets,
        plan_exercises.timers
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

  Future<void> updateGymCounts(
    int planId,
  ) async {
    _gymCounts = await getGymCounts(planId);

    notifyListeners();
  }

  Future<List<Plan>> getPlans() async {
    final rows = await _db.rawQuery('''
      SELECT
        plans.id,
        plans.days,
        plans.sequence,
        plans.title,

        plan_exercises.id
          AS plan_exercise_id,
        plan_exercises.timers,
        plan_exercises.enabled,
        plan_exercises.max_sets,
        plan_exercises.exercise_id,
        plan_exercises.warmup_sets,
        plan_exercises.plan_id,
        plan_exercises.sequence
          AS plan_exercise_sequence,

        exercises.id
          AS exercise_joined_id,
        exercises.name
          AS exercise_name,
        exercises.cardio
          AS exercise_cardio,
        exercises.category
          AS exercise_category,
        exercises.image
          AS exercise_image

      FROM plans

      LEFT JOIN plan_exercises
        ON plan_exercises.plan_id =
            plans.id
        AND plan_exercises.enabled = 1

      LEFT JOIN exercises
        ON exercises.id =
            plan_exercises.exercise_id

      ORDER BY
        plans.sequence ASC,
        plan_exercises.sequence ASC
    ''');

    final Map<int, Plan> plans = {};

    for (final row in rows) {
      final planId = (row['id'] as num).toInt();

      var plan = plans[planId];

      if (plan == null) {
        plan = Plan.fromMap(row);
        plans[planId] = plan;
      }

      if (row['plan_exercise_id'] == null) {
        continue;
      }

      final planExercise = PlanExercise.fromJoinedMap({
        'id': row['plan_exercise_id'],
        'timers': row['timers'],
        'enabled': row['enabled'],
        'max_sets': row['max_sets'],
        'exercise_id': row['exercise_id'],
        'warmup_sets': row['warmup_sets'],
        'plan_id': row['plan_id'],
        'sequence': row['plan_exercise_sequence'],
        'exercise_joined_id': row['exercise_joined_id'],
        'exercise_name': row['exercise_name'],
        'exercise_cardio': row['exercise_cardio'],
        'exercise_category': row['exercise_category'],
        'exercise_image': row['exercise_image'],
      });

      final exercises = [
        ...?plan.exercises,
        planExercise,
      ];

      plans[planId] = plan.copyWith(
        exercises: exercises,
      );
    }

    return plans.values.toList();
  }

  Future<void> updatePlans(
    List<Plan>? newPlans,
  ) async {
    if (newPlans != null) {
      _plans = newPlans;
    } else {
      _plans = await getPlans();
    }

    notifyListeners();
  }

  Plan? getPlanById(int id) {
    return _plans.where((n) => n.id == id).firstOrNull;
  }

  List<Plan> getPlansByIds(
    List<int> ids,
  ) {
    return _plans
        .where(
          (n) => ids.contains(n.id),
        )
        .toList();
  }

  Future<Plan> addPlan(
    Plan plan,
  ) async {
    plan.id = await _db.insert(
      TableName.plans.name,
      plan.toMap(),
    );

    final index = _plans.indexWhere(
      (e) => e.id == plan.id,
    );

    if (index >= 0) {
      _plans[index] = plan;
    } else {
      _plans.add(plan);
    }

    notifyListeners();

    return plan;
  }

  Future<bool> updatePlan(
    Plan? plan,
  ) async {
    if (plan == null) {
      return false;
    }

    final count = await _db.update(
      TableName.plans.name,
      plan.toMap(),
      where: 'id = ?',
      whereArgs: [plan.id],
    );

    if (count <= 0) {
      return false;
    }

    final index = _plans.indexWhere(
      (e) => e.id == plan.id,
    );

    if (index >= 0) {
      _plans[index] = plan;
    } else {
      _plans.add(plan);
    }

    notifyListeners();

    return true;
  }

  Future<bool> deletePlansByIds(
    List<int> ids,
  ) async {
    if (ids.isEmpty) {
      return false;
    }

    for (final id in ids) {
      await deletePlanById(id);
    }

    return true;
  }

  Future<bool> deletePlanById(
    int id,
  ) async {
    final plan = getPlanById(id);

    if (plan == null) {
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

  Future<void> truncateTable() async {
    await _db.execute(
      'DELETE FROM plans;',
    );

    await loadAll();
  }
}

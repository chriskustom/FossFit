import 'package:flutter/foundation.dart';
import 'package:fossfit/constants.dart';
import 'package:fossfit/db/db_constants.dart';
import 'package:fossfit/graph/cardio_data.dart';
import 'package:fossfit/graph/strength_data.dart';
import 'package:fossfit/models/gym_set_model.dart';
import 'package:sqflite/sqflite.dart';

typedef Rpm = ({
  String name,
  double rpm,
  double weight,
});

class GymSetsRepository extends ChangeNotifier {
  final Database _db;

  List<GymSet> _gymsets = [];

  GymSetsRepository(this._db);

  List<GymSet> get gymsets => List.unmodifiable(_gymsets);

  // ---------------------------------------------------------------------------
  // Basic CRUD
  // ---------------------------------------------------------------------------

  Future<void> loadAll() async {
    final rows = await _db.rawQuery('''
    SELECT
      gym_sets.*,

      exercises.id AS exercise_id,
      exercises.name AS exercise_name
      exercises.cardio AS exercise_cardio
      exercises.category AS exercise_category
      exercises.image AS exercise_image

    FROM gym_sets

    LEFT JOIN exercises
      ON exercises.id = gym_sets.exercise_id

    ORDER BY gym_sets.created DESC
  ''');

    _gymsets = rows.map((r) => GymSet.fromJoinedMap(r)).toList();

    notifyListeners();
  }

  GymSet? getGymSetById(int id) {
    return _gymsets.where((n) => n.id == id).firstOrNull;
  }

  List<GymSet> getGymSetsByIds(List<int> ids) {
    return _gymsets.where((n) => ids.contains(n.id)).toList();
  }

  Future<void> insertGymSets(List<GymSet> gymSets) async {
    for (final gymSet in gymSets) {
      await insertGymSet(gymSet);
    }
    await loadAll();
  }

  Future<GymSet> insertGymSet(GymSet gymsets) async {
    gymsets.id = await _db.insert(
      TableName.gymsets.name,
      gymsets.toMap(),
    );

    final index = _gymsets.indexWhere(
      (e) => e.id == gymsets.id,
    );

    if (index >= 0) {
      _gymsets[index] = gymsets;
    } else {
      _gymsets.add(gymsets);
    }

    notifyListeners();

    return gymsets;
  }

  Future<bool> updateGymSet(GymSet? gymsets) async {
    if (gymsets == null) {
      return false;
    }

    final count = await _db.update(
      TableName.gymsets.name,
      gymsets.toMap(),
      where: 'id = ?',
      whereArgs: [gymsets.id],
    );

    if (count <= 0) {
      return false;
    }

    final index = _gymsets.indexWhere(
      (e) => e.id == gymsets.id,
    );

    if (index >= 0) {
      _gymsets[index] = gymsets;
    } else {
      _gymsets.add(gymsets);
    }

    notifyListeners();

    return true;
  }

  Future<void> deleteGymSetsById(List<int> ids) async {
    for (var id in ids) {
      await deleteGymSetById(id);
    }
  }

  Future<bool> deleteGymSetById(int id) async {
    final gymsets = getGymSetById(id);

    if (gymsets == null) {
      return false;
    }

    final count = await _db.delete(
      TableName.gymsets.name,
      where: 'id = ?',
      whereArgs: [gymsets.id],
    );

    if (count <= 0) {
      return false;
    }

    final index = _gymsets.indexWhere(
      (e) => e.id == gymsets.id,
    );

    if (index >= 0) {
      _gymsets.remove(gymsets);
    }

    notifyListeners();

    return true;
  }

  Future<void> truncateTable() async {
    await _db.execute('DELETE FROM gym_sets;');
    await loadAll();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String getCreatedSql(Period groupBy) {
    switch (groupBy) {
      case Period.day:
        return """
          STRFTIME(
            '%Y-%m-%d',
            DATE(created, 'unixepoch', 'localtime')
          )
        """;

      case Period.week:
        return """
          STRFTIME(
            '%Y-%m-%W',
            DATE(created, 'unixepoch', 'localtime')
          )
        """;

      case Period.month:
        return """
          STRFTIME(
            '%Y-%m',
            DATE(created, 'unixepoch', 'localtime')
          )
        """;

      case Period.year:
        return """
          STRFTIME(
            '%Y',
            DATE(created, 'unixepoch', 'localtime')
          )
        """;
    }
  }

  int toUnixSeconds(DateTime dateTime) {
    return dateTime.toUtc().millisecondsSinceEpoch ~/ 1000;
  }

  DateTime fromUnixSeconds(dynamic value) {
    final seconds = value is int ? value : (value as num).toInt();

    return DateTime.fromMillisecondsSinceEpoch(
      seconds * 1000,
      isUtc: true,
    ).toLocal();
  }

  // ---------------------------------------------------------------------------
  // Cardio
  // ---------------------------------------------------------------------------

  double getCardioFromRow(
    Map<String, dynamic> row,
    CardioMetric metric,
  ) {
    switch (metric) {
      case CardioMetric.pace:
        final distance = (row['distance_sum'] as num?)?.toDouble() ?? 0;

        final duration = (row['duration_sum'] as num?)?.toDouble() ?? 0;

        return duration == 0 ? 0 : distance / duration;

      case CardioMetric.distance:
        return (row['distance_sum'] as num?)?.toDouble() ?? 0;

      case CardioMetric.duration:
        return (row['duration_sum'] as num?)?.toDouble() ?? 0;

      case CardioMetric.incline:
        return (row['incline_avg'] as num?)?.toDouble() ?? 0;

      case CardioMetric.inclineAdjustedPace:
        return (row['incline_adjusted_pace'] as num?)?.toDouble() ?? 0;
    }
  }

  Future<List<CardioData>> getCardioData({
    Period period = Period.day,
    int exerciseId = 0,
    CardioMetric metric = CardioMetric.pace,
    String target = "km",
    DateTime? start,
    DateTime? end,
  }) async {
    final groupBy = getCreatedSql(period);

    final startSeconds = toUnixSeconds(
      start ?? DateTime.fromMillisecondsSinceEpoch(0),
    );

    final endSeconds = toUnixSeconds(
      end ?? DateTime.now().toLocal().add(const Duration(days: 1)),
    );

    final results = await _db.rawQuery(
      """
      SELECT
        SUM(distance) AS distance_sum,
        SUM(duration) AS duration_sum,
        SUM(distance) / SUM(duration) AS pace,
        AVG(incline) AS incline_avg,

        SUM(distance) *
        POW(1.1, AVG(incline)) /
        SUM(duration) AS incline_adjusted_pace,

        created,
        unit

      FROM ${TableName.gymsets.name}

      WHERE exercise_id = ?
        AND hidden = 0
        AND created >= ?
        AND created < ?

      GROUP BY $groupBy

      ORDER BY $groupBy DESC

      LIMIT 11
      """,
      [
        exerciseId,
        startSeconds,
        endSeconds,
      ],
    );

    final list = <CardioData>[];

    for (final result in results.reversed) {
      var value = getCardioFromRow(
        result,
        metric,
      );

      final unit = result['unit'] as String;

      if (unit == 'km' && target == 'mi') {
        value /= 1.609;
      } else if (unit == 'mi' && target == 'km') {
        value *= 1.609;
      } else if (unit == 'm' && target == 'km') {
        value /= 1000;
      } else if (unit == 'km' && target == 'm') {
        value *= 1000;
      } else if (unit == 'm' && target == 'mi') {
        value /= 1609.34;
      } else if (unit == 'mi' && target == 'm') {
        value *= 1609.34;
      }

      list.add(
        CardioData(
          created: fromUnixSeconds(result['created']),
          value: double.parse(
            value.toStringAsFixed(2),
          ),
          unit: target,
        ),
      );
    }

    return list;
  }

  // ---------------------------------------------------------------------------
  // Strength expressions
  // ---------------------------------------------------------------------------

  String getVolumeSql() {
    return 'ROUND(SUM(weight * reps), 2)';
  }

  String getOrmSql() {
    return '''
      MAX(
        CASE
          WHEN weight >= 0
            THEN weight / (1.0278 - 0.0278 * reps)
          ELSE
            weight * (1.0278 - 0.0278 * reps)
        END
      )
    ''';
  }

  String getRelativeSql() {
    return '''
      MAX(weight) / body_weight
    ''';
  }

  double getStrengthFromRow(
    Map<String, dynamic> row,
    StrengthMetric metric,
  ) {
    switch (metric) {
      case StrengthMetric.oneRepMax:
        return (row['orm'] as num?)?.toDouble() ?? 0;

      case StrengthMetric.volume:
        return (row['volume'] as num?)?.toDouble() ?? 0;

      case StrengthMetric.relativeStrength:
        return (row['relative_strength'] as num?)?.toDouble() ?? 0;

      case StrengthMetric.bestWeight:
        return (row['max_weight'] as num?)?.toDouble() ?? 0;

      case StrengthMetric.bestReps:
        return (row['max_reps'] as num?)?.toDouble() ?? 0;
    }
  }

  // ---------------------------------------------------------------------------
  // RPM
  // ---------------------------------------------------------------------------

  Future<List<Rpm>> getRpms() async {
    final results = await _db.rawQuery(
      '''
      WITH time_diffs AS (
        SELECT
          name,
          reps,
          (
            (
              created -
              LAG(created) OVER (
                PARTITION BY name
                ORDER BY created
              )
            ) / 60.0
          ) AS time_diff,
          weight

        FROM ${TableName.gymsets.name}

        WHERE created >=
          strftime('%s', 'now') - 60 * 60 * 24 * 30

          AND cardio = 0
      ),

      reps_per_min AS (
        SELECT
          name,
          (reps / time_diff) AS rpm,
          weight

        FROM time_diffs

        WHERE time_diff IS NOT NULL
          AND time_diff <= 5
      )

      SELECT
        name,
        AVG(rpm) AS rpm,
        weight

      FROM reps_per_min

      WHERE rpm IS NOT NULL
        AND rpm BETWEEN 0.1 AND 10

      GROUP BY name, weight
      ''',
    );

    return results
        .map(
          (result) => (
            name: result['name'] as String,
            rpm: (result['rpm'] as num).toDouble(),
            weight: (result['weight'] as num).toDouble(),
          ),
        )
        .toList();
  }

  // ---------------------------------------------------------------------------
  // Strength data
  // ---------------------------------------------------------------------------

  Future<List<StrengthData>> getStrengthData({
    required String target,
    required int exerciseId,
    required StrengthMetric metric,
    required Period period,
    required DateTime? start,
    required DateTime? end,
    required int limit,
  }) async {
    final groupBy = getCreatedSql(period);

    final where = <String>[
      'exercise_id = ?',
      'hidden = 0',
    ];

    final args = <dynamic>[
      exerciseId,
    ];

    if (start != null) {
      where.add('created >= ?');
      args.add(toUnixSeconds(start));
    }

    if (end != null) {
      where.add('created < ?');
      args.add(toUnixSeconds(end));
    }

    final repsExpression = metric == StrengthMetric.bestReps ? 'MAX(reps) AS max_reps' : 'reps';

    final sql = '''
      SELECT
        MAX(weight) AS max_weight,

        ${getVolumeSql()} AS volume,

        ${getOrmSql()} AS orm,

        created,

        $repsExpression,

        unit,

        ${getRelativeSql()} AS relative_strength

      FROM ${TableName.gymsets.name}

      WHERE ${where.join(' AND ')}

      GROUP BY $groupBy

      ORDER BY $groupBy DESC

      LIMIT ?
    ''';

    args.add(limit);

    final results = await _db.rawQuery(
      sql,
      args,
    );

    final list = <StrengthData>[];

    for (final result in results.reversed) {
      final unit = result['unit'] as String;

      var value = getStrengthFromRow(
        result,
        metric,
      );

      if (unit == 'lb' && target == 'kg') {
        value *= 0.45359237;
      } else if (unit == 'kg' && target == 'lb') {
        value *= 2.20462262;
      }

      double reps = 0.0;

      try {
        reps = (result['reps'] as num).toDouble();
      } catch (_) {}

      list.add(
        StrengthData(
          created: fromUnixSeconds(result['created']),
          value: value,
          unit: unit,
          reps: reps,
        ),
      );
    }

    return list;
  }

  // ---------------------------------------------------------------------------
  // Global strength data
  // ---------------------------------------------------------------------------

  Future<List<StrengthData>> getGlobalData({
    required String target,
    required StrengthMetric metric,
    required Period period,
    required DateTime? start,
    required DateTime? end,
    required int limit,
  }) async {
    final groupBy = getCreatedSql(period);

    final where = <String>[
      'hidden = 0',
      'category IS NOT NULL',
    ];

    final args = <dynamic>[];

    if (start != null) {
      where.add('created >= ?');
      args.add(toUnixSeconds(start));
    }

    if (end != null) {
      where.add('created < ?');
      args.add(toUnixSeconds(end));
    }

    final repsExpression = metric == StrengthMetric.bestReps ? 'MAX(reps) AS max_reps' : 'reps';

    final sql = '''
      SELECT
        MAX(weight) AS max_weight,

        ${getVolumeSql()} AS volume,

        ${getOrmSql()} AS orm,

        created,

        $repsExpression,

        unit,

        ${getRelativeSql()} AS relative_strength,

        category

      FROM ${TableName.gymsets.name}

      WHERE ${where.join(' AND ')}

      GROUP BY category, $groupBy

      ORDER BY $groupBy DESC

      LIMIT ?
    ''';

    args.add(limit);

    final results = await _db.rawQuery(
      sql,
      args,
    );

    final list = <StrengthData>[];

    for (final result in results.reversed) {
      final unit = result['unit'] as String;

      var value = getStrengthFromRow(
        result,
        metric,
      );

      if (unit == 'lb' && target == 'kg') {
        value *= 0.45359237;
      } else if (unit == 'kg' && target == 'lb') {
        value *= 2.20462262;
      }

      double reps = 0.0;

      try {
        reps = (result['reps'] as num).toDouble();
      } catch (_) {}

      list.add(
        StrengthData(
          created: fromUnixSeconds(result['created']),
          value: value,
          unit: unit,
          reps: reps,
          category: result['category'] as String?,
        ),
      );
    }

    return list;
  }

  // ---------------------------------------------------------------------------
  // Categories
  // ---------------------------------------------------------------------------

  Future<List<String?>> getCategories() async {
    final results = await _db.rawQuery(
      '''
      SELECT category
      FROM ${TableName.gymsets.name}
      WHERE category IS NOT NULL
      GROUP BY category
      ''',
    );

    return results
        .map(
          (result) => result['category'] as String?,
        )
        .toList();
  }

  Future<List<String>> getCategoriesList() async {
    final results = await _db.rawQuery(
      '''
      SELECT DISTINCT category
      FROM ${TableName.gymsets.name}
      WHERE category IS NOT NULL
      ''',
    );

    return results
        .map(
          (result) => result['category'] as String? ?? '',
        )
        .toList();
  }

  // ---------------------------------------------------------------------------
  // Is best
  // ---------------------------------------------------------------------------

  Future<bool> isBest(GymSet gymSet) async {
    final rows = await _db.query(
      'exercises',
      columns: ['cardio'],
      where: 'id = ?',
      whereArgs: [gymSet.exerciseId],
      limit: 1,
    );

    final isCardio = rows.first['cardio'] == 1;
    if (isCardio) {
      final results = await _db.rawQuery(
        '''
        SELECT
          SUM(distance) / SUM(duration) AS pace

        FROM ${TableName.gymsets.name}

        ORDER BY weight DESC, reps DESC

        LIMIT 1
        ''',
      );

      if (results.isEmpty) {
        return false;
      }

      final best = (results.first['pace'] as num?)?.toDouble();

      if (best == null) {
        return false;
      }

      return (gymSet.distance ?? 0.0) / (gymSet.duration ?? 0.0) > best;
    }

    final results = await _db.rawQuery(
      '''
      SELECT
        weight,
        reps

      FROM ${TableName.gymsets.name}

      WHERE id != ?

      ORDER BY
        weight DESC,
        reps DESC

      LIMIT 1
      ''',
      [
        gymSet.id,
      ],
    );

    if (results.isEmpty) {
      return false;
    }

    final weight = (results.first['weight'] as num).toDouble();

    final reps = (results.first['reps'] as num).toDouble();

    if (gymSet.weight > weight) {
      return true;
    }

    if (gymSet.weight == weight && gymSet.reps > reps) {
      return true;
    }

    return false;
  }

  Future<void> convertUnits(String unit, int exerciseId) async {
    if (unit == 'kg')
      await _db.execute(
        '''
        UPDATE gym_sets SET weight = weight * 0.45359237, 
          unit = 'kg'
        WHERE exercise_id = ? AND unit = 'lb';
      ''',
        [exerciseId],
      );
    else if (unit == 'lb')
      await _db.execute(
        '''
        UPDATE gym_sets SET weight = weight * 2.20462262, 
          unit = 'lb'
        WHERE exercise_id = ? AND unit = 'kg';
      ''',
        [exerciseId],
      );
    else if (unit == 'km') {
      await _db.execute(
        '''
        UPDATE gym_sets SET weight = weight * 1.609, 
          unit = 'km'
        WHERE exercise_id = ? AND unit = 'mi';
      ''',
        [exerciseId],
      );
      await _db.execute(
        '''
        UPDATE gym_sets SET weight = weight / 1000, 
          unit = 'km'
        WHERE exercise_id = ? AND unit = 'm';
      ''',
        [exerciseId],
      );
    } else if (unit == 'mi') {
      await _db.execute(
        '''
        UPDATE gym_sets SET weight = weight / 1.609, 
          unit = 'mi'
        WHERE exercise_id = ? AND unit = 'km';
      ''',
        [exerciseId],
      );
      await _db.execute(
        '''
        UPDATE gym_sets SET weight = weight / 1609.34, 
          unit = 'mi'
        WHERE exercise_id = ? AND unit = 'm';
      ''',
        [exerciseId],
      );
    } else if (unit == 'm') {
      await _db.execute(
        '''
        UPDATE gym_sets SET weight = weight * 1000, 
          unit = 'm'
        WHERE exercise_id = ? AND unit = 'km';
      ''',
        [exerciseId],
      );
      await _db.execute(
        '''
        UPDATE gym_sets SET weight = weight * 1609.34, 
          unit = 'm'
        WHERE exercise_id = ? AND unit = 'mi';
      ''',
        [exerciseId],
      );
    }
  }
}

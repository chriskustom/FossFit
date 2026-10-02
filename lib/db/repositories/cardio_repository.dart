import 'package:flutter/foundation.dart';
import 'package:fossfit/app/utils/constants.dart';
import 'package:fossfit/db/db_constants.dart';
import 'package:fossfit/db/models/features/cardio_model.dart';
import 'package:sqflite/sqflite.dart';

class CardioRepository extends ChangeNotifier {
  final Database _db;

  List<Cardio> _cardio = [];
  List<Cardio> _latestcardio = [];

  CardioRepository(this._db);

  List<Cardio> get cardio => List.unmodifiable(_cardio);
  List<Cardio> get latestcardio => List.unmodifiable(_latestcardio);

  // ---------------------------------------------------------------------------
  // Loading
  // ---------------------------------------------------------------------------

  Future<void> loadAll() async {
    final rows = await _db.query(TableName.cardio.name, orderBy: 'created DESC');

    _cardio = rows.map(Cardio.fromMap).toList();
    await _loadLatestWorkout();
    notifyListeners();
  }
  // ---------------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------------

  Cardio? getCardioById(int id) {
    return _cardio.where((set) => set.id == id).firstOrNull;
  }

  List<Cardio> getTodaysSetsByExerciseId(int exerciseId, int? planId) {
    final sets = cardio;

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final startOfTomorrow = startOfDay.add(const Duration(days: 1));

    final todays = sets
        .where(
          (set) =>
              (planId == null || set.planId == planId) &&
              set.exerciseId == exerciseId &&
              set.created.isAfter(startOfDay) &&
              set.created.isBefore(startOfTomorrow),
        )
        .toList();

    todays.sort((a, b) => a.created.compareTo(b.created));

    return todays;
  }
  // ---------------------------------------------------------------------------
  // CRUD
  // ---------------------------------------------------------------------------

  Future<Cardio> insertCardio(Cardio cardio) async {
    cardio.id = await _db.insert(TableName.cardio.name, cardio.toMap());

    final index = _cardio.indexWhere((set) => set.id == cardio.id);

    if (index >= 0) {
      _cardio[index] = cardio;
    } else {
      _cardio.add(cardio);
    }

    _sortByCreated();

    await _loadLatestWorkout();
    notifyListeners();

    return cardio;
  }

  Future<void> decoupleSetsFromPlan(List<int> ids) async {
    final placeholders = List.filled(ids.length, '?').join(', ');

    await _db.execute('''
        UPDATE sets
        SET plan_id = NULL
        WHERE id IN ($placeholders);
      ''', ids);
    return;
  }

  Future<bool> updateCardio(Cardio? cardio) async {
    if (cardio == null || cardio.id == null) {
      return false;
    }

    final count = await _db.update(TableName.cardio.name, cardio.toMap(), where: 'id = ?', whereArgs: [cardio.id]);

    if (count <= 0) {
      return false;
    }

    final index = _cardio.indexWhere((set) => set.id == cardio.id);

    if (index >= 0) {
      _cardio[index] = cardio;
    } else {
      _cardio.add(cardio);
    }

    _sortByCreated();

    await _loadLatestWorkout();
    notifyListeners();

    return true;
  }

  Future<bool> deletecardioById(List<int> ids) async {
    if (ids.isEmpty) {
      return false;
    }

    final placeholders = List.filled(ids.length, '?').join(',');

    final count = await _db.delete(TableName.cardio.name, where: 'id IN ($placeholders)', whereArgs: ids);

    if (count <= 0) {
      return false;
    }

    _cardio.removeWhere((set) => set.id != null && ids.contains(set.id));

    await _loadLatestWorkout();
    notifyListeners();

    return true;
  }

  Future<bool> deleteCardioById(int id) async {
    final count = await _db.delete(TableName.cardio.name, where: 'id = ?', whereArgs: [id]);

    if (count <= 0) {
      return false;
    }

    _cardio.removeWhere((set) => set.id == id);

    await _loadLatestWorkout();
    notifyListeners();

    return true;
  }

  void _sortByCreated() {
    _cardio.sort((a, b) => b.created.compareTo(a.created));
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  int toUnixSeconds(DateTime dateTime) {
    return dateTime.toUtc().millisecondsSinceEpoch;
  }

  DateTime fromUnixSeconds(dynamic value) {
    final milliseconds = value is int ? value : (value as num).toInt();

    return DateTime.fromMillisecondsSinceEpoch(milliseconds, isUtc: true).toLocal();
  }

  // ---------------------------------------------------------------------------
  // Is best
  // ---------------------------------------------------------------------------

  Future<bool> isBest(Cardio cardio) async {
    final results = await _db.rawQuery(
      '''
      SELECT
        distance,
        duration

      FROM ${TableName.cardio.name}

      WHERE id != ?

      ORDER BY
        distance DESC,
        duration DESC

      LIMIT 1
      ''',
      [cardio.id],
    );

    if (results.isEmpty) {
      return false;
    }

    final distance = (results.first['distance'] as num?)?.toDouble();
    final duration = (results.first['duration'] as num).toDouble();

    if (cardio.distance != null && cardio.distance != null && cardio.distance! > distance!) {
      return true;
    }

    if (cardio.distance == distance && cardio.duration > duration) {
      return true;
    }

    return false;
  }

  // ---------------------------------------------------------------------------
  // Unit conversion
  // ---------------------------------------------------------------------------

  Future<void> convertUnits(String unit, int exerciseId) async {
    if (unit == 'km') {
      await _db.execute(
        '''
      UPDATE cardio
      SET
        distance = CASE
          WHEN distance_unit = 'mi' THEN distance * 1.609344
          ELSE distance
        END,
        distance_unit = 'km'
      WHERE exercise_id = ?
        AND distance_unit = 'mi';
      ''',
        [exerciseId],
      );
    } else if (unit == 'mi') {
      await _db.execute(
        '''
      UPDATE cardio
      SET
        distance = CASE
          WHEN distance_unit = 'km' THEN distance * 0.6213711922
          ELSE distance
        END,
        distance_unit = 'mi'
      WHERE exercise_id = ?
        AND distance_unit ='km';
      ''',
        [exerciseId],
      );
    }

    // Keep the in-memory cache consistent after conversions.
    await loadAll();
  }

  Future<void> _loadLatestWorkout() async {
    DateTime dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);
    final today = dayOnly(DateTime.now());
    if (_cardio.isEmpty) {
      _latestcardio = [];
      return;
    }
    final mostRecentDay = _cardio.map((s) => dayOnly(s.created)).where((d) => !d.isAfter(today)).reduce((a, b) => a.isAfter(b) ? a : b);

    _latestcardio = _cardio.where((s) => dayOnly(s.created) == mostRecentDay).toList();
  }

  String getCreatedSql(Period groupBy) {
    switch (groupBy) {
      case Period.day:
        return """
          STRFTIME(
            '%Y-%m-%d',
            DATE(created / 1000, 'unixepoch', 'localtime')
          )
        """;

      case Period.week:
        return """
          STRFTIME(
            '%Y-%m-%W',
            DATE(created / 1000, 'unixepoch', 'localtime')
          )
        """;

      case Period.month:
        return """
          STRFTIME(
            '%Y-%m',
            DATE(created / 1000, 'unixepoch', 'localtime')
          )
        """;

      case Period.year:
        return """
          STRFTIME(
            '%Y',
            DATE(created / 1000, 'unixepoch', 'localtime')
          )
        """;
    }
  }

  // ---------------------------------------------------------------------------
  // Cardio
  // ---------------------------------------------------------------------------

  double getCardioFromRow(Map<String, dynamic> row, CardioMetric metric) {
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

    final startSeconds = toUnixSeconds(start ?? DateTime.fromMillisecondsSinceEpoch(0));

    final endSeconds = toUnixSeconds(end ?? DateTime.now().toLocal().add(const Duration(days: 1)));

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
        distance_unit

      FROM ${TableName.cardio.name}

      WHERE exercise_id = ?
        AND created >= ?
        AND created < ?

      GROUP BY $groupBy

      ORDER BY $groupBy DESC

      LIMIT 11
      """,
      [exerciseId, startSeconds, endSeconds],
    );

    final list = <CardioData>[];

    for (final result in results.reversed) {
      var value = getCardioFromRow(result, metric);

      final unit = result['distance_unit'] as String;

      if (unit == 'km' && target == 'mi') {
        value /= 1.609;
      } else if (unit == 'mi' && target == 'km') {
        value *= 1.609;
      }

      list.add(CardioData(created: fromUnixSeconds(result['created']), value: double.parse(value.toStringAsFixed(2)), unit: target));
    }

    return list;
  }
}

import 'package:flutter/foundation.dart';
import 'package:fossfit/db/db_constants.dart';
import 'package:fossfit/db/models/features/gymset_model.dart';
import 'package:sqflite/sqflite.dart';

typedef Rpm = ({String name, double rpm, double weight});

class GymSetRepository extends ChangeNotifier {
  final Database _db;

  List<GymSet> _gymsets = [];
  List<GymSet> _latestgymsets = [];

  GymSetRepository(this._db);

  List<GymSet> get gymsets => List.unmodifiable(_gymsets);
  List<GymSet> get latestgymsets => List.unmodifiable(_latestgymsets);

  // ---------------------------------------------------------------------------
  // Loading
  // ---------------------------------------------------------------------------

  Future<void> loadAll() async {
    final rows = await _db.query(TableName.sets.name, orderBy: 'created DESC');

    _gymsets = rows.map(GymSet.fromMap).toList();
    await _loadLatestWorkout();
    notifyListeners();
  }
  // ---------------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------------

  GymSet? getGymSetById(int id) {
    return _gymsets.where((set) => set.id == id).firstOrNull;
  }

  List<GymSet> getTodaysSetsByExerciseId(int exerciseId, int? planId) {
    final sets = gymsets;

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

  Future<GymSet> insertGymSet(GymSet gymSet) async {
    gymSet.id = await _db.insert(TableName.sets.name, gymSet.toMap());

    final index = _gymsets.indexWhere((set) => set.id == gymSet.id);

    if (index >= 0) {
      _gymsets[index] = gymSet;
    } else {
      _gymsets.add(gymSet);
    }

    _sortByCreated();

    await _loadLatestWorkout();
    notifyListeners();

    return gymSet;
  }

  Future<bool> updateGymSet(GymSet? gymSet) async {
    if (gymSet == null || gymSet.id == null) {
      return false;
    }

    final count = await _db.update(TableName.sets.name, gymSet.toMap(), where: 'id = ?', whereArgs: [gymSet.id]);

    if (count <= 0) {
      return false;
    }

    final index = _gymsets.indexWhere((set) => set.id == gymSet.id);

    if (index >= 0) {
      _gymsets[index] = gymSet;
    } else {
      _gymsets.add(gymSet);
    }

    _sortByCreated();

    await _loadLatestWorkout();
    notifyListeners();

    return true;
  }

  Future<bool> deleteGymSetsById(List<int> ids) async {
    if (ids.isEmpty) {
      return false;
    }

    final placeholders = List.filled(ids.length, '?').join(',');

    final count = await _db.delete(TableName.sets.name, where: 'id IN ($placeholders)', whereArgs: ids);

    if (count <= 0) {
      return false;
    }

    _gymsets.removeWhere((set) => set.id != null && ids.contains(set.id));

    await _loadLatestWorkout();
    notifyListeners();

    return true;
  }

  Future<bool> deleteGymSetById(int id) async {
    final count = await _db.delete(TableName.sets.name, where: 'id = ?', whereArgs: [id]);

    if (count <= 0) {
      return false;
    }

    _gymsets.removeWhere((set) => set.id == id);

    await _loadLatestWorkout();
    notifyListeners();

    return true;
  }

  void _sortByCreated() {
    _gymsets.sort((a, b) => b.created.compareTo(a.created));
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

  Future<bool> isBest(GymSet gymSet) async {
    final results = await _db.rawQuery(
      '''
      SELECT
        weight,
        reps

      FROM ${TableName.sets.name}

      WHERE id != ?

      ORDER BY
        weight DESC,
        reps DESC

      LIMIT 1
      ''',
      [gymSet.id],
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

  // ---------------------------------------------------------------------------
  // Unit conversion
  // ---------------------------------------------------------------------------

  Future<void> convertUnits(String unit, int exerciseId) async {
    if (unit == 'kg') {
      await _db.execute(
        '''
        UPDATE gym_sets
        SET
          weight = weight * 0.45359237,
          unit = 'kg'
        WHERE exercise_id = ?
          AND unit = 'lb';
        ''',
        [exerciseId],
      );
    } else if (unit == 'lb') {
      await _db.execute(
        '''
        UPDATE gym_sets
        SET
          weight = weight * 2.20462262,
          unit = 'lb'
        WHERE exercise_id = ?
          AND unit = 'kg';
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
    if (_gymsets.isEmpty) {
      _latestgymsets = [];
      return;
    }
    final mostRecentDay = _gymsets.map((s) => dayOnly(s.created)).where((d) => !d.isAfter(today)).reduce((a, b) => a.isAfter(b) ? a : b);

    _latestgymsets = _gymsets.where((s) => dayOnly(s.created) == mostRecentDay).toList();
  }
}

import 'package:flutter/foundation.dart';
import 'package:fossfit/db/db_constants.dart';
import 'package:fossfit/db/models/features/gymset_model.dart';
import 'package:sqflite/sqflite.dart';

typedef Rpm = ({String name, double rpm, double weight});

class GymSetsRepository extends ChangeNotifier {
  final Database _db;

  List<GymSet> _gymsets = [];
  List<GymSet> _latestgymsets = [];

  GymSetsRepository(this._db);

  List<GymSet> get gymsets => List.unmodifiable(_gymsets);
  List<GymSet> get latestgymsets => List.unmodifiable(_latestgymsets);

  // ---------------------------------------------------------------------------
  // Loading
  // ---------------------------------------------------------------------------

  Future<void> loadAll() async {
    final rows = await _db.rawQuery('''
      SELECT *
      FROM gym_sets
      ORDER BY created DESC
    ''');

    _gymsets = rows.map(GymSet.fromMap).toList();
    await _loadLatestWorkout();
    notifyListeners();
  }

  Future<GymSet?> _loadById(int id) async {
    final rows = await _db.rawQuery(
      '''
      SELECT *

      FROM gym_sets

      WHERE id = ?

      LIMIT 1
      ''',
      [id],
    );

    if (rows.isEmpty) {
      return null;
    }

    return GymSet.fromMap(rows.first);
  }

  // ---------------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------------

  GymSet? getGymSetById(int id) {
    return _gymsets.where((set) => set.id == id).firstOrNull;
  }

  // ---------------------------------------------------------------------------
  // CRUD
  // ---------------------------------------------------------------------------

  Future<GymSet> insertGymSet(GymSet gymSet) async {
    final id = await _db.insert(TableName.sets.name, gymSet.toMap());

    final loadedSet = await _loadById(id);

    if (loadedSet == null) {
      // This should never happen, but keep the repository consistent if it
      // somehow does.
      gymSet.id = id;

      _gymsets.insert(0, gymSet);
    } else {
      final index = _gymsets.indexWhere((set) => set.id == id);

      if (index >= 0) {
        _gymsets[index] = loadedSet;
      } else {
        _gymsets.insert(0, loadedSet);
      }
    }

    _sortByCreated();

    notifyListeners();

    return loadedSet ?? gymSet;
  }

  Future<bool> updateGymSet(GymSet? gymSet) async {
    if (gymSet == null || gymSet.id == null) {
      return false;
    }

    final count = await _db.update(TableName.sets.name, gymSet.toMap(), where: 'id = ?', whereArgs: [gymSet.id]);

    if (count <= 0) {
      return false;
    }

    // Reload the joined object so the cached model has the same shape as
    // objects returned by loadAll().
    final loadedSet = await _loadById(gymSet.id!);

    final index = _gymsets.indexWhere((set) => set.id == gymSet.id);

    if (loadedSet != null) {
      if (index >= 0) {
        _gymsets[index] = loadedSet;
      } else {
        _gymsets.insert(0, loadedSet);
      }
    } else if (index >= 0) {
      _gymsets[index] = gymSet;
    } else {
      _gymsets.insert(0, gymSet);
    }

    _sortByCreated();

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

    notifyListeners();

    return true;
  }

  Future<bool> deleteGymSetById(int id) async {
    final count = await _db.delete(TableName.sets.name, where: 'id = ?', whereArgs: [id]);

    if (count <= 0) {
      return false;
    }

    _gymsets.removeWhere((set) => set.id == id);

    notifyListeners();

    return true;
  }

  Future<void> truncateTable() async {
    await _db.execute('DELETE FROM ${TableName.sets.name};');

    await loadAll();
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
    final mostRecentDay = _gymsets
        .map((s) => dayOnly(s.created))
        .where((d) => !d.isAfter(today))
        .reduce((a, b) => a.isAfter(b) ? a : b);

    _latestgymsets = _gymsets.where((s) => dayOnly(s.created) == mostRecentDay).toList();
  }
}

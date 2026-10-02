import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:fossfit/app/features/cardio/cardio_page.dart';
import 'package:fossfit/app/utils/utils.dart';
import 'package:fossfit/app/widgets/app_snack_bar.dart';
import 'package:fossfit/db/models/features/cardio_model.dart';
import 'package:fossfit/db/models/features/exercise_model.dart';
import 'package:fossfit/db/repositories/cardio_repository.dart';
import 'package:fossfit/db/repositories/config_reposity.dart';
import 'package:fossfit/db/repositories/exercise_repository.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class CardioServices {
  final BuildContext context;
  late CardioRepository cardioRepo;
  late ExercisesRepository exerciseRepo;
  late ConfigRepository settingsRepo;
  CardioServices({required this.context}) {
    cardioRepo = context.read<CardioRepository>();
    exerciseRepo = context.read<ExercisesRepository>();
    settingsRepo = context.read<ConfigRepository>();
  }
  List<Cardio> getAllCardio() => cardioRepo.cardio;
  Cardio? getCardioById(int id) => cardioRepo.getCardioById(id);
  Future<Cardio?> openCardioPage(BuildContext context, int? cardioId) async {
    return await showGeneralDialog<Cardio?>(
      context: context,
      barrierLabel: '',
      barrierDismissible: true,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, anim1, anim2) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            child: SizedBox(
              width: MediaQuery.of(context).size.width,
              height: double.infinity,
              child: CardioPage(cardioId: cardioId),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        final offsetAnimation = Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(anim1);
        return SlideTransition(position: offsetAnimation, child: child);
      },
    );
  }

  Future<Cardio?> insertCardio(Cardio? cardio) async {
    if (cardio == null) return null;
    return await cardioRepo.insertCardio(cardio);
  }

  Future<bool> editCardio(Cardio? cardio) async {
    if (cardio == null) return false;
    return await cardioRepo.updateCardio(cardio);
  }

  Future<bool> updateCardio(Cardio cardio) async {
    return await cardioRepo.updateCardio(cardio);
  }

  Future<void> decoupleSetsFromPlan(List<int> ids) async {
    return await cardioRepo.decoupleSetsFromPlan(ids);
  }

  Future<bool> deleteCardioById(int id) async {
    if (id <= 0) return false;
    final result = await cardioRepo.deleteCardioById(id);
    AppSnackBar.success('Deleted');
    return result;
  }

  Future<bool> deleteMultipleCardiosByIds(List<int> ids) async {
    if (ids.isEmpty) return false;
    for (final id in ids) {
      await cardioRepo.deleteCardioById(id);
    }
    cardioRepo.loadAll();
    AppSnackBar.success('Deleted');
    return true;
  }

  Future<bool> isBest(Cardio set) async {
    return await cardioRepo.isBest(set);
  }

  Cardio? getLastCardio() => getAllCardio().firstOrNull;

  List<Cardio> getTodaysSetsByExerciseId(int exerciseId, int? planId) => cardioRepo.getTodaysSetsByExerciseId(exerciseId, planId);

  List<Cardio> getSetsByExerciseId(int exerciseId, {int limit = 100}) =>
      cardioRepo.cardio.where((e) => e.exerciseId == exerciseId).take(limit).toList();
  List<Cardio> getSetsByPlanId(int planId, {int limit = 100}) => cardioRepo.cardio.where((e) => e.planId == planId).take(limit).toList();

  Widget getLastCardioWorkout(List<Cardio> sets) {
    String plural(double s) => s > 0.1 ? 's' : '';
    String plurals(int s) => s > 1 ? 's' : '';
    if (sets.isEmpty) {
      return const SizedBox.shrink();
    }

    var sortedDays = getCardioSets(sets);

    if (sortedDays.isEmpty) {
      return const SizedBox.shrink();
    }

    sortedDays.sort((a, b) => a.date.compareTo(b.date));

    final totalWorkout = sortedDays.where((day) => day.date == sortedDays.first.date).toList();

    if (totalWorkout.isEmpty) {
      return const SizedBox.shrink();
    }

    final allWorkoutSets = totalWorkout.expand((exercise) => exercise.cardioSets!).toList();

    double totalDistance = allWorkoutSets.map((e) => (e.distance ?? 0.0)).reduce((a, b) => a + b);

    int totalDuration = allWorkoutSets.map((e) => e.duration).reduce((a, b) => a + b);

    final distanceUnit = allWorkoutSets.firstOrNull?.distanceUnit ?? 'km';

    final totalExercises = totalWorkout.length;

    var dateFormat = settingsRepo.getSetting(.formats, 'short_date_format');

    final formattedDate = DateFormat(dateFormat).format(sortedDays.first.date);

    final daysSince = DateTime.now().difference(sortedDays.first.date).inDays;

    final lastWorkoutText = daysSince == 0
        ? 'You last worked out today.'
        : daysSince == 1
        ? 'You last worked out yesterday.'
        : 'You last worked out '
              '$daysSince days ago on '
              '$formattedDate.';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(lastWorkoutText, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 8),
          const Divider(),
          Text(
            '$totalExercises exercise'
            '${plurals(totalExercises)} completed',
            textAlign: TextAlign.left,
          ),
          Text(
            '$totalDistance $distanceUnit'
            '${plural(totalDistance)} covered',
            textAlign: TextAlign.left,
          ),
          Text('${formatSeconds(totalDuration)} completed', textAlign: TextAlign.left),
        ],
      ),
    );
  }

  String formatSeconds(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${secs.toString().padLeft(2, '0')}';
  }

  List<ExerciseSets> getCardioSets(List<Cardio> sets, {bool reversed = false}) {
    final exerciseItems = <ExerciseSets>[];

    for (final cardio in sets) {
      final exercise = exerciseRepo.getExerciseById(cardio.exerciseId);

      if (exercise == null || exercise.id == null) {
        continue;
      }

      final day = DateUtils.dateOnly(cardio.created);

      final index = exerciseItems.indexWhere((item) => isSameDay(item.date, day) && item.exercise.id == exercise.id);

      if (index == -1) {
        exerciseItems.add(ExerciseSets(cardioSets: [cardio], date: day, exercise: exercise));
      } else {
        exerciseItems[index].cardioSets!.add(cardio);
      }
    }

    return reversed ? exerciseItems.reversed.toList() : exerciseItems;
  }

  Map<DateTime, List<Cardio>> groupSetsByDay(List<Cardio> sets) {
    final map = <DateTime, List<Cardio>>{};

    for (final set in sets) {
      final day = DateTime(set.created.year, set.created.month, set.created.day);

      map.putIfAbsent(day, () => []);
      map[day]!.add(set);
    }

    // Optional: sort newest first
    final sortedKeys = map.keys.toList()..sort((a, b) => b.compareTo(a));

    return {for (final key in sortedKeys) key: map[key]!};
  }

  Map<DateTime, List<ExerciseSets>> groupExerciseSetsByDay(List<ExerciseSets> days) {
    final map = <DateTime, List<ExerciseSets>>{};

    for (final day in days) {
      map.putIfAbsent(day.date, () => []);
      map[day.date]!.add(day);
    }

    // Optional: sort newest first
    final sortedKeys = map.keys.toList()..sort((a, b) => b.compareTo(a));

    return {for (final key in sortedKeys) key: map[key]!};
  }
}

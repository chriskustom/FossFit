import 'package:flutter/material.dart';
import 'package:fossfit/db/repositories/exercise_repository.dart';
import 'package:fossfit/db/repositories/gym_sets_repository.dart';
import 'package:fossfit/db/repositories/settings_repository.dart';
import 'package:fossfit/models/exercise_model.dart';
import 'package:fossfit/models/gym_set_model.dart';
import 'package:fossfit/utils.dart';
import 'package:fossfit/widgets/app_snack_bar.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class GymSetServices {
  final BuildContext context;
  late GymSetsRepository gymsetsRepo;
  late ExercisesRepository exerciseRepo;
  late SettingsRepository settingsRepo;
  GymSetServices({required this.context}) {
    gymsetsRepo = context.read<GymSetsRepository>();
    exerciseRepo = context.read<ExercisesRepository>();
    settingsRepo = context.read<SettingsRepository>();
  }
  List<GymSet> getAllGymSets() => gymsetsRepo.gymsets;
  GymSet? getGymSetById(int id) => gymsetsRepo.getGymSetById(id);
  Future<GymSet?> openAddEditPage(BuildContext context, int? gymSetId) async {
    return await showGeneralDialog<GymSet?>(
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
              child: null, //TODO EDIT SET PAG
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

  Future<GymSet?> addGymSet(GymSet? gymSet) async {
    if (gymSet == null) return null;
    return await gymsetsRepo.insertGymSet(gymSet);
  }

  Future<bool> editGymSet(GymSet? gymSet) async {
    if (gymSet == null) return false;
    return await gymsetsRepo.updateGymSet(gymSet);
  }

  Future<bool> updateGymSet(GymSet gymset) async {
    return await gymsetsRepo.updateGymSet(gymset);
  }

  Future<bool> deleteGymSetById(int id) async {
    if (id <= 0) return false;
    final result = await gymsetsRepo.deleteGymSetById(id);
    AppSnackBar.success('Deleted');
    return result;
  }

  Future<bool> deleteMultipleGymSetssByIds(List<int> ids) async {
    if (ids.isEmpty) return false;
    for (final id in ids) {
      await gymsetsRepo.deleteGymSetById(id);
    }
    gymsetsRepo.loadAll();
    AppSnackBar.success('Deleted');
    return true;
  }

  Future<bool> isBest(GymSet set) async {
    return await gymsetsRepo.isBest(set);
  }

  Widget getLastGymSetWorkout(
    List<GymSet> sets,
  ) {
    String plural(int s) => s > 1 ? 's' : '';
    if (sets.isEmpty) {
      return const SizedBox.shrink();
    }

    var sortedDays = getExerciseItems(sets);

    if (sortedDays.isEmpty) {
      return const SizedBox.shrink();
    }

    sortedDays.sort(
      (a, b) => a.date.compareTo(b.date),
    );

    final totalWorkout = sortedDays
        .where(
          (day) => day.date == sortedDays.first.date,
        )
        .toList();

    if (totalWorkout.isEmpty) {
      return const SizedBox.shrink();
    }

    final allWorkoutSets = totalWorkout
        .expand(
          (exercise) => exercise.sets,
        )
        .toList();

    final strengthSet = allWorkoutSets.firstOrNull;

    final weightUnit = strengthSet?.unit ?? '';

    var totalSets = 0;
    var totalReps = 0;

    final totalExercises = totalWorkout.length;

    double totalWeight = 0;

    for (final exercise in totalWorkout) {
      totalSets += exercise.sets.length;

      for (final set in exercise.sets) {
        totalReps += set.reps.toInt();

        totalWeight += set.weight * set.reps;
      }
    }

    var dateFormat = settingsRepo.getSetting(
      key: 'short_date_format',
    );

    final formattedDate = DateFormat(
      dateFormat,
    ).format(
      sortedDays.first.date,
    );

    final daysSince = DateTime.now()
        .difference(
          sortedDays.first.date,
        )
        .inDays;

    final lastWorkoutText = daysSince == 0
        ? 'You last worked out today.'
        : daysSince == 1
            ? 'You last worked out yesterday.'
            : 'You last worked out '
                '$daysSince days ago on '
                '$formattedDate.';

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
      ),
      child: ListTile(
        title: Text(
          lastWorkoutText,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(
              height: 16,
            ),
            const Divider(),
            Text(
              '$totalExercises exercise'
              '${plural(totalExercises)} completed',
              textAlign: TextAlign.left,
            ),
            Text(
              '$totalSets set'
              '${plural(totalSets)} completed',
              textAlign: TextAlign.left,
            ),
            Text(
              '$totalReps rep'
              '${plural(totalReps)} completed',
              textAlign: TextAlign.left,
            ),
            if (totalWeight > 0)
              Text(
                '${num.parse(totalWeight.toStringAsFixed(3))}'
                '$weightUnit total lifted',
                textAlign: TextAlign.left,
              ),
          ],
        ),
      ),
    );
  }

  Widget getLastExerciseWorkout(List<ExerciseItem> sets) {
    String plural(int s) => s > 1 ? 's' : '';
    if (sets.isEmpty) return SizedBox.shrink();

    var sortedDays = sets;
    sortedDays.sort((a, b) => a.date.compareTo(b.date));
    var totalWorkout = sortedDays.where((d) => d.date == sortedDays.first.date).toList();

    var weightUnit = totalWorkout.first.sets.firstOrNull?.unit ?? '';
    var totalSets = 0;
    var totalReps = 0;
    var totalExercises = totalWorkout.length;
    double totalWeight = 0;
    for (var exercise in totalWorkout) {
      totalSets += exercise.sets.length;
      for (var set in exercise.sets) {
        totalReps += set.reps.toInt();
        totalWeight += (set.weight * set.reps);
      }
    }
    return Selector<SettingsRepository, String>(
      selector: (context, settings) {
        final format = settings.getSetting(key: 'short_date_format');
        return DateFormat(format).format(sortedDays.first.date);
      },
      builder: (context, formattedDate, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Divider(),
              const SizedBox(height: 8),
              Text(
                '$totalExercises exercise${plural(totalExercises)} completed',
              ),
              Text('$totalSets set${plural(totalSets)} completed'),
              Text('$totalReps rep${plural(totalReps)} completed'),
              if (totalWeight > 0)
                Text(
                  '${num.parse(totalWeight.toStringAsFixed(3))}$weightUnit total lifted',
                ),
            ],
          ),
        );
      },
    );
  }

  List<ExerciseItem> getExerciseItems(
    List<GymSet> sets,
  ) {
    final exerciseItems = <ExerciseItem>[];

    for (final gymSet in sets) {
      final exercise = exerciseRepo.getExerciseById(gymSet.exerciseId);

      if (exercise == null || exercise.id == null) {
        continue;
      }

      final day = DateUtils.dateOnly(
        gymSet.created,
      );

      final index = exerciseItems.indexWhere(
        (item) =>
            isSameDay(
              item.date,
              day,
            ) &&
            item.exerciseId == exercise.id,
      );

      if (index == -1) {
        exerciseItems.add(
          ExerciseItem(
            name: exercise.name,
            sets: [gymSet],
            date: day,
            exerciseId: exercise.id!,
          ),
        );
      } else {
        exerciseItems[index].sets.add(gymSet);
      }
    }

    return exerciseItems;
  }

  Map<DateTime, List<GymSet>> groupSetByDay(List<GymSet> sets) {
    final map = <DateTime, List<GymSet>>{};

    for (final set in sets) {
      final day = DateTime(
        set.created.year,
        set.created.month,
        set.created.day,
      );

      map.putIfAbsent(day, () => []);
      map[day]!.add(set);
    }

    // Optional: sort newest first
    final sortedKeys = map.keys.toList()..sort((a, b) => b.compareTo(a));

    return {
      for (final key in sortedKeys) key: map[key]!,
    };
  }

  Map<DateTime, List<ExerciseItem>> groupExerciseItemByDay(List<ExerciseItem> days) {
    final map = <DateTime, List<ExerciseItem>>{};

    for (final day in days) {
      map.putIfAbsent(day.date, () => []);
      map[day.date]!.add(day);
    }

    // Optional: sort newest first
    final sortedKeys = map.keys.toList()..sort((a, b) => b.compareTo(a));

    return {
      for (final key in sortedKeys) key: map[key]!,
    };
  }
}

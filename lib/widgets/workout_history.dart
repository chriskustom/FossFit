import 'package:flutter/material.dart';
import 'package:fossfit/models/exercise_model.dart';
import 'package:fossfit/models/gym_set_model.dart';
import 'package:fossfit/sets/workout_collapsed.dart';
import 'package:fossfit/sets/workout_list.dart';
import 'package:fossfit/utils.dart';

class WorkoutHistory extends StatelessWidget {
  final List<GymSet> gymSets;
  final ScrollController scroll;
  final Function(int) onSelect;
  final Function(GymSet) onEdit;
  final Set<int> selected;
  final bool groupHistory;
  const WorkoutHistory({
    super.key,
    required this.gymSets,
    required this.onSelect,
    required this.onEdit,
    required this.selected,
    required this.scroll,
    required this.groupHistory,
  });
  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        if (groupHistory) {
          final exerciseItems = _getExerciseItems(gymSets);
          if (exerciseItems.isEmpty) {
            return ConstrainedBox(
              constraints: BoxConstraints.expand(),
              child: Padding(
                padding: EdgeInsetsGeometry.only(top: 16),
                child: Text(
                  'No gains made on this day.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return WorkoutCollapsed(
            scroll: scroll,
            days: exerciseItems,
            onSelect: (id) => onSelect(id),
            selected: selected,
            onEdit: (gymSet) async => onEdit(gymSet),
          );
        }

        return WorkoutList(
          scroll: scroll,
          sets: gymSets,
          onSelect: (id) => onSelect(id),
          selected: selected,
          onNext: () {},
        );
      },
    );
  }

  List<ExerciseItem> _getExerciseItems(
    List<GymSet> sets,
  ) {
    final exerciseItems = <ExerciseItem>[];

    for (final gymSet in sets) {
      final exercise = gymSet.exercise;

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

    return exerciseItems.reversed.toList();
  }
}

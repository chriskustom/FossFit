import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fossfit/constants.dart';
import 'package:fossfit/db/repositories/exercise_repository.dart';
import 'package:fossfit/db/repositories/gym_sets_repository.dart';
import 'package:fossfit/db/repositories/settings_repository.dart';
import 'package:fossfit/graph/cardio_page.dart';
import 'package:fossfit/graph/strength_page.dart';
import 'package:fossfit/models/exercise_model.dart';
import 'package:fossfit/models/gym_set_model.dart';
import 'package:fossfit/utils.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

class GraphTile extends StatelessWidget {
  final GymSet gymSet;
  final Set<Exercise> selected;
  final Function(Exercise?) onSelect;
  final TabController tabCtrl;
  final bool timeBasedXAxis; // new flag to control x-axis behaviour

  const GraphTile({
    super.key,
    required this.selected,
    required this.onSelect,
    required this.gymSet,
    required this.tabCtrl,
    this.timeBasedXAxis = false,
  });

  @override
  Widget build(BuildContext context) {
    String trailing;
    final showImages = context.select<SettingsRepository, bool>(
      (settings) => settings.isEnabled(key: 'show_images'),
    );
    var exercise = context
        .watch<ExercisesRepository>()
        .getExerciseById(gymSet.exerciseId)!;
    if (exercise.cardio == true) {
      final minutes = gymSet.duration!.floor();
      final seconds =
          ((gymSet.duration! * 60) % 60).floor().toString().padLeft(2, '0');
      trailing =
          "${toString(gymSet.distance ?? 0)} ${gymSet.unit} / $minutes:$seconds";
    } else {
      trailing =
          "${toString(gymSet.reps)} x ${toString(gymSet.weight)} ${gymSet.unit}";
    }

    Widget? leading = SizedBox(
      height: 24,
      width: 24,
      child: Checkbox(
        value: selected.contains(exercise),
        onChanged: (value) {
          onSelect(exercise);
        },
      ),
    );

    if (selected.isEmpty && showImages && exercise.image?.isNotEmpty == true) {
      leading = GestureDetector(
        onTap: () => onSelect(exercise),
        child: Image.file(
          File(exercise.image!),
          errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
        ),
      );
    } else if (selected.isEmpty) {
      leading = GestureDetector(
        onTap: () => onSelect(exercise),
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              exercise.name.isNotEmpty ? exercise.name[0].toUpperCase() : '?',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ),
      );
    }

    leading = AnimatedSwitcher(
      duration: const Duration(milliseconds: 150),
      transitionBuilder: (child, animation) {
        return ScaleTransition(scale: animation, child: child);
      },
      child: leading,
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: selected.contains(exercise)
            ? Theme.of(context).colorScheme.primary.withValues(alpha: .08)
            : Colors.transparent,
        border: Border.all(
          color: selected.contains(exercise)
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
              : Colors.transparent,
          width: 1,
        ),
      ),
      child: ListTile(
        leading: leading,
        title: Text(exercise.name),
        subtitle: Selector<SettingsRepository, String>(
          selector: (context, settings) =>
              settings.getSetting(key: 'long_date_format'),
          builder: (context, dateFormat, child) => Text(
            dateFormat == 'timeago'
                ? timeago.format(gymSet.created)
                : DateFormat(dateFormat).format(gymSet.created),
          ),
        ),
        trailing: Text(
          trailing,
          style: const TextStyle(fontSize: 16),
        ),
        onTap: () async {
          if (selected.isNotEmpty) {
            onSelect(exercise);
            return;
          }

          if (exercise.cardio) {
            final data = await context.watch<GymSetsRepository>().getCardioData(
                  target: gymSet.unit,
                  exerciseId: gymSet.exerciseId,
                  metric: CardioMetric.pace,
                  period: Period.day,
                  start: null,
                  end: null,
                );
            if (!context.mounted) return;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CardioPage(
                  tabCtrl: tabCtrl,
                  exercise: exercise,
                  unit: gymSet.unit,
                  data: data,
                ),
              ),
            );
            return;
          }

          final data = await context.watch<GymSetsRepository>().getStrengthData(
                target: gymSet.unit,
                exerciseId: gymSet.exerciseId,
                metric: StrengthMetric.bestWeight,
                period: Period.day,
                start: null,
                end: null,
                limit: 20,
              );
          if (!context.mounted) return;

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StrengthPage(
                exercise: exercise,
                unit: gymSet.unit,
                data: data,
                tabCtrl: tabCtrl,
              ),
            ),
          );
        },
        onLongPress: () {
          onSelect(exercise);
        },
      ),
    );
  }
}

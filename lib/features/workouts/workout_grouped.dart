import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fossfit/db/repositories/settings_repository.dart';
import 'package:fossfit/models/exercise_model.dart';
import 'package:fossfit/models/gym_set_model.dart';
import 'package:fossfit/services/exercise_services.dart';
import 'package:fossfit/services/gym_sets_services.dart';
import 'package:fossfit/utils/utils.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sticky_headers/sticky_headers/widget.dart';
import 'package:timeago/timeago.dart' as timeago;

class WorkoutGrouped extends StatefulWidget {
  final List<GymSet> sets;
  const WorkoutGrouped({super.key, required this.sets});

  @override
  State<WorkoutGrouped> createState() => _WorkoutGroupedState();
}

class _WorkoutGroupedState extends State<WorkoutGrouped> {
  Map<DateTime, List<ExerciseItem>> _grouped = {};
  late SettingsRepository settings;

  final scroll = ScrollController();
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    settings = context.watch<SettingsRepository>();
    final showImages = settings.isEnabled(key: 'show_images');
    final services = GymSetServices(context: context);
    final sortedDays = List<ExerciseItem>.from(services.getExerciseItems(widget.sets).reversed)..sort((a, b) => b.date.compareTo(a.date));
    _grouped = services.groupExerciseItemByDay(sortedDays);

    return ListView.builder(
      controller: scroll,
      padding: const EdgeInsets.only(bottom: 96),
      itemCount: _grouped.entries.length,
      itemBuilder: (context, sectionIndex) {
        final entry = _grouped.entries.elementAt(sectionIndex);
        final date = entry.key;
        final sets = entry.value;

        return StickyHeader(
          header: Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            alignment: Alignment.center,
            child: _buildSectionDivider(
              date,
              sets,
            ),
          ),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: List.generate(
              sets.length,
              (index) => workoutChildren(sets[index], context, showImages),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionDivider(DateTime date, List<ExerciseItem> day) {
    var services = GymSetServices(context: context);
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (ctx) {
            return AlertDialog(
              title: Text(formatDateWithOrdinal(date)),
              content: services.getLastExerciseWorkout(day),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text("Close"),
                ),
              ],
            );
          },
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            const Expanded(child: Divider(thickness: 1)),
            const SizedBox(width: 4),
            const Icon(Icons.today, size: 16),
            const SizedBox(width: 4),
            Text(
              DateFormat(settings.getSetting(key: 'short_date_format')).format(date),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 4),
            const Expanded(child: Divider(thickness: 1)),
          ],
        ),
      ),
    );
  }

  Widget workoutChildren(
    ExerciseItem history,
    BuildContext context,
    bool showImages,
  ) {
    var services = ExerciseServices(context: context);
    var exercise = services.getExerciseById(history.exerciseId);
    return ExpansionTile(
      childrenPadding: EdgeInsets.all(0),
      title: Text("${history.name} (${history.sets.length})"),
      shape: const Border.symmetric(),
      children: history.sets.reversed.toList().map(
        (gymSet) {
          final reps = gymSet.reps;
          final weight = gymSet.weight;

          Widget? leading = SizedBox.shrink();

          if (showImages && exercise?.hasImage() == true) {
            leading = Container(
              width: 24,
              height: 24,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Image.file(
                width: 24,
                height: 24,
                File(exercise!.image!),
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
              ),
            );
          } else {
            leading = Container(
              width: 24,
              height: 24,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  exercise!.name.isNotEmpty ? exercise.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
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

          final dateFormat = settings.getSetting(key: 'short_date_format');
          final trailing = Text(
            dateFormat == 'timeago' ? timeago.format(gymSet.created) : DateFormat("HH:mm a").format(gymSet.created),
          );
          return ListTile(
            dense: true,
            visualDensity: VisualDensity.comfortable,
            leading: leading,
            title: Text(
              "${_getSetNumber(gymSet, history.sets)}: $reps REPS @ $weight ${gymSet.unit}",
            ),
            //selected: widget.selected.contains(gymSet.id),
            trailing: trailing,
            onLongPress: () {
              //TODO LONG PRESS SELECT
            },
            onTap: () async {
              //TODO ADD TO SELECTED OR EDIT SET
            },
          );
        },
      ).toList(),
    );
  }

  String _getSetNumber(GymSet gymSet, List<GymSet> today) {
    final currentDate = gymSet.created.toLocal();
    final sameDayEntries = today
        .where(
          (entry) => entry.created.toLocal().year == currentDate.year && entry.created.toLocal().month == currentDate.month && entry.created.toLocal().day == currentDate.day,
        )
        .toList()
        .reversed
        .toList();
    final positionOnThisDay = sameDayEntries.indexOf(gymSet) + 1;
    return 'Set $positionOnThisDay';
  }
}

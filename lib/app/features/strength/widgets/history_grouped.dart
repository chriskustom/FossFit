import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:fossfit/app/services/features/gym_set_services.dart';
import 'package:fossfit/app/utils/utils.dart';
import 'package:fossfit/db/models/features/exercise_model.dart';
import 'package:fossfit/db/models/features/gymset_model.dart';
import 'package:fossfit/db/repositories/config_reposity.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sticky_headers/sticky_headers/widget.dart';
import 'package:timeago/timeago.dart' as timeago;

class HistoryGrouped extends StatelessWidget {
  final List<GymSet> sets;
  final bool selectionMode;
  final Set<GymSet> selectedItems;
  final Function(GymSet set) toggleSelection;
  final ScrollController scroll;
  const HistoryGrouped({
    super.key,
    required this.sets,
    required this.selectionMode,
    required this.toggleSelection,
    required this.selectedItems,
    required this.scroll,
  });

  @override
  Widget build(BuildContext context) {
    var config = context.read<ConfigRepository>();
    final showImages = config.isEnabled(.workouts, 'show_images');
    final services = GymSetServices(context: context);
    final sortedDays = List<ExerciseSets>.from(services.getExerciseSets(sets, reversed: true))..sort((a, b) => b.date.compareTo(a.date));
    var grouped = services.groupExerciseSetsByDay(sortedDays);

    return ListView.builder(
      shrinkWrap: true,
      controller: scroll,
      padding: const EdgeInsets.only(bottom: 96),
      itemCount: grouped.entries.length,
      itemBuilder: (context, sectionIndex) {
        final entry = grouped.entries.elementAt(sectionIndex);
        final date = entry.key;
        final sets = entry.value;

        return StickyHeader(
          header: Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            alignment: Alignment.center,
            child: _buildSectionDivider(date, sets, context),
          ),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: List.generate(sets.length, (index) => workoutChildren(sets[index], context, showImages, config)),
          ),
        );
      },
    );
  }

  Widget _buildSectionDivider(DateTime date, List<ExerciseSets> day, BuildContext context) {
    var config = context.read<ConfigRepository>();
    var services = GymSetServices(context: context);
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (ctx) {
            return AlertDialog(
              title: Text(formatDateWithOrdinal(date)),
              content: services.getLastGymSetWorkout(day.expand((t) => t.gymSets!).toList()),

              actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("Close"))],
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
            Text(DateFormat(config.getSetting(.formats, 'short_date_format')).format(date), style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 4),
            const Expanded(child: Divider(thickness: 1)),
          ],
        ),
      ),
    );
  }

  Widget workoutChildren(ExerciseSets history, BuildContext context, bool showImages, ConfigRepository config) {
    return ExpansionTile(
      childrenPadding: EdgeInsets.all(0),
      title: Text("${history.exercise.name} (${history.gymSets!.length})", style: Theme.of(context).textTheme.labelMedium),
      shape: const Border.symmetric(),
      children: history.gymSets!.reversed.toList().map((gymSet) {
        final reps = gymSet.reps;
        final weight = gymSet.weight;

        final dateFormat = config.getSetting(.formats, 'short_date_format');
        final trailing = Text(dateFormat == 'timeago' ? timeago.format(gymSet.created) : DateFormat("HH:mm a").format(gymSet.created));
        return ListTile(
          dense: true,
          visualDensity: VisualDensity.comfortable,
          leading: _leading(context, gymSet, history.exercise, showImages),
          title: Text("${_getSetNumber(gymSet, history.gymSets!)}: $reps REPS @ $weight ${gymSet.unit}"),
          trailing: trailing,
          selected: selectedItems.contains(gymSet),
          onLongPress: () => toggleSelection(gymSet),
          onTap: () async {
            if (selectionMode) {
              toggleSelection(gymSet);
            } else {
              var services = GymSetServices(context: context);
              await services.openAddEditPage(context, gymSet.id);
            }
          },
        );
      }).toList(),
    );
  }

  String _getSetNumber(GymSet gymSet, List<GymSet> today) {
    final currentDate = gymSet.created.toLocal();
    final sameDayEntries = today
        .where(
          (entry) =>
              entry.created.toLocal().year == currentDate.year &&
              entry.created.toLocal().month == currentDate.month &&
              entry.created.toLocal().day == currentDate.day,
        )
        .toList()
        .reversed
        .toList();
    final positionOnThisDay = sameDayEntries.indexOf(gymSet) + 1;
    return 'Set $positionOnThisDay';
  }

  Widget _leading(BuildContext context, GymSet set, Exercise exercise, bool showImages) {
    Widget? leading = SizedBox(
      height: 24,
      width: 24,
      child: Checkbox(value: selectedItems.contains(set), onChanged: (_) => toggleSelection(set)),
    );

    if (!selectionMode && showImages && exercise.hasImage()) {
      leading = GestureDetector(
        onTap: () => toggleSelection(set),
        child: Container(
          width: 24,
          height: 24,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            image: DecorationImage(
              image: MemoryImage(exercise.image ?? Uint8List(0)),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(Color.fromARGB(100, 0, 0, 0), BlendMode.darken),
            ),
          ),
        ),
      );
    } else if (!selectionMode) {
      leading = GestureDetector(
        onTap: () => toggleSelection(set),
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(color: Theme.of(context).colorScheme.inversePrimary, borderRadius: BorderRadius.circular(12)),
          child: Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 2),
              child: Text(
                exercise.name.isNotEmpty ? exercise.name[0] : '?',
                textAlign: TextAlign.justify,
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
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
    return leading;
  }
}

import 'package:flutter/material.dart';
import 'package:fossfit/app/services/features/gym_set_services.dart';
import 'package:fossfit/app/utils/utils.dart';
import 'package:fossfit/app/widgets/exercise_icon.dart';
import 'package:fossfit/db/models/features/exercise_model.dart';
import 'package:fossfit/db/models/features/gymset_model.dart';
import 'package:fossfit/db/repositories/config_reposity.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sticky_headers/sticky_headers/widget.dart';
import 'package:timeago/timeago.dart' as timeago;

class WorkoutGrouped extends StatelessWidget {
  final List<GymSet> sets;
  WorkoutGrouped({super.key, required this.sets});

  final scroll = ScrollController();
  @override
  Widget build(BuildContext context) {
    var config = context.read<ConfigRepository>();
    final showImages = config.isEnabled(.workouts, 'show_images');
    final services = GymSetServices(context: context);
    final sortedDays = List<ExerciseSets>.from(services.getExerciseSets(sets, reversed: true))..sort((a, b) => b.date.compareTo(a.date));
    var grouped = services.groupExerciseSetsByDay(sortedDays);

    return ListView.builder(
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
          content: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: List.generate(sets.length, (index) => workoutChildren(sets[index], context, showImages, config))),
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
              content: services.getLastGymSetWorkout(day.expand((t) => t.sets).toList()),
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
            Text(DateFormat(config.getSetting(.formats, 'date_format')).format(date), style: const TextStyle(fontWeight: FontWeight.bold)),
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
      title: Text("${history.exercise.name} (${history.sets.length})"),
      shape: const Border.symmetric(),
      children: history.sets.reversed.toList().map((gymSet) {
        final reps = gymSet.reps;
        final weight = gymSet.weight;

        Widget? leading = ExerciseIcon(exercise: history.exercise, showImages: showImages);

        final dateFormat = config.getSetting(.formats, 'date_format');
        final trailing = Text(dateFormat == 'timeago' ? timeago.format(gymSet.created) : DateFormat("HH:mm a").format(gymSet.created));
        return ListTile(
          dense: true,
          visualDensity: VisualDensity.comfortable,
          leading: leading,
          title: Text("${_getSetNumber(gymSet, history.sets)}: $reps REPS @ $weight ${gymSet.unit}"),
          trailing: trailing,
        );
      }).toList(),
    );
  }

  String _getSetNumber(GymSet gymSet, List<GymSet> today) {
    final currentDate = gymSet.created.toLocal();
    final sameDayEntries = today
        .where((entry) => entry.created.toLocal().year == currentDate.year && entry.created.toLocal().month == currentDate.month && entry.created.toLocal().day == currentDate.day)
        .toList()
        .reversed
        .toList();
    final positionOnThisDay = sameDayEntries.indexOf(gymSet) + 1;
    return 'Set $positionOnThisDay';
  }
}

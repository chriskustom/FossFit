import 'package:flutter/material.dart';
import 'package:fossfit/app/services/features/exercise_services.dart';
import 'package:fossfit/app/services/features/gym_set_services.dart';
import 'package:fossfit/app/widgets/exercise_icon.dart';
import 'package:fossfit/db/models/features/gymset_model.dart';
import 'package:fossfit/db/repositories/config_reposity.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sticky_headers/sticky_headers/widget.dart';
import 'package:timeago/timeago.dart' as timeago;

class WorkoutList extends StatelessWidget {
  final List<GymSet> sets;
  WorkoutList({super.key, required this.sets});
  final scroll = ScrollController();

  @override
  Widget build(BuildContext context) {
    var config = context.watch<ConfigRepository>();
    final showImages = config.isEnabled(.workouts, 'show_images');
    final services = GymSetServices(context: context);
    var grouped = services.groupSetsByDay(sets);

    return ListView.builder(
      controller: scroll,
      padding: const EdgeInsets.only(bottom: 96),
      itemCount: grouped.entries.length,
      itemBuilder: (context, sectionIndex) {
        final entry = grouped.entries.elementAt(sectionIndex);
        final date = entry.key;
        final sets = entry.value.reversed.toList();

        return StickyHeader(
          header: Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            alignment: Alignment.center,
            child: _buildSectionDivider(context, date),
          ),
          content: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: List.generate(sets.length, (index) => _buildListItem(context, sets[index], showImages))),
        );
      },
    );
  }

  //region HELPERS

  Widget _buildSectionDivider(BuildContext context, DateTime date) {
    final format = context.read<ConfigRepository>().getSetting(.formats, 'date_format');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const Expanded(child: Divider(thickness: 1)),
          const SizedBox(width: 4),
          const Icon(Icons.today, size: 16),
          const SizedBox(width: 4),
          Text(DateFormat(format).format(date), style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 4),
          const Expanded(child: Divider(thickness: 1)),
        ],
      ),
    );
  }

  Widget _buildListItem(BuildContext context, GymSet gymSet, bool showImages) {
    var services = ExerciseServices(context: context);
    var exercise = services.getExerciseById(gymSet.exerciseId);
    final reps = gymSet.reps;
    final weight = gymSet.weight;
    Widget? leading = ExerciseIcon(exercise: exercise!, showImages: showImages);
    final trailing = Text("${_getSetNumber(gymSet)}: $reps REPS @ $weight ${gymSet.unit}");
    final dateFormat = context.read<ConfigRepository>().getSetting(.formats, 'date_format');
    final subtitle = Text(dateFormat == 'timeago' ? timeago.format(gymSet.created) : DateFormat("HH:mm a").format(gymSet.created));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [ListTile(dense: true, visualDensity: VisualDensity.compact, leading: leading, title: Text(exercise.name), subtitle: trailing, trailing: subtitle)],
    );
  }

  String _getSetNumber(GymSet gymSet) {
    final currentDate = gymSet.created.toLocal();
    final sameDayEntries = sets
        .where((entry) => entry.created.toLocal().year == currentDate.year && entry.created.toLocal().month == currentDate.month && entry.created.toLocal().day == currentDate.day)
        .toList()
        .reversed
        .toList();
    final positionOnThisDay = sameDayEntries.indexOf(gymSet) + 1;
    return 'Set $positionOnThisDay';
  }

  //endregion
}

class DateHeaderDelegate extends SliverPersistentHeaderDelegate {
  final DateTime date;

  DateHeaderDelegate(this.date);

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Selector<ConfigRepository, String>(
      selector: (context, settings) {
        final format = settings.getSetting(.formats, 'date_format');
        return format;
      },
      builder: (context, format, child) {
        return Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(DateFormat(format).format(date), style: Theme.of(context).textTheme.titleMedium),
        );
      },
    );
  }

  @override
  double get maxExtent => 44;

  @override
  double get minExtent => 44;

  @override
  bool shouldRebuild(DateHeaderDelegate oldDelegate) => oldDelegate.date != date;
}

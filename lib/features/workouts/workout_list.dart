import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fossfit/db/repositories/settings_repository.dart';
import 'package:fossfit/models/gym_set_model.dart';
import 'package:fossfit/services/exercise_services.dart';
import 'package:fossfit/services/gym_sets_services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sticky_headers/sticky_headers/widget.dart';
import 'package:timeago/timeago.dart' as timeago;

class WorkoutList extends StatefulWidget {
  final List<GymSet> sets;

  const WorkoutList({
    super.key,
    required this.sets,
  });

  @override
  State<StatefulWidget> createState() => _WorkoutListState();
}

class _WorkoutListState extends State<WorkoutList> {
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
    var grouped = services.groupSetByDay(widget.sets);

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
            child: _buildSectionDivider(date),
          ),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: List.generate(
              sets.length,
              (index) => _buildListItem(sets[index], index, showImages),
            ),
          ),
        );
      },
    );
  }

  //region HELPERS

  Widget _buildSectionDivider(DateTime date) {
    final format = context.read<SettingsRepository>().getSetting(key: 'short_date_format');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const Expanded(child: Divider(thickness: 1)),
          const SizedBox(width: 4),
          const Icon(Icons.today, size: 16),
          const SizedBox(width: 4),
          Text(
            DateFormat(format).format(date),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 4),
          const Expanded(child: Divider(thickness: 1)),
        ],
      ),
    );
  }

  Widget _buildListItem(
    GymSet gymSet,
    int index,
    bool showImages,
  ) {
    var services = ExerciseServices(context: context);
    var exercise = services.getExerciseById(gymSet.exerciseId);
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
      transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
      child: leading,
    );

    String trailing = "$reps REPS @ $weight ${gymSet.unit}";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _getListItem(leading, gymSet, trailing),
      ],
    );
  }

  Widget _getListItem(Widget leading, GymSet gymSet, String trailingText) {
    var services = ExerciseServices(context: context);
    var exercise = services.getExerciseById(gymSet.exerciseId);

    final trailing = Text(
      "${_getSetNumber(gymSet)}: $trailingText",
    );
    final dateFormat = settings.getSetting(key: 'short_date_format');
    final subtitle = Text(
      dateFormat == 'timeago' ? timeago.format(gymSet.created) : DateFormat("HH:mm a").format(gymSet.created),
    );

    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      leading: leading,
      title: Text(exercise?.name ?? ''),
      subtitle: trailing,
      trailing: subtitle,
      onLongPress: () {},
      onTap: () {
        //TODO EDIT SET
      },
    );
  }

  String _getSetNumber(GymSet gymSet) {
    final currentDate = gymSet.created.toLocal();
    final sameDayEntries = widget.sets
        .where(
          (entry) => entry.created.toLocal().year == currentDate.year && entry.created.toLocal().month == currentDate.month && entry.created.toLocal().day == currentDate.day,
        )
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
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Selector<SettingsRepository, String>(
      selector: (context, settings) {
        final format = settings.getSetting(key: 'short_date_format');
        return format;
      },
      builder: (context, format, child) {
        return Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            DateFormat(format).format(date),
            style: Theme.of(context).textTheme.titleMedium,
          ),
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

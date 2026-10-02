import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:fossfit/app/services/features/cardio_services.dart';
import 'package:fossfit/app/services/features/exercise_services.dart';
import 'package:fossfit/app/services/features/gym_set_services.dart';
import 'package:fossfit/app/utils/utils.dart';
import 'package:fossfit/db/models/features/cardio_model.dart';
import 'package:fossfit/db/models/features/exercise_model.dart';
import 'package:fossfit/db/models/features/gymset_model.dart';
import 'package:fossfit/db/repositories/config_reposity.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sticky_headers/sticky_headers/widget.dart';
import 'package:timeago/timeago.dart' as timeago;

class HistoryPeek extends StatelessWidget {
  final List<GymSet> sets;
  final List<Cardio> cardio;
  final String? dateHeader;
  HistoryPeek({super.key, required this.sets, required this.cardio, this.dateHeader});
  final scroll = ScrollController();

  @override
  Widget build(BuildContext context) {
    var config = context.watch<ConfigRepository>();
    final showImages = config.isEnabled(.workouts, 'show_images');
    return sets.isEmpty ? _buildCardioList(context, showImages) : _buildStrengthList(context, showImages);
  }

  Widget _buildStrengthList(BuildContext context, bool showImages) {
    final strengthServices = GymSetServices(context: context);

    var grouped = strengthServices.groupSetsByDay(sets);

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
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: List.generate(sets.length, (index) => _buildStrengthListItem(context, sets[index], showImages)),
          ),
        );
      },
    );
  }

  Widget _buildCardioList(BuildContext context, bool showImages) {
    final cardioServices = CardioServices(context: context);

    var grouped = cardioServices.groupSetsByDay(cardio);

    return ListView.builder(
      shrinkWrap: true,
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
            child: dateHeader == null
                ? _buildSectionDivider(context, date)
                : Stack(
                    children: [
                      Padding(padding: .only(top: 5), child: Divider()),
                      Center(
                        child: Container(
                          decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface),
                          child: Text(
                            dateHeader!,
                            textAlign: .center,
                            style: Theme.of(context).textTheme.titleMedium,
                            textScaler: TextScaler.linear(1.1),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: List.generate(sets.length, (index) => _buildCardioListItem(context, sets[index], showImages)),
          ),
        );
      },
    );
  }

  Widget _buildCardioListItem(BuildContext context, Cardio cardioSet, bool showImages) {
    var services = ExerciseServices(context: context);
    var exercise = services.getExerciseById(cardioSet.exerciseId);

    final dateFormat = context.read<ConfigRepository>().getSetting(.formats, 'short_date_format');
    final trailing = Text(
      dateFormat == 'timeago' ? timeago.format(cardioSet.created) : DateFormat("HH:mm a").format(cardioSet.created),
    );
    final setPace = '${cardioSet.pace}/${cardioSet.distanceUnit}';
    final subtitle = cardioSet.distance != null
        ? '${exercise?.name}: '
              '${cardioSet.distance}'
              '${cardioSet.distanceUnit} in '
              '${formatDuration(Duration(seconds: cardioSet.duration))} @ $setPace'
        : '${exercise?.name} for '
              '${formatDuration(Duration(seconds: cardioSet.duration))}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          leading: _leading(context, exercise!, showImages),
          title: Text(exercise.name),
          subtitle: Text(subtitle),
          trailing: trailing,
          onTap: () async {
            var services = CardioServices(context: context);
            await services.openCardioPage(context, cardioSet.id);
          },
        ),
      ],
    );
  }

  Widget _buildSectionDivider(BuildContext context, DateTime date) {
    final format = context.read<ConfigRepository>().getSetting(.formats, 'short_date_format');
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

  Widget _buildStrengthListItem(BuildContext context, GymSet gymSet, bool showImages) {
    var services = ExerciseServices(context: context);
    var exercise = services.getExerciseById(gymSet.exerciseId);
    final reps = gymSet.reps;
    final weight = gymSet.weight;
    final trailing = Text("${_getSetNumber(gymSet)}: $reps REPS @ $weight ${gymSet.unit}");
    final dateFormat = context.read<ConfigRepository>().getSetting(.formats, 'short_date_format');
    final subtitle = Text(
      dateFormat == 'timeago' ? timeago.format(gymSet.created) : DateFormat("HH:mm a").format(gymSet.created),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          leading: _leading(context, exercise!, showImages),
          title: Text(exercise.name),
          subtitle: trailing,
          trailing: subtitle,
          onTap: () async {
            var services = GymSetServices(context: context);
            await services.openAddEditPage(context, gymSet.id);
          },
        ),
      ],
    );
  }

  String _getSetNumber(GymSet gymSet) {
    final currentDate = gymSet.created.toLocal();
    final sameDayEntries = sets
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

  Widget _leading(BuildContext context, Exercise exercise, bool showImages) {
    Widget leading = SizedBox(height: 24, width: 24);

    if (showImages && exercise.hasImage()) {
      leading = Container(
        width: 24,
        height: 24,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          image: DecorationImage(
            image: MemoryImage(exercise.image ?? Uint8List(0)),
            fit: BoxFit.cover,
            colorFilter: const ColorFilter.mode(Color.fromARGB(100, 0, 0, 0), BlendMode.darken),
          ),
        ),
      );
    } else {
      leading = Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              exercise.name.isNotEmpty ? exercise.name[0] : '?',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ),
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 150),
      transitionBuilder: (child, animation) {
        return ScaleTransition(scale: animation, child: child);
      },
      child: leading,
    );
  }
}

class DateHeaderDelegate extends SliverPersistentHeaderDelegate {
  final DateTime date;

  DateHeaderDelegate(this.date);

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Selector<ConfigRepository, String>(
      selector: (context, settings) {
        final format = settings.getSetting(.formats, 'short_date_format');
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

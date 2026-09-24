import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fossfit/constants.dart';
import 'package:fossfit/db/repositories/plan_exercises_repository.dart';
import 'package:fossfit/db/repositories/plans_repository.dart';
import 'package:fossfit/db/repositories/settings_repository.dart';
import 'package:fossfit/models/plan_exercise_model.dart';
import 'package:fossfit/models/plan_model.dart';
import 'package:fossfit/plan/start_plan_page.dart';
import 'package:provider/provider.dart';

class PlanTile extends StatefulWidget {
  final Plan plan;
  final String weekday;
  final int index;
  final GlobalKey<NavigatorState> navigatorKey;
  final Function(int) onSelect;
  final Set<int> selected;

  const PlanTile({
    super.key,
    required this.plan,
    required this.weekday,
    required this.index,
    required this.navigatorKey,
    required this.onSelect,
    required this.selected,
  });

  @override
  State<PlanTile> createState() => _PlanTileState();
}

class _PlanTileState extends State<PlanTile> {
  late List<PlanExercise> _exercisesStream;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    _exercisesStream = context.watch<PlanExercisesRepository>().getPlanExercisesByPlanId(widget.plan.id!);
    var settingsRepo = context.watch<SettingsRepository>();
    final planRepo = context.watch<PlansRepository>();
    Widget title = const Text("Daily");
    if (widget.plan.title?.isNotEmpty == true) {
      final today = widget.plan.days.split(',').contains(widget.weekday);
      title = Text(
        widget.plan.title!,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: today ? FontWeight.bold : null,
              decoration: today ? TextDecoration.underline : null,
            ),
      );
    } else if (widget.plan.days.split(',').length < 7)
      title = RichText(text: TextSpan(children: _getChildren(context)));

    Widget? leading = SizedBox(
      height: 24,
      width: 24,
      child: Checkbox(
        value: widget.selected.contains(widget.plan.id),
        onChanged: (value) {
          widget.onSelect(widget.plan.id!);
        },
      ),
    );

    if (widget.selected.isEmpty)
      leading = GestureDetector(
        onTap: () => widget.onSelect(widget.plan.id!),
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.inversePrimary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              widget.plan.title?.isNotEmpty == true ? widget.plan.title![0] : widget.plan.days[0].toUpperCase(),
              textAlign: TextAlign.justify,
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
        color: widget.selected.contains(widget.plan.id)
            ? Theme.of(context).colorScheme.primary.withValues(alpha: .08)
            : Colors.transparent,
        border: Border.all(
          color: widget.selected.contains(widget.plan.id)
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
              : Colors.transparent,
          width: 1,
        ),
      ),
      child: ListTile(
        title: title,
        subtitle: _exercisesStream.isNotEmpty
            ? Text(
                overflow: TextOverflow.ellipsis,
                _exercisesStream.map((e) => e.exercise!.name).join(', '),
                maxLines: 2,
              )
            : Text('No exercises found...'),
        leading: leading,
        trailing: Builder(
          builder: (context) {
            final trailing = PlanTrailing.values.byName(
              settingsRepo.getSetting(key: 'plan_trailing'),
            );

            if (trailing == PlanTrailing.none) return const SizedBox();
            if (trailing == PlanTrailing.reorder && defaultTargetPlatform == TargetPlatform.linux)
              return const SizedBox();
            else if (trailing == PlanTrailing.reorder && defaultTargetPlatform == TargetPlatform.android)
              return ReorderableDragStartListener(
                index: widget.index,
                child: const Icon(Icons.drag_handle),
              );

            final idx = planRepo.planCounts.indexWhere((element) => element.planId == widget.plan.id);
            PlanCount count;
            if (idx != -1)
              count = planRepo.planCounts[idx];
            else
              return const SizedBox();

            if (trailing == PlanTrailing.count)
              return Text(
                "${count.total}",
                style: const TextStyle(fontSize: 16),
              );

            if (trailing == PlanTrailing.percent)
              return Text(
                "${((count.total) / count.maxSets * 100).toStringAsFixed(2)}%",
                style: const TextStyle(fontSize: 16),
              );
            else
              return Text(
                "${count.total} / ${count.maxSets}",
                style: const TextStyle(fontSize: 16),
              );
          },
        ),
        onTap: () async {
          if (widget.selected.isNotEmpty) return widget.onSelect(widget.plan.id!);
          final state = context.read<PlansRepository>();
          await state.updateGymCounts(widget.plan.id!);

          widget.navigatorKey.currentState!.push(
            MaterialPageRoute(
              builder: (context) => StartPlanPage(
                plan: widget.plan,
              ),
            ),
          );
        },
        onLongPress: () {
          widget.onSelect(widget.plan.id!);
        },
      ),
    );
  }

  List<InlineSpan> _getChildren(BuildContext context) {
    List<InlineSpan> result = [];

    final split = widget.plan.days.split(',');
    for (int index = 0; index < split.length; index++) {
      final day = split[index];
      result.add(
        TextSpan(
          text: day.trim(),
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: widget.weekday == day.trim() ? FontWeight.bold : null,
                decoration: widget.weekday == day.trim() ? TextDecoration.underline : null,
              ),
        ),
      );
      if (index < split.length - 1)
        result.add(
          TextSpan(
            text: ", ",
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        );
    }
    return result;
  }
}

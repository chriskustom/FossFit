import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fossfit/app/app_shell.dart';
import 'package:fossfit/db/repositories/plans_repository.dart';
import 'package:fossfit/db/repositories/settings_repository.dart';
import 'package:fossfit/features/plans/start_plan_page.dart';
import 'package:fossfit/models/constants.dart';
import 'package:fossfit/models/plan_model.dart';
import 'package:fossfit/services/exercise_services.dart';
import 'package:fossfit/services/plan_services.dart';
import 'package:fossfit/widgets/animated_fab.dart';
import 'package:fossfit/widgets/app_search.dart';
import 'package:provider/provider.dart';

class PlansPage extends StatefulWidget {
  const PlansPage({super.key});

  @override
  State<PlansPage> createState() => PlansPageState();
}

class PlansPageState extends State<PlansPage> {
  String search = '';
  late List<Plan> plans;
  final Set<int> selectedPlans = {};

  final scroll = ScrollController();
  late SettingsRepository settings;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var planRepo = context.watch<PlansRepository>(); // Watch for changes to rebuild
    settings = context.watch<SettingsRepository>();
    plans = planRepo.plans;
    return AppShell(
      body: planRepo.plans.isEmpty ? _noneFound() : _buildPlanList(),
      floatingActionButton: AnimatedFab(
        onPressed: () async {
          //TODO ADD PLAN PAGE
        },
        label: Text('Add'),
        icon: Icon(Icons.add),
        scroll: scroll,
      ),
      appBar: AppSearch(
        onSearchChange: (value) {},
        onClear: () => setState(() {}),
        onDelete: () async {},
        onSelect: () => setState(() {}),
        selected: selectedPlans,
        onEdit: () async {},
      ),
    );
  }

  Widget _buildPlanList() {
    if (PlanTrailing.values.byName(
          settings.getSetting(key: 'plan_trailing'),
        ) ==
        PlanTrailing.reorder)
      return ReorderableListView.builder(
        scrollController: scroll,
        itemCount: plans.length,
        padding: const EdgeInsets.only(bottom: 96, top: 16),
        itemBuilder: (context, index) {
          final plan = plans[index];
          return _buildPlanItem(plan, index);
        },
        onReorder: (int old, int idx) async {
          if (old < idx) {
            idx--;
          }

          final temp = plans[old];
          plans.removeAt(old);
          plans.insert(idx, temp);

          final repo = context.read<PlansRepository>();
          for (int i = 0; i < plans.length; i++) {
            final plan = plans[i];
            final updated = plan.copyWith(sequence: i);
            await repo.updatePlan(updated);
          }
        },
      );
    return ListView.builder(
      controller: scroll,
      itemCount: plans.length,
      padding: const EdgeInsets.only(bottom: 96, top: 8),
      itemBuilder: (context, index) {
        final plan = plans[index];

        return _buildPlanItem(plan, index);
      },
    );
  }

  List<InlineSpan> _getDayListFormatted(String days, String today) {
    final style = Theme.of(context).textTheme.bodyLarge;

    return days.split(',').expand((day) {
      final trimmedDay = day.trim();
      final isToday = trimmedDay == today;

      return [
        TextSpan(
          text: trimmedDay,
          style: style?.copyWith(
            fontWeight: isToday ? FontWeight.bold : null,
            decoration: isToday ? TextDecoration.underline : null,
          ),
        ),
        const TextSpan(text: ', '),
      ];
    }).toList()
      ..removeLast();
  }

  Widget _buildPlanItem(Plan plan, int index) {
    var services = PlanServices(context: context);
    var exerciseServices = ExerciseServices(context: context);
    final weekday = weekdays[DateTime.now().weekday - 1];
    var exercises = exerciseServices.getExercisesByPlanId(plan.id!).map((t) => t.name).join(', ');
    var planCounts = services.getPlanCounts();
    Widget title = const Text("Daily");
    if (plan.title?.isNotEmpty == true) {
      final today = plan.days.split(',').contains(weekday);
      title = Text(
        plan.title!,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: today ? FontWeight.bold : null,
              decoration: today ? TextDecoration.underline : null,
            ),
      );
    } else if (plan.days.split(',').length < 7) {
      title = RichText(text: TextSpan(children: _getDayListFormatted(plan.days, weekday)));
    }

    Widget? leading = SizedBox.shrink();

    if (selectedPlans.isEmpty)
      leading = Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.inversePrimary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            plan.title?.isNotEmpty == true ? plan.title![0] : plan.days[0].toUpperCase(),
            textAlign: TextAlign.justify,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
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
      key: Key(plan.id.toString()),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: selectedPlans.contains(plan.id) ? Theme.of(context).colorScheme.primary.withValues(alpha: .08) : Colors.transparent,
        border: Border.all(
          color: selectedPlans.contains(plan.id) ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3) : Colors.transparent,
          width: 1,
        ),
      ),
      child: ListTile(
        title: title,
        subtitle: exercises.isNotEmpty
            ? Text(
                overflow: TextOverflow.ellipsis,
                exercises,
                maxLines: 2,
              )
            : Text('No exercises found...'),
        leading: leading,
        trailing: Builder(
          builder: (context) {
            final trailing = PlanTrailing.values.byName(
              settings.getSetting(key: 'plan_trailing'),
            );

            if (trailing == PlanTrailing.none) return const SizedBox();
            if (trailing == PlanTrailing.reorder && defaultTargetPlatform == TargetPlatform.linux)
              return const SizedBox();
            else if (trailing == PlanTrailing.reorder && defaultTargetPlatform == TargetPlatform.android)
              return ReorderableDragStartListener(
                index: index,
                child: const Icon(Icons.drag_handle),
              );
            final idx = planCounts.indexWhere((element) => element.planId == plan.id);
            PlanCount count;
            if (idx != -1)
              count = planCounts[idx];
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
          await showGeneralDialog(
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
                    child: StartPlanPage(plan: plan),
                  ),
                ),
              );
            },
            transitionBuilder: (context, anim1, anim2, child) {
              final offsetAnimation = Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(anim1);
              return SlideTransition(position: offsetAnimation, child: child);
            },
          );
        },
        onLongPress: () {},
      ),
    );
  }

  Widget _noneFound() {
    return ListTile(
      title: const Text("No plans found"),
      subtitle: Text("Tap to create"),
      onTap: () async {
        //TODO CREATE PLAN PAGE
      },
    );
  }
}

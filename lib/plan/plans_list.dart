import 'package:flutter/material.dart';
import 'package:fossfit/constants.dart';
import 'package:fossfit/db/repositories/plans_repository.dart';
import 'package:fossfit/db/repositories/settings_repository.dart';
import 'package:fossfit/models/plan_model.dart';
import 'package:fossfit/plan/edit_plan_page.dart';
import 'package:fossfit/plan/plan_tile.dart';
import 'package:provider/provider.dart';

class PlansList extends StatefulWidget {
  final List<Plan>? plans;
  final GlobalKey<NavigatorState> navKey;
  final Set<int> selected;
  final Function(int) onSelect;
  final String search;
  final ScrollController scroll;

  const PlansList({
    super.key,
    required this.plans,
    required this.navKey,
    required this.selected,
    required this.onSelect,
    required this.search,
    required this.scroll,
  });

  @override
  State<PlansList> createState() => _PlansListState();
}

class _PlansListState extends State<PlansList> {
  @override
  Widget build(BuildContext context) {
    final noneFound = ListTile(
      title: const Text("No plans found"),
      subtitle: Text("Tap to create ${widget.search}"),
      onTap: () async {
        final plan = Plan(
          days: '',
          title: widget.search,
        );
        if (context.mounted)
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditPlanPage(
                plan: plan,
              ),
            ),
          );
      },
    );

    if (widget.plans == null) return noneFound;

    final weekday = weekdays[DateTime.now().weekday - 1];

    final filteredPlans = widget.plans!.where((plan) {
      final term = widget.search.toLowerCase();
      return plan.title?.toLowerCase().contains(term) == true || plan.days.toLowerCase().contains(term);
    }).toList();

    if (widget.plans!.isEmpty || filteredPlans.isEmpty) return noneFound;

    final settings = context.read<SettingsRepository>();

    if (PlanTrailing.values.byName(
          settings.getSetting(key: 'plan_trailing'),
        ) ==
        PlanTrailing.reorder)
      return ReorderableListView.builder(
        scrollController: widget.scroll,
        itemCount: filteredPlans.length,
        padding: const EdgeInsets.only(bottom: 96, top: 16),
        itemBuilder: (context, index) {
          final plan = filteredPlans[index];

          return PlanTile(
            key: Key(plan.id.toString()),
            plan: plan,
            weekday: weekday,
            index: index,
            navigatorKey: widget.navKey,
            selected: widget.selected,
            onSelect: (id) => widget.onSelect(id),
          );
        },
        onReorder: (int old, int idx) async {
          if (old < idx) {
            idx--;
          }

          final temp = filteredPlans[old];
          filteredPlans.removeAt(old);
          filteredPlans.insert(idx, temp);

          final repo = context.read<PlansRepository>();
          for (int i = 0; i < filteredPlans.length; i++) {
            final plan = filteredPlans[i];
            final updated = plan.copyWith(sequence: i);
            await repo.updatePlan(updated);
          }
        },
      );

    return ListView.builder(
      controller: widget.scroll,
      itemCount: filteredPlans.length,
      padding: const EdgeInsets.only(bottom: 96, top: 8),
      itemBuilder: (context, index) {
        final plan = filteredPlans[index];

        return PlanTile(
          plan: plan,
          weekday: weekday,
          index: index,
          navigatorKey: widget.navKey,
          selected: widget.selected,
          onSelect: (id) => widget.onSelect(id),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:fossfit/app/services/features/exercise_services.dart';
import 'package:fossfit/app/services/features/plan_services.dart';
import 'package:fossfit/app/shell/app_shell.dart';
import 'package:fossfit/app/utils/constants.dart';
import 'package:fossfit/app/widgets/animated_fab.dart';
import 'package:fossfit/app/widgets/confirmation_dialog.dart';
import 'package:fossfit/db/models/features/plan_model.dart';
import 'package:fossfit/db/repositories/config_reposity.dart';
import 'package:fossfit/db/repositories/plan_exercises_repository.dart';
import 'package:fossfit/db/repositories/plan_repository.dart';
import 'package:provider/provider.dart';

class PlansPage extends StatefulWidget {
  const PlansPage({super.key});

  @override
  State<StatefulWidget> createState() => _PlansPageState();
}

class _PlansPageState extends State<PlansPage> {
  late ConfigRepository config;
  List<Plan>? _displayPlans;

  final Set<Plan> _selectedItems = {};
  bool get selectionMode => _selectedItems.isNotEmpty;

  final ScrollController scroll = ScrollController();
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    config = context.watch<ConfigRepository>();
    var repo = context.watch<PlansRepository>();

    final plans = _displayPlans ?? repo.plans;
    return AppShell(
      title: selectionMode ? '${_selectedItems.length} selected' : 'Plans',

      selectActions: _selectActions(),
      body: _buildBody(plans),
      floatingActionButton: AnimatedFab(
        onPressed: () async {
          var services = PlanServices(context: context);
          await services.openAddEdiPlanPage(context, null);
        },
        label: const Text('Add'),
        icon: const Icon(Icons.add),
        scroll: scroll,
      ),
    );
  }

  Widget _buildBody(List<Plan> plans) {
    final weekday = weekdays[DateTime.now().weekday - 1];
    final exerciseServices = ExerciseServices(context: context);
    final peRepo = context.watch<PlanExercisesRepository>();

    if (plans.isEmpty) return _nonFound();
    return ReorderableListView.builder(
      scrollController: scroll,
      itemCount: plans.length,
      padding: const EdgeInsets.only(bottom: 96, top: 16),
      itemBuilder: (context, index) {
        final plan = plans[index];
        Widget title = const Text("Daily");
        if (plan.name.isNotEmpty == true) {
          final today = plan.days.split(',').contains(weekday);
          title = Text(
            plan.name,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: today ? FontWeight.bold : null,
              decoration: today ? TextDecoration.underline : null,
            ),
          );
        } else if (plan.days.split(',').length < 7) {
          title = RichText(text: TextSpan(children: _getDayListFormatted(plan.days, weekday)));
        }
        var exercisesInPlan = peRepo.getPlanExercisesByPlanId(plan.id!);
        var exercises = exerciseServices.getExercisesByPlanId(plan.id!);
        final ordered = exercises.toList()
          ..sort((a, b) {
            final aIndex = exercisesInPlan.indexWhere((x) => x.exerciseId == a.id);
            final bIndex = exercisesInPlan.indexWhere((x) => x.exerciseId == b.id);
            return aIndex.compareTo(bIndex);
          });
        var exerciseNames = ordered.map((e) => e.name).join(', ');
        return ListTile(
          key: Key(plan.id.toString()),
          leading: _leading(plan),
          title: title,
          subtitle: Text(exerciseNames, maxLines: 2, overflow: .ellipsis),
          trailing: ReorderableDragStartListener(index: index, child: const Icon(Icons.drag_handle)),
          selected: _selectedItems.contains(plan),
          onLongPress: () => _toggleSelection(plan),
          onTap: () async {
            if (selectionMode) {
              _toggleSelection(plan);
            } else {
              var services = PlanServices(context: context);
              await services.openPlanPage(context, plan.id!);
            }
          },
        );
      },
      onReorderItem: (oldIndex, newIndex) {
        context.read<PlansRepository>().reorderPlans(oldIndex, newIndex);
      },
    );
  }

  Widget _nonFound() {
    return ListTile(
      title: const Text("No plans found"),
      subtitle: Text("Tap to create "),
      onTap: () async {
        Navigator.pop(context);
        var services = PlanServices(context: context);
        await services.openAddEdiPlanPage(context, null);
      },
    );
  }

  Widget _leading(Plan plan) {
    Widget? leading = SizedBox(
      height: 24,
      width: 24,
      child: Checkbox(value: _selectedItems.contains(plan), onChanged: (_) => _toggleSelection(plan)),
    );

    if (!selectionMode) {
      leading = GestureDetector(
        onTap: () => _toggleSelection(plan),
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 2),
              child: Text(
                plan.name.isNotEmpty ? plan.name[0] : plan.days[0].toUpperCase(),
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

  void _toggleSelection(Plan plan) {
    setState(() {
      _selectedItems.contains(plan) ? _selectedItems.remove(plan) : _selectedItems.add(plan);
    });
  }

  List<IconButton> _selectActions() {
    final planServices = PlanServices(context: context);
    final plans = planServices.getAllPlans();
    List<IconButton> buttons = [];
    if (_selectedItems.isNotEmpty) {
      buttons.add(
        IconButton(
          onPressed: () {
            setState(() {
              if (_selectedItems.length == plans.length) {
                _selectedItems.clear();
              } else {
                _selectedItems.addAll(plans);
              }
            });
          },
          icon: Icon(_selectedItems.length == plans.length ? Icons.deselect : Icons.select_all),
        ),
      );

      buttons.addAll([
        IconButton(
          onPressed: () async {
            final confirmed = await showConfirmationDialog(
              context: context,
              title: "Delete?",
              content: "Are you sure?",
              barrierDismissible: true,
            );

            if (!mounted || confirmed == null || !confirmed) return;
            await planServices.deleteMultiplePlanByIds(_selectedItems.map((i) => i.id!).toList());
            setState(() => _selectedItems.clear());
          },
          icon: const Icon(Icons.delete),
        ),
      ]);
    }
    setState(() {});
    return buttons;
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
    }).toList()..removeLast();
  }
}

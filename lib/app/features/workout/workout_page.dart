import 'package:flutter/material.dart';
import 'package:fossfit/app/features/workout/widgets/workout_grouped.dart';
import 'package:fossfit/app/features/workout/widgets/workout_list.dart';
import 'package:fossfit/app/services/features/gym_set_services.dart';
import 'package:fossfit/app/shell/app_shell.dart';
import 'package:fossfit/app/widgets/animated_fab.dart';
import 'package:fossfit/app/widgets/confirmation_dialog.dart';
import 'package:fossfit/db/models/features/gymset_model.dart';
import 'package:fossfit/db/repositories/config_reposity.dart';
import 'package:fossfit/db/repositories/gym_set_repository.dart';
import 'package:provider/provider.dart';

class WorkoutPage extends StatefulWidget {
  const WorkoutPage({super.key});

  @override
  State<StatefulWidget> createState() => _WorkoutPageState();
}

class _WorkoutPageState extends State<WorkoutPage> {
  List<GymSet>? _lastWorkoutSets;
  Widget lastWorkout = const SizedBox.shrink();
  final expand = ExpansibleController();
  final scroll = ScrollController();
  final Set<int> selectedSets = {};

  late ConfigRepository config;

  final Set<GymSet> _selectedItems = {};
  bool get selectionMode => _selectedItems.isNotEmpty;
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    config = context.watch<ConfigRepository>();
    final lastWorkoutSets = _lastWorkoutSets ?? context.watch<GymSetRepository>().latestgymsets;
    var showStats = config.isEnabled(.workouts, 'show_stats');
    if (showStats) getStats(lastWorkoutSets);
    var grouped = config.isEnabled(.workouts, 'group_history');
    var timer = config.isEnabled(.timers, 'enabled');
    return AppShell(
      title: selectionMode ? '${_selectedItems.length} selected' : 'Workout',
      selectActions: _selectActions(),
      showTimer: timer,
      body: Padding(
        padding: EdgeInsets.all(8),
        child: Column(
          children: [
            if (lastWorkoutSets.isEmpty)
              const ListTile(title: Text('No entries yet'), subtitle: Text('Complete some sets to see them here')),
            if (lastWorkoutSets.isNotEmpty && showStats)
              Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: ExpansionTile(
                    childrenPadding: EdgeInsets.zero,
                    iconColor: Theme.of(context).colorScheme.onSurface,
                    leading: Icon(
                      expand.isExpanded ? Icons.analytics_outlined : Icons.fitness_center_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: Text(expand.isExpanded ? 'Stats' : 'Exercises'),
                    initiallyExpanded: true,
                    controller: expand,
                    children: [lastWorkout],
                    onExpansionChanged: (value) {
                      setState(() {});
                    },
                  ),
                ),
              ),
            Expanded(
              child: grouped
                  ? WorkoutGrouped(
                      sets: lastWorkoutSets,
                      selectedItems: _selectedItems,
                      selectionMode: selectionMode,
                      toggleSelection: (set) => _toggleSelection(set),
                      scroll: scroll,
                    )
                  : WorkoutList(
                      sets: lastWorkoutSets,
                      selectedItems: _selectedItems,
                      selectionMode: selectionMode,
                      toggleSelection: (set) => _toggleSelection(set),
                      scroll: scroll,
                    ),
            ),
            //Padding(padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8), child: CountdownTimer()),
          ],
        ),
      ),
      floatingActionButton: AnimatedFab(
        onPressed: () async {
          var services = GymSetServices(context: context);
          await services.openAddEditPage(context, null);
        },
        label: const Text('Add'),
        icon: const Icon(Icons.add),
        scroll: scroll,
        height: timer ? 60 : 0,
      ),
    );
  }

  void getStats(List<GymSet> sets) async {
    var services = GymSetServices(context: context);
    try {
      final lw = services.getLastGymSetWorkout(sets);
      setState(() {
        lastWorkout = lw;
      });
    } catch (_) {}
  }

  void _toggleSelection(GymSet set) {
    setState(() {
      _selectedItems.contains(set) ? _selectedItems.remove(set) : _selectedItems.add(set);
    });
  }

  List<IconButton> _selectActions() {
    final setServices = GymSetServices(context: context);
    final sets = setServices.getAllGymSets();
    List<IconButton> buttons = [];
    if (_selectedItems.isNotEmpty) {
      buttons.add(
        IconButton(
          onPressed: () {
            setState(() {
              if (_selectedItems.length == sets.length) {
                _selectedItems.clear();
              } else {
                _selectedItems.addAll(sets);
              }
            });
          },
          icon: Icon(_selectedItems.length == sets.length ? Icons.deselect : Icons.select_all),
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
            await setServices.deleteMultipleGymSetssByIds(_selectedItems.map((i) => i.id!).toList());
            setState(() => _selectedItems.clear());
          },
          icon: const Icon(Icons.delete),
        ),
      ]);
    }
    setState(() {});
    return buttons;
  }
}

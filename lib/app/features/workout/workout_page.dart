import 'package:flutter/material.dart';
import 'package:fossfit/app/features/workout/widgets/workout_grouped.dart';
import 'package:fossfit/app/features/workout/widgets/workout_list.dart';
import 'package:fossfit/app/services/features/gym_set_services.dart';
import 'package:fossfit/app/shell/app_shell.dart';
import 'package:fossfit/app/utils/constants.dart';
import 'package:fossfit/app/utils/utils.dart';
import 'package:fossfit/app/widgets/animated_fab.dart';
import 'package:fossfit/app/widgets/confirmation_dialog.dart';
import 'package:fossfit/app/widgets/countdown_timer.dart';
import 'package:fossfit/db/models/features/gymset_model.dart';
import 'package:fossfit/db/repositories/config_reposity.dart';
import 'package:fossfit/db/repositories/exercise_repository.dart';
import 'package:fossfit/db/repositories/gym_set_repository.dart';
import 'package:provider/provider.dart';

class WorkoutPage extends StatefulWidget {
  const WorkoutPage({super.key});

  @override
  State<StatefulWidget> createState() => _WorkoutPageState();
}

class _WorkoutPageState extends State<WorkoutPage> {
  List<GymSet>? _lastWorkoutSets;

  final expand = ExpansibleController();
  final scroll = ScrollController();
  final Set<GymSet> _selectedItems = {};

  bool get selectionMode => _selectedItems.isNotEmpty;

  @override
  void initState() {
    super.initState();
    expand.expand();
  }

  @override
  void dispose() {
    expand.dispose();
    scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timer = context.watch<CountdownTimerController>();
    context.watch<ExercisesRepository>();
    final lastWorkoutSets = _lastWorkoutSets ?? context.watch<GymSetRepository>().latestgymsets;

    return Selector<ConfigRepository, _Settings>(
      selector: (_, repo) => _Settings(
        showStats: repo.isEnabled(.workouts, 'show_stats'),
        groupHistory: repo.isEnabled(.workouts, 'group_history'),
        showTimer: repo.isEnabled(.timers, 'enabled'),
        autoStartTimer: repo.isEnabled(.timers, 'auto_start'),
      ),
      builder: (context, settings, _) {
        final lastWorkout = settings.showStats ? GymSetServices(context: context).getLastGymSetWorkout(lastWorkoutSets) : const SizedBox.shrink();

        return AppShell(
          title: selectionMode ? '${_selectedItems.length} selected' : 'Workout',
          selectActions: _selectActions(),
          showTimer: settings.showTimer,
          body: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: Column(
              children: [
                if (lastWorkoutSets.isEmpty)
                  ListTile(title: Text(emptyPhrases.randomItem), subtitle: const Text('Complete some sets to see them here')),

                if (lastWorkoutSets.isNotEmpty && settings.showStats)
                  Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: ExpansionTile(
                        childrenPadding: EdgeInsets.zero,
                        iconColor: Theme.of(context).colorScheme.onSurface,
                        leading: Icon(
                          expand.isExpanded ? Icons.analytics_outlined : Icons.view_timeline_rounded,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        title: Text(expand.isExpanded ? 'Stats' : 'Exercises'),
                        initiallyExpanded: true,
                        controller: expand,
                        children: [lastWorkout],
                        onExpansionChanged: (_) {
                          setState(() {});
                        },
                      ),
                    ),
                  ),

                Expanded(
                  child: settings.groupHistory
                      ? WorkoutGrouped(
                          sets: lastWorkoutSets,
                          selectedItems: _selectedItems,
                          selectionMode: selectionMode,
                          toggleSelection: _toggleSelection,
                          editSet: _editSet,
                          scroll: scroll,
                        )
                      : WorkoutList(
                          sets: lastWorkoutSets,
                          selectedItems: _selectedItems,
                          selectionMode: selectionMode,
                          toggleSelection: _toggleSelection,
                          editSet: _editSet,
                          scroll: scroll,
                        ),
                ),
              ],
            ),
          ),
          floatingActionButton: AnimatedFab(
            onPressed: () async {
              final services = GymSetServices(context: context);

              await services.openAddEditPage(context, null);

              if (settings.autoStartTimer && mounted) {
                timer.start();
              }
            },
            label: const Text('Add'),
            icon: const Icon(Icons.add),
            scroll: scroll,
          ),
        );
      },
    );
  }

  Future<void> _editSet(GymSet gymSet) async {
    final services = GymSetServices(context: context);

    await services.openAddEditPage(context, gymSet.id);

    if (!mounted) return;

    setState(() {
      _lastWorkoutSets = context.read<GymSetRepository>().latestgymsets;
    });
  }

  void _toggleSelection(GymSet set) {
    setState(() {
      if (_selectedItems.contains(set)) {
        _selectedItems.remove(set);
      } else {
        _selectedItems.add(set);
      }
    });
  }

  List<IconButton> _selectActions() {
    final setServices = GymSetServices(context: context);
    final sets = setServices.getAllGymSets();

    final List<IconButton> buttons = [];

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

      buttons.add(
        IconButton(
          onPressed: () async {
            final confirmed = await showConfirmationDialog(context: context, title: 'Delete?', content: 'Are you sure?', barrierDismissible: true);

            if (!mounted || confirmed != true) return;

            await setServices.deleteMultipleGymSetssByIds(_selectedItems.map((i) => i.id!).toList());

            if (!mounted) return;

            setState(() {
              _selectedItems.clear();
            });
          },
          icon: const Icon(Icons.delete),
        ),
      );
    }

    return buttons;
  }
}

class _Settings {
  final bool showStats;
  final bool showTimer;
  final bool groupHistory;
  final bool autoStartTimer;

  const _Settings({required this.showStats, required this.showTimer, required this.groupHistory, required this.autoStartTimer});

  @override
  bool operator ==(Object other) {
    return other is _Settings &&
        other.showStats == showStats &&
        other.showTimer == showTimer &&
        other.groupHistory == groupHistory &&
        other.autoStartTimer == autoStartTimer;
  }

  @override
  int get hashCode => Object.hash(showStats, showTimer, groupHistory, autoStartTimer);
}

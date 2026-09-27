import 'package:flutter/material.dart';
import 'package:fossfit/app/app_shell.dart';
import 'package:fossfit/db/repositories/gym_sets_repository.dart';
import 'package:fossfit/db/repositories/settings_repository.dart';
import 'package:fossfit/features/workouts/workout_grouped.dart';
import 'package:fossfit/features/workouts/workout_list.dart';
import 'package:fossfit/models/gym_set_model.dart';
import 'package:fossfit/services/gym_sets_services.dart';
import 'package:fossfit/widgets/animated_fab.dart';
import 'package:fossfit/widgets/app_search.dart';
import 'package:provider/provider.dart';

class WorkoutPage extends StatefulWidget {
  const WorkoutPage({
    super.key,
  });

  @override
  State<WorkoutPage> createState() => _WorkoutPageState();
}

class _WorkoutPageState extends State<WorkoutPage> {
  Widget lastWorkout = const SizedBox.shrink();
  final expand = ExpansibleController();
  final scroll = ScrollController();
  final Set<int> selectedSets = {};
  @override
  Widget build(BuildContext context) {
    final settingsRepo = context.watch<SettingsRepository>();
    final setsRepo = context.watch<GymSetsRepository>();

    final showStats = settingsRepo.isEnabled(
      key: 'stats_panel',
    );
    if (showStats) getStats(setsRepo.latestgymsets);
    final groupHistory = settingsRepo.isEnabled(
      key: 'group_history',
    );

    return AppShell(
      appBar: buildAppBar(),
      floatingActionButton: AnimatedFab(
        onPressed: () {}, //TODO MAKE ON ADD
        label: const Text('Add'),
        icon: const Icon(Icons.add),
        scroll: scroll,
      ),
      body: Column(
        children: [
          if (setsRepo.latestgymsets.isEmpty)
            const ListTile(
              title: Text('No entries yet'),
              subtitle: Text(
                'Complete some sets to see them here',
              ),
            ),
          if (setsRepo.latestgymsets.isNotEmpty && showStats)
            Theme(
              data: Theme.of(context).copyWith(
                dividerColor: Colors.transparent,
              ),
              child: Padding(
                padding: const EdgeInsets.only(
                  top: 8,
                ),
                child: ExpansionTile(
                  childrenPadding: EdgeInsets.zero,
                  iconColor: Theme.of(context).colorScheme.onSurface,
                  leading: Icon(
                    expand.isExpanded ? Icons.analytics_outlined : Icons.fitness_center_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(
                    expand.isExpanded ? 'Stats' : 'Exercises',
                  ),
                  initiallyExpanded: true,
                  controller: expand,
                  children: [
                    lastWorkout,
                  ],
                ),
              ),
            ),
          Expanded(
            child: groupHistory ? WorkoutGrouped(sets: setsRepo.latestgymsets) : WorkoutList(sets: setsRepo.latestgymsets),
          ),
        ],
      ),
    );
  }

  AppSearch buildAppBar() {
    return AppSearch(
      selected: selectedSets,
      filter: null, //TODO FIX FILTER
      onSearchChange: (value) {},
      onClear: () {
        setState(() {
          selectedSets.clear();
        });
      },
      onDelete: () async {
        //TODO DELETE SETS
        setState(() {
          selectedSets.clear();
        });
      },
      onSelect: () {
        //TODO ON SELECT ITEM

        setState(() {
          selectedSets.addAll([]);
        });
      },
      onEdit: (gymSet) async {
        //TODO ON EDIT ITEM
      },
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
}

import 'package:flutter/material.dart';
import 'package:fossfit/app/features/workout/widgets/workout_grouped.dart';
import 'package:fossfit/app/features/workout/widgets/workout_list.dart';
import 'package:fossfit/app/services/features/gymset_services.dart';
import 'package:fossfit/app/shell/app_shell.dart';
import 'package:fossfit/app/widgets/fanimated_fab.dart';
import 'package:fossfit/db/models/features/gymset_model.dart';
import 'package:fossfit/db/repositories/config_reposity.dart';
import 'package:fossfit/db/repositories/gymsets_repository.dart';
import 'package:provider/provider.dart';

class WorkoutPage extends StatefulWidget {
  const WorkoutPage({super.key});

  @override
  State<StatefulWidget> createState() => _WorkoutPageState();
}

class _WorkoutPageState extends State<WorkoutPage> {
  late List<GymSet> _lastWorkoutSets;
  Widget lastWorkout = const SizedBox.shrink();
  final expand = ExpansibleController();
  final scroll = ScrollController();
  final Set<int> selectedSets = {};

  late ConfigRepository config;
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    config = context.watch<ConfigRepository>();
    _lastWorkoutSets = context.watch<GymSetsRepository>().latestgymsets;

    var showStats = config.isEnabled(.workouts, 'show_stats');
    if (showStats) getStats(_lastWorkoutSets);
    var grouped = config.isEnabled(.workouts, 'group_history');
    return AppShell(
      title: 'Workout',
      body: Column(
        children: [
          if (_lastWorkoutSets.isEmpty)
            const ListTile(title: Text('No entries yet'), subtitle: Text('Complete some sets to see them here')),
          if (_lastWorkoutSets.isNotEmpty && showStats)
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
                ),
              ),
            ),
          Expanded(
            child: grouped ? WorkoutGrouped(sets: _lastWorkoutSets) : WorkoutList(sets: _lastWorkoutSets),
          ),
        ],
      ),
      floatingActionButton: AnimatedFab(
        onPressed: () {},
        label: const Text('Add'),
        icon: const Icon(Icons.add),
        scroll: scroll,
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
}

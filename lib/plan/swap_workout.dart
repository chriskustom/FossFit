import 'package:flutter/material.dart';
import 'package:fossfit/db/repositories/exercise_repository.dart';
import 'package:fossfit/db/repositories/plan_exercises_repository.dart';
import 'package:fossfit/db/repositories/plans_repository.dart';
import 'package:fossfit/models/exercise_model.dart';
import 'package:provider/provider.dart';

class SwapWorkout extends StatefulWidget {
  final Exercise exercise;
  final int planId;

  const SwapWorkout({super.key, required this.exercise, required this.planId});

  @override
  State<SwapWorkout> createState() => _SwapWorkoutState();
}

class _SwapWorkoutState extends State<SwapWorkout> {
  late List<Exercise> _distinctExercises;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final peRepo = context.watch<PlanExercisesRepository>();
    final planRepo = context.watch<PlansRepository>();
    _distinctExercises = context.watch<ExercisesRepository>().exercises;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Swap workout'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search Exercises',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: Builder(
              builder: (context) {
                if (_distinctExercises.isEmpty) {
                  return const SizedBox();
                }

                final exercises = _distinctExercises
                    .where(
                      (exercise) => exercise.name
                          .toLowerCase()
                          .contains(_searchQuery.toLowerCase()),
                    )
                    .toList();

                return ListView.builder(
                  itemCount: exercises.length,
                  itemBuilder: (context, index) {
                    final exercise = exercises[index];
                    return ListTile(
                      title: Text(exercise.name),
                      onTap: () async {
                        final old = peRepo
                            .getPlanExercisesByPlanId(widget.planId)
                            .where((t) => t.exercise!.id == exercise.id!)
                            .first;
                        await peRepo.updatePlanExercise(
                            old.copyWith(exerciseId: exercise.id));

                        if (!context.mounted) return;

                        planRepo.updatePlans(null);
                        Navigator.pop(context, true);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

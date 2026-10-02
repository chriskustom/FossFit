import 'package:flutter/material.dart';
import 'package:fossfit/db/models/features/exercise_model.dart';
import 'package:fossfit/db/repositories/exercise_repository.dart';
import 'package:provider/provider.dart';

class SwapPlanExercise extends StatefulWidget {
  final int exerciseId;
  final int planId;

  const SwapPlanExercise({super.key, required this.exerciseId, required this.planId});

  @override
  State<SwapPlanExercise> createState() => _SwapPlanExerciseState();
}

class _SwapPlanExerciseState extends State<SwapPlanExercise> {
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
    _distinctExercises = context.watch<ExercisesRepository>().strengthExercises;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: const Text('Swap workout')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(labelText: 'Search Exercises', border: OutlineInputBorder(), prefixIcon: Icon(Icons.search)),
            ),
          ),
          Expanded(
            child: Builder(
              builder: (context) {
                if (_distinctExercises.isEmpty) {
                  return const SizedBox();
                }

                final exercises = _distinctExercises.where((exercise) => exercise.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

                return ListView.builder(
                  itemCount: exercises.length,
                  itemBuilder: (context, index) {
                    final exercise = exercises[index];
                    return ListTile(
                      title: Text(exercise.name),
                      onTap: () async {
                        Navigator.pop(context, exercise.id);
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

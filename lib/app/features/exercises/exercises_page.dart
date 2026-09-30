import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:fossfit/app/shell/app_shell.dart';
import 'package:fossfit/app/widgets/app_snack_bar.dart';
import 'package:fossfit/app/widgets/exercise_icon.dart';
import 'package:fossfit/app/widgets/fanimated_fab.dart';
import 'package:fossfit/db/models/features/exercise_model.dart';
import 'package:fossfit/db/repositories/config_reposity.dart';
import 'package:fossfit/db/repositories/exercise_repository.dart';
import 'package:fossfit/db/repositories/gym_set_repository.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

class ExercisesPage extends StatefulWidget {
  const ExercisesPage({super.key});

  @override
  State<StatefulWidget> createState() => _ExercisesPageState();
}

class _ExercisesPageState extends State<ExercisesPage> {
  late ConfigRepository config;
  List<Exercise> exercises = [];
  final ScrollController _scrollController = ScrollController();
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    config = context.watch<ConfigRepository>();
    var exRepo = context.watch<ExercisesRepository>();
    var gymSetRepo = context.watch<GymSetRepository>();
    exercises = exRepo.exercises;
    var showImages = config.isEnabled(.workouts, 'show_images');
    final dateFormat = config.getSetting(.formats, 'long_date_format');

    return AppShell(
      title: 'Exercises',
      body: Padding(
        padding: EdgeInsets.all(8),
        child: ListView.builder(
          controller: _scrollController,
          itemCount: exercises.length,
          itemBuilder: (context, index) {
            var exercise = exercises[index];
            var lastSet = gymSetRepo.gymsets.where((g) => g.exerciseId == exercise.id).toList();
            lastSet.sorted((a, b) => b.created.compareTo(a.created));
            var subtitle = lastSet.isEmpty
                ? Text('Never completed')
                : Text(dateFormat == 'timeago' ? timeago.format(lastSet.first.created) : DateFormat(dateFormat).format(lastSet.first.created));
            return ListTile(
              key: Key('${exercise.id}-${exercise.name}'),
              leading: ExerciseIcon(exercise: exercise, showImages: showImages),
              title: Text(exercise.name),
              subtitle: subtitle,
            );
          },
        ),
      ),
      floatingActionButton: AnimatedFab(
        onPressed: () {
          /*TODO ADD EXERCISE */
          AppSnackBar.info('Add Exercise');
        },
        label: const Text('Add'),
        icon: const Icon(Icons.add),
        scroll: _scrollController,
      ),
    );
  }
}

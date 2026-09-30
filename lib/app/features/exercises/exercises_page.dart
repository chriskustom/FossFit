import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:fossfit/app/services/features/exercise_services.dart';
import 'package:fossfit/app/shell/app_shell.dart';
import 'package:fossfit/app/utils/constants.dart';
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

  String search = '';
  final searchCtrl = TextEditingController();
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
    final matching = exercises.where((exercise) {
      if (search.isNotEmpty && !exercise.name.toLowerCase().contains(search)) {
        return false;
      }

      return true;
    }).toList();
    var showImages = config.isEnabled(.workouts, 'show_images');
    final dateFormat = config.getSetting(.formats, 'long_date_format');
    return AppShell(
      showSearch: false,
      title: 'Exercises',
      body: Padding(
        padding: EdgeInsets.all(8),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SearchBar(
                leading: const Padding(padding: EdgeInsets.all(8.0), child: Icon(Icons.search)),
                textCapitalization: TextCapitalization.sentences,
                hintText: 'Search exercises...',
                controller: searchCtrl,
                onChanged: (value) {
                  setState(() {
                    search = value;
                  });
                },
              ),
            ),

            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemCount: matching.length,
                itemBuilder: (context, index) {
                  var exercise = matching[index];
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
                    onTap: () async {
                      var exServices = ExerciseServices(context: context);
                      var data = await gymSetRepo.getStrengthData(
                        target: lastSet.first.unit ?? exercise.defaultUnit ?? 'kg',
                        exerciseId: exercise.id!,
                        metric: StrengthMetric.bestWeight,
                        period: Period.day,
                        start: null,
                        end: null,
                        limit: 20,
                      );
                      if (!context.mounted) return;

                      await exServices.openExercisePage(context, exercise.id!, data);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: AnimatedFab(
        onPressed: () async {
          var services = ExerciseServices(context: context);
          await services.openAddEditExercisePage(context, null, null);
        },
        label: const Text('Add'),
        icon: const Icon(Icons.add),
        scroll: _scrollController,
      ),
    );
  }
}

import 'package:flutter/material.dart' as material;
import 'package:flutter/material.dart';
import 'package:fossfit/animated_fab.dart';
import 'package:fossfit/constants.dart';
import 'package:fossfit/day_selector.dart';
import 'package:fossfit/db/repositories/exercise_repository.dart';
import 'package:fossfit/db/repositories/plan_exercises_repository.dart';
import 'package:fossfit/db/repositories/plans_repository.dart';
import 'package:fossfit/graph/add_exercise_page.dart';
import 'package:fossfit/models/exercise_model.dart';
import 'package:fossfit/models/plan_exercise_model.dart';
import 'package:fossfit/models/plan_model.dart';
import 'package:fossfit/plan/exercise_tile.dart';
import 'package:fossfit/utils.dart';
import 'package:provider/provider.dart';

class EditPlanPage extends StatefulWidget {
  final Plan plan;

  const EditPlanPage({
    required this.plan,
    super.key,
  });

  @override
  State<EditPlanPage> createState() => _EditPlanPageState();
}

class _EditPlanPageState extends State<EditPlanPage> {
  late List<bool> days;

  final Map<int, PlanExercise> _planExercises = {};

  bool showOff = true;
  String search = '';

  final node = FocusNode();
  final searchCtrl = TextEditingController();
  final titleCtrl = TextEditingController();

  bool _loadingExercises = true;

  @override
  void initState() {
    super.initState();

    titleCtrl.text = widget.plan.title ?? '';

    final list = widget.plan.days.split(',');

    days = weekdays
        .map(
          (day) => list.contains(day),
        )
        .toList();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPlanExercises();
    });
  }

  Future<void> _loadPlanExercises() async {
    if (!mounted) return;

    final exerciseRepo = context.read<ExercisesRepository>();

    final planExerciseRepo = context.read<PlanExercisesRepository>();

    // Make absolutely sure the repository has current
    // data before we initialize the editor.
    await planExerciseRepo.loadAll();

    if (!mounted) return;

    final allExercises = exerciseRepo.exercises;

    _planExercises.clear();

    for (final pe in planExerciseRepo.getPlanExercisesByPlanId(
      widget.plan.id ?? -1,
    )) {
      final exercise = allExercises
          .where(
            (e) => e.id == pe.exerciseId,
          )
          .firstOrNull;

      if (exercise == null) continue;

      _planExercises[exercise.id!] = pe.copyWith(
        exercise: exercise,
      );
    }

    setState(() {
      _loadingExercises = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final exerciseRepo = context.watch<ExercisesRepository>();

    final tiles = _loadingExercises ? <Widget>[] : _buildTiles(exerciseRepo.exercises);

    var title = widget.plan.days.replaceAll(',', ', ');

    if (title.isNotEmpty) {
      title = title[0].toUpperCase() + title.substring(1).toLowerCase();
    } else {
      title = 'Add plan';
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(title),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16.0,
        ),
        child: ListView(
          children: [
            TextField(
              decoration: const material.InputDecoration(
                labelText: 'Title (optional)',
              ),
              controller: titleCtrl,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16.0),
            DaySelector(
              daySwitches: days,
            ),
            const SizedBox(height: 8),
            material.Padding(
              padding: const EdgeInsets.all(8.0),
              child: SearchBar(
                leading: const material.Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(Icons.search),
                ),
                textCapitalization: TextCapitalization.sentences,
                hintText: 'Search exercises...',
                controller: searchCtrl,
                trailing: [
                  IconButton(
                    icon: showOff
                        ? const Icon(
                            Icons.visibility,
                          )
                        : const Icon(
                            Icons.visibility_off,
                          ),
                    onPressed: () {
                      setState(() {
                        showOff = !showOff;
                      });
                    },
                    tooltip: 'Toggle visibility',
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    search = value;
                  });
                },
              ),
            ),
            const SizedBox(height: 8),
            if (_loadingExercises)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (tiles.isEmpty)
              _buildNothingFound()
            else
              ...tiles,
            const SizedBox(height: 176),
          ],
        ),
      ),
      floatingActionButton: AnimatedFab(
        onPressed: save,
        label: const Text('Save'),
        icon: const Icon(Icons.save),
      ),
    );
  }

  List<Widget> _buildTiles(
    List<Exercise> allExercises,
  ) {
    final query = search.trim().toLowerCase();

    final matching = allExercises.where(
      (exercise) {
        if (query.isNotEmpty && !exercise.name.toLowerCase().contains(query)) {
          return false;
        }

        return true;
      },
    ).toList();

    matching.sort((a, b) {
      final aSelected = _planExercises[a.id]?.enabled == true;

      final bSelected = _planExercises[b.id]?.enabled == true;

      if (aSelected && !bSelected) return -1;
      if (!aSelected && bSelected) return 1;

      return 0;
    });

    final result = <Widget>[];

    for (final exercise in matching) {
      final id = exercise.id;

      if (id == null) continue;

      var planExercise = _planExercises[id];

      planExercise ??= PlanExercise(
        enabled: false,
        timers: true,
        maxSets: 3,
        warmupSets: null,
        exerciseId: id,
        exercise: exercise,
      );

      planExercise = planExercise.copyWith(
        exercise: exercise,
      );

      _planExercises[id] = planExercise;

      result.add(
        ExerciseTile(
          key: ValueKey(id),
          planExercise: planExercise,
          onChange: (value) {
            final exerciseId = value.exerciseId;

            setState(() {
              _planExercises[exerciseId] = value.copyWith(
                exercise: exercise,
              );
            });
          },
        ),
      );
    }

    return result;
  }

  Widget _buildNothingFound() {
    if (search.trim().isEmpty) {
      return const ListTile(
        title: Text('Nothing found'),
      );
    }

    return ListTile(
      title: const Text('Nothing found'),
      subtitle: Text(
        'Tap to create $search',
      ),
      onTap: () async {
        final exercise = await Navigator.of(context).push<Exercise>(
          material.MaterialPageRoute(
            builder: (context) => AddExercisePage(
              name: search.trim(),
            ),
          ),
        );

        if (exercise == null || !mounted) {
          return;
        }

        setState(() {
          _planExercises[exercise.id!] = PlanExercise(
            enabled: true,
            timers: true,
            maxSets: 3,
            warmupSets: null,
            exerciseId: exercise.id!,
            exercise: exercise,
          );

          search = '';
          searchCtrl.clear();
        });
      },
    );
  }

  @override
  void dispose() {
    node.dispose();
    searchCtrl.dispose();
    titleCtrl.dispose();
    super.dispose();
  }

  Future<void> save() async {
    final selected = <String>[];

    for (int i = 0; i < days.length; i++) {
      if (days[i]) {
        selected.add(weekdays[i]);
      }
    }

    if (selected.isEmpty && titleCtrl.text.isEmpty) {
      return toast('Select days');
    }

    final enabledExercises = _planExercises.values
        .where(
          (exercise) => exercise.enabled,
        )
        .toList();

    if (enabledExercises.isEmpty) {
      return toast(
        'Select exercises',
      );
    }

    final planRepo = context.read<PlansRepository>();

    final peRepo = context.read<PlanExercisesRepository>();

    if (widget.plan.id != null) {
      final oldPlan = planRepo.getPlanById(
        widget.plan.id!,
      );

      if (oldPlan == null) {
        return;
      }

      final newPlan = oldPlan.copyWith(
        days: selected.join(','),
        title: titleCtrl.text,
      );

      await planRepo.updatePlan(
        newPlan,
      );

      await peRepo.deleteAllExerciseForPlanById(
        oldPlan.id!,
      );

      for (var i = 0; i < enabledExercises.length; i++) {
        final exercise = enabledExercises[i];

        final newPe = PlanExercise(
          enabled: true,
          timers: exercise.timers,
          exercise: exercise.exercise,
          planId: oldPlan.id!,
          sequence: i,
          maxSets: exercise.maxSets,
          warmupSets: exercise.warmupSets,
          exerciseId: exercise.exerciseId,
        );

        await peRepo.addPlanExercises(
          newPe,
        );
      }
    } else {
      final newPlan = await planRepo.addPlan(
        Plan(
          days: selected.join(','),
          title: titleCtrl.text,
        ),
      );

      for (var i = 0; i < enabledExercises.length; i++) {
        final exercise = enabledExercises[i];

        final newPe = PlanExercise(
          enabled: true,
          timers: exercise.timers,
          exercise: exercise.exercise,
          planId: newPlan.id!,
          sequence: i,
          maxSets: exercise.maxSets,
          warmupSets: exercise.warmupSets,
          exerciseId: exercise.exerciseId,
        );

        await peRepo.addPlanExercises(
          newPe,
        );
      }
    }

    // Rebuild both repositories from the database so
    // PlansRepository contains the exact same Plan
    // structure that StartPlanPage will read.
    await peRepo.loadAll();
    await planRepo.updatePlans(null);
    await planRepo.updatePlanCounts();

    if (!mounted) return;

    Navigator.pop(context);
  }
}

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart' as material;
import 'package:flutter/material.dart';
import 'package:fossfit/animated_fab.dart';
import 'package:fossfit/constants.dart';
import 'package:fossfit/day_selector.dart';
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

  const EditPlanPage({required this.plan, super.key});

  @override
  createState() => _EditPlanPageState();
}

class _EditPlanPageState extends State<EditPlanPage> {
  late List<bool> days;
  List<PlanExercise> exercises = [];

  bool showOff = true;
  String search = '';

  final node = FocusNode();
  final searchCtrl = TextEditingController();
  final titleCtrl = TextEditingController();

  Iterable<Widget> get tiles {
    final match = exercises.where(
      (pe) {
        if (showOff)
          return pe.exercise!.name.toLowerCase().contains(search.toLowerCase());
        if (pe.enabled)
          return pe.exercise!.name.toLowerCase().contains(search.toLowerCase());
        return false;
      },
    );

    if (match.isEmpty)
      return [
        ListTile(
          title: const Text("Nothing found"),
          subtitle: Text("Tap to create $search"),
          onTap: () async {
            Exercise? exercise = await Navigator.of(context).push(
              material.MaterialPageRoute(
                builder: (context) => AddExercisePage(
                  name: search,
                ),
              ),
            );
            if (exercise == null || !mounted) return;

            final repo = context.read<PlanExercisesRepository>();

            await repo.addPlanExercises(
              PlanExercise(
                timers: true,
                enabled: true,
                maxSets: 3,
                exerciseId: exercise.id!,
              ),
            );
            setState(() {
              exercises = exercises;
              search = '';
            });
            searchCtrl.text = '';
          },
        ),
      ];

    return match.toList().map(
          (pe) => ExerciseTile(
            planExercise: pe,
            onChange: (value) {
              final id = exercises
                  .indexWhere((exercise) => exercise.exercise == pe.exercise);
              if (id == -1) return;
              setState(() {
                exercises[id] = value;
              });
            },
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    exercises = context.watch<PlanExercisesRepository>().planexercises;

    var title = widget.plan.days.replaceAll(",", ", ");
    if (title.isNotEmpty)
      title = title[0].toUpperCase() + title.substring(1).toLowerCase();
    else
      title = "Add plan";

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(title),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: ListView(
          children: [
            TextField(
              decoration: const material.InputDecoration(
                labelText: 'Title (optional)',
              ),
              controller: titleCtrl,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(
              height: 16.0,
            ),
            DaySelector(daySwitches: days),
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
                trailing: [
                  IconButton(
                    icon: showOff
                        ? const Icon(Icons.visibility)
                        : const Icon(Icons.visibility_off),
                    onPressed: () {
                      setState(() {
                        showOff = !showOff;
                      });
                    },
                    tooltip: 'Toggle visibility',
                  ),
                ],
                onChanged: (value) => setState(() {
                  search = value;
                }),
              ),
            ),
            const SizedBox(height: 8),
            ...List.generate(tiles.length, (index) => tiles.elementAt(index)),
            const SizedBox(height: 176),
          ],
        ),
      ),
      floatingActionButton: AnimatedFab(
        onPressed: save,
        label: const Text("Save"),
        icon: const Icon(Icons.save),
      ),
    );
  }

  @override
  void dispose() {
    node.dispose();
    searchCtrl.dispose();
    titleCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    titleCtrl.text = widget.plan.title ?? "";
    final list = widget.plan.days.split(',');
    days = weekdays.map((day) => list.contains(day)).toList();
  }

  Future<void> save() async {
    final selected = [];
    for (int i = 0; i < days.length; i++)
      if (days[i]) selected.add(weekdays[i]);

    if (selected.isEmpty && titleCtrl.text.isEmpty) return toast('Select days');

    if (exercises.where((exercise) => exercise.enabled).isEmpty)
      return toast('Select exercises');
    var planRepo = context.read<PlansRepository>();
    var peRepo = context.read<PlanExercisesRepository>();

    //Update
    if (widget.plan.id != null) {
      var oldPlan = planRepo.getPlanById(widget.plan.id!);

      var newPlan = oldPlan!.copyWith(
        days: selected.join(','),
        title: titleCtrl.text,
      );
      await planRepo.updatePlan(newPlan);
      await peRepo.deleteAllExerciseForPlanById(oldPlan.id!);
      for (final e in exercises) {
        var newPe = PlanExercise(
          enabled: e.enabled,
          timers: e.timers,
          exercise: e.exercise,
          id: e.id!,
          planId: e.planId!,
          sequence: e.sequence!,
          maxSets: e.maxSets,
          exerciseId: e.exerciseId,
        );
        await peRepo.addPlanExercises(newPe);
      }
      //INSERT
    } else {
      final newPlan = await planRepo.addPlan(
        Plan(
          days: selected.join(','),
          title: titleCtrl.text,
        ),
      );
      for (final e in exercises) {
        var newPe = PlanExercise(
          enabled: e.enabled,
          timers: e.timers,
          exercise: e.exercise,
          id: e.id!,
          planId: newPlan.id!,
          sequence: e.sequence!,
          maxSets: e.maxSets,
          exerciseId: e.exerciseId,
        );
        await peRepo.addPlanExercises(newPe);
      }
    }

    if (!mounted) return;
    final state = context.read<PlansRepository>();
    state.updatePlans(null);
    Navigator.pop(context);
  }
}

import 'package:flutter/material.dart';
import 'package:fossfit/app/services/features/exercise_services.dart';
import 'package:fossfit/app/shell/app_shell.dart';
import 'package:fossfit/app/utils/constants.dart';
import 'package:fossfit/app/widgets/app_snack_bar.dart';
import 'package:fossfit/app/widgets/day_selector.dart';
import 'package:fossfit/app/widgets/exercise_icon.dart';
import 'package:fossfit/app/widgets/fanimated_fab.dart';
import 'package:fossfit/db/models/features/exercise_model.dart';
import 'package:fossfit/db/models/features/plan_exercise_model.dart';
import 'package:fossfit/db/models/features/plan_model.dart';
import 'package:fossfit/db/repositories/exercise_repository.dart';
import 'package:fossfit/db/repositories/plan_exercises_repository.dart';
import 'package:fossfit/db/repositories/plan_repository.dart';
import 'package:provider/provider.dart';

class AddEditPlanPage extends StatefulWidget {
  final int? planId;
  const AddEditPlanPage({super.key, required this.planId});

  @override
  State<AddEditPlanPage> createState() => _AddEditPlanPageState();
}

class _AddEditPlanPageState extends State<AddEditPlanPage> {
  Plan? _plan;

  final node = FocusNode();
  final searchCtrl = TextEditingController();
  final titleCtrl = TextEditingController();
  List<bool>? _days;
  bool isEditMode = false;
  String search = '';

  List<Exercise>? _planExercises;
  @override
  void initState() {
    super.initState();
    isEditMode = widget.planId != null;
    if (isEditMode) {
      currentPlanId.value = widget.planId;
    }
  }

  @override
  void dispose() {
    node.dispose();
    searchCtrl.dispose();
    titleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final planRepo = context.watch<PlansRepository>();
    final exerciseRepo = context.watch<ExercisesRepository>();
    final planExerciseRepo = context.read<PlanExercisesRepository>();
    var plan = _plan ?? planRepo.getPlanById(widget.planId ?? 0);
    final list = plan?.days.split(',') ?? [];
    _days = _days ?? weekdays.map((day) => list.contains(day)).toList();
    _planExercises =
        _planExercises ??
        exerciseRepo.exercises
            .where((e) => planExerciseRepo.getPlanExercisesByPlanId(plan?.id ?? 0).map((pe) => pe.exerciseId).contains(e.id))
            .toList();
    final tiles = _buildTiles(exerciseRepo.exercises, _planExercises!);
    titleCtrl.text = isEditMode ? plan!.name : 'Add plan';
    return AppShell(
      showNavBar: false,
      showSearch: false,
      title: titleCtrl.text,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: ListView(
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Title (optional)'),
              controller: titleCtrl,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16.0),
            DaySelector(daySwitches: _days ?? []),
            const SizedBox(height: 8),
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
            const SizedBox(height: 8),
            if (tiles.isEmpty) _buildNothingFound() else ...tiles,
            const SizedBox(height: 176),
          ],
        ),
      ),
      floatingActionButton: AnimatedFab(
        onPressed: () async {
          await save();
        },
        label: const Text('Save'),
        icon: const Icon(Icons.save),
      ),
    );
  }

  List<Widget> _buildTiles(List<Exercise> allExercises, List<Exercise> planExercises) {
    final query = search.trim().toLowerCase();

    final matching = allExercises.where((exercise) {
      if (query.isNotEmpty && !exercise.name.toLowerCase().contains(query)) {
        return false;
      }

      return true;
    }).toList();
    matching.sort((a, b) {
      final aIndex = planExercises.indexOf(a);
      final bIndex = planExercises.indexOf(b);

      final aSelected = aIndex != -1;
      final bSelected = bIndex != -1;

      // Both enabled: preserve the order they were added
      if (aSelected && bSelected) {
        return aIndex.compareTo(bIndex);
      }

      // Enabled exercises come before disabled
      if (aSelected) return -1;
      if (bSelected) return 1;

      // Both disabled: alphabetical
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    final result = <Widget>[];

    for (final exercise in matching) {
      final id = exercise.id;

      if (id == null) continue;

      result.add(
        ListTile(
          leading: ExerciseIcon(exercise: exercise),
          title: Text(exercise.name),
          trailing: Transform.scale(
            scale: switchScale,
            child: Switch.adaptive(
              value: planExercises.contains(exercise),
              onChanged: (on) {
                if (on) planExercises.add(exercise);
                if (!on) planExercises.removeAt(planExercises.indexOf(exercise));
                _planExercises = planExercises;
                setState(() {});
              },
            ),
          ),
        ),
      );
    }

    return result;
  }

  Widget _buildNothingFound() {
    if (search.trim().isEmpty) {
      return const ListTile(title: Text('Nothing found'));
    }

    return ListTile(
      title: const Text('Nothing found'),
      subtitle: Text('Tap to create $search'),
      onTap: () async {
        var services = ExerciseServices(context: context);
        await services.openAddEditExercisePage(context, null, search);
      },
    );
  }

  Future<void> save() async {
    final selectedDays = <String>[];

    for (int i = 0; i < _days!.length; i++) {
      if (_days![i]) {
        selectedDays.add(weekdays[i]);
      }
    }

    if (selectedDays.isEmpty && titleCtrl.text.isEmpty) {
      AppSnackBar.info('Please select days!');
      return;
    }

    if (_planExercises!.isEmpty) {
      AppSnackBar.info('Please select exercises');
      return;
    }

    final planRepo = context.read<PlansRepository>();

    final peRepo = context.read<PlanExercisesRepository>();

    if (isEditMode) {
      final oldPlan = planRepo.getPlanById(widget.planId!);

      if (oldPlan == null) {
        return;
      }

      await peRepo.deleteAllExerciseForPlanById(oldPlan.id!);

      for (var i = 0; i < _planExercises!.length; i++) {
        final exercise = _planExercises![i];
        final newPe = PlanExercise(
          planId: oldPlan.id!,
          sequence: i,
          maxSets: exercise.defaultSets,
          rest: exercise.defaultRest,
          exerciseId: exercise.id!,
        );
        await peRepo.insertPlanExercise(newPe);
      }
      final newPlan = oldPlan.copyWith(days: selectedDays.join(','), name: titleCtrl.text);
      await planRepo.updatePlan(newPlan);
    } else {
      final newPlan = await planRepo.insertPlan(
        Plan(days: selectedDays.join(','), name: titleCtrl.text.isEmpty ? selectedDays.join(', ') : titleCtrl.text),
      );

      for (var i = 0; i < _planExercises!.length; i++) {
        final exercise = _planExercises![i];

        final newPe = PlanExercise(
          planId: newPlan.id!,
          sequence: i,
          maxSets: exercise.defaultSets,
          rest: exercise.defaultRest,
          exerciseId: exercise.id!,
        );

        await peRepo.insertPlanExercise(newPe);
      }
    }
    peRepo.loadAll();
    if (!mounted) return;

    Navigator.pop(context);
  }
}

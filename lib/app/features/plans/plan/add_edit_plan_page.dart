import 'package:flutter/material.dart';
import 'package:fossfit/app/services/features/exercise_services.dart';
import 'package:fossfit/app/shell/app_shell.dart';
import 'package:fossfit/app/utils/constants.dart';
import 'package:fossfit/app/widgets/animated_fab.dart';
import 'package:fossfit/app/widgets/app_snack_bar.dart';
import 'package:fossfit/app/widgets/confirmation_dialog.dart';
import 'package:fossfit/app/widgets/day_selector.dart';
import 'package:fossfit/app/widgets/exercise_icon.dart';
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
  final scroll = ScrollController();

  List<bool>? _days;
  List<Exercise>? _planExercises;

  bool isEditMode = false;
  bool _planCreated = false;
  bool _saving = false;
  bool _isLeaving = false;

  String search = '';

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
    scroll.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final planRepo = context.watch<PlansRepository>();
    final exerciseRepo = context.watch<ExercisesRepository>();
    final planExerciseRepo = context.read<PlanExercisesRepository>();

    final plan = _plan ?? planRepo.getPlanById(widget.planId ?? 0);

    final days = plan?.days.split(',') ?? [];

    _days ??= weekdays.map((day) => days.contains(day)).toList();

    _planExercises ??= exerciseRepo.exercises
        .where((exercise) => planExerciseRepo.getPlanExercisesByPlanId(plan?.id ?? 0).map((pe) => pe.exerciseId).contains(exercise.id))
        .toList();

    if (isEditMode && plan != null) {
      if (titleCtrl.text != plan.name) {
        titleCtrl.text = plan.name;
      }
    }

    final tiles = _buildTiles(exerciseRepo.exercises, _planExercises!);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await planExerciseRepo.loadAll();
        await planRepo.loadAll();
        await _handleBack();
      },
      child: AppShell(
        showNavBar: false,
        showSearch: false,
        title: isEditMode ? titleCtrl.text : 'Add plan',
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: ListView(
            controller: scroll,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'Title (optional)'),
                controller: titleCtrl,
                textCapitalization: TextCapitalization.sentences,
              ),

              const SizedBox(height: 16),

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
        floatingActionButton: isEditMode
            ? null
            : AnimatedFab(
                onPressed: () async {
                  await save();
                },
                label: const Text('Save'),
                icon: const Icon(Icons.save),
                scroll: scroll,
              ),
      ),
    );
  }

  Set<int> _initialSelectedExerciseIds = {};

  List<Widget> _buildTiles(List<Exercise> allExercises, List<Exercise> planExercises) {
    final query = search.trim().toLowerCase();

    final matching = allExercises.where((exercise) {
      if (query.isNotEmpty && !exercise.name.toLowerCase().contains(query)) {
        return false;
      }

      return true;
    }).toList();

    if (_initialSelectedExerciseIds.isEmpty && planExercises.isNotEmpty) {
      _initialSelectedExerciseIds = planExercises.where((exercise) => exercise.id != null).map((exercise) => exercise.id!).toSet();
    }

    final initiallySelected = matching.where((exercise) {
      return _initialSelectedExerciseIds.contains(exercise.id) && planExercises.contains(exercise);
    }).toList();
    final remaining = matching.where((exercise) {
      return !(_initialSelectedExerciseIds.contains(exercise.id) && planExercises.contains(exercise));
    }).toList();

    remaining.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    final sortedExercises = [...initiallySelected, ...remaining];

    return sortedExercises.map((exercise) {
      final id = exercise.id;

      if (id == null) {
        return const SizedBox.shrink();
      }

      final selected = planExercises.contains(exercise);

      return ListTile(
        leading: ExerciseIcon(exercise: exercise),
        title: Text(exercise.name),
        trailing: Transform.scale(
          scale: switchScale,
          child: Switch.adaptive(
            value: selected,
            onChanged: (value) async {
              await _setExerciseSelected(exercise, value);
            },
          ),
        ),
        onTap: () async {
          await _setExerciseSelected(exercise, !selected);
        },
      );
    }).toList();
  }

  Future<void> _setExerciseSelected(Exercise exercise, bool selected) async {
    final exerciseId = exercise.id;

    if (exerciseId == null) {
      return;
    }

    final planExerciseRepo = context.read<PlanExercisesRepository>();

    final currentExercises = List<Exercise>.from(_planExercises ?? []);

    final alreadySelected = currentExercises.contains(exercise);

    if (selected == alreadySelected) {
      return;
    }

    final plan = await _ensurePlan();

    if (plan == null || plan.id == null) {
      AppSnackBar.info('Unable to create plan');
      return;
    }

    try {
      if (selected) {
        final existing = planExerciseRepo.getPlanExercisesByPlanId(plan.id!);
        final alreadyExists = existing.any((pe) => pe.exerciseId == exerciseId);

        if (!alreadyExists) {
          final sequence = existing.isEmpty ? 0 : existing.map((pe) => pe.sequence).reduce((a, b) => a > b ? a : b) + 1;

          final planExercise = PlanExercise(planId: plan.id!, sequence: sequence, maxSets: exercise.defaultSets, exerciseId: exerciseId);

          await planExerciseRepo.insertPlanExercise(planExercise);
        }

        currentExercises.add(exercise);
      } else {
        final existing = planExerciseRepo.getPlanExercisesByPlanId(plan.id!);

        final matching = existing.where((pe) => pe.exerciseId == exerciseId);

        for (final planExercise in matching) {
          if (planExercise.id != null) {
            await planExerciseRepo.deletePlanExerciseById(planExercise.id!);
          }
        }

        currentExercises.remove(exercise);

        await _resequencePlanExercises(plan.id!);
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _planExercises = currentExercises;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      AppSnackBar.info('Unable to update exercise');
    }
  }

  Future<Plan?> _ensurePlan() async {
    if (_plan?.id != null) {
      return _plan;
    }

    if (widget.planId != null) {
      final planRepo = context.read<PlansRepository>();

      final existing = planRepo.getPlanById(widget.planId!);

      if (existing != null) {
        _plan = existing;
        return existing;
      }
    }

    final planRepo = context.read<PlansRepository>();

    final newPlan = await planRepo.insertPlan(Plan(days: '', name: ''));

    _plan = newPlan;
    _planCreated = true;

    return newPlan;
  }

  Future<void> _resequencePlanExercises(int planId) async {
    final planExerciseRepo = context.read<PlanExercisesRepository>();

    final exercises = planExerciseRepo.getPlanExercisesByPlanId(planId);

    for (var i = 0; i < exercises.length; i++) {
      final exercise = exercises[i];

      if (exercise.id == null) {
        continue;
      }

      if (exercise.sequence == i) {
        continue;
      }

      await planExerciseRepo.updatePlanExercise(exercise.copyWith(sequence: i));
    }
  }

  Widget _buildNothingFound() {
    if (search.trim().isEmpty) {
      return const ListTile(title: Text('Nothing found'));
    }

    return ListTile(
      title: const Text('Nothing found'),
      subtitle: Text('Tap to create $search'),
      onTap: () async {
        final services = ExerciseServices(context: context);

        await services.openAddEditExercisePage(context, null, search);
      },
    );
  }

  Future<void> _handleBack() async {
    if (_isLeaving) {
      return;
    }

    if (isEditMode) {
      if (mounted) {
        Navigator.of(context).pop();
      }
      return;
    }

    if (!_planCreated || _plan == null) {
      if (mounted) {
        Navigator.of(context).pop();
      }
      return;
    }

    _isLeaving = true;

    final saveChanges = await showConfirmationDialog(
      context: context,
      title: 'Unsaved changes',
      content: 'You have unsaved plan changes. Save before leaving?',
      confirmLabel: 'Save',
      cancelLabel: 'Discard',
      barrierDismissible: true,
    );

    if (!mounted) {
      return;
    }

    if (saveChanges == null) {
      _isLeaving = false;
      return;
    }

    if (saveChanges) {
      await _savePlanAndExit();
    } else {
      await _discardNewPlan();
    }
  }

  Future<void> _savePlanAndExit() async {
    final selectedDays = <String>[];

    for (var i = 0; i < (_days?.length ?? 0); i++) {
      if (_days![i]) {
        selectedDays.add(weekdays[i]);
      }
    }

    if (selectedDays.isEmpty) {
      AppSnackBar.info('Please select days!');
      _isLeaving = false;
      return;
    }

    if ((_planExercises ?? []).isEmpty) {
      AppSnackBar.info('Please select exercises');
      _isLeaving = false;
      return;
    }

    final plan = _plan;

    if (plan == null || plan.id == null) {
      _isLeaving = false;
      return;
    }

    final planRepo = context.read<PlansRepository>();

    final planName = titleCtrl.text.trim();

    final updatedPlan = plan.copyWith(days: selectedDays.join(','), name: planName.isEmpty ? selectedDays.join(', ') : planName);

    await planRepo.updatePlan(updatedPlan);

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop();
  }

  Future<void> _discardNewPlan() async {
    final plan = _plan;

    if (plan == null || plan.id == null) {
      if (mounted) {
        Navigator.of(context).pop();
      }
      return;
    }

    final planExerciseRepo = context.read<PlanExercisesRepository>();

    final planRepo = context.read<PlansRepository>();
    final planExercises = planExerciseRepo.getPlanExercisesByPlanId(plan.id!);

    for (final planExercise in planExercises) {
      if (planExercise.id != null) {
        await planExerciseRepo.deletePlanExerciseById(planExercise.id!);
      }
    }

    await planRepo.deletePlanById(plan.id!);

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop();
  }

  Future<void> save() async {
    if (_saving) {
      return;
    }

    final selectedDays = <String>[];

    for (var i = 0; i < (_days?.length ?? 0); i++) {
      if (_days![i]) {
        selectedDays.add(weekdays[i]);
      }
    }

    if (selectedDays.isEmpty) {
      AppSnackBar.info('Please select days!');
      return;
    }

    if ((_planExercises ?? []).isEmpty) {
      AppSnackBar.info('Please select exercises');
      return;
    }

    final planRepo = context.read<PlansRepository>();

    setState(() {
      _saving = true;
    });

    try {
      final plan = await _ensurePlan();

      if (plan == null || plan.id == null) {
        return;
      }

      final planName = titleCtrl.text.trim();

      final updatedPlan = plan.copyWith(days: selectedDays.join(','), name: planName.isEmpty ? selectedDays.join(', ') : planName);

      await planRepo.updatePlan(updatedPlan);

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }
}

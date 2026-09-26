import 'dart:async';
import 'dart:io' show Platform, File;
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fossfit/animated_fab.dart';
import 'package:fossfit/constants.dart';
import 'package:fossfit/custom_set_indicator.dart';
import 'package:fossfit/db/repositories/exercise_repository.dart';
import 'package:fossfit/db/repositories/gym_sets_repository.dart';
import 'package:fossfit/db/repositories/plan_exercises_repository.dart';
import 'package:fossfit/db/repositories/plans_repository.dart';
import 'package:fossfit/db/repositories/settings_repository.dart';
import 'package:fossfit/graph/graph_history_page.dart';
import 'package:fossfit/models/exercise_model.dart';
import 'package:fossfit/models/gym_set_model.dart';
import 'package:fossfit/models/plan_exercise_model.dart';
import 'package:fossfit/models/plan_model.dart';
import 'package:fossfit/permissions_page.dart';
import 'package:fossfit/plan/edit_plan_page.dart';
import 'package:fossfit/plan/exercise_modal.dart';
import 'package:fossfit/sets/edit_set_page.dart';
import 'package:fossfit/timer/timer_state.dart';
import 'package:fossfit/utils.dart';
import 'package:provider/provider.dart';

class StartPlanPage extends StatefulWidget {
  const StartPlanPage({
    super.key,
    required this.plan,
  });

  final Plan plan;

  @override
  State<StartPlanPage> createState() => _StartPlanPageState();
}

//TODO FIX IMAGES
typedef Tapped = ({
  int index,
  DateTime dateTime,
});

class _StartPlanPageState extends State<StartPlanPage>
    with WidgetsBindingObserver {
  final reps = TextEditingController(text: '0.0');
  final weight = TextEditingController(text: '0.0');
  final notes = TextEditingController();
  final distance = TextEditingController(text: '0.0');
  final minutes = TextEditingController(text: '0.0');
  final seconds = TextEditingController(text: '0.0');
  final incline = TextEditingController(text: '0');

  final formKey = GlobalKey<FormState>();

  int selected = 0;
  bool cardio = false;

  DateTime? lastSaved;
  List<Rpm>? rpms;

  String? category;
  String? image;
  Exercise? currentExercise;

  List<PlanExercise> planExercises = [];

  String unit = 'kg';
  String title = '';

  Tapped lastTap = (
    index: 0,
    dateTime: DateTime(0),
  );

  int? expandedIndex = 0;

  final Map<int, ExpansibleController> controllers = {};

  @override
  void initState() {
    super.initState();

    unit = 'kg';
    title = widget.plan.days.replaceAll(',', ', ');

    WidgetsBinding.instance.addObserver(this);

    _loadExercises();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _refreshPlanFromRepository();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state != AppLifecycleState.resumed ||
        rpms == null ||
        !mounted ||
        lastSaved == null) {
      return;
    }

    final settings = context.read<SettingsRepository>();
    final difference = DateTime.now().difference(lastSaved!);

    if (cardio && settings.isEnabled(key: 'duration_estimation')) {
      _estimateCardioDuration(difference);
      return;
    }

    if (!cardio && settings.isEnabled(key: 'rep_estimation')) {
      _estimateReps(difference);
    }
  }

  @override
  void dispose() {
    reps.dispose();
    weight.dispose();
    distance.dispose();
    minutes.dispose();
    incline.dispose();
    notes.dispose();
    seconds.dispose();

    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  void _refreshPlanFromRepository() {
    if (!mounted || widget.plan.id == null) return;

    final planRepo = context.read<PlansRepository>();
    final currentPlan = planRepo.getPlanById(widget.plan.id!);

    if (currentPlan == null) return;

    final exercises = currentPlan.exercises ?? [];

    if (_samePlanExercises(planExercises, exercises)) {
      return;
    }

    final oldSelectedId =
        selected < planExercises.length ? planExercises[selected].id : null;

    final oldExpandedId = expandedIndex != null &&
            expandedIndex! >= 0 &&
            expandedIndex! < planExercises.length
        ? planExercises[expandedIndex!].id
        : null;

    final newPlanExercises = List<PlanExercise>.from(exercises);

    if (newPlanExercises.isEmpty) {
      setState(() {
        planExercises = [];
        selected = 0;
        expandedIndex = null;
        currentExercise = null;
      });
      return;
    }

    final selectedIndex = newPlanExercises.indexWhere(
      (e) => e.id == oldSelectedId,
    );

    final newSelected = selectedIndex >= 0 ? selectedIndex : 0;

    final expandedIndexValue = newPlanExercises.indexWhere(
      (e) => e.id == oldExpandedId,
    );

    final newExpanded = expandedIndexValue >= 0 ? expandedIndexValue : 0;

    final exercise = newPlanExercises[newSelected].exercise;

    setState(() {
      planExercises = newPlanExercises;
      selected = newSelected.clamp(0, newPlanExercises.length - 1);
      expandedIndex = newExpanded;

      if (exercise != null) {
        currentExercise = exercise;
        cardio = exercise.cardio;
        category = exercise.category;
        image = exercise.image;
      }
    });
  }

  bool _samePlanExercises(
    List<PlanExercise> a,
    List<PlanExercise> b,
  ) {
    if (a.length != b.length) return false;

    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id ||
          a[i].exerciseId != b[i].exerciseId ||
          a[i].sequence != b[i].sequence ||
          a[i].enabled != b[i].enabled ||
          a[i].exercise?.image != b[i].exercise?.image) {
        return false;
      }
    }

    return true;
  }

  Future<void> _loadExercises() async {
    if (!mounted) return;

    final settings = context.read<SettingsRepository>();
    final repo = context.read<GymSetsRepository>();

    if (settings.isEnabled(key: 'rep_estimation')) {
      final value = await repo.getRpms();

      if (!mounted) return;

      setState(() {
        rpms = value;
      });
    }

    final su = settings.getSetting(key: 'strength_unit');
    final cu = settings.getSetting(key: 'cardio_unit');

    if (!cardio && su != 'last-entry') {
      if (mounted) {
        setState(() => unit = su);
      }
    } else if (cardio && cu != 'last-entry') {
      if (mounted) {
        setState(() => unit = cu);
      }
    }
  }

  void _estimateCardioDuration(Duration difference) {
    minutes.text = difference.inMinutes.toString();
    seconds.text = (difference.inSeconds % 60).toString();
  }

  Future<void> _estimateReps(Duration difference) async {
    final parsedWeight = double.tryParse(weight.text) ?? 0;

    if (!mounted || rpms == null || planExercises.isEmpty) return;

    if (selected < 0 || selected >= planExercises.length) return;

    final exercise = planExercises[selected].exercise;

    if (exercise == null) return;

    final matchingRpms =
        rpms!.where((rpm) => rpm.name == exercise.name).toList();

    if (matchingRpms.isEmpty) return;

    final closestRpm = matchingRpms.reduce(
      (rpm1, rpm2) => (rpm1.weight - parsedWeight).abs() <
              (rpm2.weight - parsedWeight).abs()
          ? rpm1
          : rpm2,
    );

    final estimatedReps = (difference.inMinutes * closestRpm.rpm).clamp(1, 50);

    if (estimatedReps <= 0) return;

    reps.text = estimatedReps.toInt().toString();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<PlansRepository>();
    context.watch<PlanExercisesRepository>();
    context.watch<ExercisesRepository>();
    _refreshPlanFromRepository();

    if (planExercises.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Text('No exercises in this plan'),
        ),
      );
    }

    if (title.isEmpty) {
      title = widget.plan.days.replaceAll(',', ', ');

      if (widget.plan.title?.isNotEmpty == true) {
        title = widget.plan.title!;
      }
    }
    select(0);
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: _buildAppBar(context),
      body: Padding(
        padding: const EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: 104,
        ),
        child: Form(
          key: formKey,
          child: Column(
            children: [
              Expanded(
                child: _buildPlanList(context),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: AnimatedFab(
        onPressed: save,
        label: const Text('Save'),
        icon: const Icon(Icons.save),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(title),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        if (currentExercise != null)
          IconButton(
            tooltip: 'History',
            icon: const Icon(Icons.history),
            onPressed: _showHistory,
          ),
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: _editPlan,
        ),
      ],
    );
  }

  Future<void> _showHistory() async {
    final exercise = currentExercise;
    if (exercise == null) return;

    final setRepo = context.read<GymSetsRepository>();

    final gymSets = setRepo.gymsets
        .where(
          (tbl) => tbl.exercise!.name == exercise.name && !tbl.hidden,
        )
        .take(10)
        .toList();

    gymSets.sort((a, b) => b.created.compareTo(a.created));

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.75,
          widthFactor: 0.85,
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: GraphHistoryPage(
              exercise: exercise,
              gymSets: gymSets,
              peek: true,
            ),
          ),
        );
      },
    );
  }

  Future<void> _editPlan() async {
    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditPlanPage(
          plan: widget.plan,
        ),
      ),
    );

    if (!mounted) return;

    _refreshPlanFromRepository();
  }

  Widget strengthFields() {
    final screenWidth = MediaQuery.of(context).size.width;

    final repsField = TextFormField(
      controller: reps,
      decoration: const InputDecoration(labelText: 'Reps'),
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
      ),
      textInputAction: TextInputAction.next,
      onFieldSubmitted: (_) => selectAll(weight),
      onTap: () => selectAll(reps),
      validator: _requiredNumberValidator,
    );

    final weightField = _weightField(
      onFieldSubmitted: (_) => save(),
    );

    if (screenWidth <= 450) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          repsField,
          const SizedBox(height: 8),
          weightField,
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: repsField),
        const SizedBox(width: 8),
        Expanded(child: weightField),
      ],
    );
  }

  List<Widget> cardioFields() {
    return [
      Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: minutes,
              decoration: const InputDecoration(labelText: 'Minutes'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: false,
              ),
              onTap: () => selectAll(minutes),
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => selectAll(seconds),
              validator: _optionalIntegerValidator,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              controller: seconds,
              decoration: const InputDecoration(labelText: 'Seconds'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: false,
              ),
              onTap: () => selectAll(seconds),
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => selectAll(distance),
              validator: _optionalIntegerValidator,
            ),
          ),
        ],
      ),
      Row(
        children: [
          Expanded(
            child: _cardioPrimaryField(),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              controller: incline,
              decoration: const InputDecoration(labelText: 'Incline %'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onTap: () => selectAll(incline),
              onFieldSubmitted: (_) => save(),
              validator: _optionalNumberValidator,
            ),
          ),
        ],
      ),
    ];
  }

  Widget _cardioPrimaryField() {
    if (unit == 'kg' || unit == 'lb' || unit == 'stone') {
      return _weightField(
        onFieldSubmitted: (_) {},
      );
    }

    return TextFormField(
      textInputAction: TextInputAction.next,
      controller: distance,
      decoration: const InputDecoration(labelText: 'Distance'),
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
      ),
      onFieldSubmitted: (_) => selectAll(incline),
      onTap: () => selectAll(distance),
      validator: _optionalNumberValidator,
    );
  }

  Widget _weightField({
    required void Function(String) onFieldSubmitted,
  }) {
    return TextFormField(
      controller: weight,
      decoration: InputDecoration(
        labelText: 'Weight ($unit)',
        suffixIcon: Selector<SettingsRepository, bool>(
          selector: (context, settings) =>
              settings.isEnabled(key: 'show_body_weight'),
          builder: (context, showBodyWeight, child) {
            if (!showBodyWeight) {
              return const SizedBox.shrink();
            }

            return IconButton(
              tooltip: 'Use body weight',
              icon: const Icon(Icons.scale),
              onPressed: useBodyWeight,
            );
          },
        ),
      ),
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
      ),
      onTap: () => selectAll(weight),
      onFieldSubmitted: onFieldSubmitted,
      validator: _requiredNumberValidator,
    );
  }

  String? _requiredNumberValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Required';
    }

    if (double.tryParse(value) == null) {
      return 'Invalid number';
    }

    return null;
  }

  String? _optionalNumberValidator(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    if (double.tryParse(value) == null) {
      return 'Invalid number';
    }

    return null;
  }

  String? _optionalIntegerValidator(String? value) {
    if (value?.isNotEmpty == true && int.tryParse(value!) == null) {
      return 'Invalid number';
    }

    return null;
  }

  Widget unitSelector() {
    return Selector<SettingsRepository, bool>(
      selector: (context, settings) => settings.isEnabled(key: 'show_units'),
      builder: (context, showUnits, child) {
        if (!showUnits) {
          return const SizedBox.shrink();
        }

        return DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            labelText: 'Unit',
            labelStyle: TextStyle(
              overflow: TextOverflow.ellipsis,
            ),
          ),
          initialValue: unit,
          items: strengthUnits,
          onChanged: (value) {
            if (value == null) return;

            setState(() {
              unit = value;
            });
          },
        );
      },
    );
  }

  Widget notesField() {
    return Selector<SettingsRepository, bool>(
      selector: (context, settings) => settings.isEnabled(key: 'show_notes'),
      builder: (context, showNotes, child) {
        if (!showNotes) {
          return const SizedBox.shrink();
        }

        return TextFormField(
          controller: notes,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Notes',
            border: InputBorder.none,
          ),
        );
      },
    );
  }

  GymSet? getLast(Exercise exercise) {
    final sets = context.read<GymSetsRepository>().gymsets;

    final matching = sets
        .where(
          (set) => set.exerciseId == exercise.id && !set.hidden,
        )
        .toList();

    if (matching.isEmpty) {
      return null;
    }

    matching.sort(
      (a, b) => b.created.compareTo(a.created),
    );

    return matching.first;
  }

  void _updateGymSetTextFields(GymSet gymSet, Exercise exercise) {
    final settings = context.read<SettingsRepository>();

    final su = settings.getSetting(key: 'strength_unit');
    final cu = settings.getSetting(key: 'cardio_unit');

    if ((!exercise.cardio && su == 'last-entry') ||
        (exercise.cardio && cu == 'last-entry')) {
      unit = gymSet.unit;
    } else if (exercise.cardio) {
      unit = cu;
    } else {
      unit = su;
    }

    reps.text = toString(gymSet.reps);
    weight.text = toString(gymSet.weight);
    distance.text = toString(gymSet.distance!);
    minutes.text = (gymSet.duration ?? 0).floor().toString();
    seconds.text = (((gymSet.duration ?? 0) * 60) % 60).floor().toString();
    incline.text = gymSet.incline?.toString() ?? '';
    cardio = exercise.cardio;
    category = exercise.category;
    image = exercise.image;
    notes.text = gymSet.notes ?? '';
    currentExercise = exercise;
  }

  List<GymSet> _todaySetsStream(Exercise exercise) {
    final sets = context.watch<GymSetsRepository>().gymsets;

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final startOfTomorrow = startOfDay.add(const Duration(days: 1));

    final todays = sets
        .where(
          (set) =>
              set.planId == widget.plan.id &&
              set.exerciseId == exercise.id &&
              set.created.isAfter(startOfDay) &&
              set.created.isBefore(startOfTomorrow),
        )
        .toList();

    todays.sort((a, b) => a.created.compareTo(b.created));

    return todays;
  }

  Future<void> save() async {
    if (!(formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (!mounted || planExercises.isEmpty) return;

    final setRepo = context.read<GymSetsRepository>();
    final planRepo = context.read<PlansRepository>();
    final exercise = planExercises[selected].exercise;

    if (exercise == null) return;

    final settings = context.read<SettingsRepository>();

    final bodyWeight = await _getBodyWeight(
      exercise,
      settings,
    );

    if (!mounted) return;

    if (!settings.isEnabled(key: 'explained_permissions') &&
        settings.isEnabled(key: 'rest_timers') &&
        !kIsWeb) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const PermissionsPage(),
        ),
      );
    }

    if (!mounted) return;

    final counts = planRepo.gymCounts;

    final countIndex = counts.indexWhere(
      (element) => element.name == exercise.name,
    );

    int? maxSets;
    double? restMs;
    int? warmupSets;
    var peTimers = true;

    if (countIndex != -1) {
      final count = counts[countIndex];

      maxSets = count.maxSets;
      restMs = count.restMs?.toDouble();
      warmupSets = count.warmupSets;
      peTimers = count.timers;
    }

    var count = countIndex == -1 ? 0 : counts[countIndex].count;

    count++;

    final gymSetInsert = GymSet(
      unit: unit,
      created: DateTime.now().toLocal(),
      duration: _durationInMinutes(),
      bodyWeight: bodyWeight ?? 0.0,
      restMs: restMs?.toInt(),
      planId: widget.plan.id,
      reps: double.tryParse(reps.text) ?? 0,
      weight: double.tryParse(weight.text) ?? 0,
      incline: int.tryParse(incline.text),
      distance: double.tryParse(distance.text) ?? 0,
      notes: notes.text,
      exerciseId: exercise.id!,
      hidden: false,
    );

    final finishedSetCount =
        count == (maxSets ?? settings.getInt(key: 'max_sets'));

    final finishedPlan =
        finishedSetCount && selected == planExercises.length - 1;

    final isWarmup =
        count <= (warmupSets ?? settings.getInt(key: 'warmup_sets'));

    restMs ??= settings.getInt(key: 'timer_duration').toDouble();

    if (!finishedPlan &&
        !isWarmup &&
        settings.isEnabled(key: 'rest_timers') &&
        peTimers) {
      context.read<TimerState>().startTimer(
            '$exercise ($count)',
            Duration(milliseconds: restMs.toInt()),
            settings.getSetting(key: 'alarm_sound'),
            settings.isEnabled(key: 'vibrate'),
          );
    }

    final finishedExercise =
        finishedSetCount && selected < planExercises.length - 1;

    final gymSet = await setRepo.insertGymSet(gymSetInsert);

    await planRepo.updateGymCounts(widget.plan.id!);

    final trailing = settings.getSetting(key: 'plan_trailing');

    if (['count', 'ratio', 'percent'].contains(trailing.split('.').last)) {
      await planRepo.updatePlanCounts();
    }

    if (!mounted) return;

    setState(() {
      _updateGymSetTextFields(gymSet, exercise);
      lastSaved = DateTime.now();
    });

    if (finishedExercise) {
      await select(selected + 1);

      if (selected < planExercises.length) {
        controllers[planExercises[selected].id]?.expand();
      }
    }

    if (!settings.isEnabled(key: 'notifications')) {
      return;
    }

    final best = await setRepo.isBest(gymSet);

    if (!best || !mounted) return;

    final random = Random();

    if (random.nextDouble() < 0.3) {
      final message = positiveReinforcement[random.nextInt(
        positiveReinforcement.length,
      )];

      toast(message);
    }
  }

  double _durationInMinutes() {
    return (int.tryParse(seconds.text) ?? 0) / 60 +
        (int.tryParse(minutes.text) ?? 0);
  }

  Future<double?> _getBodyWeight(
    Exercise exercise,
    SettingsRepository settings,
  ) async {
    if (!settings.isEnabled(key: 'show_body_weight')) {
      return null;
    }

    final current = await getBodyWeight(context);

    if (current != null) {
      return current.weight;
    }

    final lastSet = getLast(exercise);

    return lastSet?.bodyWeight;
  }

  Future<void> select(int index) async {
    if (index < 0 || index >= planExercises.length) {
      return;
    }

    setState(() {
      selected = index;
    });

    final exercise = planExercises[index].exercise;

    if (exercise == null || !mounted) {
      return;
    }

    final last = getLast(exercise);

    if (last == null || !mounted) {
      return;
    }
    setState(() {
      _updateGymSetTextFields(last, exercise);
    });
  }

  Future<void> useBodyWeight() async {
    final weightSet = await getBodyWeight(context);

    if (!mounted) return;

    if (weightSet == null) {
      toast('No weight entered yet');
      return;
    }

    weight.text = toString(weightSet.weight);
  }

  Future<void> tap(
    int index,
    List<GymCount> counts,
    Exercise exercise,
  ) async {
    final sets = context.read<GymSetsRepository>().gymsets;

    await select(index);

    final count = counts.elementAtOrNull(index);

    if (count == null || count.count == 0) return;

    final now = DateTime.now();

    if (now.difference(lastTap.dateTime) >= const Duration(milliseconds: 300) ||
        index != lastTap.index) {
      setState(() {
        lastTap = (
          index: index,
          dateTime: now,
        );
      });

      return;
    }

    final gymSet = sets.where((t) => t.id == exercise.id).firstOrNull;

    if (gymSet == null || !mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditSetPage(
          gymSet: gymSet,
        ),
      ),
    );
  }

  Widget _buildPlanList(BuildContext context) {
    final settings = context.watch<SettingsRepository>();
    final planExerciseRepo = context.watch<PlanExercisesRepository>();

    final maxSets = settings.getInt(key: 'max_sets');

    final trailing = PlanTrailing.values.byName(
      settings.getSetting(key: 'plan_trailing').replaceFirst(
            'PlanTrailing.',
            '',
          ),
    );

    final showImage = settings.isEnabled(key: 'show_images');

    final counts = context.watch<PlansRepository>().gymCounts;

    if (trailing == PlanTrailing.reorder) {
      return ReorderableListView.builder(
        itemCount: planExercises.length,
        padding: const EdgeInsets.only(bottom: 76),
        itemBuilder: (context, index) => _buildExerciseItem(
          context,
          index,
          maxSets,
          trailing,
          counts,
          showImage,
        ),
        onReorder: (oldIndex, newIndex) async {
          if (oldIndex < newIndex) {
            newIndex--;
          }

          final selectedId = planExercises[selected].id;

          final expandedId =
              expandedIndex != null ? planExercises[expandedIndex!].id : null;

          final item = planExercises.removeAt(oldIndex);

          planExercises.insert(newIndex, item);

          for (var i = 0; i < planExercises.length; i++) {
            await planExerciseRepo.updatePlanExercise(
              planExercises[i].copyWith(
                sequence: i,
              ),
            );
          }

          if (!context.mounted) return;

          selected = planExercises.indexWhere(
            (exercise) => exercise.id == selectedId,
          );

          if (expandedId != null) {
            final newExpandedIndex = planExercises.indexWhere(
              (exercise) => exercise.id == expandedId,
            );

            expandedIndex = newExpandedIndex == -1 ? null : newExpandedIndex;
          }

          if (expandedIndex != null && expandedId != null) {
            controllers[expandedId]?.expand();
          }

          await context.read<PlansRepository>().updatePlans(null);
        },
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 76),
      itemCount: planExercises.length,
      itemBuilder: (context, index) => _buildExerciseItem(
        context,
        index,
        maxSets,
        trailing,
        counts,
        showImage,
      ),
    );
  }

  Widget _buildExerciseItem(
    BuildContext context,
    int index,
    int maxSets,
    PlanTrailing trailing,
    List<GymCount> counts,
    bool showImages,
  ) {
    final planItem = planExercises[index];

    final countIndex = counts.indexWhere(
      (element) => element.name == planItem.exercise?.name,
    );

    var count = 0;
    var max = maxSets;

    if (countIndex != -1) {
      final gymCount = counts[countIndex];

      count = gymCount.count;
      max = gymCount.maxSets ?? maxSets;
    }

    final iconColor = index == expandedIndex
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onSurface;

    return GestureDetector(
      key: ValueKey(planItem.id),
      onLongPressStart: (_) => _showExerciseModal(
        context,
        planItem,
        index,
        count,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Theme(
            data: Theme.of(context).copyWith(
              dividerColor: Colors.transparent,
            ),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.all(2),
              initiallyExpanded: index == (expandedIndex ?? 0),
              controller: controllers.putIfAbsent(
                planItem.id!,
                ExpansibleController.new,
              ),
              textColor: Theme.of(context).colorScheme.primary,
              trailing: _buildTrailing(
                trailing,
                count,
                max,
                index,
              ),
              onExpansionChanged: (open) {
                if (open) {
                  if (expandedIndex != null && expandedIndex != index) {
                    final previousExercise = planExercises[expandedIndex!];

                    controllers[previousExercise.id]?.collapse();
                  }

                  expandedIndex = index;
                  select(index);
                } else if (expandedIndex == index) {
                  expandedIndex = null;
                }

                setState(() {});
              },
              title: _buildExerciseTitle(
                planItem,
                iconColor,
                count,
                max,
                index,
                showImages,
              ),
              children: [
                if (!cardio) strengthFields(),
                if (cardio) ...cardioFields(),
                unitSelector(),
                notesField(),
                const SizedBox(height: 4),
                CustomSetIndicator(
                  sets: _todaySetsStream(
                    planItem.exercise!,
                  ),
                  max: max,
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildExerciseTitle(
    PlanExercise planItem,
    Color iconColor,
    int count,
    int max,
    int index,
    bool showImages,
  ) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.inversePrimary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: showImages && planItem.exercise?.hasImage() == true
              ? Stack(
                  children: [
                    Image.file(
                      width: 24,
                      height: 24,
                      File(
                        planItem.exercise!.image!,
                      ),
                      opacity: count == max
                          ? const AlwaysStoppedAnimation(
                              0.75,
                            )
                          : null,
                    ),
                    if (count == max)
                      Icon(
                        Icons.check,
                        color: iconColor,
                        size: 20,
                      ),
                  ],
                )
              : Center(
                  child: count == max
                      ? Icon(
                          Icons.check,
                          color: iconColor,
                          size: 20,
                        )
                      : Text(
                          planItem.exercise!.name[0].toUpperCase(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: iconColor,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            planItem.exercise!.name,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        if (controllers[planItem.id]?.isExpanded == false)
          ..._buildBlips(planItem.exercise!),
      ],
    );
  }

  Widget _buildTrailing(
    PlanTrailing trailing,
    int count,
    int max,
    int index,
  ) {
    switch (trailing) {
      case PlanTrailing.reorder:
        return ReorderableDragStartListener(
          index: index,
          child: Platform.isAndroid || Platform.isIOS
              ? const Icon(
                  Icons.drag_handle,
                  size: 32,
                )
              : const SizedBox.shrink(),
        );

      case PlanTrailing.ratio:
        return Text(
          '$count / $max',
          style: const TextStyle(
            fontSize: 16,
          ),
        );

      case PlanTrailing.count:
        return Text(
          count.toString(),
          style: const TextStyle(
            fontSize: 16,
          ),
        );

      case PlanTrailing.percent:
        return Text(
          '${(count / max * 100).toStringAsFixed(2)}%',
          style: const TextStyle(
            fontSize: 16,
          ),
        );

      case PlanTrailing.none:
        return const SizedBox.shrink();
    }
  }

  List<Widget> _buildBlips(Exercise exercise) {
    final items = <Widget>[];
    var completedSets = _todaySetsStream(exercise).length;
    var maxSets = widget.plan.exercises
            ?.where((t) => t.exerciseId == exercise.id)
            .firstOrNull
            ?.maxSets ??
        3;
    for (int i = 0; i < maxSets; i++) {
      items.add(
        SizedBox(
          width: 10,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            height: 4,
            child: AnimatedFractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: completedSets > i ? 1 : 0,
              duration: const Duration(
                milliseconds: 250,
              ),
              curve: Curves.ease,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
        ),
      );

      if (i < maxSets - 1) {
        items.add(
          const SizedBox(width: 6),
        );
      }
    }

    return items;
  }

  Future<void> _showExerciseModal(
    BuildContext context,
    PlanExercise exercise,
    int index,
    int count,
  ) async {
    final planRepo = context.read<PlansRepository>();

    await showModalBottomSheet(
      useRootNavigator: true,
      context: context,
      builder: (context) {
        return SafeArea(
          child: ExerciseModal(
            planId: widget.plan.id!,
            exercise: exercise.exercise!,
            hasData: count > 0,
            onSelect: () => select(index),
            onMax: () {
              planRepo.updateGymCounts(
                widget.plan.id!,
              );
            },
          ),
        );
      },
    );
  }
}

import 'dart:async';
import 'dart:io' show Platform, File;
import 'dart:math';

import 'package:drift/drift.dart'
    show
        OrderingTerm,
        OrderingMode,
        TableOrViewStatements,
        Value,
        BooleanExpressionOperators,
        QueryTableExtensions,
        ComparableExpr;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fossfit/animated_fab.dart';
import 'package:fossfit/constants.dart';
import 'package:fossfit/custom_set_indicator.dart';
import 'package:fossfit/database/database.dart';
import 'package:fossfit/database/gym_sets.dart';
import 'package:fossfit/graph/graph_history_page.dart';
import 'package:fossfit/main.dart';
import 'package:fossfit/permissions_page.dart';
import 'package:fossfit/plan/edit_plan_page.dart';
import 'package:fossfit/plan/exercise_modal.dart';
import 'package:fossfit/plan/plan_state.dart';
import 'package:fossfit/sets/edit_set_page.dart';
import 'package:fossfit/settings/settings_state.dart';
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
  String? currentExercise;

  late Stream<List<PlanExercise>> stream;
  late PlanState planState;
  late String unit;
  late String title;

  Tapped lastTap = (
    index: 0,
    dateTime: DateTime(0),
  );

  int? expandedIndex = 0;

  final Map<int, ExpansibleController> controllers = {};

  @override
  void initState() {
    super.initState();

    planState = context.read<PlanState>();
    unit = 'kg';
    title = widget.plan.days.replaceAll(',', ', ');

    planState.addListener(planChanged);
    WidgetsBinding.instance.addObserver(this);

    _loadExercises();
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

    final settings = context.read<SettingsState>().value;
    final difference = DateTime.now().difference(lastSaved!);

    if (cardio && settings.durationEstimation) {
      _estimateCardioDuration(difference);
      return;
    }

    if (!cardio && settings.repEstimation) {
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
    planState.removeListener(planChanged);

    super.dispose();
  }

  Future<void> _loadExercises() async {
    stream = (db.planExercises.select()
          ..where(
            (pe) => pe.planId.equals(widget.plan.id) & pe.enabled,
          )
          ..orderBy([
            (pe) => OrderingTerm(
                  expression: pe.sequence,
                  mode: OrderingMode.asc,
                ),
          ]))
        .watch();

    await select(0);

    if (!mounted) return;

    final settings = context.read<SettingsState>().value;

    if (settings.repEstimation) {
      getRpms().then((value) {
        if (!mounted) return;
        setState(() => rpms = value);
      });
    }

    if (!cardio && settings.strengthUnit != 'last-entry') {
      setState(() => unit = settings.strengthUnit);
    } else if (cardio && settings.cardioUnit != 'last-entry') {
      setState(() => unit = settings.cardioUnit);
    }
  }

  void _estimateCardioDuration(Duration difference) {
    minutes.text = difference.inMinutes.toString();
    seconds.text = (difference.inSeconds % 60).toString();
  }

  Future<void> _estimateReps(Duration difference) async {
    final parsedWeight = double.parse(weight.text);
    final planExercises = await stream.first;

    if (!mounted || rpms == null || planExercises.isEmpty) return;

    final exercise = planExercises[selected].exercise;

    final matchingRpms = rpms!.where((rpm) => rpm.name == exercise).toList();

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
    if (widget.plan.title?.isNotEmpty == true) {
      title = widget.plan.title!;
    }

    planState = context.watch<PlanState>();

    return StreamBuilder<List<PlanExercise>>(
      stream: stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

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
                    child: _buildPlanList(context, snapshot),
                  ),
                ],
              ),
            ),
          ),
          floatingActionButton: AnimatedFab(
            onPressed: () => save(snapshot),
            label: const Text('Save'),
            icon: const Icon(Icons.save),
          ),
        );
      },
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
    final gymSets = await (db.gymSets.select()
          ..orderBy([
            (u) => OrderingTerm(
                  expression: u.created,
                  mode: OrderingMode.desc,
                ),
          ])
          ..where((tbl) => tbl.name.equals(exercise))
          ..where((tbl) => tbl.hidden.equals(false))
          ..limit(10))
        .get();

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
              name: exercise,
              gymSets: gymSets,
              peek: true,
            ),
          ),
        );
      },
    );
  }

  Future<void> _editPlan() async {
    final plan =
        await (db.plans.select()..whereSamePrimaryKey(widget.plan)).getSingle();

    await planState.setExercises(plan.toCompanion(false));

    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditPlanPage(
          plan: plan.toCompanion(false),
        ),
      ),
    );
  }

  Widget strengthFields(
    AsyncSnapshot<List<PlanExercise>> snapshot,
  ) {
    double screenWidth = MediaQuery.of(context).size.width;
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
      onFieldSubmitted: (_) => save(snapshot),
    );

    print(screenWidth);
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

  List<Widget> cardioFields(
    AsyncSnapshot<List<PlanExercise>> snapshot,
  ) {
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
              onFieldSubmitted: (_) => save(snapshot),
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
        suffixIcon: Selector<SettingsState, bool>(
          selector: (context, settings) => settings.value.showBodyWeight,
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
    return Selector<SettingsState, bool>(
      selector: (context, settings) => settings.value.showUnits,
      builder: (context, showUnits, child) {
        if (!showUnits) {
          return const SizedBox.shrink();
        }

        return DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            labelText: 'Unit',
            labelStyle: TextStyle(overflow: TextOverflow.ellipsis),
          ),
          initialValue: unit,
          items: strengthUnits,
          onChanged: (value) {
            if (value == null) return;
            setState(() => unit = value);
          },
        );
      },
    );
  }

  Widget notesField() {
    return Selector<SettingsState, bool>(
      selector: (context, settings) => settings.value.showNotes,
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

  Future<GymSet?> getLast(String exercise) {
    return (db.gymSets.select()
          ..where((tbl) => tbl.name.equals(exercise))
          ..orderBy([
            (u) => OrderingTerm(
                  expression: u.created,
                  mode: OrderingMode.desc,
                ),
          ])
          ..limit(1))
        .getSingleOrNull();
  }

  void _updateGymSetTextFields(GymSet gymSet) {
    final settings = context.read<SettingsState>().value;

    if ((!gymSet.cardio && settings.strengthUnit == 'last-entry') ||
        (gymSet.cardio && settings.cardioUnit == 'last-entry')) {
      unit = gymSet.unit;
    } else if (gymSet.cardio) {
      unit = settings.cardioUnit;
    } else {
      unit = settings.strengthUnit;
    }

    reps.text = toString(gymSet.reps);
    weight.text = toString(gymSet.weight);
    distance.text = toString(gymSet.distance);
    minutes.text = gymSet.duration.floor().toString();
    seconds.text = ((gymSet.duration * 60) % 60).floor().toString();
    incline.text = gymSet.incline?.toString() ?? '';
    cardio = gymSet.cardio;
    category = gymSet.category;
    image = gymSet.image;
    notes.text = gymSet.notes ?? '';
    currentExercise = gymSet.name;
  }

  Stream<List<GymSet>> _todaySetsStream(String exercise) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final startOfTomorrow = startOfDay.add(const Duration(days: 1));

    return (db.gymSets.select()
          ..where(
            (set) =>
                set.planId.equals(widget.plan.id) &
                set.name.equals(exercise) &
                set.created.isBiggerOrEqualValue(startOfDay) &
                set.created.isSmallerThanValue(startOfTomorrow),
          )
          ..orderBy([
            (set) => OrderingTerm(
                  expression: set.created,
                  mode: OrderingMode.asc,
                ),
          ]))
        .watch();
  }

  Stream<List<GymSet>> _getExerciseImage(String exercise) {
    return (db.gymSets.select()
          ..where(
            (set) => set.name.equals(exercise) & set.image.isNotNull(),
          )
          ..limit(1))
        .watch();
  }

  void planChanged() {
    final index = planState.plans.indexWhere(
      (plan) => plan.id == widget.plan.id,
    );

    if (index == -1) {
      Navigator.pop(context);
      return;
    }

    if (!mounted) return;

    final plan = planState.plans[index];

    setState(() {
      title = plan.days.replaceAll(',', ', ');
    });
  }

  Future<void> save(
    AsyncSnapshot<List<PlanExercise>> snapshot,
  ) async {
    if (!(formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (!mounted) return;

    final exercise = snapshot.data![selected].exercise;
    final settings = context.read<SettingsState>().value;

    final bodyWeight = await _getBodyWeight(exercise, settings);

    if (!mounted) return;

    if (!settings.explainedPermissions && settings.restTimers && !kIsWeb) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const PermissionsPage(),
        ),
      );
    }

    if (!mounted) return;

    final counts = planState.gymCounts;
    final countIndex = counts.indexWhere(
      (element) => element.name == exercise,
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

    final gymSetInsert = GymSetsCompanion.insert(
      name: exercise,
      unit: unit,
      created: DateTime.now().toLocal(),
      cardio: Value(cardio),
      duration: Value(_durationInMinutes()),
      bodyWeight: Value.absentIfNull(bodyWeight),
      restMs: Value(restMs?.toInt()),
      planId: Value(widget.plan.id),
      category: Value(category),
      image: Value(image),
      reps: double.tryParse(reps.text) ?? 0,
      weight: double.tryParse(weight.text) ?? 0,
      incline: Value(int.tryParse(incline.text)),
      distance: Value(double.tryParse(distance.text) ?? 0),
      notes: Value(notes.text),
    );

    final finishedSetCount = count == (maxSets ?? settings.maxSets);

    final finishedPlan =
        finishedSetCount && selected == snapshot.data!.length - 1;

    final isWarmup = count <= (warmupSets ?? settings.warmupSets ?? 0);

    restMs ??= settings.timerDuration.toDouble();

    if (!finishedPlan && !isWarmup && settings.restTimers && peTimers) {
      context.read<TimerState>().startTimer(
            '$exercise ($count)',
            Duration(milliseconds: restMs.toInt()),
            settings.alarmSound,
            settings.vibrate,
          );
    }

    final finishedExercise =
        finishedSetCount && selected < snapshot.data!.length - 1;

    final gymSet = await db.into(db.gymSets).insertReturning(gymSetInsert);

    await planState.updateGymCounts(widget.plan.id);
    await planState.updateDefaults();

    if (settings.planTrailing == 'PlanTrailing.count' ||
        settings.planTrailing == 'PlanTrailing.ratio' ||
        settings.planTrailing == 'PlanTrailing.percent') {
      planState.updatePlanCounts();
    }

    if (!mounted) return;

    setState(() {
      _updateGymSetTextFields(gymSet);
      lastSaved = DateTime.now();
    });

    if (finishedExercise) {
      await select(selected + 1);
      var idx = snapshot.data![selected].id;
      controllers[idx]?.expand();
    }

    if (!settings.notifications) return;

    final best = await isBest(gymSet);

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
    String exercise,
    dynamic settings,
  ) async {
    if (!settings.showBodyWeight) {
      return null;
    }

    final current = await getBodyWeight();

    if (current != null) {
      return current.weight;
    }

    final lastSet = await getLast(exercise);
    return lastSet?.bodyWeight;
  }

  Future<void> select(int index) async {
    setState(() => selected = index);

    final exercises = await stream.first;
    final last = await getLast(exercises[index].exercise);

    if (last == null || !mounted) return;

    setState(() {
      _updateGymSetTextFields(last);
    });
  }

  Future<void> useBodyWeight() async {
    final weightSet = await getBodyWeight();

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
    String exercise,
  ) async {
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

    final gymSet = await (db.gymSets.select()
          ..where((tbl) => tbl.name.equals(exercise))
          ..orderBy([
            (u) => OrderingTerm(
                  expression: u.created,
                  mode: OrderingMode.desc,
                ),
          ])
          ..limit(1))
        .getSingle();

    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditSetPage(
          gymSet: gymSet,
        ),
      ),
    );
  }

  Widget _buildPlanList(
    BuildContext context,
    AsyncSnapshot<List<PlanExercise>> snapshot,
  ) {
    final exercises = snapshot.data!;

    final maxSets = context.select<SettingsState, int>(
      (settings) => settings.value.maxSets,
    );

    final trailing = context.select<SettingsState, PlanTrailing>(
      (settings) => PlanTrailing.values.byName(
        settings.value.planTrailing.replaceFirst(
          'PlanTrailing.',
          '',
        ),
      ),
    );

    final showImage = context.select<SettingsState, bool>(
      (settings) => settings.value.showImages,
    );
    final counts = context.watch<PlanState>().gymCounts;

    if (trailing == PlanTrailing.reorder) {
      return ReorderableListView.builder(
        itemCount: exercises.length,
        padding: const EdgeInsets.only(bottom: 76),
        itemBuilder: (context, index) => _buildExerciseItem(
          context,
          snapshot,
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

          final selectedId = exercises[selected].id;
          final expandedId =
              expandedIndex != null ? exercises[expandedIndex!].id : null;

          final item = exercises.removeAt(oldIndex);
          exercises.insert(newIndex, item);

          await db.batch((batch) {
            for (var i = 0; i < exercises.length; i++) {
              batch.update(
                db.planExercises,
                PlanExercisesCompanion(
                  sequence: Value(i),
                ),
                where: (pe) => pe.id.equals(exercises[i].id),
              );
            }
          });

          if (!context.mounted) return;

          selected = exercises.indexWhere(
            (exercise) => exercise.id == selectedId,
          );

          if (expandedId != null) {
            final newExpandedIndex = exercises.indexWhere(
              (exercise) => exercise.id == expandedId,
            );

            expandedIndex = newExpandedIndex == -1 ? null : newExpandedIndex;
          }

          if (expandedIndex != null) {
            controllers[expandedId]?.expand();
          }

          final state = context.read<PlanState>();

          state.setExercises(widget.plan.toCompanion(false));
          state.updatePlans(null);
        },
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 76),
      itemCount: exercises.length,
      itemBuilder: (context, index) => _buildExerciseItem(
        context,
        snapshot,
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
    AsyncSnapshot<List<PlanExercise>> snapshot,
    int index,
    int maxSets,
    PlanTrailing trailing,
    List<GymCount> counts,
    bool showImages,
  ) {
    final planItem = snapshot.data![index];

    final countIndex = counts.indexWhere(
      (element) => element.name == planItem.exercise,
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
              tilePadding: EdgeInsets.all(2),
              initiallyExpanded: index == (expandedIndex ?? 0),
              controller: controllers.putIfAbsent(
                planItem.id,
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
                    final previousExercise = snapshot.data![expandedIndex!];
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
                if (!cardio) strengthFields(snapshot),
                if (cardio) ...cardioFields(snapshot),
                unitSelector(),
                notesField(),
                const SizedBox(height: 4),
                StreamBuilder<List<GymSet>>(
                  stream: _todaySetsStream(planItem.exercise),
                  builder: (context, snapshot) {
                    return CustomSetIndicator(
                      sets: snapshot.data ?? const [],
                      max: max,
                    );
                  },
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
          child: StreamBuilder<List<GymSet>>(
            stream: _getExerciseImage(planItem.exercise),
            builder: (context, snapshot) {
              return showImages &&
                      snapshot.hasData &&
                      snapshot.data!.isNotEmpty &&
                      snapshot.data!.first.image != null
                  ? Stack(
                      children: [
                        Image.file(
                          width: 24,
                          height: 24,
                          File(snapshot.data!.first.image!),
                          opacity: count == max
                              ? AlwaysStoppedAnimation(0.75)
                              : null,
                        ),
                        count == max
                            ? Icon(
                                Icons.check,
                                color: iconColor,
                                size: 20,
                              )
                            : SizedBox.shrink(),
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
                              planItem.exercise[0].toUpperCase(),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: iconColor,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                              ),
                            ),
                    );
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            planItem.exercise,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        if (controllers[planItem.id]?.isExpanded == false)
          ..._buildBlips(max, count),
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
              ? Icon(
                  Icons.drag_handle,
                  size: 32,
                )
              : SizedBox.shrink(),
        );

      case PlanTrailing.ratio:
        return Text(
          '$count / $max',
          style: const TextStyle(fontSize: 16),
        );

      case PlanTrailing.count:
        return Text(
          count.toString(),
          style: const TextStyle(fontSize: 16),
        );

      case PlanTrailing.percent:
        return Text(
          '${(count / max * 100).toStringAsFixed(2)}%',
          style: const TextStyle(fontSize: 16),
        );

      case PlanTrailing.none:
        return const SizedBox.shrink();
    }
  }

  List<Widget> _buildBlips(int max, int count) {
    List<Widget> items = [];
    for (int i = 0; i < max; i++) {
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
              widthFactor: count > i ? 1 : 0,
              duration: const Duration(milliseconds: 250),
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
      if (i < max - 1) {
        items.add(const SizedBox(width: 6));
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
    await showModalBottomSheet(
      useRootNavigator: true,
      context: context,
      builder: (context) {
        return SafeArea(
          child: ExerciseModal(
            planId: widget.plan.id,
            exercise: exercise.exercise,
            hasData: count > 0,
            onSelect: () => select(index),
            onMax: () {
              planState.updateGymCounts(widget.plan.id);
            },
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart' as material;
import 'package:flutter/material.dart';
import 'package:fossfit/animated_fab.dart';
import 'package:fossfit/app/app_shell.dart';
import 'package:fossfit/app_search.dart';
import 'package:fossfit/db/repositories/exercise_repository.dart';
import 'package:fossfit/db/repositories/gym_sets_repository.dart';
import 'package:fossfit/db/repositories/settings_repository.dart';
import 'package:fossfit/filters.dart';
import 'package:fossfit/models/exercise_model.dart';
import 'package:fossfit/models/gym_set_model.dart';
import 'package:fossfit/sets/edit_set_page.dart';
import 'package:fossfit/utils.dart';
import 'package:fossfit/widgets/workout_history.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class WorkoutPage extends StatefulWidget {
  const WorkoutPage({
    super.key,
  });

  @override
  State<WorkoutPage> createState() => WorkoutPageState();
}

class WorkoutPageState extends State<WorkoutPage> {
  final repsGt = TextEditingController();
  final repsLt = TextEditingController();
  final weightGt = TextEditingController();
  final weightLt = TextEditingController();

  final scroll = ScrollController();
  final expand = ExpansibleController();

  List<GymSet> gymSets = [];
  List<GymSet> latestSets = [];
  List<GymSet> filteredGymSets = [];

  Widget lastWorkout = const SizedBox.shrink();

  final Set<int> selected = {};

  String search = '';

  DateTime? startDate;
  DateTime? endDate;
  String? category;

  SettingsRepository get settings => context.read<SettingsRepository>();

  @override
  void initState() {
    super.initState();

    scroll.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    repsGt.dispose();
    repsLt.dispose();
    weightGt.dispose();
    weightLt.dispose();

    scroll.removeListener(_onScroll);
    scroll.dispose();

    expand.dispose();

    super.dispose();
  }

  void _onScroll() {
    if (scroll.offset > 0.0) {
      //expand.collapse();
    } else {
      //expand.expand();
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsRepo = context.watch<SettingsRepository>();
    final setsRepo = context.watch<GymSetsRepository>();
    latestSets = setsRepo.latestgymsets;
    gymSets = filteredGymSets;

    final showStats = settingsRepo.isEnabled(
      key: 'stats_panel',
    );
    if (showStats) getStats(latestSets);
    final groupHistory = settingsRepo.isEnabled(
      key: 'group_history',
    );
    return AppShell(
      appBar: buildAppBar(),
      floatingActionButton: AnimatedFab(
        onPressed: onAdd,
        label: const Text('Add'),
        icon: const Icon(Icons.add),
        scroll: scroll,
      ),
      body: Column(
        children: [
          if (latestSets.isEmpty)
            const ListTile(
              title: Text('No entries yet'),
              subtitle: Text(
                'Complete some sets to see them here',
              ),
            ),
          if (latestSets.isNotEmpty && showStats)
            Theme(
              data: Theme.of(context).copyWith(
                dividerColor: Colors.transparent,
              ),
              child: Padding(
                padding: const EdgeInsets.only(
                  top: 8,
                ),
                child: ExpansionTile(
                  childrenPadding: EdgeInsets.zero,
                  iconColor: Theme.of(context).colorScheme.onSurface,
                  leading: Icon(
                    expand.isExpanded
                        ? Icons.analytics_outlined
                        : Icons.fitness_center_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(
                    expand.isExpanded ? 'Stats' : 'Exercises',
                  ),
                  initiallyExpanded: true,
                  controller: expand,
                  children: [
                    lastWorkout,
                  ],
                ),
              ),
            ),
          Expanded(
            child: WorkoutHistory(
              gymSets: latestSets,
              onSelect: (id) {
                setState(() {
                  if (selected.contains(id)) {
                    selected.remove(id);
                  } else {
                    selected.add(id);
                  }
                });
              },
              onEdit: (gymSet) async => onEdit(gymSet),
              selected: selected,
              scroll: scroll,
              groupHistory: groupHistory,
            ),
          ),
        ],
      ),
    );
  }

  AppSearch buildAppBar() {
    return AppSearch(
      selected: selected,
      filter: Filters(
        full: false,
        repsGtCtrl: repsGt,
        repsLtCtrl: repsLt,
        weightGtCtrl: weightGt,
        weightLtCtrl: weightLt,
        setStream: _resetLimitAndApplyFilters,
        endDate: endDate,
        startDate: startDate,
        setEnd: (value) {
          endDate = value;

          _applyFilters();
        },
        setStart: (value) {
          startDate = value;

          _applyFilters();
        },
        category: category,
        setCategory: (value) {
          category = value;

          _applyFilters();
        },
      ),
      onChange: (value) {
        search = value;
        _applyFilters();
      },
      onClear: () {
        setState(() {
          selected.clear();
        });
      },
      onDelete: () async {
        await context.read<GymSetsRepository>().deleteGymSetsById(
              selected.toList(),
            );

        if (!mounted) {
          return;
        }

        setState(() {
          selected.clear();
        });
      },
      onSelect: () {
        if (gymSets.isEmpty) {
          return;
        }

        setState(() {
          selected.addAll(
            gymSets
                .map(
                  (gymSet) => gymSet.id,
                )
                .whereType<int>(),
          );
        });
      },
      onEdit: (gymSet) async => onEdit(gymSet),
    );
  }

  void onEdit(GymSet gymSet) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditSetPage(
          gymSet: gymSet,
        ),
      ),
    );

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> onAdd() async {
    final settings = context.read<SettingsRepository>();
    final exercisesRepo = context.read<ExercisesRepository>();

    var bodyWeight = 0.0;

    if (settings.isEnabled(
      key: 'show_body_weight',
    )) {
      bodyWeight = (await getBodyWeight(context))?.weight ?? 0.0;
    }

    if (!mounted) {
      return;
    }

    final now = DateTime.now().toLocal();

    GymSet? gymSet;

    if (gymSets.isNotEmpty) {
      final previous = gymSets.first;

      if (previous.exercise != null) {
        gymSet = previous.copyWith(
          bodyWeight: bodyWeight,
          created: now,
        );
      }
    }

    if (gymSet == null) {
      final exercise = exercisesRepo.getExerciseById(1);

      if (exercise == null) {
        toast(
          'No default exercise is available',
        );
        return;
      }

      gymSet = GymSet(
        id: 0,
        bodyWeight: bodyWeight,
        restMs: const Duration(
          minutes: 3,
          seconds: 30,
        ).inMilliseconds,
        reps: 0,
        created: now,
        unit: 'kg',
        weight: 0,
        duration: 0,
        distance: 0,
        hidden: false,
        exerciseId: exercise.id!,
        exercise: exercise,
      );
    }

    final exercise = gymSet.exercise;

    if (exercise == null) {
      toast(
        'Exercise could not be loaded',
      );
      return;
    }

    final strengthUnit = settings.getSetting(
      key: 'strength_unit',
    );

    final cardioUnit = settings.getSetting(
      key: 'cardio_unit',
    );

    if (!exercise.cardio) {
      if (strengthUnit != 'last-entry') {
        gymSet = gymSet.copyWith(
          unit: strengthUnit,
        );
      }
    } else {
      if (cardioUnit != 'last-entry') {
        gymSet = gymSet.copyWith(
          unit: cardioUnit,
        );
      }
    }

    if (!mounted) {
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditSetPage(
          gymSet: gymSet!,
        ),
      ),
    );

    setState(() {});
  }

  void _resetLimitAndApplyFilters() {
    if (!mounted) {
      return;
    }
    _applyFilters();
  }

  void _applyFilters() {
    if (!mounted) {
      return;
    }

    Iterable<GymSet> query = latestSets.where(
      (set) => !set.hidden && set.exercise != null,
    );

    final terms = search.toLowerCase().split(' ').where(
          (term) => term.isNotEmpty,
        );

    for (final term in terms) {
      query = query.where(
        (set) => set.exercise!.name.toLowerCase().contains(term),
      );
    }

    if (category != null) {
      query = query.where(
        (set) => set.exercise!.category == category,
      );
    }

    if (startDate != null) {
      query = query.where(
        (set) =>
            set.created.isAfter(startDate!) ||
            set.created.isAtSameMomentAs(
              startDate!,
            ),
      );
    }

    if (endDate != null) {
      query = query.where(
        (set) =>
            set.created.isBefore(endDate!) ||
            set.created.isAtSameMomentAs(
              endDate!,
            ),
      );
    }

    if (repsGt.text.isNotEmpty) {
      final value = double.tryParse(repsGt.text) ?? 0;

      query = query.where(
        (set) => set.reps > value && !set.exercise!.cardio,
      );
    }

    if (repsLt.text.isNotEmpty) {
      final value = double.tryParse(repsLt.text) ?? 0;

      query = query.where(
        (set) => set.reps < value && !set.exercise!.cardio,
      );
    }

    if (weightGt.text.isNotEmpty) {
      final value = double.tryParse(weightGt.text) ?? 0;

      query = query.where(
        (set) => set.weight > value && !set.exercise!.cardio,
      );
    }

    if (weightLt.text.isNotEmpty) {
      final value = double.tryParse(weightLt.text) ?? 0;

      query = query.where(
        (set) => set.weight < value && !set.exercise!.cardio,
      );
    }

    filteredGymSets = query.toList();

    setState(() {});
  }

  List<ExerciseItem> _getExerciseItems(
    List<GymSet> sets,
  ) {
    final exerciseItems = <ExerciseItem>[];

    for (final gymSet in sets) {
      final exercise = gymSet.exercise;

      if (exercise == null || exercise.id == null) {
        continue;
      }

      final day = DateUtils.dateOnly(
        gymSet.created,
      );

      final index = exerciseItems.indexWhere(
        (item) =>
            isSameDay(
              item.date,
              day,
            ) &&
            item.exerciseId == exercise.id,
      );

      if (index == -1) {
        exerciseItems.add(
          ExerciseItem(
            name: exercise.name,
            sets: [gymSet],
            date: day,
            exerciseId: exercise.id!,
          ),
        );
      } else {
        exerciseItems[index].sets.add(gymSet);
      }
    }

    return exerciseItems;
  }

  void getStats(List<GymSet> sets) async {
    try {
      final lw = await getLastWorkout(sets);
      setState(() {
        lastWorkout = lw;
      });
    } catch (_) {}
  }

  Future<material.Widget> getLastWorkout(
    List<GymSet> sets,
  ) async {
    String plural(int s) => s > 1 ? 's' : '';
    if (sets.isEmpty) {
      return const SizedBox.shrink();
    }

    var sortedDays = _getExerciseItems(sets);

    if (sortedDays.isEmpty) {
      return const SizedBox.shrink();
    }

    sortedDays.sort(
      (a, b) => a.date.compareTo(b.date),
    );

    final totalWorkout = sortedDays
        .where(
          (day) => day.date == sortedDays.first.date,
        )
        .toList();

    if (totalWorkout.isEmpty) {
      return const SizedBox.shrink();
    }

    final allWorkoutSets = totalWorkout
        .expand(
          (exercise) => exercise.sets,
        )
        .toList();

    final cardioSet = allWorkoutSets
        .where(
          (set) => set.exercise!.cardio,
        )
        .firstOrNull;

    final strengthSet = allWorkoutSets
        .where(
          (set) => !set.exercise!.cardio,
        )
        .firstOrNull;

    final cardioUnit = cardioSet?.unit ?? '';

    final weightUnit = strengthSet?.unit ?? '';

    var totalSets = 0;
    var totalReps = 0;

    final totalExercises = totalWorkout.length;

    double totalDistance = 0;
    double totalWeight = 0;

    for (final exercise in totalWorkout) {
      totalSets += exercise.sets.length;

      for (final set in exercise.sets) {
        totalReps += set.reps.toInt();

        totalDistance += set.distance ?? 0;

        totalWeight += set.weight * set.reps;
      }
    }

    return Selector<SettingsRepository, String>(
      selector: (
        context,
        settings,
      ) {
        return settings.getSetting(
          key: 'short_date_format',
        );
      },
      builder: (
        context,
        dateFormat,
        child,
      ) {
        final formattedDate = DateFormat(
          dateFormat,
        ).format(
          sortedDays.first.date,
        );

        final daysSince = DateTime.now()
            .difference(
              sortedDays.first.date,
            )
            .inDays;

        final lastWorkoutText = daysSince == 0
            ? 'You last worked out today.'
            : daysSince == 1
                ? 'You last worked out yesterday.'
                : 'You last worked out '
                    '$daysSince days ago on '
                    '$formattedDate.';

        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
          ),
          child: ListTile(
            title: Text(
              lastWorkoutText,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(
                  height: 16,
                ),
                const Divider(),
                Text(
                  '$totalExercises exercise'
                  '${plural(totalExercises)} completed',
                  textAlign: TextAlign.left,
                ),
                Text(
                  '$totalSets set'
                  '${plural(totalSets)} completed',
                  textAlign: TextAlign.left,
                ),
                Text(
                  '$totalReps rep'
                  '${plural(totalReps)} completed',
                  textAlign: TextAlign.left,
                ),
                if (totalWeight > 0)
                  Text(
                    '${num.parse(totalWeight.toStringAsFixed(3))}'
                    '$weightUnit total lifted',
                    textAlign: TextAlign.left,
                  ),
                if (totalDistance > 0)
                  Text(
                    '$totalDistance'
                    '$cardioUnit total travelled',
                    textAlign: TextAlign.left,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

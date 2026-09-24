import 'package:flutter/material.dart' as material;
import 'package:flutter/material.dart';
import 'package:fossfit/animated_fab.dart';
import 'package:fossfit/app_search.dart';
import 'package:fossfit/db/repositories/exercise_repository.dart';
import 'package:fossfit/db/repositories/gym_sets_repository.dart';
import 'package:fossfit/db/repositories/settings_repository.dart';
import 'package:fossfit/filters.dart';
import 'package:fossfit/models/exercise_model.dart';
import 'package:fossfit/models/gym_set_model.dart';
import 'package:fossfit/sets/edit_set_page.dart';
import 'package:fossfit/sets/edit_sets_page.dart';
import 'package:fossfit/sets/history_collapsed.dart';
import 'package:fossfit/sets/history_list.dart';
import 'package:fossfit/utils.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class HistoryPage extends StatefulWidget {
  final TabController tabController;

  const HistoryPage({
    super.key,
    required this.tabController,
  });

  @override
  State<HistoryPage> createState() => HistoryPageState();
}

class HistoryPageState extends State<HistoryPage> with AutomaticKeepAliveClientMixin {
  final GlobalKey<NavigatorState> navKey = GlobalKey<NavigatorState>();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    widget.tabController.addListener(_onTabChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Sync when HistoryPage is first created.
    _refreshRepository();
  }

  @override
  void didUpdateWidget(covariant HistoryPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.tabController != widget.tabController) {
      oldWidget.tabController.removeListener(_onTabChanged);
      widget.tabController.addListener(_onTabChanged);
    }
  }

  void _onTabChanged() {
    if (!mounted) {
      return;
    }

    if (widget.tabController.indexIsChanging) {
      return;
    }

    final settings = context.read<SettingsRepository>();

    final tabs = settings
        .getSetting(
          key: 'tabs',
        )
        .split(',')
        .map((tab) => tab.trim())
        .where((tab) => tab.isNotEmpty)
        .toList();

    final historyIndex = tabs.indexOf('HistoryPage');

    if (historyIndex < 0) {
      return;
    }

    if (widget.tabController.index == historyIndex) {
      _refreshRepository();
    }
  }

  Future<void> _refreshRepository() async {
    if (!mounted) {
      return;
    }

    final setsRepo = context.read<GymSetsRepository>();

    await setsRepo.loadAll();
  }

  @override
  void dispose() {
    widget.tabController.removeListener(_onTabChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return NavigatorPopHandler(
      onPopWithResult: (result) {
        final navigator = navKey.currentState;

        if (navigator == null || !navigator.canPop()) {
          return;
        }

        final settings = context.read<SettingsRepository>();

        final tabs = settings
            .getSetting(
              key: 'tabs',
            )
            .split(',')
            .map((tab) => tab.trim())
            .where((tab) => tab.isNotEmpty)
            .toList();

        final historyIndex = tabs.indexOf('HistoryPage');

        if (widget.tabController.index == historyIndex) {
          navigator.pop();
        }
      },
      child: Navigator(
        key: navKey,
        onGenerateRoute: (settings) {
          return MaterialPageRoute(
            builder: (context) => _HistoryPageWidget(
              navigatorKey: navKey,
            ),
            settings: settings,
          );
        },
      ),
    );
  }
}

class _HistoryPageWidget extends StatefulWidget {
  final GlobalKey<NavigatorState> navigatorKey;

  const _HistoryPageWidget({
    required this.navigatorKey,
  });

  @override
  State<_HistoryPageWidget> createState() => _HistoryPageWidgetState();
}

class _HistoryPageWidgetState extends State<_HistoryPageWidget> {
  final repsGt = TextEditingController();
  final repsLt = TextEditingController();
  final weightGt = TextEditingController();
  final weightLt = TextEditingController();

  final scroll = ScrollController();
  final expand = ExpansibleController();

  List<GymSet> gymSets = [];
  List<GymSet> _allGymSets = [];

  Widget lastWorkout = const SizedBox.shrink();

  final Set<int> selected = {};

  String search = '';
  int limit = 100;

  DateTime? startDate;
  DateTime? endDate;
  String? category;

  bool _statsLoading = false;

  SettingsRepository get settings => context.read<SettingsRepository>();

  @override
  void initState() {
    super.initState();

    scroll.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _syncFromRepository();
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
      expand.collapse();
    } else {
      expand.expand();
    }
  }

  /// Copies the latest repository data into this page's local state.
  ///
  /// The repository is the source of truth.
  void _syncFromRepository() {
    if (!mounted) {
      return;
    }

    final setsRepo = context.read<GymSetsRepository>();

    final repositorySets = setsRepo.gymsets;

    if (_sameGymSets(_allGymSets, repositorySets)) {
      return;
    }

    setState(() {
      _allGymSets = List<GymSet>.of(repositorySets);
    });

    _applyFilters();

    if (settings.isEnabled(key: 'stats_panel')) {
      _refreshStats();
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsRepo = context.watch<SettingsRepository>();

    return Consumer<GymSetsRepository>(
      builder: (
        context,
        setsRepo,
        child,
      ) {
        final repositorySets = setsRepo.gymsets;

        // Repository changes are the primary way this page updates.
        //
        // This is deliberately scheduled after build because _applyFilters()
        // eventually calls setState().
        if (!_sameGymSets(_allGymSets, repositorySets)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) {
              return;
            }

            _syncFromRepository();
          });
        }

        final showStats = settingsRepo.isEnabled(
          key: 'stats_panel',
        );

        return Scaffold(
          resizeToAvoidBottomInset: false,
          body: Column(
            children: [
              AppSearch(
                filter: Filters(
                  repsGtCtrl: repsGt,
                  repsLtCtrl: repsLt,
                  weightGtCtrl: weightGt,
                  weightLtCtrl: weightLt,
                  setStream: _resetLimitAndApplyFilters,
                  endDate: endDate,
                  startDate: startDate,
                  setEnd: (value) {
                    setState(() {
                      endDate = value;
                      limit = 100;
                    });

                    _applyFilters();
                  },
                  setStart: (value) {
                    setState(() {
                      startDate = value;
                      limit = 100;
                    });

                    _applyFilters();
                  },
                  category: category,
                  setCategory: (value) {
                    setState(() {
                      category = value;
                      limit = 100;
                    });

                    _applyFilters();
                  },
                ),
                onShare: _onShare,
                onChange: (value) {
                  setState(() {
                    search = value;
                    limit = 100;
                  });

                  _applyFilters();
                },
                onClear: () {
                  setState(() {
                    selected.clear();
                  });
                },
                onDelete: () async {
                  await setsRepo.deleteGymSetsById(
                    selected.toList(),
                  );

                  if (!mounted) {
                    return;
                  }

                  setState(() {
                    selected.clear();
                  });

                  // deleteGymSetsById already updates the repository and
                  // notifies listeners. This refresh is only needed if there
                  // are changes made elsewhere at the database level.
                  await _refreshRepository();
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
                selected: selected,
                onEdit: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditSetsPage(
                        ids: selected.toList(),
                      ),
                    ),
                  ).then((_) {
                    _refreshRepository();
                  });
                },
              ),
              if (gymSets.isEmpty)
                const ListTile(
                  title: Text('No entries yet'),
                  subtitle: Text(
                    'Complete some sets to see them here',
                  ),
                ),
              if (gymSets.isNotEmpty && showStats)
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
                        expand.isExpanded ? Icons.analytics_outlined : Icons.history_outlined,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      title: Text(
                        expand.isExpanded ? 'Stats' : 'History',
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
                child: Builder(
                  builder: (context) {
                    final groupHistory = settingsRepo.isEnabled(
                      key: 'group_history',
                    );

                    if (groupHistory) {
                      final exerciseItems = _getExerciseItems(_allGymSets);

                      return HistoryCollapsed(
                        scroll: scroll,
                        days: exerciseItems.reversed.toList(),
                        onSelect: (id) {
                          setState(() {
                            if (selected.contains(id)) {
                              selected.remove(id);
                            } else {
                              selected.add(id);
                            }
                          });
                        },
                        selected: selected,
                        onNext: () {
                          setState(() {
                            limit += 100;
                          });

                          _applyFilters();
                        },
                      );
                    }

                    return HistoryList(
                      scroll: scroll,
                      sets: gymSets,
                      onSelect: (id) {
                        setState(() {
                          if (selected.contains(id)) {
                            selected.remove(id);
                          } else {
                            selected.add(id);
                          }
                        });
                      },
                      selected: selected,
                      onNext: () {
                        setState(() {
                          limit += 100;
                        });

                        _applyFilters();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          floatingActionButton: AnimatedFab(
            onPressed: onAdd,
            label: const Text('Add'),
            icon: const Icon(Icons.add),
            scroll: scroll,
          ),
        );
      },
    );
  }

  Future<void> _refreshRepository() async {
    if (!mounted) {
      return;
    }

    final setsRepo = context.read<GymSetsRepository>();

    await setsRepo.loadAll();

    // loadAll() calls notifyListeners().
    //
    // Consumer above will therefore see the new data. We also explicitly
    // synchronize here so this page doesn't depend on another build cycle.
    if (!mounted) {
      return;
    }

    _syncFromRepository();
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

    // EditSetPage may have changed the database without this page itself
    // being rebuilt. Reload the repository when it returns.
    await _refreshRepository();
  }

  Future<void> _onShare() async {
    final selectedSets = gymSets
        .where(
          (gymSet) => selected.contains(gymSet.id),
        )
        .toList();

    final summaries = selectedSets
        .where(
          (set) => set.exercise != null,
        )
        .map(
          (set) => '${toString(set.reps)}x'
              '${toString(set.weight)}'
              '${set.unit} '
              '${set.exercise!.name}',
        )
        .join(', ');

    await SharePlus.instance.share(
      ShareParams(
        text: 'I just did $summaries',
      ),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      selected.clear();
    });
  }

  void _resetLimitAndApplyFilters() {
    if (!mounted) {
      return;
    }

    setState(() {
      limit = 100;
    });

    _applyFilters();
  }

  void _applyFilters() {
    if (!mounted) {
      return;
    }

    Iterable<GymSet> query = _allGymSets.where(
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

    final filtered = query.take(limit).toList();

    setState(() {
      gymSets = filtered;
    });
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

  void _refreshStats() {
    if (!mounted || _statsLoading) {
      return;
    }

    _statsLoading = true;

    final sets = List<GymSet>.of(
      gymSets,
    );

    getLastWorkout(sets)
        .then(
          (widget) {
            if (!mounted) {
              return;
            }

            setState(() {
              lastWorkout = widget;
            });
          },
        )
        .catchError(
          (_) {},
        )
        .whenComplete(
          () {
            _statsLoading = false;
          },
        );
  }

  Future<material.Widget> getLastWorkout(
    List<GymSet> sets,
  ) async {
    DateTime dayOnly(DateTime date) {
      return DateTime(
        date.year,
        date.month,
        date.day,
      );
    }

    String plural(int value) {
      return value > 1 ? 's' : '';
    }

    final today = dayOnly(
      DateTime.now(),
    );

    if (sets.isEmpty) {
      return const SizedBox.shrink();
    }

    final validDates = sets
        .map(
          (set) => dayOnly(
            set.created,
          ),
        )
        .where(
          (date) => !date.isAfter(today),
        )
        .toList();

    if (validDates.isEmpty) {
      return const SizedBox.shrink();
    }

    final mostRecentDay = validDates.reduce(
      (a, b) => a.isAfter(b) ? a : b,
    );

    final result = sets
        .where(
          (set) => dayOnly(set.created) == mostRecentDay,
        )
        .toList();

    var sortedDays = _getExerciseItems(result);

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

  bool _sameGymSets(
    List<GymSet> a,
    List<GymSet> b,
  ) {
    if (identical(a, b)) {
      return true;
    }

    if (a.length != b.length) {
      return false;
    }

    for (var i = 0; i < a.length; i++) {
      final aSet = a[i];
      final bSet = b[i];

      if (aSet.id != bSet.id) {
        return false;
      }

      // Also compare values that can change while keeping the same ID.
      if (aSet.created != bSet.created ||
          aSet.weight != bSet.weight ||
          aSet.reps != bSet.reps ||
          aSet.distance != bSet.distance ||
          aSet.duration != bSet.duration ||
          aSet.hidden != bSet.hidden ||
          aSet.unit != bSet.unit) {
        return false;
      }

      if (aSet.exercise?.id != bSet.exercise?.id) {
        return false;
      }
    }

    return true;
  }
}

import 'dart:io';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/material.dart';
import 'package:fossfit/animated_fab.dart';
import 'package:fossfit/app_search.dart';
import 'package:fossfit/constants.dart';
import 'package:fossfit/db/repositories/exercise_repository.dart';
import 'package:fossfit/db/repositories/gym_sets_repository.dart';
import 'package:fossfit/db/repositories/settings_repository.dart';
import 'package:fossfit/graph/add_exercise_page.dart';
import 'package:fossfit/graph/cardio_data.dart';
import 'package:fossfit/graph/cardio_page.dart';
import 'package:fossfit/graph/flex_line.dart';
import 'package:fossfit/graph/global_progress_page.dart';
import 'package:fossfit/graph/strength_page.dart';
import 'package:fossfit/graphs_filters.dart';
import 'package:fossfit/models/constants.dart';
import 'package:fossfit/models/exercise_model.dart';
import 'package:fossfit/models/gym_set_model.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class GraphsPage extends StatefulWidget {
  final TabController tabController;

  const GraphsPage({
    super.key,
    required this.tabController,
  });

  @override
  createState() => GraphsPageState();
}

class GraphsPageState extends State<GraphsPage>
    with AutomaticKeepAliveClientMixin {
  late List<GymSet> sets = [];
  late List<Exercise> exercises = [];

  final Set<Exercise> selected = {};
  final GlobalKey<NavigatorState> navKey = GlobalKey<NavigatorState>();
  final Map<int, ExpansibleController> controllers = {};
  int? expandedIndex = 0;
  String search = '';
  String? category;

  final scroll = ScrollController();

  bool extendFab = true;
  int total = 0;

  GraphSort sort = GraphSort.dateDesc;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    sets = context.watch<GymSetsRepository>().gymsets;
    exercises = context.watch<ExercisesRepository>().exercises;

    return NavigatorPopHandler(
      onPopWithResult: (result) {
        if (navKey.currentState!.canPop() == false) return;

        final settings = context.watch<SettingsRepository>();

        final graphsIndex =
            settings.getSetting(key: 'tabs').split(',').indexOf('GraphsPage');

        if (widget.tabController.index == graphsIndex) {
          Navigator.of(navKey.currentContext!).pop();
        }
      },
      child: Navigator(
        key: navKey,
        onGenerateRoute: (settings) => MaterialPageRoute(
          builder: (context) => graphsPage(),
          settings: settings,
        ),
      ),
    );
  }

  void longPressGlobal() {
    showModalBottomSheet(
      useRootNavigator: true,
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.visibility_off),
                title: const Text('Hide global progress'),
                onTap: () {
                  context.read<SettingsRepository>().setSetting(
                        category: SettingCategory.appearance,
                        key: 'show_global_progress',
                        value: '0',
                      );

                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.clear),
                title: const Text('Cancel'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  LineTouchTooltipData tooltipData(
    List<dynamic> data,
    String unit,
    String format,
  ) {
    return LineTouchTooltipData(
      fitInsideVertically: true,
      fitInsideHorizontally: true,
      getTooltipColor: (touch) => Theme.of(context).colorScheme.surface,
      getTooltipItems: (touchedSpots) {
        final row = data.elementAt(touchedSpots.last.spotIndex);
        final created = DateFormat(format).format(row.created);

        String text;

        if (row is CardioData) {
          text = "${row.value} ${row.unit} / min";
        } else {
          text = "${row.reps} x ${row.value.toStringAsFixed(2)}$unit $created";
        }

        return [
          LineTooltipItem(
            text,
            TextStyle(
              color: Theme.of(context).textTheme.bodyLarge!.color,
            ),
          ),
          if (touchedSpots.length > 1) null,
        ];
      },
    );
  }

  Widget getPeek(
    GymSet gymSet,
    List<dynamic> data,
    String format,
  ) {
    final List<FlSpot> spots = [];

    for (var index = 0; index < data.length; index++) {
      spots.add(
        FlSpot(
          index.toDouble(),
          data[index].value,
        ),
      );
    }

    return material.SizedBox(
      height: MediaQuery.of(context).size.height * 0.15,
      child: material.Padding(
        padding: const EdgeInsets.only(
          right: 48.0,
          top: 48.0,
          left: 48.0,
          bottom: 8.0,
        ),
        child: FlexLine(
          data: data,
          spots: spots,
          tooltipData: () => tooltipData(
            data,
            gymSet.unit,
            format,
          ),
          hideBottom: true,
          hideLeft: true,
        ),
      ),
    );
  }

  List<GymSet> _latestSetsByExercise(List<GymSet> gymSets) {
    final latest = <int, GymSet>{};

    for (final gymSet in gymSets) {
      if (gymSet.exercise == null) continue;

      final existing = latest[gymSet.exerciseId];

      if (existing == null || gymSet.created.isAfter(existing.created)) {
        latest[gymSet.exerciseId] = gymSet;
      }
    }

    return latest.values.toList();
  }

  Scaffold graphsPage() {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Builder(
        builder: (context) {
          if (exercises.isEmpty) {
            return const SizedBox();
          }

          final terms =
              search.toLowerCase().split(" ").where((term) => term.isNotEmpty);

          var exerciseSets = _latestSetsByExercise(sets);

          if (category != null) {
            exerciseSets = exerciseSets
                .where(
                  (gymSet) => gymSet.exercise!.category == category,
                )
                .toList();
          }

          for (final term in terms) {
            exerciseSets = exerciseSets
                .where(
                  (gymSet) =>
                      gymSet.exercise!.name.toLowerCase().contains(term),
                )
                .toList();
          }

          switch (sort) {
            case GraphSort.dateDesc:
              exerciseSets.sort(
                (a, b) => b.created.compareTo(a.created),
              );
              break;

            case GraphSort.dateAsc:
              exerciseSets.sort(
                (a, b) => a.created.compareTo(b.created),
              );
              break;

            case GraphSort.name:
              exerciseSets.sort(
                (a, b) => a.exercise!.name.toLowerCase().compareTo(
                      b.exercise!.name.toLowerCase(),
                    ),
              );
              break;
          }

          return material.Column(
            children: [
              AppSearch(
                filter: GraphsFilters(
                  category: category,
                  setCategory: (value) {
                    setState(() {
                      category = value;
                    });
                  },
                  sort: sort,
                  setSort: (value) {
                    setState(() {
                      sort = value;
                    });
                  },
                ),
                onShare: () {},
                onChange: (value) {
                  setState(() {
                    search = value;
                  });
                },
                onClear: () {
                  setState(() {
                    selected.clear();
                    total = 0;
                  });
                },
                onDelete: () {},
                onSelect: () {},
                selected: selected,
                onEdit: () {},
                confirmText: "This will delete $total records. Are you sure?",
              ),
              if (exerciseSets.isEmpty &&
                  !'global progress'.contains(
                    search.toLowerCase(),
                  ))
                ListTile(
                  title: const Text("No graphs found"),
                  subtitle: Text(
                    "Tap to create an exercise called $search",
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => AddExercisePage(
                          name: search,
                        ),
                      ),
                    );
                  },
                ),
              Selector<SettingsRepository, bool>(
                selector: (
                  p0,
                  settingsRepository,
                ) =>
                    settingsRepository.isEnabled(
                  key: 'show_global_progress',
                ),
                builder: (
                  context,
                  showGlobal,
                  child,
                ) =>
                    Expanded(
                  child: _buildExerciseList(
                    exerciseSets,
                    showGlobal,
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: AnimatedFab(
        onPressed: () => navKey.currentState!.push(
          MaterialPageRoute(
            builder: (context) => const AddExercisePage(),
          ),
        ),
        label: const Text('Add'),
        scroll: scroll,
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildExerciseList(
    List<GymSet> exerciseSets,
    bool showGlobalProgress,
  ) {
    final settings = context.watch<SettingsRepository>();

    final showPeekGraph = settings.isEnabled(key: 'peek_graph');
    final showImages = settings.isEnabled(key: 'show_images');

    final showGlobal = 'global graphs'.contains(search.toLowerCase()) &&
        category == null &&
        showGlobalProgress;

    final itemCount = exerciseSets.length + (showGlobal ? 1 : 0) + 1;

    return Padding(
      padding: EdgeInsets.all(4),
      child: ListView.builder(
        controller: scroll,
        padding: const EdgeInsets.only(
          bottom: 50,
          top: 8,
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          if (showGlobal && index == 0) {
            return material.Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 8,
              ),
              child: ListTile(
                leading: const Icon(Icons.language),
                title: const Text("Global progress"),
                subtitle: const Text(
                  "A chart grouped by category",
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        GlobalProgressPage(tabController: widget.tabController),
                  ),
                ),
                onLongPress: longPressGlobal,
              ),
            );
          }

          final exerciseIndex = index - (showGlobal ? 1 : 0);

          // Bottom spacer.
          if (exerciseIndex >= exerciseSets.length) {
            return const SizedBox(height: 96);
          }

          final gymSet = exerciseSets[exerciseIndex];
          final exercise = gymSet.exercise!;

          return _buildTile(
            showPeekGraph,
            gymSet,
            exercise,
            _getLeading(showImages, exercise),
          );
        },
      ),
    );
  }

  Widget _buildTile(
    bool showPeekGraph,
    GymSet lastSet,
    Exercise exercise,
    Widget? leading,
  ) {
    return showPeekGraph
        ? GestureDetector(
            onLongPress: () {
              _openGraph(exercise, lastSet);
            },
            child: ExpansionTile(
              leading: leading,
              title: Text(exercise.name),
              subtitle: _buildExerciseSubtitle(lastSet),
              controller: controllers.putIfAbsent(
                exercise.id!,
                ExpansibleController.new,
              ),
              initiallyExpanded: false,
              onExpansionChanged: (open) {
                if (open) {
                  for (var e in exercises) {
                    if (e.id != exercise.id) controllers[e.id]?.collapse();
                  }
                }
                setState(() {});
              },
              children: [
                _buildPeekGraph(lastSet),
              ],
            ),
          )
        : ListTile(
            leading: leading,
            title: Text(exercise.name),
            subtitle: _buildExerciseSubtitle(lastSet),
            onTap: () {
              _openGraph(exercise, lastSet);
            },
          );
  }

  Widget _buildExerciseSubtitle(GymSet gymSet) {
    final settings = context.read<SettingsRepository>();

    final format = settings.getSetting(
      key: 'short_date_format',
    );

    return Text(
      "Last completed: "
      "${DateFormat(format).format(gymSet.created.toLocal())}",
    );
  }

  Widget _buildPeekGraph(GymSet gymSet) {
    final repo = context.read<GymSetsRepository>();

    return Consumer<SettingsRepository>(
      builder: (
        context,
        settings,
        child,
      ) {
        return FutureBuilder<List<dynamic>>(
          future: gymSet.exercise!.cardio
              ? repo.getCardioData(
                  exerciseId: gymSet.exercise!.id!,
                )
              : repo.getStrengthData(
                  target: gymSet.unit,
                  exerciseId: gymSet.exercise!.id!,
                  metric: StrengthMetric.bestWeight,
                  period: Period.day,
                  start: null,
                  end: null,
                  limit: 20,
                ),
          builder: (
            context,
            snapshot,
          ) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (snapshot.hasError || snapshot.data == null) {
              return const SizedBox(
                height: 40,
              );
            }

            return getPeek(
              gymSet,
              snapshot.data!,
              settings.getSetting(
                key: 'short_date_format',
              ),
            );
          },
        );
      },
    );
  }

  void _openGraph(Exercise exercise, GymSet gymSet) async {
    var repo = context.read<GymSetsRepository>();
    if (!context.mounted) return;

    if (exercise.cardio) {
      final data = await repo.getCardioData(
        target: gymSet.unit,
        exerciseId: exercise.id!,
        metric: CardioMetric.pace,
        period: Period.day,
        start: null,
        end: null,
      );
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CardioPage(
            tabCtrl: widget.tabController,
            exercise: exercise,
            unit: gymSet.unit,
            data: data,
          ),
        ),
      );
      return;
    }

    final data = await repo.getStrengthData(
      target: gymSet.unit,
      exerciseId: gymSet.exerciseId,
      metric: StrengthMetric.bestWeight,
      period: Period.day,
      start: null,
      end: null,
      limit: 20,
    );
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StrengthPage(
          exercise: exercise,
          unit: gymSet.unit,
          data: data,
          tabCtrl: widget.tabController,
        ),
      ),
    );
  }

  Widget _getLeading(bool showImages, Exercise exercise) {
    return showImages && (exercise.image != null && exercise.image != '')
        ? Container(
            width: 24,
            height: 24,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Image.file(
              width: 24,
              height: 24,
              File(exercise.image!),
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.error),
            ),
          )
        : Container(
            width: 24,
            height: 24,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                exercise.name[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          );
  }
}

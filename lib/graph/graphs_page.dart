import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/material.dart';
import 'package:fossfit/animated_fab.dart';
import 'package:fossfit/app_search.dart';
import 'package:fossfit/constants.dart';
import 'package:fossfit/db/repositories/gym_sets_repository.dart';
import 'package:fossfit/db/repositories/plan_exercises_repository.dart';
import 'package:fossfit/db/repositories/plans_repository.dart';
import 'package:fossfit/db/repositories/settings_repository.dart';
import 'package:fossfit/graph/add_exercise_page.dart';
import 'package:fossfit/graph/cardio_data.dart';
import 'package:fossfit/graph/edit_graph_page.dart';
import 'package:fossfit/graph/flex_line.dart';
import 'package:fossfit/graph/global_progress_page.dart';
import 'package:fossfit/graphs_filters.dart';
import 'package:fossfit/models/constants.dart';
import 'package:fossfit/models/gym_sets_model.dart';
import 'package:fossfit/utils.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sticky_headers/sticky_headers/widget.dart';

import 'graph_tile.dart';

class GraphsPage extends StatefulWidget {
  final TabController tabController;

  const GraphsPage({super.key, required this.tabController});

  @override
  createState() => GraphsPageState();
}

class GraphsPageState extends State<GraphsPage> with AutomaticKeepAliveClientMixin {
  late List<GymSets> sets = [];

  final Set<String> selected = {};
  final GlobalKey<NavigatorState> navKey = GlobalKey<NavigatorState>();
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
    return NavigatorPopHandler(
      onPopWithResult: (result) {
        if (navKey.currentState!.canPop() == false) return;
        final settings = context.watch<SettingsRepository>();
        final graphsIndex = settings.getSetting(key: 'tabs').split(',').indexOf('GraphsPage');
        if (widget.tabController.index == graphsIndex) Navigator.of(navKey.currentContext!).pop();
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

  void onDelete() async {
    final plansRepo = context.read<PlansRepository>();
    final copy = selected.toList();
    var gymRepo = context.read<GymSetsRepository>();
    var planExerciseRepo = context.read<PlanExercisesRepository>();

    setState(() {
      selected.clear();
    });
    var gymsetIds = sets.where((t) => copy.contains(t.name)).map((t) => t.id!).toList();
    await gymRepo.deleteGymSetsById(gymsetIds);

    final plans = plansRepo.plans;

    for (final plan in plans) {
      for (final exercise in copy) {
        await planExerciseRepo.deletePlanExerciseByNameAndPlanId(exercise, plan.id!);
      }
    }
    await plansRepo.updatePlans(null);
  }

  LineTouchTooltipData tooltipData(
    List<dynamic> data,
    String unit,
    String format,
  ) {
    return LineTouchTooltipData(
      getTooltipColor: (touch) => Theme.of(context).colorScheme.surface,
      getTooltipItems: (touchedSpots) {
        final row = data.elementAt(touchedSpots.last.spotIndex);
        final created = DateFormat(format).format(row.created);

        String text;
        if (row is CardioData)
          text = "${row.value} ${row.unit} / min";
        else
          text = "${row.reps} x ${row.value.toStringAsFixed(2)}$unit $created";

        return [
          LineTooltipItem(
            text,
            TextStyle(color: Theme.of(context).textTheme.bodyLarge!.color),
          ),
          if (touchedSpots.length > 1) null,
        ];
      },
    );
  }

  Widget getPeek(GymSets gymSet, List<dynamic> data, String format) {
    List<FlSpot> spots = [];
    for (var index = 0; index < data.length; index++) {
      spots.add(FlSpot(index.toDouble(), data[index].value));
    }

    return material.SizedBox(
      height: MediaQuery.of(context).size.height * 0.15,
      child: material.Padding(
        padding: const EdgeInsets.only(right: 48.0, top: 8.0, left: 48, bottom: 8),
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

  Scaffold graphsPage() {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Builder(
        builder: (context) {
          if (sets.isEmpty) return const SizedBox();

          final terms = search.toLowerCase().split(" ").where((term) => term.isNotEmpty);
          var stream = sets.where((gymSet) {
            if (category != null) {
              return gymSet.category == category;
            }
            return true;
          });

          for (final term in terms) {
            stream = stream.where(
              (gymSet) => gymSet.name.toLowerCase().contains(term),
            );
          }

          final gymSets = stream.toList();
          switch (sort) {
            case GraphSort.dateDesc:
              gymSets.sort(
                (a, b) => b.created.compareTo(a.created),
              );
              break;

            case GraphSort.dateAsc:
              gymSets.sort(
                (a, b) => a.created.compareTo(b.created),
              );
              break;

            case GraphSort.name:
              gymSets.sort(
                (a, b) => a.name.toLowerCase().compareTo(
                      b.name.toLowerCase(),
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
                onShare: onShare,
                onChange: (value) {
                  setState(() {
                    search = value;
                  });
                },
                onClear: () => setState(() {
                  selected.clear();
                }),
                onDelete: onDelete,
                onSelect: () => setState(() {
                  selected.addAll(
                    gymSets.map((gymSet) => gymSet.name),
                  );
                }),
                selected: selected,
                onEdit: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditGraphPage(
                      name: selected.first,
                    ),
                  ),
                ),
                confirmText: "This will delete $total records. Are you sure?",
              ),
              if (gymSets.isEmpty && !'global progress'.contains(search.toLowerCase()))
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
                selector: (p0, settingsRepository) => settingsRepository.isEnabled(key: 'show_global_progress'),
                builder: (context, showGlobal, child) => Expanded(
                  child: (sort == GraphSort.name)
                      ? _sortedGraphList(gymSets, showGlobal)
                      : _stickyHeadersGraphList(gymSets, showGlobal),
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
        label: Text('Add'),
        scroll: scroll,
        icon: Icon(Icons.add),
      ),
    );
  }

  Future<void> onShare() async {
    final copy = selected.toList();
    setState(() {
      selected.clear();
    });
    final sets = (this.sets)
        .where(
          (gymSet) => copy.contains(gymSet.name),
        )
        .toList();
    final text = sets
        .map(
          (gymSet) => "${toString(gymSet.reps)}x${toString(gymSet.weight)}${gymSet.unit} ${gymSet.name}",
        )
        .join(', ');
    await SharePlus.instance.share(ShareParams(text: "I just did $text"));
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
                        category: SettingCategory.appearance.name,
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

  material.ListView _stickyHeadersGraphList(
    List<GymSets> gymSets,
    bool showGlobalProgress,
  ) {
    _grouped = _groupByDay(gymSets);
    var itemCount = _grouped.entries.length + 1;
    final showGlobal = 'global graphs'.contains(search.toLowerCase()) && category == null && showGlobalProgress;
    if (showGlobal) itemCount++;

    final settings = context.watch<SettingsRepository>();
    final showPeekGraph = settings.isEnabled(key: 'peek_graph') && _grouped.entries.firstOrNull != null;
    if (showPeekGraph) itemCount++;
    var repo = context.watch<GymSetsRepository>();
    return ListView.builder(
      itemCount: itemCount,
      controller: scroll,
      padding: const EdgeInsets.only(bottom: 50, top: 8),
      itemBuilder: (context, index) {
        int currentIdx = index;

        if (showGlobal) {
          if (index == 0) {
            return material.Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2),
              child: ListTile(
                leading: const Icon(Icons.language),
                title: const Text("Global progress"),
                subtitle: const Text("A chart grouped by category"),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const GlobalProgressPage(),
                  ),
                ),
                onLongPress: longPressGlobal,
              ),
            );
          }
          currentIdx--;
        }
        bool peek = showPeekGraph && currentIdx == 0;

        if (index == itemCount - 1) return const SizedBox(height: 96);

        if (showPeekGraph && currentIdx > 1) {
          currentIdx--;
        }

        final set = _grouped.entries.elementAtOrNull(currentIdx);
        if (set == null) return const SizedBox();
        final date = set.key;
        final sets = set.value;

        return StickyHeader(
          header: Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            alignment: Alignment.center,
            child: _buildSectionDivider(date),
          ),
          content: material.Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: List.generate(
              sets.length,
              (index) {
                return material.Column(
                  children: [
                    GraphTile(
                      selected: selected,
                      gymSet: set.value[index],
                      onSelect: (name) async {
                        if (selected.contains(name))
                          setState(() {
                            selected.remove(name);
                          });
                        else
                          setState(() {
                            selected.add(name);
                          });
                        final result = sets.where((t) => selected.contains(t.name)).length;
                        setState(() {
                          total = result;
                        });
                      },
                      tabCtrl: widget.tabController,
                    ),
                    if (peek && index == 0) ...[
                      Consumer<SettingsRepository>(
                        builder: (
                          BuildContext context,
                          SettingsRepository settings,
                          Widget? child,
                        ) {
                          if (_grouped.entries.firstOrNull == null) return const SizedBox();

                          return FutureBuilder(
                            builder: (context, snapshot) => snapshot.data != null
                                ? getPeek(
                                    _grouped.entries.first.value.first,
                                    snapshot.data!,
                                    settings.getSetting(key: 'short_date_format'),
                                  )
                                : const SizedBox(),
                            future: _grouped.entries.first.value.first.cardio
                                ? repo.getCardioData(
                                    name: _grouped.entries.first.value.first.name,
                                  )
                                : repo.getStrengthData(
                                    target: _grouped.entries.first.value.first.unit,
                                    name: _grouped.entries.first.value.first.name,
                                    metric: StrengthMetric.bestWeight,
                                    period: Period.day,
                                    start: null,
                                    end: null,
                                    limit: 20,
                                  ),
                          );
                        },
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  material.ListView _sortedGraphList(
    List<GymSets> gymSets,
    bool showGlobalProgress,
  ) {
    var itemCount = gymSets.length + 1;
    final showGlobal = 'global graphs'.contains(search.toLowerCase()) && category == null && showGlobalProgress;
    if (showGlobal) itemCount++;

    final settings = context.watch<SettingsRepository>();
    final showPeekGraph = settings.isEnabled(key: 'peek_graph') && gymSets.firstOrNull != null;
    if (showPeekGraph) itemCount++;

    var repo = context.watch<GymSetsRepository>();
    return ListView.builder(
      itemCount: itemCount,
      controller: scroll,
      padding: const EdgeInsets.only(bottom: 50, top: 8),
      itemBuilder: (context, index) {
        int currentIdx = index;

        if (showGlobal) {
          if (index == 0) {
            return material.Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2),
              child: ListTile(
                leading: const Icon(Icons.language),
                title: const Text("Global progress"),
                subtitle: const Text("A chart grouped by category"),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const GlobalProgressPage(),
                  ),
                ),
                onLongPress: longPressGlobal,
              ),
            );
          }
          currentIdx--;
        }

        if (showPeekGraph && currentIdx == 1) {
          return Consumer<SettingsRepository>(
            builder: (
              BuildContext context,
              SettingsRepository settings,
              Widget? child,
            ) {
              if (!showPeekGraph) return const SizedBox();
              if (gymSets.firstOrNull == null) return const SizedBox();

              return FutureBuilder(
                builder: (context, snapshot) => snapshot.data != null
                    ? getPeek(
                        gymSets.first,
                        snapshot.data!,
                        settings.getSetting(key: 'short_date_format'),
                      )
                    : const SizedBox(),
                future: gymSets.first.cardio
                    ? repo.getCardioData(name: gymSets.first.name)
                    : repo.getStrengthData(
                        target: gymSets.first.unit,
                        name: gymSets.first.name,
                        metric: StrengthMetric.bestWeight,
                        period: Period.day,
                        start: null,
                        end: null,
                        limit: 20,
                      ),
              );
            },
          );
        }

        if (index == itemCount - 1) return const SizedBox(height: 96);

        if (showPeekGraph && currentIdx > 1) {
          currentIdx--;
        }

        final set = gymSets.elementAtOrNull(currentIdx);
        if (set == null) return const SizedBox();

        final previousItem = currentIdx > 0 ? gymSets[currentIdx - 1] : set;

        final bool showDivider = sort != GraphSort.name &&
            (currentIdx == 0 ||
                !isSameDay(
                  set.created.toLocal(),
                  previousItem.created.toLocal(),
                ));

        return material.Column(
          children: [
            if (showDivider)
              material.Row(
                children: [
                  const material.Expanded(child: Divider()),
                  const Icon(Icons.today),
                  const SizedBox(width: 4),
                  Selector<SettingsRepository, String>(
                    selector: (p0, p1) => p1.getSetting(key: 'short_date_format'),
                    builder: (context, format, child) => Text(
                      DateFormat(format).format(set.created.toLocal()),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const material.Expanded(child: Divider()),
                ],
              ),
            GraphTile(
              selected: selected,
              gymSet: set,
              onSelect: (name) async {
                if (selected.contains(name))
                  setState(() {
                    selected.remove(name);
                  });
                else
                  setState(() {
                    selected.add(name);
                  });
                final result = sets.where((t) => selected.contains(t.name)).length;
                setState(() {
                  total = result;
                });
              },
              tabCtrl: widget.tabController,
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionDivider(DateTime date) {
    final format = context.read<SettingsRepository>().getSetting(key: 'short_date_format');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const Expanded(child: Divider(thickness: 1)),
          const SizedBox(width: 4),
          const Icon(Icons.today, size: 16),
          const SizedBox(width: 4),
          Text(
            DateFormat(format).format(date),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 4),
          const Expanded(child: Divider(thickness: 1)),
        ],
      ),
    );
  }

  Map<DateTime, List<GymSets>> _grouped = {};
  Map<DateTime, List<GymSets>> _groupByDay(
    List<GymSets> sets,
  ) {
    final map = <DateTime, List<GymSets>>{};

    for (final set in sets) {
      final day = DateTime(
        set.created.year,
        set.created.month,
        set.created.day,
      );

      map.putIfAbsent(day, () => []);
      map[day]!.add(set);
    }

    // Optional: sort newest first
    final sortedKeys = map.keys.toList()
      ..sort(
        sort == GraphSort.dateDesc ? (a, b) => b.compareTo(a) : (a, b) => a.compareTo(b),
      );

    return {
      for (final key in sortedKeys) key: map[key]!,
    };
  }
}

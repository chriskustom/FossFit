import 'package:flutter/material.dart' as material;
import 'package:flutter/material.dart';
import 'package:fossfit/animated_fab.dart';
import 'package:fossfit/app_search.dart';
import 'package:fossfit/db/repositories/gym_sets_repository.dart';
import 'package:fossfit/db/repositories/settings_repository.dart';
import 'package:fossfit/filters.dart';
import 'package:fossfit/models/gym_set_model.dart';
import 'package:fossfit/sets/edit_set_page.dart';
import 'package:fossfit/sets/edit_sets_page.dart';
import 'package:fossfit/sets/history_collapsed.dart';
import 'package:fossfit/sets/history_list.dart';
import 'package:fossfit/utils.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class ExerciseItem {
  final int exerciseId;
  final String name;
  final List<GymSet> sets;
  final DateTime date;

  ExerciseItem({
    required this.exerciseId,
    required this.name,
    required this.sets,
    required this.date,
  });
}

class HistoryPage extends StatefulWidget {
  final TabController tabController;

  const HistoryPage({super.key, required this.tabController});

  @override
  createState() => HistoryPageState();
}

class HistoryPageState extends State<HistoryPage>
    with AutomaticKeepAliveClientMixin {
  final GlobalKey<NavigatorState> navKey = GlobalKey<NavigatorState>();

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return NavigatorPopHandler(
      onPopWithResult: (result) {
        if (navKey.currentState!.canPop() == false) return;
        final settings = context.watch<SettingsRepository>();
        final historyIndex =
            settings.getSetting(key: 'tabs').split(',').indexOf('HistoryPage');
        if (widget.tabController.index == historyIndex)
          navKey.currentState!.pop();
      },
      child: Navigator(
        key: navKey,
        onGenerateRoute: (settings) => MaterialPageRoute(
          builder: (context) => _HistoryPageWidget(
            navigatorKey: navKey,
          ),
          settings: settings,
        ),
      ),
    );
  }
}

class _HistoryPageWidget extends StatefulWidget {
  final GlobalKey<NavigatorState> navigatorKey;

  const _HistoryPageWidget({required this.navigatorKey});

  @override
  createState() => _HistoryPageWidgetState();
}

class _HistoryPageWidgetState extends State<_HistoryPageWidget> {
  late List<GymSet> gymSets = [];

  final repsGt = TextEditingController();
  final repsLt = TextEditingController();
  final weightGt = TextEditingController();
  final weightLt = TextEditingController();
  final scroll = ScrollController();

  final expand = ExpansibleController();

  Widget lastWorkout = SizedBox.shrink();
  Set<int> selected = {};
  String search = '';
  int limit = 100;
  DateTime? startDate;
  DateTime? endDate;
  String? category;

  @override
  Widget build(BuildContext context) {
    var setsRepo = context.watch<GymSetsRepository>();
    var settingsRepo = context.watch<SettingsRepository>();
    gymSets = setsRepo.gymsets;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Builder(
        builder: (context) {
          final showStats = settingsRepo.isEnabled(key: 'stats_panel');
          if (showStats) getStats();
          return material.Column(
            children: [
              AppSearch(
                filter: Filters(
                  repsGtCtrl: repsGt,
                  repsLtCtrl: repsLt,
                  weightGtCtrl: weightGt,
                  weightLtCtrl: weightLt,
                  setStream: () {
                    setState(() {
                      limit = 100;
                    });
                    setStream();
                  },
                  endDate: endDate,
                  startDate: startDate,
                  setEnd: (value) {
                    setState(() {
                      endDate = value;
                      limit = 100;
                    });
                    setStream();
                  },
                  setStart: (value) {
                    setState(() {
                      startDate = value;
                      limit = 100;
                    });
                    setStream();
                  },
                  category: category,
                  setCategory: (value) {
                    setState(() {
                      category = value;
                      limit = 100;
                    });
                    setStream();
                  },
                ),
                onShare: () async {
                  final gymSets = this
                      .gymSets
                      .where(
                        (gymSet) => selected.contains(gymSet.id),
                      )
                      .toList();
                  final summaries = gymSets
                      .map(
                        (gymSet) =>
                            "${toString(gymSet.reps)}x${toString(gymSet.weight)}${gymSet.unit} ${gymSet.exercise!.name}",
                      )
                      .join(', ');
                  await SharePlus.instance
                      .share(ShareParams(text: "I just did $summaries"));
                  setState(() {
                    selected.clear();
                  });
                },
                onChange: (value) {
                  setState(() {
                    search = value;
                    limit = 100;
                  });
                  setStream();
                },
                onClear: () => setState(() {
                  selected.clear();
                }),
                onDelete: () async {
                  await setsRepo.deleteGymSetsById(selected.toList());
                  setState(() {
                    selected.clear();
                  });
                },
                onSelect: () => setState(() {
                  if (gymSets.isEmpty) return;
                  selected.addAll(gymSets.map((gymSet) => gymSet.id!));
                }),
                selected: selected,
                onEdit: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditSetsPage(
                      ids: selected.toList(),
                    ),
                  ),
                ),
              ),
              if (gymSets.isEmpty == true)
                const ListTile(
                  title: Text("No entries yet"),
                  subtitle: Text(
                    "Complete some sets to see them here",
                  ),
                ),
              if (gymSets.isNotEmpty == true && showStats) ...[
                Theme(
                  data: Theme.of(context)
                      .copyWith(dividerColor: Colors.transparent),
                  child: Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: ExpansionTile(
                      childrenPadding: EdgeInsets.all(0),
                      iconColor: Theme.of(context).colorScheme.onSurface,
                      leading: Icon(
                        expand.isExpanded
                            ? Icons.analytics_outlined
                            : Icons.history_outlined,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      title: Text(expand.isExpanded ? 'Stats' : 'History'),
                      initiallyExpanded: true,
                      controller: expand,
                      children: [lastWorkout],
                    ),
                  ),
                ),
              ],
              Expanded(
                child: Builder(
                  builder: (context) {
                    final groupHistory =
                        settingsRepo.isEnabled(key: 'group_history');

                    if (groupHistory) {
                      final exerciseItems = _getExerciseItems(gymSets);
                      return HistoryCollapsed(
                        scroll: scroll,
                        days: exerciseItems.reversed.toList(),
                        onSelect: (id) {
                          if (selected.contains(id))
                            setState(() {
                              selected.remove(id);
                            });
                          else
                            setState(() {
                              selected.add(id);
                            });
                        },
                        selected: selected,
                        onNext: () {
                          setState(() {
                            limit += 100;
                          });
                          setStream();
                        },
                      );
                    } else
                      return HistoryList(
                        scroll: scroll,
                        sets: gymSets,
                        onSelect: (id) {
                          if (selected.contains(id))
                            setState(() {
                              selected.remove(id);
                            });
                          else
                            setState(() {
                              selected.add(id);
                            });
                        },
                        selected: selected,
                        onNext: () {
                          setState(() {
                            limit += 100;
                          });
                          setStream();
                        },
                      );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: AnimatedFab(
        onPressed: onAdd,
        label: Text('Add'),
        icon: Icon(Icons.add),
        scroll: scroll,
      ),
    );
  }

  void onAdd() async {
    final settings = context.watch<SettingsRepository>();
    final gymSets = this.gymSets;
    var bodyWeight = 0.0;
    if (settings.isEnabled(key: 'show_body_weight'))
      bodyWeight = (await getBodyWeight())?.weight ?? 0.0;

    GymSet gymSet = gymSets.firstOrNull ??
        GymSet(
          id: 0,
          bodyWeight: bodyWeight,
          restMs: const Duration(minutes: 3, seconds: 30).inMilliseconds,
          reps: 0,
          created: DateTime.now().toLocal(),
          unit: 'kg',
          weight: 0,
          duration: 0,
          distance: 0,
          hidden: false,
          exerciseId: 1,
        );
    gymSet = gymSet.copyWith(
      bodyWeight: bodyWeight,
      created: DateTime.now().toLocal(),
    );

    var su = settings.getSetting(key: 'strength_unit');
    var cu = settings.getSetting(key: 'cardio_unit');
    if (su != 'last-entry' && !gymSet.exercise!.cardio)
      gymSet = gymSet.copyWith(
        unit: su,
      );
    else if (cu != 'last-entry' && gymSet.exercise!.cardio)
      gymSet = gymSet.copyWith(
        unit: cu,
      );

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditSetPage(
          gymSet: gymSet,
        ),
      ),
    );
  }

  List<ExerciseItem> _getExerciseItems(List<GymSet> gymSets) {
    List<ExerciseItem> exerciseItems = [];
    for (final gymSet in gymSets) {
      final day = DateUtils.dateOnly(gymSet.created);
      final index = exerciseItems.indexWhere(
        (hd) => isSameDay(hd.date, day) && hd.name == gymSet.exercise?.name,
      );
      if (index == -1)
        exerciseItems.add(
          ExerciseItem(
            name: gymSet.exercise!.name,
            sets: [gymSet],
            date: day,
            exerciseId: gymSet.exercise!.id!,
          ),
        );
      else
        exerciseItems[index].sets.add(gymSet);
    }
    return exerciseItems;
  }

  void getStats() async {
    try {
      final lw = await getLastWorkout(gymSets);
      setState(() {
        lastWorkout = lw;
      });
    } catch (_) {}
  }

  Future<material.Widget> getLastWorkout(List<GymSet> sets) async {
    DateTime dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);
    String plural(int s) => s > 1 ? 's' : '';
    final today = dayOnly(DateTime.now());
    if (sets.isEmpty) return SizedBox.shrink();
    final mostRecentDay = sets
        .map((s) => dayOnly(s.created))
        .where((d) => !d.isAfter(today))
        .reduce((a, b) => a.isAfter(b) ? a : b);

    final result =
        sets.where((s) => dayOnly(s.created) == mostRecentDay).toList();
    var sortedDays = _getExerciseItems(result);
    sortedDays.sort((a, b) => a.date.compareTo(b.date));
    var totalWorkout =
        sortedDays.where((d) => d.date == sortedDays.first.date).toList();

    var cardioUnit = totalWorkout.first.sets.any((n) => n.exercise!.cardio)
        ? totalWorkout.first.sets.firstWhere((n) => n.exercise!.cardio).unit
        : '';
    var weightUnit = totalWorkout.first.sets.any((n) => !n.exercise!.cardio)
        ? totalWorkout.first.sets.firstWhere((n) => !n.exercise!.cardio).unit
        : '';
    var totalSets = 0;
    var totalReps = 0;
    var totalExercises = totalWorkout.length;
    double totalDistance = 0;
    double totalWeight = 0;
    for (var exercise in totalWorkout) {
      totalSets += exercise.sets.length;
      for (var set in exercise.sets) {
        totalReps += set.reps.toInt();
        totalDistance += (set.distance ?? 0);
        totalWeight += (set.weight * set.reps);
      }
    }
    return Selector<SettingsRepository, String>(
      selector: (context, settings) {
        final format = settings.getSetting(key: 'short_date_format');
        return DateFormat(format).format(sortedDays.first.date);
      },
      builder: (context, formattedDate, child) {
        var daysSince = DateTime.now().difference(sortedDays.first.date).inDays;
        var lastWorkout =
            'You last worked out ${daysSince == 0 ? 'today.' : daysSince == 1 ? 'yesterday.' : '$daysSince days ago on $formattedDate.'}';
        return Padding(
          padding: EdgeInsets.only(left: 8, right: 8),
          child: ListTile(
            title: Text(lastWorkout),
            subtitle: material.Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 16,
                ),
                Divider(),
                Text(
                  '$totalExercises exercise${plural(totalExercises)} completed',
                  textAlign: TextAlign.left,
                ),
                Text(
                  '$totalSets set${plural(totalSets)} completed',
                  textAlign: TextAlign.left,
                ),
                Text(
                  '$totalReps rep${plural(totalReps)} completed',
                  textAlign: TextAlign.left,
                ),
                if (totalWeight > 0)
                  Text(
                    '${num.parse(totalWeight.toStringAsFixed(3))}$weightUnit total lifted',
                    textAlign: TextAlign.left,
                  ),
                if (totalDistance > 0)
                  Text(
                    '$totalDistance$cardioUnit total travelled',
                    textAlign: TextAlign.left,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    scroll.addListener(() {
      if (scroll.offset > 0.0) {
        expand.collapse();
      } else {
        expand.expand();
      }
    });
    setStream();
  }

  void setStream() {
    final terms =
        search.toLowerCase().split(" ").where((term) => term.isNotEmpty);

    var query = gymSets.where((tbl) => !tbl.hidden).take(limit);

    for (final term in terms) {
      query = query..where((tbl) => tbl.exercise!.name.contains(term));
    }

    if (category != null)
      query = query..where((tbl) => tbl.exercise!.category == category!);
    if (startDate != null)
      query = query
        ..where(
          (tbl) =>
              tbl.created.isAfter(startDate!) ||
              tbl.created.isAtSameMomentAs(startDate!),
        );
    if (endDate != null)
      query = query
        ..where(
          (tbl) =>
              tbl.created.isBefore(endDate!) ||
              tbl.created.isAtSameMomentAs(endDate!),
        );
    if (repsGt.text.isNotEmpty)
      query = query
        ..where(
          (tbl) =>
              tbl.reps > (double.tryParse(repsGt.text) ?? 0) &&
              !tbl.exercise!.cardio,
        );
    if (repsLt.text.isNotEmpty)
      query = query
        ..where(
          (tbl) =>
              tbl.reps < (double.tryParse(repsLt.text) ?? 0) &&
              !tbl.exercise!.cardio,
        );
    if (weightGt.text.isNotEmpty)
      query = query
        ..where(
          (tbl) =>
              tbl.weight > (double.tryParse(weightGt.text) ?? 0) &&
              !tbl.exercise!.cardio,
        );
    if (weightLt.text.isNotEmpty)
      query = query
        ..where(
          (tbl) =>
              tbl.weight < (double.tryParse(weightLt.text) ?? 0) &&
              !tbl.exercise!.cardio,
        );

    setState(() {
      gymSets = query.toList();
    });
  }
}

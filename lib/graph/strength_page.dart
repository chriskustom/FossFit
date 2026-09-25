import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/material.dart';
import 'package:fossfit/constants.dart';
import 'package:fossfit/db/repositories/gym_sets_repository.dart';
import 'package:fossfit/db/repositories/settings_repository.dart';
import 'package:fossfit/graph/edit_graph_page.dart';
import 'package:fossfit/graph/flex_line.dart';
import 'package:fossfit/graph/graph_history_page.dart';
import 'package:fossfit/graph/strength_data.dart';
import 'package:fossfit/models/exercise_model.dart';
import 'package:fossfit/models/gym_set_model.dart';
import 'package:fossfit/sets/edit_set_page.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class StrengthPage extends StatefulWidget {
  final Exercise exercise;
  final String unit;
  final List<StrengthData> data;
  final TabController tabCtrl;

  const StrengthPage({
    super.key,
    required this.exercise,
    required this.unit,
    required this.data,
    required this.tabCtrl,
  });

  @override
  createState() => _StrengthPageState();
}

class _StrengthPageState extends State<StrengthPage> {
  late List<StrengthData> data = widget.data;
  late String target = widget.unit;
  late String name = widget.exercise.name;
  bool useTimeBasedXAxis = false;

  int limit = 20;
  StrengthMetric metric = StrengthMetric.bestWeight;
  Period period = Period.day;
  DateTime? start;
  DateTime? end;
  DateTime lastTap = DateTime.fromMicrosecondsSinceEpoch(0);
  List<GymSet> gymSets = [];
  @override
  void initState() {
    super.initState();
    widget.tabCtrl.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    widget.tabCtrl.removeListener(_onTabChanged);
    super.dispose();
  }

  void _onTabChanged() {
    final settings = context.read<SettingsRepository>();
    if (widget.tabCtrl.index ==
        settings.getSetting(key: 'tabs').indexOf('GraphsPage')) {
      setData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsRepository>();
    final setsRepo = context.watch<GymSetsRepository>();
    gymSets = setsRepo.gymsets
        .where((t) => t.exerciseId == widget.exercise.id!)
        .toList();
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            onPressed: () async {
              if (!context.mounted) return;

              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => GraphHistoryPage(
                    exercise: widget.exercise,
                    gymSets: gymSets
                        .where(
                          (t) =>
                              t.exerciseId == widget.exercise.id && !t.hidden,
                        )
                        .take(20)
                        .toList(),
                  ),
                ),
              );
              Timer(kThemeAnimationDuration, setData);
            },
            icon: const Icon(Icons.history),
            tooltip: "History",
          ),
          IconButton(
            onPressed: () async {
              String? newName = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditGraphPage(
                    exercise: widget.exercise,
                  ),
                ),
              );
              if (mounted && newName != null)
                setState(() {
                  name = newName;
                });
            },
            icon: const Icon(Icons.edit),
            tooltip: "Edit",
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Builder(
          builder: (context) {
            List<FlSpot> spots = [];
            for (var index = 0; index < data.length; index++) {
              if (useTimeBasedXAxis) {
                spots.add(
                  FlSpot(
                    data[index].created.millisecondsSinceEpoch.toDouble(),
                    data[index].value,
                  ),
                );
              } else {
                spots.add(FlSpot(index.toDouble(), data[index].value));
              }
            }

            return ListView(
              children: [
                Visibility(
                  visible: name != 'Weight',
                  child: DropdownButtonFormField(
                    decoration: const InputDecoration(labelText: 'Metric'),
                    initialValue: metric,
                    items: [
                      const DropdownMenuItem(
                        value: StrengthMetric.bestWeight,
                        child: Text("Best weight"),
                      ),
                      const DropdownMenuItem(
                        value: StrengthMetric.bestReps,
                        child: Text("Best reps"),
                      ),
                      const DropdownMenuItem(
                        value: StrengthMetric.oneRepMax,
                        child: Text("One rep max"),
                      ),
                      const DropdownMenuItem(
                        value: StrengthMetric.volume,
                        child: Text("Volume"),
                      ),
                      if (settings.isEnabled(key: 'show_body_weight'))
                        const DropdownMenuItem(
                          value: StrengthMetric.relativeStrength,
                          child: Text("Relative strength"),
                        ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        metric = value!;
                      });
                      setData();
                    },
                  ),
                ),
                DropdownButtonFormField(
                  decoration: const InputDecoration(labelText: 'Period'),
                  initialValue: period,
                  items: const [
                    DropdownMenuItem(
                      value: Period.day,
                      child: Text("Daily"),
                    ),
                    DropdownMenuItem(
                      value: Period.week,
                      child: Text("Weekly"),
                    ),
                    DropdownMenuItem(
                      value: Period.month,
                      child: Text("Monthly"),
                    ),
                    DropdownMenuItem(
                      value: Period.year,
                      child: Text("Yearly"),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      period = value!;
                    });
                    setData();
                  },
                ),
                Visibility(
                  visible: settings.isEnabled(key: 'show_units'),
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Unit'),
                    initialValue: target,
                    items: const [
                      DropdownMenuItem(
                        value: 'kg',
                        child: Text("Kilograms (kg)"),
                      ),
                      DropdownMenuItem(
                        value: 'lb',
                        child: Text("Pounds (lb)"),
                      ),
                      DropdownMenuItem(
                        value: 'stone',
                        child: Text("Stone"),
                      ),
                    ],
                    onChanged: (String? newValue) {
                      setState(() {
                        target = newValue!;
                      });
                      setData();
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: ListTile(
                          title: const Text('Start date'),
                          subtitle: start == null
                              ? Text(
                                  settings.getSetting(key: 'short_date_format'),
                                )
                              : Text(
                                  DateFormat(
                                    settings.getSetting(
                                      key: 'short_date_format',
                                    ),
                                  ).format(start!),
                                ),
                          onLongPress: () {
                            setState(() {
                              start = null;
                            });
                            setData();
                          },
                          trailing: const Icon(Icons.calendar_today),
                          onTap: () => _selectStart(),
                        ),
                      ),
                      Expanded(
                        child: ListTile(
                          title: const Text('Stop date'),
                          subtitle: Selector<SettingsRepository, String>(
                            selector: (p0, settings) =>
                                settings.getSetting(key: 'short_date_format'),
                            builder: (context, value, child) {
                              if (end == null) return Text(value);

                              return Text(
                                DateFormat(value).format(end!),
                              );
                            },
                          ),
                          onLongPress: () {
                            setState(() {
                              end = null;
                            });
                            setData();
                          },
                          trailing: const Icon(Icons.calendar_today),
                          onTap: () => _selectEnd(),
                        ),
                      ),
                    ],
                  ),
                ),
                SwitchListTile(
                  title: const Text('Use time-based X axis'),
                  value: useTimeBasedXAxis,
                  onChanged: (val) => setState(() {
                    useTimeBasedXAxis = val;
                  }),
                ),
                material.Column(
                  children: [
                    material.Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        "Limit ($limit)",
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                    Slider(
                      value: limit.toDouble(),
                      inactiveColor: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.24),
                      min: 10,
                      max: 100,
                      onChanged: (value) {
                        setState(() {
                          limit = value.toInt();
                        });
                        setData();
                      },
                    ),
                  ],
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.35,
                  child: data.isEmpty
                      ? const ListTile(title: Text("No data yet."))
                      : Padding(
                          padding:
                              const EdgeInsets.only(right: 32.0, top: 16.0),
                          child: FlexLine(
                            data: data,
                            spots: spots,
                            tooltipData: () => tooltipData(
                              settings.getSetting(key: 'short_date_format'),
                            ),
                            touchLine: touchLine,
                            timeBasedXAxis: useTimeBasedXAxis,
                          ),
                        ),
                ),
                const SizedBox(height: 116),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> setData() async {
    if (!mounted) return;
    final strengthData =
        await context.read<GymSetsRepository>().getStrengthData(
              target: target,
              exerciseId: widget.exercise.id!,
              metric: metric,
              period: period,
              start: start,
              end: end,
              limit: limit,
            );
    setState(() {
      data = strengthData;
    });
  }

  LineTouchTooltipData tooltipData(
    String format,
  ) {
    return LineTouchTooltipData(
      getTooltipColor: (touch) => Theme.of(context).colorScheme.surface,
      getTooltipItems: (touchedSpots) {
        final row = data.elementAt(touchedSpots.last.spotIndex);
        final created = DateFormat(format).format(row.created);
        final formatter = NumberFormat("#,###.00");

        String text = "${row.value.toStringAsFixed(2)}$target $created";
        switch (metric) {
          case StrengthMetric.bestReps:
          case StrengthMetric.relativeStrength:
            text = "${row.value.toStringAsFixed(2)} $created";
            break;
          case StrengthMetric.volume:
          case StrengthMetric.oneRepMax:
            text = "${formatter.format(row.value)}$target $created";
            break;
          case StrengthMetric.bestWeight:
            break;
        }

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

  Future<void> touchLine(
    FlTouchEvent event,
    LineTouchResponse? touchResponse,
  ) async {
    if (event is ScaleUpdateDetails) return;
    if (event is! FlPanDownEvent) return;
    if (DateTime.now().difference(lastTap) >= const Duration(milliseconds: 300))
      return setState(() {
        lastTap = DateTime.now();
      });

    final index = touchResponse?.lineBarSpots?[0].spotIndex;
    if (index == null) return;
    final row = data[index];
    GymSet? gymSet;
    var theseSets = gymSets.where((t) => t.created == row.created).toList();
    switch (metric) {
      case StrengthMetric.oneRepMax:
        gymSet = await context
            .read<GymSetsRepository>()
            .getOrmEstimate(row.created, row.value, widget.exercise.name);
        break;
      case StrengthMetric.volume:
        gymSet = theseSets.take(1).first;
        break;
      case StrengthMetric.bestWeight:
        gymSet = theseSets
            .where(
              (tbl) => tbl.weight == row.value,
            )
            .take(1)
            .first;
        break;
      case StrengthMetric.relativeStrength:
        gymSet = theseSets
            .where(
              (tbl) => ((tbl.weight / (tbl.bodyWeight)) == (row.value) ||
                  (tbl.weight / (tbl.bodyWeight)).isNaN),
            )
            .take(1)
            .first;
        break;
      case StrengthMetric.bestReps:
        gymSet = theseSets
            .where(
              (tbl) => tbl.reps == (row.value),
            )
            .take(1)
            .first;
        break;
    }

    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditSetPage(
          gymSet: gymSet!,
        ),
      ),
    );
    Timer(kThemeAnimationDuration, setData);
  }

  Future<void> _selectEnd() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: end,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate == null) return;

    setState(() {
      end = pickedDate;
    });
    setData();
  }

  Future<void> _selectStart() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: start,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate == null) return;

    setState(() {
      start = pickedDate;
    });
    setData();
  }
}

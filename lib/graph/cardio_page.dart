import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:fossfit/constants.dart';
import 'package:fossfit/db/repositories/gym_sets_repository.dart';
import 'package:fossfit/db/repositories/settings_repository.dart';
import 'package:fossfit/graph/cardio_data.dart';
import 'package:fossfit/graph/edit_graph_page.dart';
import 'package:fossfit/graph/flex_line.dart';
import 'package:fossfit/graph/graph_history_page.dart';
import 'package:fossfit/models/exercise_model.dart';
import 'package:fossfit/models/gym_set_model.dart';
import 'package:fossfit/sets/edit_set_page.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class CardioPage extends StatefulWidget {
  final Exercise exercise;
  final String unit;
  final List<CardioData> data;
  final TabController tabCtrl;

  const CardioPage({
    super.key,
    required this.exercise,
    required this.unit,
    required this.data,
    required this.tabCtrl,
  });

  @override
  createState() => _CardioPageState();
}

class _CardioPageState extends State<CardioPage> {
  late List<CardioData> data = widget.data;
  late String target = widget.unit;
  CardioMetric metric = CardioMetric.pace;
  Period period = Period.day;
  DateTime? start;
  DateTime? end;
  TabController? ctrl;
  DateTime lastTap = DateTime(0);
  bool useTimeBasedXAxis = false;

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
    final settings = context.watch<SettingsRepository>();
    if (widget.tabCtrl.index ==
        settings.getSetting(key: 'tabs').indexOf('GraphsPage')) {
      setData();
    }
  }

  LineTouchTooltipData tooltipData(String format) => LineTouchTooltipData(
        getTooltipColor: (touch) => Theme.of(context).colorScheme.surface,
        getTooltipItems: (touchedSpots) {
          return touchedSpots.map((spot) {
            // Only show tooltip for the first line (index 0 = actual data)
            // Return null for trend line (index 1)
            if (spot.barIndex != 0) return null;

            final row = data.elementAt(spot.spotIndex);
            String text = row.value.toStringAsFixed(2);
            final created = DateFormat(format).format(row.created);
            switch (metric) {
              case CardioMetric.pace:
                text = "${row.value} ${row.unit} / min";
                break;
              case CardioMetric.duration:
                final minutes = row.value.floor();
                final seconds =
                    ((row.value * 60) % 60).floor().toString().padLeft(2, '0');
                text = "$minutes:$seconds";
                break;
              case CardioMetric.distance:
                text += " ${row.unit}";
                break;
              case CardioMetric.incline:
                text += "%";
                break;
              case CardioMetric.inclineAdjustedPace:
                break;
            }
            return LineTooltipItem(
              "$text\n$created",
              TextStyle(
                color: Theme.of(context).textTheme.bodyLarge!.color,
              ),
            );
          }).toList();
        },
      );

  Future<void> touchLine(
    FlTouchEvent event,
    LineTouchResponse? response,
  ) async {
    if (event is ScaleUpdateDetails) return;
    if (event is! FlPanDownEvent) return;
    if (DateTime.now().difference(lastTap) >= const Duration(milliseconds: 300))
      return setState(() {
        lastTap = DateTime.now();
      });

    final index = response?.lineBarSpots?[0].spotIndex;
    if (index == null) return;
    final row = data[index];
    if (!context.mounted) return;
    GymSet? gymSet = context
        .watch<GymSetsRepository>()
        .gymsets
        .where(
          (tbl) =>
              tbl.created == row.created &&
              tbl.exerciseId == widget.exercise.id,
        )
        .first;

    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditSetPage(
          gymSet: gymSet,
        ),
      ),
    );
    Timer(kThemeAnimationDuration, setData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(widget.exercise.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            onPressed: () async {
              final gymSets = context
                  .watch<GymSetsRepository>()
                  .gymsets
                  .where(
                    (tbl) =>
                        tbl.exerciseId == widget.exercise.id && !tbl.hidden,
                  )
                  .toList();

              if (!context.mounted) return;

              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => GraphHistoryPage(
                    exercise: widget.exercise,
                    gymSets: gymSets,
                  ),
                ),
              );
              Timer(kThemeAnimationDuration, setData);
            },
            icon: const Icon(Icons.history),
            tooltip: "History",
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditGraphPage(
                    exercise: widget.exercise,
                  ),
                ),
              );
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
            final rows = data;

            for (var index = 0; index < rows.length; index++) {
              final row = rows.elementAt(index);
              final value = double.parse(row.value.toStringAsFixed(1));
              if (useTimeBasedXAxis) {
                spots.add(
                  FlSpot(
                    row.created.millisecondsSinceEpoch.toDouble(),
                    value,
                  ),
                );
              } else {
                spots.add(FlSpot(index.toDouble(), value));
              }
            }

            final settings = context.watch<SettingsRepository>();

            return ListView(
              children: [
                DropdownButtonFormField(
                  decoration: const InputDecoration(labelText: 'Metric'),
                  initialValue: metric,
                  items: const [
                    DropdownMenuItem(
                      value: CardioMetric.pace,
                      child: Text("Pace (distance / time)"),
                    ),
                    DropdownMenuItem(
                      value: CardioMetric.inclineAdjustedPace,
                      child: Text("Adjusted pace"),
                    ),
                    DropdownMenuItem(
                      value: CardioMetric.duration,
                      child: Text("Duration"),
                    ),
                    DropdownMenuItem(
                      value: CardioMetric.distance,
                      child: Text("Distance"),
                    ),
                    DropdownMenuItem(
                      value: CardioMetric.incline,
                      child: Text("Incline"),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      metric = value!;
                    });
                    setData();
                  },
                ),
                SizedBox(height: 8),
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
                SizedBox(height: 8),
                if (metric == CardioMetric.distance)
                  Selector<SettingsRepository, bool>(
                    selector: (_, config) =>
                        config.isEnabled(key: 'show_units'),
                    builder: (context, value, child) => Visibility(
                      visible: value,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(labelText: 'Unit'),
                          initialValue: target,
                          items: const [
                            DropdownMenuItem(
                              value: 'km',
                              child: Text("Kilometers (km)"),
                            ),
                            DropdownMenuItem(
                              value: 'mi',
                              child: Text("Miles (mi)"),
                            ),
                            DropdownMenuItem(
                              value: 'm',
                              child: Text("Meters (m)"),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              target = value!;
                            });
                            setData();
                          },
                        ),
                      ),
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        title: const Text('Start date'),
                        subtitle: Selector<SettingsRepository, String>(
                          selector: (_, config) =>
                              config.getSetting(key: 'short_date_format'),
                          builder: (context, value, child) {
                            if (start == null) return Text(value);

                            return Text(
                              DateFormat(value).format(start!),
                            );
                          },
                        ),
                        onLongPress: () => setState(() {
                          start = null;
                        }),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () => _selectStart(),
                      ),
                    ),
                    Expanded(
                      child: ListTile(
                        title: const Text('Stop date'),
                        subtitle: Selector<SettingsRepository, String>(
                          selector: (_, config) =>
                              config.getSetting(key: 'short_date_format'),
                          builder: (context, value, child) {
                            if (end == null) return Text(value);

                            return Text(
                              DateFormat(value).format(end!),
                            );
                          },
                        ),
                        onLongPress: () => setState(() {
                          end = null;
                        }),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () => _selectEnd(),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('Use time-based X axis'),
                  value: useTimeBasedXAxis,
                  onChanged: (val) => setState(() {
                    useTimeBasedXAxis = val;
                  }),
                ),
                if (rows.isEmpty)
                  ListTile(
                    title: Text("No data yet for ${widget.exercise.name}"),
                    subtitle:
                        const Text("Complete some plans to view graphs here"),
                    contentPadding: EdgeInsets.zero,
                  ),
                if (rows.isNotEmpty)
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.40,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 32.0, top: 16.0),
                      child: FlexLine(
                        spots: spots,
                        tooltipData: () => tooltipData(
                          settings.getSetting(key: 'shortDateFormat'),
                        ),
                        touchLine: touchLine,
                        data: data,
                        timeBasedXAxis: useTimeBasedXAxis,
                      ),
                    ),
                  ),
                const SizedBox(height: 200),
              ],
            );
          },
        ),
      ),
    );
  }

  void setData() async {
    final cardio = await context.watch<GymSetsRepository>().getCardioData(
          end: end,
          period: period,
          metric: metric,
          exerciseId: widget.exercise.id!,
          start: start,
          target: target,
        );

    if (!mounted) return;
    setState(() {
      data = cardio;
    });
  }

  Future<void> _selectEnd() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: end,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked == null) return;
    setState(() {
      end = picked;
    });
    setData();
  }

  Future<void> _selectStart() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: start,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked == null) return;
    setState(() {
      start = picked;
    });
    setData();
  }
}

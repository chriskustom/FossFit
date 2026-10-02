import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:fossfit/app/features/exercises/exercise/graph/flex_line.dart';
import 'package:fossfit/app/features/workout/widgets/workout_peek.dart';
import 'package:fossfit/app/services/features/cardio_services.dart';
import 'package:fossfit/app/services/features/exercise_services.dart';
import 'package:fossfit/app/services/features/gym_set_services.dart';
import 'package:fossfit/app/shell/app_shell.dart';
import 'package:fossfit/app/utils/constants.dart';
import 'package:fossfit/app/widgets/confirmation_dialog.dart';
import 'package:fossfit/db/models/features/cardio_model.dart';
import 'package:fossfit/db/models/features/exercise_model.dart';
import 'package:fossfit/db/models/features/gymset_model.dart';
import 'package:fossfit/db/repositories/cardio_repository.dart';
import 'package:fossfit/db/repositories/config_reposity.dart';
import 'package:fossfit/db/repositories/exercise_repository.dart';
import 'package:fossfit/db/repositories/gym_set_repository.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class CardioExercisePage extends StatefulWidget {
  final int exerciseId;
  final List<CardioData> initialData;
  const CardioExercisePage({super.key, required this.exerciseId, required this.initialData});

  @override
  State<CardioExercisePage> createState() => _CardioExercisePageState();
}

class _CardioExercisePageState extends State<CardioExercisePage> {
  late List<CardioData> data = widget.initialData;
  bool useTimeBasedXAxis = false;

  int limit = 20;
  CardioMetric metric = CardioMetric.pace;
  Period period = Period.day;
  DateTime? start;
  DateTime? end;
  DateTime lastTap = DateTime.fromMicrosecondsSinceEpoch(0);
  List<GymSet> gymSets = [];
  String? _unit;
  Exercise? exercise;

  bool isDeleting = false;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<ConfigRepository>();
    final setsRepo = context.watch<GymSetRepository>();
    final exRepo = context.watch<ExercisesRepository>();
    exercise = exercise ?? exRepo.getExerciseById(widget.exerciseId);
    gymSets = setsRepo.gymsets.where((t) => t.exerciseId == widget.exerciseId).toList();
    _unit = _unit ?? gymSets.firstOrNull?.unit ?? exercise!.defaultUnit ?? 'kg';
    setData();
    return AppShell(
      title: exercise!.name,
      showNavBar: false,
      showSearch: false,
      actions: [
        IconButton(
          onPressed: () async {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              showDragHandle: true,
              builder: (context) {
                return FractionallySizedBox(
                  heightFactor: 0.75,
                  widthFactor: 0.85,
                  child: Material(
                    color: Theme.of(context).colorScheme.surface,
                    clipBehavior: Clip.antiAlias,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    child: WorkoutPeek(sets: gymSets),
                  ),
                );
              },
            );
          },
          icon: const Icon(Icons.history),
          tooltip: "History",
        ),
        IconButton(
          onPressed: () async {
            var services = ExerciseServices(context: context);
            await services.openAddEditExercisePage(context, exercise!.id, null);
          },
          icon: const Icon(Icons.edit),
          tooltip: "Edit",
        ),
        buildDeleteButton(),
      ],
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Builder(
              builder: (context) {
                List<FlSpot> spots = [];
                for (var index = 0; index < data.length; index++) {
                  if (useTimeBasedXAxis) {
                    spots.add(FlSpot(data[index].created.millisecondsSinceEpoch.toDouble(), data[index].value));
                  } else {
                    spots.add(FlSpot(index.toDouble(), data[index].value));
                  }
                }

                return ListView(
                  children: [
                    DropdownButtonFormField(
                      decoration: const InputDecoration(labelText: 'Metric'),
                      initialValue: metric,
                      items: const [
                        DropdownMenuItem(value: CardioMetric.pace, child: Text("Pace (distance / time)")),
                        DropdownMenuItem(value: CardioMetric.inclineAdjustedPace, child: Text("Adjusted pace")),
                        DropdownMenuItem(value: CardioMetric.duration, child: Text("Duration")),
                        DropdownMenuItem(value: CardioMetric.distance, child: Text("Distance")),
                        DropdownMenuItem(value: CardioMetric.incline, child: Text("Incline")),
                      ],
                      onChanged: (value) {
                        setState(() {
                          metric = value!;
                        });
                        setData();
                      },
                    ),
                    DropdownButtonFormField(
                      decoration: const InputDecoration(labelText: 'Period'),
                      initialValue: period,
                      items: const [
                        DropdownMenuItem(value: Period.day, child: Text("Daily")),
                        DropdownMenuItem(value: Period.week, child: Text("Weekly")),
                        DropdownMenuItem(value: Period.month, child: Text("Monthly")),
                        DropdownMenuItem(value: Period.year, child: Text("Yearly")),
                      ],
                      onChanged: (value) {
                        setState(() {
                          period = value!;
                        });
                        setData();
                      },
                    ),
                    Visibility(
                      visible: settings.isEnabled(.workouts, 'show_units'),
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: 'Unit'),
                        initialValue: _unit,
                        items: distanceUnits.map((u) => DropdownMenuItem<String>(value: u.key, child: Text(u.value))).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _unit = newValue!;
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
                                  ? Text(settings.getSetting(.formats, 'short_date_format'))
                                  : Text(DateFormat(settings.getSetting(.formats, 'short_date_format')).format(start!)),
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
                              subtitle: Selector<ConfigRepository, String>(
                                selector: (p0, settings) => settings.getSetting(.formats, 'short_date_format'),
                                builder: (context, value, child) {
                                  if (end == null) return Text(value);

                                  return Text(DateFormat(value).format(end!));
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
                    Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Text("Limit ($limit)", style: Theme.of(context).textTheme.bodyLarge),
                        ),
                        Slider(
                          value: limit.toDouble(),
                          inactiveColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.24),
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
                              padding: const EdgeInsets.only(right: 32.0, top: 16.0),
                              child: FlexLine(
                                data: data,
                                spots: spots,
                                tooltipData: () => tooltipData(settings.getSetting(.formats, 'short_date_format')),
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
          if (isDeleting)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.4),
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }

  Widget buildDeleteButton() {
    return IconButton(icon: const Icon(Icons.delete), onPressed: () => showDeleteDialog());
  }

  Future<void> showDeleteDialog() async {
    var services = ExerciseServices(context: context);
    var setServices = CardioServices(context: context);
    var exerciseSets = setServices.getSetsByExerciseId(widget.exerciseId);
    var name = services.getExerciseById(widget.exerciseId)!.name;
    var setsExist = exerciseSets.length > 1;

    var text = setsExist
        ? '\'$name\' has activities logged. \nDeleting this exercise will delete these activities. \n\nDo you wish to proceed?'
        : 'Are you sure you want to delete exercise: \'$name\'?';
    final proceed = await showConfirmationDialog(
      context: context,
      title: 'Confirm delete',
      content: text,
      confirmStyle: TextButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
      cancelStyle: TextButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
      cancelLabel: 'No',
      confirmLabel: 'Delete',
      barrierDismissible: true,
    );

    if (proceed == null || !proceed || !mounted) return;

    Navigator.pop(context);
    setState(() {
      isDeleting = true;
    });
    await services.deleteExercises([widget.exerciseId]);
    setState(() {
      isDeleting = false;
    });
    if (mounted) {
      Navigator.pop(context);
    }
  }

  void setData() async {
    if (!mounted) return;
    final cardioData = await context.read<CardioRepository>().getCardioData(
      target: _unit ?? 'kg',
      exerciseId: widget.exerciseId,
      metric: metric,
      period: period,
      start: start,
      end: end,
    );
    setState(() {
      data = cardioData;
    });
  }

  LineTouchTooltipData tooltipData(String format) {
    return LineTouchTooltipData(
      getTooltipColor: (touch) => Theme.of(context).colorScheme.surface,
      getTooltipItems: (touchedSpots) {
        final row = data.elementAt(touchedSpots.last.spotIndex);
        final created = DateFormat(format).format(row.created);
        String text = "${row.value.toStringAsFixed(2)}$_unit $created";
        switch (metric) {
          case CardioMetric.pace:
            text = "${row.value} ${row.unit} / min";
            break;
          case CardioMetric.duration:
            final minutes = row.value.floor();
            final seconds = ((row.value * 60) % 60).floor().toString().padLeft(2, '0');
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

        return [LineTooltipItem(text, TextStyle(color: Theme.of(context).textTheme.bodyLarge!.color)), if (touchedSpots.length > 1) null];
      },
    );
  }

  Future<void> touchLine(FlTouchEvent event, LineTouchResponse? touchResponse) async {
    final services = GymSetServices(context: context);
    if (event is ScaleUpdateDetails) return;
    if (event is! FlPanDownEvent) return;
    if (DateTime.now().difference(lastTap) >= const Duration(milliseconds: 300)) {
      return setState(() {
        lastTap = DateTime.now();
      });
    }

    final index = touchResponse?.lineBarSpots?[0].spotIndex;
    if (index == null) return;
    final row = data[index];
    GymSet? gymSet = gymSets.where((t) => t.created == row.created).toList().firstOrNull;

    if (!mounted) return;
    await services.openAddEditPage(context, gymSet?.id);
  }

  Future<void> _selectEnd() async {
    final DateTime? pickedDate = await showDatePicker(context: context, initialDate: end, firstDate: DateTime(2000), lastDate: DateTime(2100));

    if (pickedDate == null) return;

    setState(() {
      end = pickedDate;
    });
    setData();
  }

  Future<void> _selectStart() async {
    final DateTime? pickedDate = await showDatePicker(context: context, initialDate: start, firstDate: DateTime(2000), lastDate: DateTime(2100));

    if (pickedDate == null) return;

    setState(() {
      start = pickedDate;
    });
    setData();
  }
}

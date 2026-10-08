import 'dart:typed_data';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:fossfit/app/features/exercises/exercise/graph/flex_line.dart';
import 'package:fossfit/app/features/exercises/exercise/image/image_page.dart';
import 'package:fossfit/app/features/workout/widgets/workout_peek.dart';
import 'package:fossfit/app/services/features/exercise_services.dart';
import 'package:fossfit/app/services/features/gym_set_services.dart';
import 'package:fossfit/app/shell/app_shell.dart';
import 'package:fossfit/app/utils/constants.dart';
import 'package:fossfit/app/widgets/confirmation_dialog.dart';
import 'package:fossfit/db/models/features/exercise_model.dart';
import 'package:fossfit/db/models/features/gymset_model.dart';
import 'package:fossfit/db/models/features/strength_model.dart';
import 'package:fossfit/db/repositories/config_reposity.dart';
import 'package:fossfit/db/repositories/exercise_repository.dart';
import 'package:fossfit/db/repositories/gym_set_repository.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ExercisePage extends StatefulWidget {
  final int exerciseId;
  final List<StrengthData> initialData;
  const ExercisePage({super.key, required this.exerciseId, required this.initialData});

  @override
  State<ExercisePage> createState() => _ExercisePageState();
}

class _ExercisePageState extends State<ExercisePage> with SingleTickerProviderStateMixin {
  late List<StrengthData> data = widget.initialData;

  final ExpansibleController _controller = ExpansibleController();

  int limit = 20;
  StrengthMetric metric = StrengthMetric.bestWeight;
  Period period = Period.day;
  DateTime? start;
  DateTime? end;
  DateTime lastTap = DateTime.fromMicrosecondsSinceEpoch(0);
  List<GymSet> gymSets = [];
  String? _unit;
  Exercise? exercise;

  bool isDeleting = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<ConfigRepository>();
    final setsRepo = context.watch<GymSetRepository>();
    final exRepo = context.watch<ExercisesRepository>();
    exercise = exercise ?? exRepo.getExerciseById(widget.exerciseId);
    gymSets = setsRepo.gymsets.where((t) => t.exerciseId == widget.exerciseId).toList();
    _unit = _unit ?? gymSets.firstOrNull?.unit ?? exercise!.defaultUnit ?? 'kg';
    final imageSize = MediaQuery.of(context).size.width * 0.25;
    setData();
    return AppShell(
      title: exercise!.name,
      showNavBar: false,
      showSearch: false,
      actions: [
        IconButton(
          onPressed: () async {
            var services = ExerciseServices(context: context);
            await services.openAddEditExercisePage(context, exercise!.id, null);
            setState(() {
              exercise = exRepo.getExerciseById(widget.exerciseId);
            });
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
                  spots.add(FlSpot(index.toDouble(), data[index].value));
                }

                return ListView(
                  children: [
                    if (exercise!.hasImage() == true) ...[
                      Center(
                        child: InkWell(
                          onTap: () async {
                            final imageFile = ImageFile(name: exercise!.name, bytes: exercise!.image ?? Uint8List(0));

                            if (!context.mounted) return;
                            showGeneralDialog(
                              context: context,
                              barrierLabel: "Right Sheet",
                              barrierDismissible: true,
                              barrierColor: Colors.black54,
                              transitionDuration: const Duration(milliseconds: 200),
                              pageBuilder: (context, anim1, anim2) {
                                return Align(
                                  alignment: Alignment.centerRight,
                                  child: Material(
                                    color: Colors.white,
                                    child: SizedBox(
                                      width: MediaQuery.of(context).size.width,
                                      height: double.infinity,
                                      child: ImagePage(image: imageFile),
                                    ),
                                  ),
                                );
                              },
                              transitionBuilder: (context, anim1, anim2, child) {
                                final offsetAnimation = Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(anim1);
                                return SlideTransition(position: offsetAnimation, child: child);
                              },
                            );
                          },
                          child: Container(
                            width: imageSize,
                            height: imageSize,
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(imageSize * 0.15),
                              image: DecorationImage(image: MemoryImage(exercise?.image ?? Uint8List(0)), fit: BoxFit.cover),
                            ),
                          ),
                        ),
                      ),
                    ],
                    DropdownButtonFormField(
                      decoration: const InputDecoration(labelText: 'Metric'),
                      initialValue: metric,
                      items: [
                        const DropdownMenuItem(value: StrengthMetric.bestWeight, child: Text("Best weight")),
                        const DropdownMenuItem(value: StrengthMetric.bestReps, child: Text("Best reps")),
                        const DropdownMenuItem(value: StrengthMetric.oneRepMax, child: Text("One rep max")),
                        const DropdownMenuItem(value: StrengthMetric.volume, child: Text("Volume")),
                        if (settings.isEnabled(.workouts, 'show_body_weight'))
                          const DropdownMenuItem(value: StrengthMetric.relativeStrength, child: Text("Relative strength")),
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
                        items: const [
                          DropdownMenuItem(value: 'kg', child: Text("Kilograms (kg)")),
                          DropdownMenuItem(value: 'lb', child: Text("Pounds (lb)")),
                          DropdownMenuItem(value: 'stone', child: Text("Stone")),
                        ],
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

                    Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ListTileTheme(
                        data: ListTileThemeData(contentPadding: EdgeInsets.only(top: 6), minVerticalPadding: 0, dense: true),
                        child: ExpansionTile(
                          title: Row(
                            mainAxisSize: .max,
                            children: [
                              Padding(
                                padding: .only(left: 16),
                                child: Text(
                                  _controller.isExpanded ? 'Graph' : 'History',
                                  textScaler: TextScaler.linear(1.1),
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              ),
                              if (!_controller.isExpanded) ...[
                                SizedBox(width: 8),

                                Expanded(
                                  child: Text("(expand for graph)", textAlign: TextAlign.left, style: Theme.of(context).textTheme.bodySmall),
                                ),
                              ],
                              Expanded(
                                flex: _controller.isExpanded ? 1 : 0,
                                child: Text("Limit ($limit)", textAlign: TextAlign.right, style: Theme.of(context).textTheme.bodyMedium),
                              ),
                            ],
                          ),
                          initiallyExpanded: false,
                          controller: _controller,
                          onExpansionChanged: (value) => setState(() {}),
                          subtitle: Slider(
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
                          children: [
                            data.isEmpty
                                ? const ListTile(title: Text("No data yet."))
                                : SizedBox(
                                    height: MediaQuery.of(context).size.height * 0.35,
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 32.0, top: 16.0),
                                      child: FlexLine(
                                        data: data,
                                        spots: spots,
                                        tooltipData: () => tooltipData(settings.getSetting(.formats, 'short_date_format')),
                                        touchLine: touchLine,
                                      ),
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    const SizedBox(height: 8.0),
                    SizedBox(height: 400, child: WorkoutPeek(sets: gymSets.take(limit).toList())),
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
    var setServices = GymSetServices(context: context);
    var exerciseSets = setServices.getSetsByExerciseId(widget.exerciseId);
    var name = services.getExerciseById(widget.exerciseId)!.name;
    var setsExist = exerciseSets.length > 1;

    var text = setsExist
        ? '\'$name\' has sets logged. \nDeleting this exercise will delete these sets. \n\nDo you wish to proceed?'
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
    final strengthData = await context.read<GymSetRepository>().getStrengthData(
      target: _unit ?? 'kg',
      exerciseId: widget.exerciseId,
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

  LineTouchTooltipData tooltipData(String format) {
    return LineTouchTooltipData(
      getTooltipColor: (touch) => Theme.of(context).colorScheme.surface,
      getTooltipItems: (touchedSpots) {
        final row = data.elementAt(touchedSpots.last.spotIndex);
        final created = DateFormat(format).format(row.created);
        final formatter = NumberFormat("#,###.00");

        String text = "${row.value.toStringAsFixed(2)}$_unit $created";
        switch (metric) {
          case StrengthMetric.bestReps:
          case StrengthMetric.relativeStrength:
            text = "${row.value.toStringAsFixed(2)} $created";
            break;
          case StrengthMetric.volume:
          case StrengthMetric.oneRepMax:
            text = "${formatter.format(row.value)}$_unit $created";
            break;
          case StrengthMetric.bestWeight:
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
    GymSet? gymSet;
    var theseSets = gymSets.where((t) => t.created == row.created).toList();
    switch (metric) {
      case StrengthMetric.oneRepMax:
        gymSet = await context.read<GymSetRepository>().getOrmEstimate(row.created, row.value, exercise!.name);
        break;
      case StrengthMetric.volume:
        gymSet = theseSets.take(1).first;
        break;
      case StrengthMetric.bestWeight:
        gymSet = theseSets.where((tbl) => tbl.weight == row.value).take(1).first;
        break;
      case StrengthMetric.relativeStrength:
        gymSet = theseSets
            .where((tbl) => ((tbl.weight / (tbl.bodyWeight ?? 0.0)) == (row.value) || (tbl.weight / (tbl.bodyWeight ?? 0.0)).isNaN))
            .take(1)
            .first;
        break;
      case StrengthMetric.bestReps:
        gymSet = theseSets.where((tbl) => tbl.reps == (row.value)).take(1).first;
        break;
    }

    if (!mounted) return;
    await services.openAddEditPage(context, gymSet.id);
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

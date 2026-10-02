import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fossfit/app/utils/constants.dart';
import 'package:fossfit/app/utils/utils.dart';
import 'package:fossfit/db/models/features/cardio_model.dart';
import 'package:fossfit/db/models/features/exercise_model.dart';
import 'package:fossfit/db/repositories/cardio_repository.dart';
import 'package:fossfit/db/repositories/exercise_repository.dart';
import 'package:provider/provider.dart';

class AddEditCardioPage extends StatefulWidget {
  final int? cardioId;
  final TextEditingController distance;
  final TextEditingController incline;
  final TextEditingController notes;
  final TextEditingController hoursController;
  final TextEditingController minutesController;
  final TextEditingController secondsController;
  const AddEditCardioPage({
    super.key,
    this.cardioId,
    required this.distance,
    required this.incline,
    required this.notes,
    required this.hoursController,
    required this.minutesController,
    required this.secondsController,
  });

  @override
  State<AddEditCardioPage> createState() => _AddEditCardioPageState();
}

class _AddEditCardioPageState extends State<AddEditCardioPage> {
  List<Cardio>? _lastWorkoutSets;

  final distance = TextEditingController(text: '0.0');
  String? distanceUnit;
  final distNode = FocusNode();

  final hoursController = TextEditingController(text: '00');
  final minutesController = TextEditingController(text: '00');
  final secondsController = TextEditingController(text: '00');

  final incline = TextEditingController(text: '0.0');
  final inclineNode = FocusNode();

  final notes = TextEditingController();

  late Future<List<String>> _cardioExerciseNamesFuture;

  bool gap = false;

  Exercise? currentExercise;
  String? name;

  String? pace;

  bool isEditMode = false;
  Cardio? _cardioSet;

  @override
  void initState() {
    super.initState();
    if (widget.cardioId != null) {
      isEditMode = true;
    }

    final exerciseRepository = context.read<ExercisesRepository>();
    _cardioExerciseNamesFuture = exerciseRepository.getCardioExerciseNames();
  }

  @override
  void dispose() {
    distance.dispose();
    distNode.dispose();

    hoursController.dispose();
    minutesController.dispose();
    secondsController.dispose();

    incline.dispose();
    inclineNode.dispose();

    notes.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<CardioRepository>();
    final exRepo = context.watch<ExercisesRepository>();

    final lastWorkoutSets = _lastWorkoutSets ?? repo.latestcardio;
    if (widget.cardioId != null) {
      isEditMode = true;
    }
    if (isEditMode) {
      _cardioSet = _cardioSet ?? repo.getCardioById(widget.cardioId!);
      isEditMode = true;
      currentExercise = exRepo.getExerciseById(_cardioSet!.exerciseId);
      name = currentExercise!.name;
      nameTec.text = name ?? '';
      distance.text = _cardioSet!.distance.toString();
      distanceUnit = _cardioSet!.distanceUnit;
      incline.text = _cardioSet!.incline.toString();
      var duration = formatDuration(Duration(seconds: _cardioSet!.duration)).split(':');
      hoursController.text = duration[0];
      minutesController.text = duration[1];
      secondsController.text = duration[2];
    }

    if (currentExercise == null && exRepo.cardioExercises.isNotEmpty) {
      currentExercise = exRepo.cardioExercises.first;
    }

    final effectiveDistanceUnit =
        distanceUnit ?? (lastWorkoutSets.isNotEmpty ? lastWorkoutSets.first.distanceUnit : currentExercise?.defaultUnit ?? 'km');

    final effectivePaceUnit = _getPaceUnit(effectiveDistanceUnit);

    pace = _calculatePace(effectiveDistanceUnit, effectivePaceUnit);

    return Column(children: [..._getCardioFields(effectiveDistanceUnit, effectivePaceUnit)]);
  }

  List<Widget> _getCardioFields(String effectiveDistanceUnit, String effectivePaceUnit) {
    return [
      _nameAutoCompleteField(),
      SizedBox(height: 8),

      Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: distance,
              focusNode: distNode,
              decoration: InputDecoration(labelText: 'Distance ($effectiveDistanceUnit)'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onTap: () => selectAll(distance),
              onFieldSubmitted: (_) {
                selectAll(hoursController);
              },
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return null;
                }

                if (double.tryParse(value) == null) {
                  return 'Invalid number';
                }

                return null;
              },
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              controller: incline,
              focusNode: inclineNode,
              decoration: const InputDecoration(labelText: 'Incline (%)'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onTap: () => selectAll(incline),
              onFieldSubmitted: (_) {
                selectAll(hoursController);
              },
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return null;
                }

                if (double.tryParse(value) == null) {
                  return 'Invalid number';
                }

                return null;
              },
            ),
          ),
        ],
      ),

      SizedBox(height: 8),
      _getDurationFields(),

      SizedBox(height: 8),
      _unitSelector(effectiveDistanceUnit),

      SizedBox(height: 8),
      ListTile(
        title: Text('${gap ? 'Grade Adjusted ' : ''}Pace ($effectivePaceUnit)'),
        subtitle: Text(
          'Switch to '
          '${gap ? '' : 'Grade Adjusted '}Pace',
        ),
        trailing: Transform.scale(
          scale: switchScale,
          child: Switch.adaptive(
            value: gap,
            onChanged: (value) {
              setState(() {
                gap = value;
              });
            },
          ),
        ),
      ),

      SizedBox(height: 8),
      ListTile(
        title: const Text('Calculated pace'),
        trailing: Text(pace ?? '', style: Theme.of(context).textTheme.titleMedium),
      ),
    ];
  }

  TextEditingController nameTec = TextEditingController();
  Widget _nameAutoCompleteField() {
    final repo = context.read<ExercisesRepository>();

    return FutureBuilder<List<String>>(
      future: _cardioExerciseNamesFuture,
      builder: (context, snapshot) {
        final names = snapshot.data ?? const <String>[];

        return Autocomplete<String>(
          initialValue: TextEditingValue(text: currentExercise?.name ?? name ?? ''),
          optionsBuilder: (value) {
            if (value.text.isEmpty) {
              return names;
            }

            final search = value.text.toLowerCase();

            return names.where((option) => option.toLowerCase().contains(search));
          },
          onSelected: (selection) {
            final exercise = repo.getExerciseByName(selection);

            if (exercise == null) {
              return;
            }

            setState(() {
              name = selection;
              currentExercise = exercise;
            });
          },
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            nameTec = controller;
            return TextFormField(
              controller: controller,
              focusNode: focusNode,
              decoration: const InputDecoration(labelText: 'Exercise name'),
              textInputAction: TextInputAction.next,
              onTap: () => selectAll(controller),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Required';
                }

                if (!names.contains(value)) {
                  return 'Invalid';
                }

                return null;
              },
              onFieldSubmitted: (_) {
                final search = controller.text.trim().toLowerCase();

                final options = names.where((option) => option.toLowerCase().contains(search));

                if (options.isNotEmpty) {
                  final firstOption = options.first;

                  controller.value = TextEditingValue(
                    text: firstOption,
                    selection: TextSelection.collapsed(offset: firstOption.length),
                  );

                  _selectExercise(firstOption, repo);
                }

                onFieldSubmitted();
              },
              onChanged: (value) {
                final exercise = repo.getExerciseByName(value);

                if (exercise == null) {
                  return;
                }

                setState(() {
                  name = value;
                  currentExercise = exercise;
                });
              },
            );
          },
        );
      },
    );
  }

  Widget _unitSelector(String effectiveDistanceUnit) {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(labelText: 'Unit'),
      initialValue: effectiveDistanceUnit,
      items: distanceUnits.map((u) => DropdownMenuItem<String>(value: u.key, child: Text(u.value))).toList(),
      onChanged: (newValue) {
        if (newValue == null) {
          return;
        }

        setState(() {
          distanceUnit = newValue;
        });
      },
    );
  }

  void _selectExercise(String selection, ExercisesRepository repo) {
    final exercise = repo.getExerciseByName(selection);

    if (exercise == null) {
      return;
    }

    setState(() {
      name = selection;
      currentExercise = exercise;
    });
  }

  Widget _getDurationFields() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 60,
          child: TextField(
            controller: hoursController,
            keyboardType: TextInputType.number,
            onTap: () => selectAll(hoursController),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(2)],
            textAlign: TextAlign.center,
            decoration: const InputDecoration(hintText: 'HH'),
            onChanged: (_) {
              setState(() {});
            },
          ),
        ),

        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 6),
          child: Text(':', style: TextStyle(fontSize: 24)),
        ),

        SizedBox(
          width: 60,
          child: TextField(
            controller: minutesController,
            keyboardType: TextInputType.number,
            onTap: () => selectAll(minutesController),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(2)],
            textAlign: TextAlign.center,
            decoration: const InputDecoration(hintText: 'MM'),
            onChanged: (_) {
              setState(() {});
            },
          ),
        ),

        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 6),
          child: Text(':', style: TextStyle(fontSize: 24)),
        ),

        SizedBox(
          width: 60,
          child: TextField(
            controller: secondsController,
            keyboardType: TextInputType.number,
            onTap: () => selectAll(secondsController),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(2)],
            textAlign: TextAlign.center,
            decoration: const InputDecoration(hintText: 'SS'),
            onChanged: (_) {
              setState(() {});
            },
          ),
        ),
      ],
    );
  }

  String _getPaceUnit(String unit) {
    switch (unit) {
      case 'mi':
        return 'min/mi';
      case 'km':
      default:
        return 'min/km';
    }
  }

  String _calculatePaceFromSeconds(int totalSeconds, String distanceUnit, String paceUnit) {
    final totalDistance = double.tryParse(distance.text) ?? 0.0;

    if (totalSeconds <= 0 || totalDistance <= 0) {
      return '0.0';
    }

    if (gap) {
      return formatGradeAdjustedPace(
        totalSeconds: totalSeconds,
        totalDistance: totalDistance,
        inclinePercent: double.tryParse(incline.text) ?? 0.0,
        paceUnit: paceUnit,
        distanceUnit: distanceUnit,
      );
    }

    return formatPace(totalSeconds: totalSeconds, totalDistance: totalDistance, paceUnit: paceUnit, distanceUnit: distanceUnit);
  }

  String _calculatePace(String distanceUnit, String paceUnit) {
    final totalSeconds = durationToSeconds(
      hours: int.tryParse(hoursController.text) ?? 0,
      minutes: int.tryParse(minutesController.text) ?? 0,
      seconds: int.tryParse(secondsController.text) ?? 0,
    );
    return _calculatePaceFromSeconds(totalSeconds, distanceUnit, paceUnit);
  }
}

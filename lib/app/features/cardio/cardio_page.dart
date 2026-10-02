import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fossfit/app/services/features/cardio_services.dart';
import 'package:fossfit/app/services/features/exercise_services.dart';
import 'package:fossfit/app/shell/app_shell.dart';
import 'package:fossfit/app/utils/constants.dart';
import 'package:fossfit/app/utils/utils.dart';
import 'package:fossfit/app/widgets/animated_fab.dart';
import 'package:fossfit/app/widgets/confirmation_dialog.dart';
import 'package:fossfit/db/models/features/cardio_model.dart';
import 'package:fossfit/db/models/features/exercise_model.dart';
import 'package:fossfit/db/repositories/cardio_repository.dart';
import 'package:fossfit/db/repositories/config_reposity.dart';
import 'package:fossfit/db/repositories/exercise_repository.dart';
import 'package:provider/provider.dart';

class CardioPage extends StatefulWidget {
  final int? cardioId;
  final bool? full;
  const CardioPage({super.key, this.cardioId, this.full});

  @override
  State<CardioPage> createState() => _CardioPageState();
}

class _CardioPageState extends State<CardioPage> {
  List<Cardio>? _lastWorkoutSets;
  List<Cardio>? _cardioSets;

  Widget lastWorkout = const SizedBox.shrink();

  final expand = ExpansibleController();
  final scroll = ScrollController();

  final Set<Cardio> _selectedItems = {};

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

  bool _statsLoaded = false;

  bool get selectionMode => _selectedItems.isNotEmpty;

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

    expand.dispose();
    scroll.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<ConfigRepository>();
    final repo = context.watch<CardioRepository>();
    final exRepo = context.watch<ExercisesRepository>();

    final lastWorkoutSets = _lastWorkoutSets ?? repo.latestcardio;
    final cardioSets = _cardioSets ?? repo.cardio;

    if (isEditMode) {
      _cardioSet = _cardioSet ?? repo.getCardioById(widget.cardioId!);
      isEditMode = true;
      currentExercise = currentExercise ?? exRepo.getExerciseById(_cardioSet!.exerciseId);
      name = currentExercise!.name;
      nameTec.text = name ?? '';
      distance.text = _cardioSet!.distance.toString();
      distanceUnit = _cardioSet!.distanceUnit;
      incline.text = _cardioSet!.incline.toString();
      var duration = formatDuration(Duration(seconds: _cardioSet!.duration)).split(':');
      hoursController.text = duration[0];
      minutesController.text = duration[1];
      secondsController.text = duration[2]; /*  */
    }

    if (currentExercise == null && exRepo.cardioExercises.isNotEmpty) {
      currentExercise = exRepo.cardioExercises.first;
    }

    final showStats = config.isEnabled(.workouts, 'show_stats');

    final showImages = config.isEnabled(.workouts, 'show_images');

    final timer = config.isEnabled(.timers, 'enabled');

    final effectiveDistanceUnit =
        distanceUnit ??
        (lastWorkoutSets.isNotEmpty ? lastWorkoutSets.first.distanceUnit : currentExercise?.defaultUnit ?? 'km');

    final effectivePaceUnit = _getPaceUnit(effectiveDistanceUnit);

    if (showStats && lastWorkoutSets.isNotEmpty && !_statsLoaded) {
      _statsLoaded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadStats(lastWorkoutSets);
        }
      });
    }
    pace = _calculatePace(effectiveDistanceUnit, effectivePaceUnit);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (isEditMode) {
          _resetFields();
          if (widget.full ?? true) {
            return;
          } else {
            Navigator.of(context).pop();
            return;
          }
        }
        if (!isEditMode) Navigator.of(context).pop();
      },
      child: AppShell(
        showNavBar: widget.full ?? true,
        title: selectionMode ? '${_selectedItems.length} selected' : "${isEditMode ? 'Edit' : 'Add'} cardio session",
        selectActions: _selectActions(),
        actions: isEditMode ? _clearActions() : [],
        showTimer: timer,
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              ..._getCardioFields(effectiveDistanceUnit, effectivePaceUnit),

              Text('Cardio history', textAlign: .center),
              Divider(),
              if (lastWorkoutSets.isEmpty)
                const ListTile(title: Text('No entries yet'), subtitle: Text('Complete a session to see them here')),
              Expanded(child: _getCardioHistory(cardioSets, showImages)),
            ],
          ),
        ),
        floatingActionButton: AnimatedFab(
          onPressed: () async => save(),
          label: isEditMode ? Text('Save') : Text('Log'),
          icon: isEditMode ? Icon(Icons.save_rounded) : Icon(Icons.add_rounded),
          scroll: scroll,
          height: timer ? 60 : 0,
        ),
      ),
    );
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

  Widget _getCardioHistory(List<Cardio> cardioList, bool showImages) {
    if (isEditMode || cardioList.isEmpty) {
      return const SizedBox.shrink();
    }

    final exServices = ExerciseServices(context: context);

    return ListView.builder(
      controller: scroll,
      itemCount: cardioList.length,
      itemBuilder: (context, index) {
        final cardioSet = cardioList[index];

        final exercise = exServices.getExerciseById(cardioSet.exerciseId);

        if (exercise == null) {
          return const SizedBox.shrink();
        }
        final setPace = '${cardioSet.pace}/${cardioSet.distanceUnit}';
        final title = cardioSet.distance != null
            ? '${exercise.name}: '
                  '${cardioSet.distance}'
                  '${cardioSet.distanceUnit} in '
                  '${formatDuration(Duration(seconds: cardioSet.duration))} @ $setPace'
            : '${exercise.name} for '
                  '${formatDuration(Duration(seconds: cardioSet.duration))}';

        return ListTile(
          dense: true,
          visualDensity: VisualDensity.comfortable,
          leading: _leading(context, cardioSet, exercise, showImages),
          title: Text(title),
          selected: _selectedItems.contains(cardioSet),
          onLongPress: () {
            _toggleSelection(cardioSet);
          },
          onTap: () async {
            if (selectionMode) {
              _toggleSelection(cardioSet);
              return;
            }
            _cardioSet = cardioSet;
            setState(() {
              isEditMode = true;
              currentExercise = exercise;
              name = exercise.name;
              nameTec.text = name ?? '';
              distance.text = cardioSet.distance.toString();
              distanceUnit = cardioSet.distanceUnit;
              incline.text = cardioSet.incline.toString();
              var duration = formatDuration(Duration(seconds: cardioSet.duration)).split(':');
              hoursController.text = duration[0];
              minutesController.text = duration[1];
              secondsController.text = duration[2];
            });
          },
        );
      },
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

    return formatPace(
      totalSeconds: totalSeconds,
      totalDistance: totalDistance,
      paceUnit: paceUnit,
      distanceUnit: distanceUnit,
    );
  }

  String _calculatePace(String distanceUnit, String paceUnit) {
    final totalSeconds = durationToSeconds(
      hours: int.tryParse(hoursController.text) ?? 0,
      minutes: int.tryParse(minutesController.text) ?? 0,
      seconds: int.tryParse(secondsController.text) ?? 0,
    );
    return _calculatePaceFromSeconds(totalSeconds, distanceUnit, paceUnit);
  }

  Widget _leading(BuildContext context, Cardio set, Exercise exercise, bool showImages) {
    Widget leading = SizedBox(
      height: 24,
      width: 24,
      child: Checkbox(
        value: _selectedItems.contains(set),
        onChanged: (_) {
          _toggleSelection(set);
        },
      ),
    );

    if (!selectionMode && showImages && exercise.hasImage()) {
      leading = GestureDetector(
        onTap: () {
          _toggleSelection(set);
        },
        child: Container(
          width: 24,
          height: 24,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            image: DecorationImage(
              image: MemoryImage(exercise.image ?? Uint8List(0)),
              fit: BoxFit.cover,
              colorFilter: const ColorFilter.mode(Color.fromARGB(100, 0, 0, 0), BlendMode.darken),
            ),
          ),
        ),
      );
    } else if (!selectionMode) {
      leading = GestureDetector(
        onTap: () {
          _toggleSelection(set);
        },
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                exercise.name.isNotEmpty ? exercise.name[0] : '?',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
        ),
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 150),
      transitionBuilder: (child, animation) {
        return ScaleTransition(scale: animation, child: child);
      },
      child: leading,
    );
  }

  Widget _buildDeleteButton() {
    return IconButton(icon: const Icon(Icons.delete), onPressed: () => _showDeleteDialog());
  }

  Future<void> _showDeleteDialog() async {
    var services = CardioServices(context: context);

    final proceed = await showConfirmationDialog(
      context: context,
      title: 'Confirm delete',
      content: 'Are you sure you want to delete this session?',
      confirmStyle: TextButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
      cancelStyle: TextButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
      cancelLabel: 'No',
      confirmLabel: 'Delete',
      barrierDismissible: true,
    );

    if (proceed == null || !proceed || !mounted) return;

    //Navigator.pop(context);
    await services.deleteCardioById(widget.cardioId ?? _cardioSet!.id!);
    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> save() async {
    final exercise = currentExercise;

    if (exercise == null || exercise.id == null) {
      return;
    }

    if (isEditMode) {
      final selectedDistanceUnit = distanceUnit ?? 'km';

      final totalSeconds = durationToSeconds(
        hours: int.tryParse(hoursController.text) ?? 0,
        minutes: int.tryParse(minutesController.text) ?? 0,
        seconds: int.tryParse(secondsController.text) ?? 0,
      );

      final totalDistance = double.tryParse(distance.text);

      final paceUnit = _getPaceUnit(selectedDistanceUnit);

      final cardioSet = _cardioSet!.copyWith(
        duration: totalSeconds,
        exerciseId: exercise.id!,
        distance: totalDistance,
        distanceUnit: selectedDistanceUnit,
        pace: getPace(
          totalSeconds: totalSeconds,
          totalDistance: totalDistance ?? 0.0,
          paceUnit: paceUnit,
          distanceUnit: selectedDistanceUnit,
        ),
        incline: double.tryParse(incline.text),
        note: notes.text,
        created: DateTime.now(),
      );

      final services = CardioServices(context: context);

      await services.updateCardio(cardioSet);
    } else {
      final selectedDistanceUnit = distanceUnit ?? 'km';

      final totalSeconds = durationToSeconds(
        hours: int.tryParse(hoursController.text) ?? 0,
        minutes: int.tryParse(minutesController.text) ?? 0,
        seconds: int.tryParse(secondsController.text) ?? 0,
      );

      final totalDistance = double.tryParse(distance.text);

      final paceUnit = _getPaceUnit(selectedDistanceUnit);

      final cardioSet = Cardio(
        duration: totalSeconds,
        exerciseId: exercise.id!,
        distance: totalDistance,
        distanceUnit: selectedDistanceUnit,
        pace: getPace(
          totalSeconds: totalSeconds,
          totalDistance: totalDistance ?? 0.0,
          paceUnit: paceUnit,
          distanceUnit: selectedDistanceUnit,
        ),
        incline: double.tryParse(incline.text),
        note: notes.text,
        created: DateTime.now(),
      );

      final services = CardioServices(context: context);

      await services.insertCardio(cardioSet);
    }

    _resetFields();
  }

  void _loadStats(List<Cardio> sets) {
    final services = CardioServices(context: context);

    try {
      final workout = services.getLastCardioWorkout(sets);

      if (!mounted) {
        return;
      }

      setState(() {
        lastWorkout = workout;
      });
    } catch (_) {}
  }

  void _toggleSelection(Cardio set) {
    setState(() {
      if (_selectedItems.contains(set)) {
        _selectedItems.remove(set);
      } else {
        _selectedItems.add(set);
      }
    });
  }

  List<Widget> _clearActions() {
    return [
      _buildDeleteButton(),
      IconButton(
        onPressed: () {
          setState(() {
            _resetFields();
          });
        },
        icon: Icon(Icons.clear_rounded),
      ),
    ];
  }

  List<IconButton> _selectActions() {
    if (_selectedItems.isEmpty) {
      return [];
    }

    final setServices = CardioServices(context: context);

    final sets = setServices.getAllCardio();

    final allSelected = sets.isNotEmpty && _selectedItems.length == sets.length;

    return [
      IconButton(
        onPressed: () {
          setState(() {
            if (allSelected) {
              _selectedItems.clear();
            } else {
              _selectedItems.addAll(sets);
            }
          });
        },
        icon: Icon(allSelected ? Icons.deselect : Icons.select_all),
      ),
      IconButton(
        onPressed: () async {
          final confirmed = await showConfirmationDialog(
            context: context,
            title: 'Delete?',
            content: 'Are you sure?',
            barrierDismissible: true,
          );

          if (!mounted || confirmed != true) {
            return;
          }

          final ids = _selectedItems.map((item) => item.id).whereType<int>().toList();

          if (ids.isEmpty) {
            return;
          }

          await setServices.deleteMultipleCardiosByIds(ids);

          if (!mounted) {
            return;
          }

          setState(() {
            _selectedItems.clear();
          });
        },
        icon: const Icon(Icons.delete),
      ),
    ];
  }

  void _resetFields() {
    setState(() {
      distance.text = '0.0';

      hoursController.text = '00';
      minutesController.text = '00';
      secondsController.text = '00';

      incline.text = '0.0';

      notes.clear();

      gap = false;

      currentExercise = context.read<ExercisesRepository>().cardioExercises.firstOrNull;

      name = currentExercise?.name;

      distanceUnit = currentExercise?.defaultUnit ?? 'km';
      _cardioSet = null;
      isEditMode = false;
    });
  }
}

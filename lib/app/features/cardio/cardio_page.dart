import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fossfit/app/features/cardio/add_edit_cardio_page.dart';
import 'package:fossfit/app/services/features/cardio_services.dart';
import 'package:fossfit/app/services/features/exercise_services.dart';
import 'package:fossfit/app/shell/app_shell.dart';
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
  const CardioPage({super.key, this.cardioId});

  @override
  State<CardioPage> createState() => _CardioPageState();
}

class _CardioPageState extends State<CardioPage> {
  List<Cardio>? _lastWorkoutSets;
  List<Cardio>? _cardioSets;

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

  Exercise? currentExercise;
  String? name;

  bool get selectionMode => _selectedItems.isNotEmpty;

  bool isEditMode = false;
  Cardio? _cardioSet;

  @override
  void initState() {
    super.initState();
    if (widget.cardioId != null) {
      isEditMode = true;
    }
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

    final showImages = config.isEnabled(.workouts, 'show_images');

    final timer = config.isEnabled(.timers, 'enabled');

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (isEditMode) {
          _resetFields();
          return;
        }
        if (!isEditMode) {
          Navigator.pop(context);
        }
      },
      child: AppShell(
        title: selectionMode ? '${_selectedItems.length} selected' : "${isEditMode ? 'Edit' : 'Add'} cardio session",
        selectActions: _selectActions(),
        actions: isEditMode ? _clearActions() : [],
        showTimer: timer,
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              AddEditCardioPage(
                cardioId: _cardioSet?.id ?? widget.cardioId,
                distance: distance,
                incline: incline,
                notes: notes,
                hoursController: hoursController,
                minutesController: minutesController,
                secondsController: secondsController,
              ),
              Text('Cardio history', textAlign: .center),
              Divider(),
              if (lastWorkoutSets.isEmpty) const ListTile(title: Text('No entries yet'), subtitle: Text('Complete a session to see them here')),
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

  TextEditingController nameTec = TextEditingController();

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
          decoration: BoxDecoration(color: Theme.of(context).colorScheme.inversePrimary, borderRadius: BorderRadius.circular(12)),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                exercise.name.isNotEmpty ? exercise.name[0] : '?',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
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
        pace: getPace(totalSeconds: totalSeconds, totalDistance: totalDistance ?? 0.0, paceUnit: paceUnit, distanceUnit: selectedDistanceUnit),
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
        pace: getPace(totalSeconds: totalSeconds, totalDistance: totalDistance ?? 0.0, paceUnit: paceUnit, distanceUnit: selectedDistanceUnit),
        incline: double.tryParse(incline.text),
        note: notes.text,
        created: DateTime.now(),
      );

      final services = CardioServices(context: context);

      await services.insertCardio(cardioSet);
    }

    _resetFields();
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

  List<IconButton> _clearActions() {
    return [
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
          final confirmed = await showConfirmationDialog(context: context, title: 'Delete?', content: 'Are you sure?', barrierDismissible: true);

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

      currentExercise = context.read<ExercisesRepository>().cardioExercises.firstOrNull;

      name = currentExercise?.name;

      distanceUnit = currentExercise?.defaultUnit ?? 'km';
      _cardioSet = null;
      isEditMode = false;
    });
  }
}

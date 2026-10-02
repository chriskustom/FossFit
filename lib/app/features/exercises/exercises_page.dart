import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:fossfit/app/services/features/exercise_services.dart';
import 'package:fossfit/app/shell/app_shell.dart';
import 'package:fossfit/app/utils/constants.dart';
import 'package:fossfit/app/widgets/animated_fab.dart';
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
import 'package:timeago/timeago.dart' as timeago;

class ExercisesPage extends StatefulWidget {
  const ExercisesPage({super.key});

  @override
  State<StatefulWidget> createState() => _ExercisesPageState();
}

class _ExercisesPageState extends State<ExercisesPage> {
  late ConfigRepository config;
  List<Exercise> exercises = [];
  final ScrollController _scrollController = ScrollController();

  String search = '';
  final searchCtrl = TextEditingController();

  final Set<Exercise> _selectedItems = {};
  bool get selectionMode => _selectedItems.isNotEmpty;

  bool isDeleting = false;
  int? selectedType;
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    config = context.watch<ConfigRepository>();
    var exRepo = context.watch<ExercisesRepository>();
    var gymSetRepo = context.watch<GymSetRepository>();
    var cardioRepo = context.watch<CardioRepository>();
    exercises = exRepo.exercises;
    final matching = exercises.where((exercise) {
      if (selectedType != null && exercise.type != selectedType) {
        return false;
      }

      if (search.isNotEmpty && !exercise.name.toLowerCase().contains(search.toLowerCase())) {
        return false;
      }

      return true;
    }).toList();

    final dateFormat = config.getSetting(.formats, 'long_date_format');
    return AppShell(
      showSearch: false,
      selectActions: _selectActions(),
      title: selectionMode ? '${_selectedItems.length} selected' : 'Exercises',
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.all(8),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SearchBar(
                    leading: const Padding(padding: EdgeInsets.all(8.0), child: Icon(Icons.search)),
                    textCapitalization: TextCapitalization.sentences,
                    hintText: 'Search exercises...',
                    controller: searchCtrl,
                    onChanged: (value) {
                      setState(() {
                        search = value;
                      });
                    },
                    trailing: buildFilterMenu(
                      selectedType: selectedType,
                      onChanged: (value) {
                        setState(() {
                          selectedType = value;
                        });
                      },
                    ),
                  ),
                ),

                if (matching.isEmpty)
                  _buildNothingFound()
                else
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: matching.length,
                      itemBuilder: (context, index) {
                        var exercise = matching[index];
                        var lastSet = exercise.type == 0
                            ? gymSetRepo.gymsets.where((g) => g.exerciseId == exercise.id).toList()
                            : cardioRepo.cardio.where((g) => g.exerciseId == exercise.id).toList();
                        lastSet.sorted((a, b) => b.created.compareTo(a.created));
                        var subtitle = lastSet.isEmpty
                            ? Text('Never completed')
                            : Text(
                                'Last completed - ${dateFormat == 'timeago' ? timeago.format(lastSet.first.created) : DateFormat(dateFormat).format(lastSet.first.created)}',
                              );
                        return ListTile(
                          key: Key('${exercise.id}-${exercise.name}'),
                          leading: _leading(exercise),
                          title: Text(exercise.name),
                          subtitle: subtitle,
                          selected: _selectedItems.contains(exercise),
                          onLongPress: () => _toggleSelection(exercise),
                          onTap: () async {
                            if (selectionMode) {
                              _toggleSelection(exercise);
                            } else {
                              var exServices = ExerciseServices(context: context);
                              if (exercise.type == 0) {
                                var data = await gymSetRepo.getStrengthData(
                                  target: lastSet.cast<GymSet>().firstOrNull?.unit ?? exercise.defaultUnit ?? 'kg',
                                  exerciseId: exercise.id!,
                                  metric: StrengthMetric.bestWeight,
                                  period: Period.day,
                                  start: null,
                                  end: null,
                                  limit: 20,
                                );
                                if (!context.mounted) return;

                                await exServices.openStrengthPage(context, exercise.id!, data);
                              } else {
                                var data = await cardioRepo.getCardioData(
                                  target:
                                      lastSet.cast<Cardio>().firstOrNull?.distanceUnit ?? exercise.defaultUnit ?? 'km',
                                  exerciseId: exercise.id!,
                                  metric: CardioMetric.pace,
                                  period: Period.day,
                                  start: null,
                                  end: null,
                                );
                                if (!context.mounted) return;

                                await exServices.openCardioPage(context, exercise.id!, data);
                              }
                            }
                          },
                        );
                      },
                    ),
                  ),
              ],
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
      floatingActionButton: AnimatedFab(
        onPressed: () async {
          var services = ExerciseServices(context: context);
          await services.openAddEditExercisePage(context, null, null);
        },
        label: const Text('Add'),
        icon: const Icon(Icons.add),
        scroll: _scrollController,
      ),
    );
  }

  List<Widget> buildFilterMenu({required int? selectedType, required ValueChanged<int?> onChanged}) {
    return [
      PopupMenuButton<int?>(
        icon: Icon(
          selectedType == null
              ? Icons.filter_list
              : selectedType == 0
              ? Icons.fitness_center
              : Icons.directions_run,
        ),
        onSelected: (value) => onChanged(value),
        itemBuilder: (context) => [
          const PopupMenuItem<int?>(
            value: null,
            child: Row(children: [Icon(Icons.list), SizedBox(width: 12), Text('All')]),
          ),
          const PopupMenuItem<int?>(
            value: 0,
            child: Row(children: [Icon(Icons.fitness_center), SizedBox(width: 12), Text('Strength')]),
          ),
          const PopupMenuItem<int?>(
            value: 1,
            child: Row(children: [Icon(Icons.directions_run), SizedBox(width: 12), Text('Cardio')]),
          ),
        ],
      ),
    ];
  }

  Widget _buildNothingFound() {
    if (search.trim().isEmpty) {
      return const ListTile(title: Text('Nothing found'));
    }

    return ListTile(
      title: const Text('Nothing found'),
      subtitle: Text('Tap to create $search'),
      onTap: () async {
        var services = ExerciseServices(context: context);
        await services.openAddEditExercisePage(context, null, search);
      },
    );
  }

  Widget _leading(Exercise exercise) {
    var showImages = config.isEnabled(.workouts, 'show_image');
    Widget? leading = SizedBox(
      height: 24,
      width: 24,
      child: Checkbox(value: _selectedItems.contains(exercise), onChanged: (_) => _toggleSelection(exercise)),
    );

    if (!selectionMode && showImages && exercise.hasImage()) {
      leading = GestureDetector(
        onTap: () => _toggleSelection(exercise),
        child: Container(
          width: 24,
          height: 24,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            image: DecorationImage(
              image: MemoryImage(exercise.image ?? Uint8List(0)),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(Color.fromARGB(100, 0, 0, 0), BlendMode.darken),
            ),
          ),
        ),
      );
    } else if (!selectionMode) {
      leading = GestureDetector(
        onTap: () => _toggleSelection(exercise),
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 2),
              child: Text(
                exercise.name.isNotEmpty ? exercise.name[0].toUpperCase() : '?',
                textAlign: TextAlign.justify,
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

    leading = AnimatedSwitcher(
      duration: const Duration(milliseconds: 150),
      transitionBuilder: (child, animation) {
        return ScaleTransition(scale: animation, child: child);
      },
      child: leading,
    );
    return leading;
  }

  void _toggleSelection(Exercise plan) {
    setState(() {
      _selectedItems.contains(plan) ? _selectedItems.remove(plan) : _selectedItems.add(plan);
    });
  }

  List<IconButton> _selectActions() {
    final planServices = ExerciseServices(context: context);
    final plans = planServices.getAllExercises();
    List<IconButton> buttons = [];
    if (_selectedItems.isNotEmpty) {
      buttons.add(
        IconButton(
          onPressed: () {
            setState(() {
              if (_selectedItems.length == plans.length) {
                _selectedItems.clear();
              } else {
                _selectedItems.addAll(plans);
              }
            });
          },
          icon: Icon(_selectedItems.length == plans.length ? Icons.deselect : Icons.select_all),
        ),
      );

      buttons.addAll([
        IconButton(
          onPressed: () async {
            final confirmed = await showConfirmationDialog(
              context: context,
              title: "Delete?",
              content:
                  'Deleting multiple exercises will delete every set for those exercises, \nand remove the exercise from any plans they are included in.'
                  '\nThis is destructive and non-reversible.'
                  '\nPlease back-up your database first.'
                  '\n\nAre you sure you wish to continue?',
              barrierDismissible: true,
              confirmStyle: TextButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
              cancelStyle: TextButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
              cancelLabel: 'No, Cancel',
              confirmLabel: 'Yes, Delete.',
            );

            if (!mounted || confirmed == null || !confirmed) return;
            setState(() {
              isDeleting = true;
            });
            await planServices.deleteExercises(_selectedItems.map((i) => i.id!).toList());
            setState(() {
              isDeleting = false;
              _selectedItems.clear();
            });
          },
          icon: const Icon(Icons.delete),
        ),
      ]);
    }
    return buttons;
  }
}

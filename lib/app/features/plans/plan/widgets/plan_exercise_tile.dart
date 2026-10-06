import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fossfit/app/services/features/gym_set_services.dart';
import 'package:fossfit/app/utils/constants.dart';
import 'package:fossfit/app/utils/utils.dart';
import 'package:fossfit/app/widgets/custom_set_indicator.dart';
import 'package:fossfit/app/widgets/exercise_icon.dart';
import 'package:fossfit/db/models/features/exercise_model.dart';
import 'package:fossfit/db/models/features/gymset_model.dart';
import 'package:fossfit/db/models/features/plan_exercise_model.dart';
import 'package:fossfit/db/repositories/config_reposity.dart';
import 'package:fossfit/db/repositories/gym_set_repository.dart';
import 'package:fossfit/db/repositories/plan_exercises_repository.dart';
import 'package:provider/provider.dart';

class PlanExerciseTile extends StatefulWidget {
  final int planId;
  final int index;

  final TextEditingController notes;
  final TextEditingController weight;
  final TextEditingController reps;
  final TextEditingController unit;

  final Exercise exercise;

  final ExpansibleController expander;
  final Function(bool open) onExpansionChanged;
  final Function() onFieldSubmitted;
  final Function() onSwap;
  const PlanExerciseTile({
    super.key,
    required this.planId,
    required this.index,
    required this.expander,
    required this.onExpansionChanged,
    required this.notes,
    required this.weight,
    required this.reps,
    required this.unit,
    required this.exercise,
    required this.onFieldSubmitted,
    required this.onSwap,
  });

  @override
  State<PlanExerciseTile> createState() => _PlanExerciseTileState();
}

class _PlanExerciseTileState extends State<PlanExerciseTile> {
  String? category;
  String? image;
  PlanExercise? currentPlanExercise;
  String title = '';

  late ConfigRepository config;

  @override
  void initState() {
    if (widget.index == 0) widget.expander.expand();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    config = context.watch<ConfigRepository>();
    var peRepo = context.watch<PlanExercisesRepository>();
    final services = GymSetServices(context: context);
    final planExercise = currentPlanExercise ?? peRepo.getPlanExerciseByExerciseAndPlan(widget.exercise.id!, widget.planId)!;

    final max = planExercise.maxSets ?? widget.exercise.defaultSets ?? 3;
    final completedSets = services.getTodaysSetsByExerciseId(widget.exercise.id!, widget.planId);
    final showImages = config.isEnabled(.workouts, 'show_images');
    final lastSets = services.getSetsByExerciseId(widget.exercise.id!, limit: max);

    widget.reps.text = (lastSets.firstOrNull?.reps ?? 0).toString();
    widget.weight.text = (lastSets.firstOrNull?.weight ?? 0.0).toString();
    widget.notes.text = (lastSets.firstOrNull?.note ?? '');
    widget.unit.text = (lastSets.firstOrNull?.unit ?? widget.exercise.defaultUnit).toString();

    return GestureDetector(
      onLongPress: () => _showExerciseModal(context, planExercise, completedSets),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.all(2),
              initiallyExpanded: widget.index == 0,
              controller: widget.expander,
              textColor: Theme.of(context).colorScheme.primary,
              trailing: ReorderableDragStartListener(
                index: widget.index,
                child: Platform.isAndroid ? const Icon(Icons.drag_handle, size: 32) : const SizedBox.shrink(),
              ),
              onExpansionChanged: (open) => widget.onExpansionChanged(open),
              title: _buildExerciseTitle(widget.exercise, planExercise, completedSets.length, max, showImages),
              children: [
                strengthFields(completedSets.length, max),
                unitSelector(),
                notesField(),
                const SizedBox(height: 4),
                CustomSetIndicator(sets: completedSets, max: max),
              ],
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildExerciseTitle(Exercise exercise, PlanExercise planExercise, int completedSets, int max, bool showImages) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(color: Theme.of(context).colorScheme.secondaryContainer, borderRadius: BorderRadius.circular(12)),
          child: showImages && exercise.hasImage() == true
              ? Stack(
                  children: [
                    ExerciseIcon(exercise: exercise, showImages: showImages),
                    if (completedSets == max) Icon(Icons.check, size: 20),
                  ],
                )
              : Center(
                  child: completedSets == max
                      ? Icon(Icons.check, size: 20)
                      : Text(
                          exercise.name[0].toUpperCase(),
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                        ),
                ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(exercise.name, overflow: TextOverflow.ellipsis)),
        const SizedBox(width: 8),
        if (widget.expander.isExpanded == false) ..._buildBlips(exercise, planExercise, completedSets),
      ],
    );
  }

  Widget strengthFields(int done, int max) {
    final screenWidth = MediaQuery.of(context).size.width;

    final repsField = TextFormField(
      controller: widget.reps,
      decoration: const InputDecoration(labelText: 'Reps'),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: TextInputAction.next,
      onFieldSubmitted: (_) => selectAll(widget.weight),
      onTap: () => selectAll(widget.reps),
      validator: _requiredNumberValidator,
    );

    final weightField = TextFormField(
      controller: widget.weight,
      decoration: InputDecoration(labelText: 'Weight (${widget.unit.text})'),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onTap: () => selectAll(widget.weight),
      onFieldSubmitted: (_) => widget.onFieldSubmitted(),
      validator: _requiredNumberValidator,
    );

    if (screenWidth <= 450) {
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [repsField, const SizedBox(height: 8), weightField]);
    }

    return Row(
      children: [
        Expanded(child: repsField),
        const SizedBox(width: 8),
        Expanded(child: weightField),
      ],
    );
  }

  Widget unitSelector() {
    return Selector<ConfigRepository, bool>(
      selector: (context, settings) => settings.isEnabled(.workouts, 'show_units'),
      builder: (context, showUnits, child) {
        if (!showUnits) {
          return const SizedBox.shrink();
        }

        return DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            labelText: 'Unit',
            labelStyle: TextStyle(overflow: TextOverflow.ellipsis),
          ),
          initialValue: widget.unit.text,
          items: unitsList.map((u) => DropdownMenuItem(value: u.key, child: Text(u.value))).toList(),
          onChanged: (value) {
            widget.unit.text = value!;
          },
        );
      },
    );
  }

  Widget notesField() {
    return Selector<ConfigRepository, bool>(
      selector: (context, settings) => settings.isEnabled(.workouts, 'show_notes'),
      builder: (context, showNotes, child) {
        if (!showNotes) {
          return const SizedBox.shrink();
        }

        return TextFormField(
          controller: widget.notes,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Notes', border: InputBorder.none),
        );
      },
    );
  }

  List<Widget> _buildBlips(Exercise exercise, PlanExercise planExercise, int completedSets) {
    final items = <Widget>[];

    var maxSets = planExercise.maxSets ?? exercise.defaultSets ?? 3;
    for (int i = 0; i < maxSets; i++) {
      items.add(
        SizedBox(
          width: 10,
          child: Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(2), color: Theme.of(context).colorScheme.outlineVariant),
            height: 4,
            child: AnimatedFractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: completedSets > i ? 1 : 0,
              duration: const Duration(milliseconds: 250),
              curve: Curves.ease,
              child: DecoratedBox(
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(2), color: Theme.of(context).colorScheme.primary),
              ),
            ),
          ),
        ),
      );

      if (i < maxSets - 1) {
        items.add(const SizedBox(width: 6));
      }
    }

    return items;
  }

  String? _requiredNumberValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Required';
    }

    if (double.tryParse(value) == null) {
      return 'Invalid number';
    }

    return null;
  }

  final max = TextEditingController();
  Future<void> _showExerciseModal(BuildContext context, PlanExercise exercise, List<GymSet> sets) async {
    final peRepo = context.read<PlanExercisesRepository>();
    final setsRepo = context.read<GymSetRepository>();

    await showModalBottomSheet(
      useRootNavigator: true,
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Settings'),
                onTap: () async {
                  Navigator.pop(context);

                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog.adaptive(
                        title: Text(widget.exercise.name),
                        content: SingleChildScrollView(
                          child: Column(
                            children: [
                              const SizedBox(height: 16),
                              TextField(
                                controller: max,
                                keyboardType: const TextInputType.numberWithOptions(decimal: false),
                                onTap: () => selectAll(max),
                                onChanged: (value) async {
                                  await peRepo.updatePlanExercise(exercise.copyWith(maxSets: int.tryParse(value) ?? 3));
                                },
                                decoration: InputDecoration(
                                  labelText: "Working sets (max: 20)",
                                  border: const OutlineInputBorder(),
                                  hintText: exercise.maxSets.toString(),
                                ),
                              ),
                            ],
                          ),
                        ),
                        actions: [
                          TextButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            label: const Text("OK"),
                            icon: const Icon(Icons.check),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
              if (sets.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('Edit'),
                  onTap: () async {
                    Navigator.pop(context);
                    final gymSet = sets.first;

                    var services = GymSetServices(context: context);
                    await services.openAddEditPage(context, gymSet.id);
                  },
                ),
              if (sets.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.undo),
                  title: const Text('Undo'),
                  onTap: () async {
                    Navigator.pop(context);
                    final gymSet = sets.first;
                    await setsRepo.deleteGymSetById(gymSet.id!);

                    setState(() {});
                  },
                ),
              if (sets.isEmpty) ListTile(leading: const Icon(Icons.swap_horiz), title: const Text('Swap'), onTap: () => widget.onSwap()),
            ],
          ),
        );
      },
    );
  }
}

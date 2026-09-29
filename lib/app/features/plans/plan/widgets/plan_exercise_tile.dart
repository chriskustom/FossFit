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
import 'package:fossfit/db/repositories/exercise_repository.dart';
import 'package:fossfit/db/repositories/gym_set_repository.dart';
import 'package:fossfit/db/repositories/plan_exercises_repository.dart';
import 'package:provider/provider.dart';

class PlanExerciseTile extends StatefulWidget {
  final int planId;
  final int exerciseId;
  final int index;
  final ExpansibleController expander;
  final Function(bool open) onExpansionChanged;
  const PlanExerciseTile({
    super.key,
    required this.exerciseId,
    required this.planId,
    required this.index,
    required this.expander,
    required this.onExpansionChanged,
  });

  @override
  State<PlanExerciseTile> createState() => _PlanExerciseTileState();
}

class _PlanExerciseTileState extends State<PlanExerciseTile> {
  TextEditingController reps = TextEditingController(text: '0.0');
  TextEditingController weight = TextEditingController(text: '0.0');
  TextEditingController notes = TextEditingController();
  String? category;
  String? image;
  Exercise? currentExercise;
  PlanExercise? currentPlanExercise;

  String unit = 'kg';
  String title = '';

  late ConfigRepository config;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    config = context.watch<ConfigRepository>();
    var peRepo = context.watch<PlanExercisesRepository>();
    var exRepo = context.watch<ExercisesRepository>();
    final services = GymSetServices(context: context);
    final planExercise = currentPlanExercise ?? peRepo.getPlanExercisesById(widget.exerciseId, widget.planId)!;
    final exercise = currentExercise ?? exRepo.getExerciseById(widget.exerciseId)!;
    final max = currentPlanExercise?.maxSets ?? currentExercise?.defaultSets ?? 3;
    final completedSets = _todaySetsStream(exercise);
    final showImages = config.isEnabled(.workouts, 'show_images');
    final lastSets = services.getSetsByExerciseId(exercise.id!);
    reps.text = (lastSets.firstOrNull?.reps ?? 0).toString();
    weight.text = (lastSets.firstOrNull?.weight ?? 0.0).toString();
    notes.text = (lastSets.firstOrNull?.note ?? '');
    unit = (lastSets.firstOrNull?.unit ?? exercise.defaultUnit).toString();
    return Column(
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
            title: _buildExerciseTitle(exercise, planExercise, completedSets.length, max, widget.index, showImages),
            children: [
              strengthFields(),
              unitSelector(),
              notesField(),
              const SizedBox(height: 4),
              CustomSetIndicator(sets: _todaySetsStream(exercise), max: max),
            ],
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _buildExerciseTitle(
    Exercise exercise,
    PlanExercise planExercise,
    int count,
    int max,
    int index,
    bool showImages,
  ) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.inversePrimary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: showImages && exercise.hasImage() == true
              ? Stack(
                  children: [
                    ExerciseIcon(exercise: exercise, showImages: showImages),
                    if (count == max) Icon(Icons.check, size: 20),
                  ],
                )
              : Center(
                  child: count == max
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
        if (widget.expander.isExpanded == false) ..._buildBlips(exercise, planExercise),
      ],
    );
  }

  Widget strengthFields() {
    final screenWidth = MediaQuery.of(context).size.width;

    final repsField = TextFormField(
      controller: reps,
      decoration: const InputDecoration(labelText: 'Reps'),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: TextInputAction.next,
      onFieldSubmitted: (_) => selectAll(weight),
      onTap: () => selectAll(reps),
      validator: _requiredNumberValidator,
    );

    final weightField = _weightField(
      onFieldSubmitted: (_) => {
        //TODO SAVE
      },
    );

    if (screenWidth <= 450) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [repsField, const SizedBox(height: 8), weightField],
      );
    }

    return Row(
      children: [
        Expanded(child: repsField),
        const SizedBox(width: 8),
        Expanded(child: weightField),
      ],
    );
  }

  Widget _weightField({required void Function(String) onFieldSubmitted}) {
    return TextFormField(
      controller: weight,
      decoration: InputDecoration(labelText: 'Weight ($unit)'),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onTap: () => selectAll(weight),
      onFieldSubmitted: onFieldSubmitted,
      validator: _requiredNumberValidator,
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
          initialValue: unit,
          items: unitsList.map((u) => DropdownMenuItem(value: u.key, child: Text(u.value))).toList(),
          onChanged: (value) {
            unit = value!;
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
          controller: notes,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Notes', border: InputBorder.none),
        );
      },
    );
  }

  List<Widget> _buildBlips(Exercise exercise, PlanExercise planExercise) {
    final items = <Widget>[];
    var completedSets = _todaySetsStream(exercise).length;

    var maxSets = planExercise.maxSets ?? exercise.defaultSets ?? 3;
    for (int i = 0; i < maxSets; i++) {
      items.add(
        SizedBox(
          width: 10,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            height: 4,
            child: AnimatedFractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: completedSets > i ? 1 : 0,
              duration: const Duration(milliseconds: 250),
              curve: Curves.ease,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: Theme.of(context).colorScheme.primary,
                ),
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

  List<GymSet> _todaySetsStream(Exercise exercise) {
    final sets = context.read<GymSetRepository>().gymsets;

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final startOfTomorrow = startOfDay.add(const Duration(days: 1));

    final todays = sets
        .where(
          (set) =>
              set.planId == widget.planId &&
              set.exerciseId == exercise.id &&
              set.created.isAfter(startOfDay) &&
              set.created.isBefore(startOfTomorrow),
        )
        .toList();

    todays.sort((a, b) => a.created.compareTo(b.created));

    return todays;
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
}

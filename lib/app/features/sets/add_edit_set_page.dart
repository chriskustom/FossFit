import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:fossfit/app/features/workout/widgets/workout_peek.dart';
import 'package:fossfit/app/services/features/exercise_services.dart';
import 'package:fossfit/app/services/features/gym_set_services.dart';
import 'package:fossfit/app/services/image_services.dart';
import 'package:fossfit/app/shell/app_shell.dart';
import 'package:fossfit/app/utils/constants.dart';
import 'package:fossfit/app/utils/utils.dart';
import 'package:fossfit/app/widgets/animated_fab.dart';
import 'package:fossfit/app/widgets/app_snack_bar.dart';
import 'package:fossfit/app/widgets/confirmation_dialog.dart';
import 'package:fossfit/db/models/features/exercise_model.dart';
import 'package:fossfit/db/models/features/gymset_model.dart';
import 'package:fossfit/db/repositories/config_reposity.dart';
import 'package:fossfit/db/repositories/exercise_repository.dart';
import 'package:fossfit/db/repositories/gym_set_repository.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

class AddEditSetPage extends StatefulWidget {
  final int? setId;

  const AddEditSetPage({super.key, this.setId});

  @override
  createState() => _AddEditSetPageState();
}

class _AddEditSetPageState extends State<AddEditSetPage> {
  final repsTEC = TextEditingController();
  final weightTEC = TextEditingController();
  final ormTEC = TextEditingController();
  final bodyWeightTEC = TextEditingController();
  final noteTEC = TextEditingController();
  final weightNode = FocusNode();
  final repsNode = FocusNode();
  TextEditingController categoryTEC = TextEditingController();
  TextEditingController exerciseNameTEC = TextEditingController();

  List<Exercise> exercises = [];
  DateTime created = DateTime.now().toLocal();
  bool isEditMode = false;

  int? rest;
  Uint8List? image;
  String? category;
  String? unit;
  String? name;
  bool isDeleting = false;
  late bool dateSet = false;

  late ConfigRepository config;
  late Exercise currentExercise;
  GymSet? gymSet;

  @override
  void initState() {
    super.initState();
    isEditMode = widget.setId != null;
    if (isEditMode) {
      currentSetId.value = widget.setId;
    }
  }

  @override
  void dispose() {
    super.dispose();
    repsTEC.dispose();
    ormTEC.dispose();
    noteTEC.dispose();
    weightNode.dispose();
    weightTEC.dispose();
    bodyWeightTEC.dispose();
    repsNode.dispose();
  }

  @override
  Widget build(BuildContext context) {
    config = context.watch<ConfigRepository>();
    var exerciseRepo = context.watch<ExercisesRepository>();
    var setServices = GymSetServices(context: context);
    gymSet = setServices.getGymSetById(widget.setId ?? 0);

    if (isEditMode) {
      //set exercuse to gymset exercise
      currentExercise = exerciseRepo.getExerciseById(gymSet!.exerciseId)!;
      updateFields(gymSet);
    }
    if (!isEditMode && name == null) {
      //initial load of new set
      //set exercise to last completed exercise (or first if none completed)
      var lastSet = setServices.getLastGymSet();
      var lastExercise = exerciseRepo.getExerciseById(lastSet?.exerciseId ?? 0);
      currentExercise = lastExercise ?? exerciseRepo.exercises.first;
      updateFields(lastSet);
    }
    if (!isEditMode && name != null) {
      //exercise has changed, get details of last gymset from this exercise
      //get exercise
      currentExercise = exerciseRepo.getExerciseByName(name!) ?? currentExercise;
      var lastSet = setServices.getSetsByExerciseId(currentExercise.id!).firstOrNull;
      updateFields(lastSet);
    }

    return AppShell(
      title: currentExercise.name,
      body: buildBody(),
      actions: [if (widget.setId != null) buildDeleteButton()],
      floatingActionButton: buildSaveButton(),
    );
  }

  //region Fields
  Widget buildDeleteButton() {
    return IconButton(icon: const Icon(Icons.delete), onPressed: () => showDeleteDialog());
  }

  Future<void> showDeleteDialog() async {
    var services = GymSetServices(context: context);

    final proceed = await showConfirmationDialog(
      context: context,
      title: 'Confirm delete',
      content: 'Are you sure you want to delete this set?',
      confirmStyle: TextButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
      cancelStyle: TextButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
      cancelLabel: 'No',
      confirmLabel: 'Delete',
      barrierDismissible: true,
    );

    if (proceed == null || !proceed || !mounted) return;

    Navigator.pop(context);
    await services.deleteGymSetById(widget.setId!);
    if (mounted) {
      Navigator.pop(context);
    }
  }

  Widget buildBody() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: Key(currentExercise.name),
        child: Consumer<ConfigRepository>(
          builder: (context, configRepository, child) {
            final showUnits = configRepository.isEnabled(.workouts, 'show_units');
            final showCategories = configRepository.isEnabled(.workouts, 'show_categories');
            final showNotes = configRepository.isEnabled(.workouts, 'show_notes');
            final showImages = configRepository.isEnabled(.workouts, 'show_images');
            final showBodyweight = configRepository.isEnabled(.workouts, 'show_bodyweight');

            return ListView(
              children: [
                nameAutoCompleteField(),
                const SizedBox(height: 8.0),
                ...buildStrengthFields(),
                const SizedBox(height: 8.0),
                if (showBodyweight) ...[bodyWeightFields(), const SizedBox(height: 8.0)],
                if (showUnits) ...[unitSelector(), const SizedBox(height: 8.0)],
                if (showCategories) ...[categorySelector(), const SizedBox(height: 8.0)],
                if (showNotes) ...[notesField(), const SizedBox(height: 8.0)],
                dateSelector(),
                if (showImages) ...[const SizedBox(height: 8.0), imageField()],
                if (name != '') ...[
                  SizedBox(height: 300, child: WorkoutPeek(sets: getHistory())),
                  const SizedBox(height: 8.0),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> buildStrengthFields() {
    return [
      Row(
        children: [
          Expanded(child: buildRepsField()),
          const SizedBox(width: 8),
          Expanded(child: buildWeightField()),
        ],
      ),
      const SizedBox(height: 8),
      if (name != 'Weight') buildORMField(),
    ];
  }

  Widget buildRepsField() {
    return TextFormField(
      controller: repsTEC,
      focusNode: repsNode,
      decoration: const InputDecoration(labelText: 'Reps'),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onTap: () => selectAll(repsTEC),
      onChanged: (value) => setORM(),
      textInputAction: TextInputAction.next,
      onFieldSubmitted: (_) => selectAll(weightTEC),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Required';
        if (double.tryParse(value) == null) return 'Invalid number';
        return null;
      },
    );
  }

  Widget buildWeightField() {
    return TextFormField(
      controller: weightTEC,
      decoration: InputDecoration(labelText: 'Weight ($unit)'),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onTap: () => selectAll(weightTEC),
      onFieldSubmitted: (value) async {
        var gymSet = await save();
        if (gymSet != null && mounted) {
          Navigator.pop(context, gymSet);
        }
      },
      onChanged: (value) => setORM(),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Required';
        if (double.tryParse(value) == null) return 'Invalid number';
        return null;
      },
    );
  }

  Widget buildORMField() {
    return TextField(
      controller: ormTEC,
      decoration: const InputDecoration(labelText: 'One rep max (estimate)'),
      enabled: false,
    );
  }

  Widget bodyWeightFields() {
    return TextFormField(
      controller: bodyWeightTEC,
      decoration: InputDecoration(labelText: 'Body weight ($unit)'),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onTap: () => selectAll(bodyWeightTEC),
      validator: (value) {
        if (value == null) return null;
        if (value.isNotEmpty && double.tryParse(value) == null) {
          return 'Invalid number';
        }
        return null;
      },
    );
  }

  Widget unitSelector() {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(labelText: 'Unit'),
      initialValue: unit,
      items: unitsList.map((u) => DropdownMenuItem(value: u.key, child: Text(u.value))).toList(),
      onChanged: (String? newValue) {
        setState(() {
          unit = newValue!;
        });
      },
    );
  }

  Widget categorySelector() {
    var repo = context.read<ExercisesRepository>();
    return FutureBuilder(
      future: repo.getDistinctCategories(),
      builder: (context, snapshot) {
        return Autocomplete<String>(
          initialValue: TextEditingValue(text: currentExercise.category ?? ""),
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (snapshot.data == null) return [];
            if (textEditingValue.text == '') {
              return snapshot.data!;
            }
            return snapshot.data!.where((String option) {
              return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
            });
          },
          onSelected: (String selection) {
            category = selection;
          },
          fieldViewBuilder:
              (
                BuildContext context,
                TextEditingController textEditingController,
                FocusNode focusNode,
                VoidCallback onFieldSubmitted,
              ) {
                categoryTEC = textEditingController;
                return TextFormField(
                  controller: textEditingController,
                  focusNode: focusNode,
                  decoration: const InputDecoration(labelText: 'Category'),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Required';
                    if (!snapshot.data!.contains(value)) return 'Invlaid';
                    return null;
                  },
                  onChanged: (value) {
                    if (value.isEmpty || !snapshot.data!.contains(value)) return;
                    category = value;
                  },
                );
              },
        );
      },
    );
  }

  Widget notesField() {
    return TextField(
      maxLines: 3,
      decoration: const InputDecoration(labelText: 'Notes'),
      textCapitalization: TextCapitalization.sentences,
      controller: noteTEC,
    );
  }

  Widget dateSelector() {
    final lastSet = context
        .read<GymSetRepository>()
        .gymsets
        .where((e) => e.exerciseId == currentExercise.id)
        .firstOrNull;

    if (lastSet == null) {
      return const ListTile(
        title: Text('Created date'),
        subtitle: Text('No date available'),
        trailing: Icon(Icons.calendar_today),
      );
    }

    final lastDate = lastSet.created;
    final now = DateTime.now();

    final displayDate = !isEditMode
        ? now
        : lastDate.add(const Duration(minutes: 3)).isAfter(now)
        ? now
        : gymSet != null
        ? gymSet!.created
        : lastDate.add(const Duration(minutes: 3));

    created = dateSet ? created : displayDate;

    return Selector<ConfigRepository, String>(
      selector: (context, settings) => settings.getSetting(.formats, 'long_date_format'),
      builder: (context, longDateFormat, child) => ListTile(
        title: const Text('Created date'),
        subtitle: Text(
          longDateFormat == 'timeago' ? timeago.format(created) : DateFormat(longDateFormat).format(created),
        ),
        trailing: const Icon(Icons.calendar_today),
        onTap: () => selectDate(),
      ),
    );
  }

  Widget buildSaveButton() {
    return AnimatedFab(
      onPressed: () async {
        var gymSet = await save();
        if (gymSet != null && mounted) {
          Navigator.pop(context, gymSet);
        }
      },
      label: const Text("Save"),
      icon: const Icon(Icons.save),
    );
  }

  Selector<ConfigRepository, bool> imageField() {
    final imageSize = MediaQuery.of(context).size.width * 0.25;
    return Selector<ConfigRepository, bool>(
      selector: (context, settings) => settings.isEnabled(.workouts, 'show_images'),
      builder: (context, showImages, child) {
        return Column(
          children: [
            if (image == null || !currentExercise.hasImage())
              TextButton.icon(
                onPressed: () async {
                  var pickedImage = await pickImage(context);
                  if (pickedImage != null || pickedImage!.isNotEmpty) {
                    setState(() {
                      image = pickedImage;
                    });
                  }
                },
                label: const Text('Image'),
                icon: const Icon(Icons.image),
              ),
            if (image != null && currentExercise.hasImage()) ...[
              const SizedBox(height: 8),
              Tooltip(
                message: 'Long-press to delete',
                child: GestureDetector(
                  onTap: () => () async {
                    var pickedImage = await pickImage(context);
                    if (pickedImage != null || pickedImage!.isNotEmpty) {
                      setState(() {
                        image = pickedImage;
                      });
                    }
                  },
                  onLongPress: () => setState(() {
                    image = null;
                    isDeleting = true;
                  }),
                  child: Container(
                    width: imageSize,
                    height: imageSize,
                    clipBehavior: Clip.hardEdge,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(imageSize * 0.15),
                      image: DecorationImage(image: MemoryImage(image ?? Uint8List(0)), fit: BoxFit.contain),
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  List<GymSet> getHistory() {
    var services = GymSetServices(context: context);
    return services.getSetsByExerciseId(currentExercise.id!);
  }

  Widget nameAutoCompleteField() {
    var repo = context.read<ExercisesRepository>();
    return FutureBuilder(
      future: repo.getExerciseNames(),
      builder: (context, snapshot) {
        return Autocomplete<String>(
          initialValue: TextEditingValue(text: currentExercise.name),
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (snapshot.data == null) return [];
            if (textEditingValue.text == '') {
              return snapshot.data!;
            }
            return snapshot.data!.where((String option) {
              return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
            });
          },
          onSelected: (String selection) {
            setState(() {
              name = selection;
              currentExercise = repo.getExerciseByName(selection) ?? currentExercise;
            });
          },
          fieldViewBuilder:
              (
                BuildContext context,
                TextEditingController textEditingController,
                FocusNode focusNode,
                VoidCallback onFieldSubmitted,
              ) {
                exerciseNameTEC = textEditingController;
                return TextFormField(
                  controller: textEditingController,
                  focusNode: focusNode,
                  decoration: const InputDecoration(labelText: 'Exercise name'),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Required';
                    if (!snapshot.data!.contains(value)) return 'Invlaid';
                    return null;
                  },
                  onChanged: (value) {
                    if (value.isEmpty || !snapshot.data!.contains(value)) return;
                    setState(() {
                      name = value;
                      currentExercise = repo.getExerciseByName(value) ?? currentExercise;
                    });
                  },
                );
              },
        );
      },
    );
  }
  //endregion

  //region helpers

  void updateFields(GymSet? gymSet) {
    if (gymSet != null) {
      unit = gymSet.unit ?? currentExercise.defaultUnit!;
      rest = gymSet.rest ?? currentExercise.defaultRest;
      if (gymSet.reps != 0) repsTEC.text = gymSet.reps.toString();
      weightTEC.text = toString(gymSet.weight);
      setORM();
      if (gymSet.bodyWeight != 0) bodyWeightTEC.text = toString(gymSet.bodyWeight!);
      if (currentExercise.category != null && currentExercise.category!.isNotEmpty) {
        categoryTEC.text = currentExercise.category!;
      }
      if (gymSet.note != null && gymSet.note!.isNotEmpty) {
        noteTEC.text = gymSet.note!;
      }
    } else {
      unit = currentExercise.defaultUnit!;
      rest = currentExercise.defaultRest;
    }
    exerciseNameTEC.text = currentExercise.name;
    category = currentExercise.category;
    image = isDeleting ? null : image ?? currentExercise.image;
    name = currentExercise.name;
    isDeleting = false;
  }

  void setORM() {
    final parsedReps = double.tryParse(repsTEC.text);
    final parsedWeight = double.tryParse(weightTEC.text);
    if (parsedReps == null || parsedWeight == null) return;
    if (parsedReps > 0) {
      ormTEC.text =
          "${(double.parse(weightTEC.text) / (1.0278 - (0.0278 * double.parse(repsTEC.text)))).toStringAsFixed(2)} $unit";
    } else {
      ormTEC.text =
          "${(double.parse(weightTEC.text) * (1.0278 - (0.0278 * double.parse(repsTEC.text)))).toStringAsFixed(2)} $unit";
    }
  }

  Future<void> selectDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: created,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      selectTime(pickedDate);
    }
  }

  Future<void> selectTime(DateTime pickedDate) async {
    final TimeOfDay? pickedTime = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(created));

    if (pickedTime != null) {
      dateSet = true;
      setState(() {
        created = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute);
      });
    }
  }

  Future<GymSet?> save() async {
    var exerciseServices = ExerciseServices(context: context);
    var setServices = GymSetServices(context: context);
    bool success = false;
    bool isBest = false;
    GymSet? newGymSet;
    //Add new
    if (widget.setId == null) {
      newGymSet = GymSet(
        reps: int.tryParse(repsTEC.text) ?? 0,
        weight: double.tryParse(weightTEC.text) ?? 0.0,
        unit: unit,
        note: noteTEC.text,
        bodyWeight: double.tryParse(bodyWeightTEC.text) ?? 0.0,
        rest: rest,
        created: created,
        exerciseId: currentExercise.id!,
      );
      success = await setServices.insertGymSet(newGymSet) != null;
      isBest = await setServices.isBest(newGymSet);
    } else {
      newGymSet = gymSet!.copyWith(
        reps: int.tryParse(repsTEC.text) ?? 0,
        weight: double.tryParse(weightTEC.text) ?? 0.0,
        unit: unit,
        note: noteTEC.text,
        bodyWeight: double.tryParse(bodyWeightTEC.text) ?? 0.0,
        rest: rest,
        created: created,
        exerciseId: currentExercise.id!,
      );
      success = await setServices.updateGymSet(newGymSet);
      isBest = await setServices.isBest(newGymSet);
    }
    if (success) {
      exerciseServices.updateExercise(currentExercise.copyWith(category: categoryTEC.text, image: image));
      if (isBest) {
        AppSnackBar.success("New PB. Well done");
      }
    }
    return newGymSet;
  }

  //endregion
}

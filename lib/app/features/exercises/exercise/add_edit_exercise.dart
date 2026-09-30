import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:fossfit/app/services/features/gym_set_services.dart';
import 'package:fossfit/app/services/image_services.dart';
import 'package:fossfit/app/shell/app_shell.dart';
import 'package:fossfit/app/utils/constants.dart';
import 'package:fossfit/app/utils/utils.dart';
import 'package:fossfit/app/widgets/fanimated_fab.dart';
import 'package:fossfit/db/models/features/exercise_model.dart';
import 'package:fossfit/db/repositories/config_reposity.dart';
import 'package:fossfit/db/repositories/exercise_repository.dart';
import 'package:fossfit/db/repositories/gym_set_repository.dart';
import 'package:provider/provider.dart';

class AddEditExercise extends StatefulWidget {
  final int? exerciseId;
  final String? name;
  const AddEditExercise({super.key, this.exerciseId, this.name});

  @override
  State<AddEditExercise> createState() => _AddEditExerciseState();
}

class _AddEditExerciseState extends State<AddEditExercise> {
  final TextEditingController nameCtrl = TextEditingController();
  final FocusNode nameNode = FocusNode();
  final TextEditingController descCtrl = TextEditingController();
  TextEditingController catController = TextEditingController();

  TextEditingController setsController = TextEditingController();

  bool isEditMode = false;
  Exercise? _exercise;
  String? unit;
  String? category;
  Uint8List? image;
  @override
  void initState() {
    super.initState();
    if (widget.exerciseId != null) {
      isEditMode = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    var settings = context.watch<ConfigRepository>();
    var exRepo = context.watch<ExercisesRepository>();

    if (isEditMode) {
      _exercise = exRepo.getExerciseById(widget.exerciseId!);
      nameCtrl.text = _exercise?.name ?? '';
      catController.text = _exercise?.category ?? '';
      descCtrl.text = _exercise?.description ?? '';
      unit = _exercise?.defaultUnit;
      category = _exercise?.category;
      image = _exercise?.image;
      setsController.text = (_exercise?.defaultSets).toString();
    } else {
      nameCtrl.text = widget.name ?? 'Add Exercise';
      catController.text = '';
      unit = 'kg';
    }
    var prefix = isEditMode ? 'Update all' : 'Add ';

    return AppShell(
      showNavBar: false,
      showSearch: false,
      title: '$prefix ${nameCtrl.text}',
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextFormField(
              controller: nameCtrl,
              focusNode: nameNode,
              decoration: const InputDecoration(labelText: 'Name'),
              textCapitalization: TextCapitalization.sentences,
              autofocus: true,
              validator: (value) => value?.isNotEmpty == true ? null : 'Required',
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: descCtrl,
              decoration: const InputDecoration(labelText: 'Description'),
              textCapitalization: TextCapitalization.sentences,
              autofocus: true,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Unit'),
              initialValue: unit,
              items: unitsList.map((u) => DropdownMenuItem(value: u.key, child: Text(u.value))).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  unit = newValue!;
                });
              },
            ),
            const SizedBox(height: 8),
            categorySelector(),
            const SizedBox(height: 8),
            defaults(),
            const SizedBox(height: 8),
            Visibility(visible: settings.isEnabled(.workouts, 'show_images'), child: imageField()),
          ],
        ),
      ),
      floatingActionButton: AnimatedFab(onPressed: () => save(), label: const Text('Save'), icon: const Icon(Icons.save)),
    );
  }

  Widget defaults() {
    return TextFormField(
      controller: setsController,
      textInputAction: TextInputAction.next,
      decoration: const InputDecoration(labelText: "Default Sets"),
      keyboardType: TextInputType.number,
      onTap: () => selectAll(setsController),
      validator: (value) {
        if (value == null || value.isEmpty) return null;
        if (int.tryParse(value) == null) {
          return 'Invalid number';
        }
        return null;
      },
    );
  }

  Widget categorySelector() {
    var repo = context.read<ExercisesRepository>();
    return FutureBuilder(
      future: repo.getDistinctCategories(),
      builder: (context, snapshot) {
        return Autocomplete<String>(
          initialValue: TextEditingValue(text: _exercise?.category ?? ""),
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
          fieldViewBuilder: (BuildContext context, TextEditingController textEditingController, FocusNode focusNode, VoidCallback onFieldSubmitted) {
            catController = textEditingController;
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

  Selector<ConfigRepository, bool> imageField() {
    return Selector<ConfigRepository, bool>(
      selector: (context, settings) => settings.isEnabled(.workouts, 'show_images'),
      builder: (context, showImages, child) {
        return Column(
          children: [
            if (image == null || image!.isEmpty)
              TextButton.icon(
                onPressed: () async {
                  image = await pickImage(context);
                },
                label: const Text('Image'),
                icon: const Icon(Icons.image),
              ),
            if (image != null && image!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Tooltip(
                message: 'Long-press to delete',
                child: GestureDetector(
                  onTap: () => () async {
                    image = await pickImage(context);
                  },
                  onLongPress: () => setState(() {
                    image = null;
                  }),
                  child: Container(
                    width: 24,
                    height: 24,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: showImages
                          ? DecorationImage(
                              image: MemoryImage(image ?? Uint8List(0)),
                              fit: BoxFit.cover,
                              colorFilter: ColorFilter.mode(Color.fromARGB(100, 0, 0, 0), BlendMode.darken),
                            )
                          : null,
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

  Future<void> save() async {
    var exRepo = context.read<ExercisesRepository>();
    var setServices = GymSetServices(context: context);
    if (isEditMode) {
      var updated = _exercise!.copyWith(
        name: nameCtrl.text,
        description: descCtrl.text,
        category: category,
        image: image,
        defaultSets: int.tryParse(setsController.text),
        defaultUnit: unit,
      );
      var exerciseSets = setServices.getSetsByExerciseId(_exercise!.id!);
      var mixedUnits = exerciseSets.map((g) => g.unit).toSet().length > 1;
      if (exerciseSets.isNotEmpty && mixedUnits && unit != null) {
        await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Units conflict'),
              content: Text('Not all of your records have the same unit. This will convert all units to $unit. Are you sure?'),
              actions: <Widget>[
                TextButton.icon(
                  label: const Text('Cancel'),
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                TextButton.icon(
                  label: const Text('Confirm'),
                  icon: const Icon(Icons.check),
                  onPressed: () async {
                    Navigator.pop(context);
                    await convertUnits();
                  },
                ),
              ],
            );
          },
        );
      }
      if (!mounted) return;

      await exRepo.updateExercise(updated);
      if (!mounted) return;

      Navigator.pop(context);
    } else {
      var exercise = exRepo.getExerciseByName(nameCtrl.text);
      if (exercise != null) {
        await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Name taken'),
              content: Text('This exercise already exists. Would you like to edit this instead?'),
              actions: <Widget>[
                TextButton.icon(
                  label: const Text('No'),
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    Navigator.pop(context);
                    nameNode.requestFocus();
                    selectAll(nameCtrl);
                  },
                ),
                TextButton.icon(
                  label: const Text('Yes'),
                  icon: const Icon(Icons.check),
                  onPressed: () async {
                    Navigator.pop(context);
                    _exercise = exercise;
                    setState(() {});
                  },
                ),
              ],
            );
          },
        );
        return;
      }

      var newEx = Exercise(
        name: nameCtrl.text,
        description: descCtrl.text,
        category: category,
        image: image,
        defaultSets: int.tryParse(setsController.text),
        defaultUnit: unit,
      );
      await exRepo.addExercise(newEx);
      if (!mounted) return;
      Navigator.pop(context);
    }
  }

  Future<void> convertUnits() async {
    await context.read<GymSetRepository>().convertUnits(unit ?? '', _exercise!.id!);
  }
}

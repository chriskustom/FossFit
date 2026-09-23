import 'dart:io';

import 'package:flutter/material.dart' as material;
import 'package:flutter/material.dart';
import 'package:fossfit/animated_fab.dart';
import 'package:fossfit/db/repositories/exercise_repository.dart';
import 'package:fossfit/db/repositories/settings_repository.dart';
import 'package:fossfit/models/exercise_model.dart';
import 'package:fossfit/utils.dart';
import 'package:provider/provider.dart';

class AddExercisePage extends StatefulWidget {
  final String? name;

  const AddExercisePage({super.key, this.name});

  @override
  createState() => _AddExercisePageState();
}

class _AddExercisePageState extends State<AddExercisePage> {
  final TextEditingController nameCtrl = TextEditingController();
  TextEditingController catController = TextEditingController();
  bool cardio = false;

  String unit = 'kg';
  String? category;

  String? image;
  final key = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    if (widget.name != null) nameCtrl.text = widget.name!;
  }

  @override
  Widget build(BuildContext context) {
    var settings = context.watch<SettingsRepository>();
    var strengthUnit = settings.getSetting(key: 'strength_unit');
    var cardioUnit = settings.getSetting(key: 'cardio_unit');
    if (strengthUnit != 'last-entry' && !cardio) {
      unit = strengthUnit;
    } else {
      if (cardioUnit != 'last-entry' && cardio) {
        unit = cardioUnit;
      }
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Add exercise'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: key,
          child: ListView(
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
                textCapitalization: TextCapitalization.sentences,
                autofocus: true,
                validator: (value) =>
                    value?.isNotEmpty == true ? null : 'Required',
              ),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Unit'),
                initialValue: unit,
                items: const [
                  DropdownMenuItem(
                    value: 'kg',
                    child: Text("Kilograms (kg)"),
                  ),
                  DropdownMenuItem(
                    value: 'lb',
                    child: Text("Pounds (lb)"),
                  ),
                  DropdownMenuItem(
                    value: 'stone',
                    child: Text("Stone"),
                  ),
                  DropdownMenuItem(
                    value: 'km',
                    child: Text("Kilometers (km)"),
                  ),
                  DropdownMenuItem(
                    value: 'mi',
                    child: Text("Miles (mi)"),
                  ),
                ],
                onChanged: (String? newValue) {
                  setState(() {
                    unit = newValue!;
                  });
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: catController,
                decoration: const InputDecoration(
                  labelText: 'Category',
                ),
                onChanged: (value) => setState(() {
                  category = value;
                }),
              ),
              ListTile(
                title: cardio ? const Text('Cardio') : const Text('Strength'),
                leading: cardio
                    ? const Icon(Icons.sports_gymnastics)
                    : const Icon(Icons.fitness_center),
                onTap: () {
                  setState(() {
                    if (cardio)
                      unit = 'kg';
                    else
                      unit = 'km';
                    cardio = !cardio;
                  });
                },
                trailing: Switch(
                  value: cardio,
                  onChanged: (value) => setState(() {
                    cardio = value;
                  }),
                ),
              ),
              Visibility(
                visible: settings.isEnabled(key: 'show_images'),
                child: material.Column(
                  children: [
                    material.Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton.icon(
                          onPressed: pick,
                          label: const Text('Image'),
                          icon: const Icon(Icons.image),
                        ),
                        if (image != null)
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                image = null;
                              });
                            },
                            label: const Text("Delete"),
                            icon: const Icon(Icons.delete),
                          ),
                      ],
                    ),
                    if (image != null) ...[
                      const SizedBox(height: 8),
                      Image.file(
                        File(image!),
                        errorBuilder: (context, error, stackTrace) =>
                            TextButton.icon(
                          label: const Text('Image error'),
                          icon: const Icon(Icons.error),
                          onPressed: () => pick(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: AnimatedFab(
        onPressed: () => save(unit),
        label: const Text('Save'),
        icon: const Icon(Icons.save),
      ),
    );
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    super.dispose();
  }

  void pick() async {
    var result = await pickImageFile();
    if (result == null) return;

    setState(() {
      image = result;
    });
  }

  Future<void> save(String unit) async {
    if (!key.currentState!.validate()) return;

    final insert = Exercise(
      name: nameCtrl.text,
      cardio: cardio,
      image: image,
      category: category,
    );
    context.read<ExercisesRepository>().addExercise(insert);
    if (!mounted) return;

    Navigator.pop(context, insert);
  }

  Widget categorySelector() {
    return Selector<SettingsRepository, bool>(
      selector: (context, settings) =>
          settings.isEnabled(key: 'show_categories'),
      builder: (context, showCategories, child) {
        if (!showCategories || !cardio) {
          return const SizedBox();
        }
        var repo = context.watch<ExercisesRepository>();
        return FutureBuilder(
          future: repo.getDistinctCategories(),
          builder: (context, snapshot) {
            return Autocomplete<String>(
              initialValue: TextEditingValue(
                text: repo.getExerciseByName(widget.name ?? '')?.category ?? "",
              ),
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (snapshot.data == null) return [];
                if (textEditingValue.text == '') {
                  return snapshot.data!;
                }
                return snapshot.data!.where((String option) {
                  return option.toLowerCase().contains(
                        textEditingValue.text.toLowerCase(),
                      );
                });
              },
              onSelected: (String selection) {
                setState(() {
                  category = selection;
                });
              },
              fieldViewBuilder: (
                BuildContext context,
                TextEditingController textEditingController,
                FocusNode focusNode,
                VoidCallback onFieldSubmitted,
              ) {
                catController = textEditingController;
                return TextFormField(
                  controller: textEditingController,
                  focusNode: focusNode,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                  ),
                  onChanged: (value) => setState(() {
                    category = value;
                  }),
                );
              },
            );
          },
        );
      },
    );
  }
}

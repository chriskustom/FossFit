import 'dart:io';

import 'package:flutter/material.dart' as material;
import 'package:flutter/material.dart';
import 'package:fossfit/animated_fab.dart';
import 'package:fossfit/db/repositories/gym_sets_repository.dart';
import 'package:fossfit/db/repositories/settings_repository.dart';
import 'package:fossfit/models/gym_sets_model.dart';
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
  bool cardio = false;

  String unit = 'kg';

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
                validator: (value) => value?.isNotEmpty == true ? null : 'Required',
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
              ListTile(
                title: cardio ? const Text('Cardio') : const Text('Strength'),
                leading: cardio ? const Icon(Icons.sports_gymnastics) : const Icon(Icons.fitness_center),
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
                        errorBuilder: (context, error, stackTrace) => TextButton.icon(
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

    final insert = GymSets(
      created: DateTime.now().toLocal(),
      reps: 0,
      weight: 0,
      name: nameCtrl.text,
      unit: unit,
      cardio: cardio,
      hidden: true,
      image: image,
    );
    context.read<GymSetsRepository>().addGymSets(insert);
    if (!mounted) return;

    Navigator.pop(context, insert);
  }
}

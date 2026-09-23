import 'dart:io';

import 'package:flutter/material.dart' as material;
import 'package:flutter/material.dart';
import 'package:fossfit/animated_fab.dart';
import 'package:fossfit/db/repositories/exercise_repository.dart';
import 'package:fossfit/db/repositories/gym_sets_repository.dart';
import 'package:fossfit/db/repositories/plans_repository.dart';
import 'package:fossfit/db/repositories/settings_repository.dart';
import 'package:fossfit/models/exercise_model.dart';
import 'package:fossfit/models/gym_set_model.dart';
import 'package:fossfit/utils.dart';
import 'package:provider/provider.dart';

class EditGraphPage extends StatefulWidget {
  final Exercise exercise;

  const EditGraphPage({required this.exercise, super.key});

  @override
  createState() => _EditGraphPageState();
}

class _EditGraphPageState extends State<EditGraphPage> {
  late final TextEditingController name =
      TextEditingController(text: widget.exercise.name);
  final TextEditingController minutes = TextEditingController();
  final TextEditingController seconds = TextEditingController();
  final key = GlobalKey<FormState>();
  List<GymSet> gymSets = [];
  bool? cardio;
  String? unit;
  String? image;
  String? category;

  @override
  Widget build(BuildContext context) {
    gymSets = context.watch<GymSetsRepository>().gymsets;
    var firstGymSet = gymSets.first;
    image = widget.exercise.image;
    cardio = widget.exercise.cardio;
    category = widget.exercise.category;

    if (firstGymSet.restMs != null) {
      final duration = Duration(milliseconds: firstGymSet.restMs!);
      minutes.text = duration.inMinutes.toString();
      seconds.text = (duration.inSeconds % 60).toString();
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text("Update all ${widget.exercise.name.toLowerCase()}"),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Form(
          key: key,
          child: ListView(
            children: [
              TextField(
                controller: name,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: "New name"),
                textCapitalization: TextCapitalization.sentences,
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: minutes,
                      textInputAction: TextInputAction.next,
                      decoration:
                          const InputDecoration(labelText: "Rest minutes"),
                      keyboardType: material.TextInputType.number,
                      onTap: () => selectAll(minutes),
                      validator: (value) {
                        if (value == null || value.isEmpty) return null;
                        if (int.tryParse(value) == null)
                          return 'Invalid number';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(
                    width: 8.0,
                  ),
                  Expanded(
                    child: TextFormField(
                      controller: seconds,
                      textInputAction: TextInputAction.next,
                      decoration:
                          const InputDecoration(labelText: "Rest seconds"),
                      keyboardType: material.TextInputType.number,
                      onTap: () {
                        selectAll(seconds);
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) return null;
                        if (int.tryParse(value) == null)
                          return 'Invalid number';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              Selector<SettingsRepository, bool>(
                selector: (p0, settings) =>
                    settings.isEnabled(key: 'showCategories'),
                builder: (context, showCategories, child) {
                  if (!showCategories) return const SizedBox();
                  return FutureBuilder(
                    future:
                        context.watch<GymSetsRepository>().getCategoriesList(),
                    builder: (context, snapshot) {
                      return DropdownButtonFormField(
                        decoration:
                            const InputDecoration(labelText: 'Category'),
                        initialValue: category,
                        items: snapshot.data
                            ?.map(
                              (category) => DropdownMenuItem(
                                value: category,
                                child: Text(category),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            category = value!;
                          });
                        },
                      );
                    },
                  );
                },
              ),
              DropdownButtonFormField(
                decoration: const InputDecoration(labelText: 'Unit'),
                initialValue: unit,
                items: const [
                  DropdownMenuItem(
                    value: null,
                    child: Text(""),
                  ),
                  DropdownMenuItem(
                    value: 'kg',
                    child: Text("kg"),
                  ),
                  DropdownMenuItem(
                    value: 'lb',
                    child: Text("lb"),
                  ),
                  DropdownMenuItem(
                    value: 'km',
                    child: Text("km"),
                  ),
                  DropdownMenuItem(
                    value: 'mi',
                    child: Text("mi"),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    unit = value;
                  });
                },
              ),
              if (cardio != null)
                ListTile(
                  leading: cardio!
                      ? const Icon(Icons.sports_gymnastics)
                      : const Icon(Icons.fitness_center),
                  title:
                      cardio! ? const Text('Cardio') : const Text('Strength'),
                  onTap: () {
                    setState(() {
                      cardio = !cardio!;
                      if (unit == null || unit?.isEmpty == true) return;
                      if (cardio!)
                        unit = unit == 'kg' ? 'km' : 'mi';
                      else
                        unit = unit == 'km' ? 'kg' : 'lb';
                    });
                  },
                  trailing: Switch(
                    value: cardio!,
                    onChanged: (value) => setState(() {
                      cardio = value;
                    }),
                  ),
                ),
              Selector<SettingsRepository, bool>(
                builder: (context, showImages, child) {
                  return Visibility(
                    visible: showImages,
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
                  );
                },
                selector: (context, settings) =>
                    settings.isEnabled(key: 'show_images'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: AnimatedFab(
        onPressed: save,
        label: const Text("Update"),
        icon: const Icon(Icons.sync),
      ),
    );
  }

  @override
  dispose() {
    name.dispose();
    minutes.dispose();
    seconds.dispose();
    super.dispose();
  }

  Future<void> doUpdate() async {
    var repo = context.read<GymSetsRepository>();
    var exerciseRepo = context.read<ExercisesRepository>();
    Duration? duration;
    if (int.tryParse(minutes.text) != null && int.tryParse(minutes.text)! > 0 ||
        int.tryParse(seconds.text) != null && int.tryParse(seconds.text)! > 0)
      duration = Duration(
        minutes: int.tryParse(minutes.text) ?? 0,
        seconds: int.tryParse(seconds.text) ?? 0,
      );
    var toUpdate = gymSets.where((tbl) => tbl.exerciseId == widget.exercise.id);
    for (final oldGymSet in toUpdate) {
      if (name.text != widget.exercise.name) {
        exerciseRepo.updateExercise(
          widget.exercise.copyWith(
            name: name.text != widget.exercise.name
                ? name.text
                : widget.exercise.name,
            category: category,
            image: image,
            cardio: cardio,
          ),
        );
      }
      var newGymSet = oldGymSet.copyWith(
        unit: unit,
        restMs: duration?.inMilliseconds,
        created: null,
        hidden: null,
        reps: null,
        weight: null,
      );
      await repo.updateGymSet(newGymSet);
    }

    if (!mounted) return;
    await context.read<PlansRepository>().updatePlans(null);
  }

  Future<int> getCount() async {
    final result = context
        .watch<GymSetsRepository>()
        .gymsets
        .where((t) => t.exerciseId == widget.exercise.id)
        .length;
    return result;
  }

  @override
  void initState() {
    super.initState();
  }

  Future<bool> mixedUnits() async {
    return gymSets.map((t) => t.unit).toSet().length > 1;
  }

  void pick() async {
    var result = await pickImageFile();
    if (result == null) return;

    setState(() {
      image = result;
    });
  }

  Future<void> save() async {
    if (!key.currentState!.validate()) return;

    final count = await getCount();

    if (count > 0 && widget.exercise.name != name.text && mounted)
      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Update conflict'),
            content: Text(
              'Your new name exists already for $count records. Are you sure?',
            ),
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
                  await doUpdate();
                },
              ),
            ],
          );
        },
      );
    else if (unit != null && await mixedUnits() && mounted)
      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Units conflict'),
            content: Text(
              'Not all of your records have the same unit. This will convert all units to $unit. Are you sure?',
            ),
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
                  await doUpdate();
                },
              ),
            ],
          );
        },
      );
    else
      await doUpdate();

    if (!mounted) return;
    Navigator.pop(context, name.text);
  }

  Future<void> convertUnits() async {
    await context
        .read<GymSetsRepository>()
        .convertUnits(unit ?? '', widget.exercise.id!);
  }
}

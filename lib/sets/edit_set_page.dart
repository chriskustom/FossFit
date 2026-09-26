import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart' as material;
import 'package:flutter/material.dart';
import 'package:fossfit/animated_fab.dart';
import 'package:fossfit/app/app_shell.dart';
import 'package:fossfit/constants.dart';
import 'package:fossfit/db/repositories/exercise_repository.dart';
import 'package:fossfit/db/repositories/gym_sets_repository.dart';
import 'package:fossfit/db/repositories/settings_repository.dart';
import 'package:fossfit/models/exercise_model.dart';
import 'package:fossfit/models/gym_set_model.dart';
import 'package:fossfit/sets/workout_list.dart';
import 'package:fossfit/timer/timer_state.dart';
import 'package:fossfit/utils.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

class EditSetPage extends StatefulWidget {
  final GymSet gymSet;

  const EditSetPage({super.key, required this.gymSet});

  @override
  createState() => _EditSetPageState();
}

class _EditSetPageState extends State<EditSetPage> {
  final reps = TextEditingController();
  final weight = TextEditingController();
  final orm = TextEditingController();
  final body = TextEditingController();
  final distance = TextEditingController();
  final minutes = TextEditingController();
  final seconds = TextEditingController();
  final incline = TextEditingController();
  final notes = TextEditingController();
  final repsNode = FocusNode();
  final distNode = FocusNode();
  final key = GlobalKey<FormState>();

  var categoryCtrl = TextEditingController();
  DateTime created = DateTime.now().toLocal();
  TextEditingController? nameCtrl;
  List<String> options = [];
  int? restMs;
  String? image;
  String? category;

  late String unit;
  late bool cardio;
  late String name;
  late bool dateSet = false;
  late Exercise exercise;

  void onSelected(String option, bool showBodyWeight) async {
    final setRepo = context.read<GymSetsRepository>();
    final last = setRepo.gymsets
        .where((t) => t.exercise!.name == option && !t.hidden)
        .firstOrNull;
    if (last == null)
      return setState(() {
        name = option;
      });

    if (showBodyWeight)
      updateFields(last);
    else {
      final bodyWeight = await getBodyWeight(context);
      updateFields(
        last.copyWith(
          bodyWeight: bodyWeight?.weight,
        ),
      );
    }

    if (cardio) {
      distNode.requestFocus();
      selectAll(distance);
    } else {
      repsNode.requestFocus();
      selectAll(reps);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsRepository>();
    final showBodyWeight = settings.isEnabled(key: 'show_body_weight');
    final exRepo = context.watch<ExercisesRepository>();
    final names = exRepo.exercises.map((result) => result.name);
    setState(() {
      options = names.toList();
    });

    return AppShell(
      body: buildBody(showBodyWeight),
      appBar: buildAppBar(),
      floatingActionButton: buildSaveButton(),
      showNavBar: false,
    );
  }

  AppBar buildAppBar() {
    return AppBar(
      title: Text(
        widget.gymSet.id! > 0 ? widget.gymSet.exercise!.name : 'Add set',
      ),
      actions: [
        if (widget.gymSet.id! > 0) buildDeleteButton(),
      ],
    );
  }

  Widget buildDeleteButton() {
    return IconButton(
      icon: const Icon(Icons.delete),
      onPressed: () => showDeleteDialog(),
    );
  }

  Future<void> showDeleteDialog() async {
    final repo = context.watch<GymSetsRepository>();
    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text(
            'Are you sure you want to delete ${widget.gymSet.exercise!.name}?',
          ),
          actions: [
            TextButton.icon(
              label: const Text('Cancel'),
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(dialogContext),
            ),
            TextButton.icon(
              label: const Text('Delete'),
              icon: const Icon(Icons.delete),
              onPressed: () async {
                Navigator.pop(dialogContext);
                await repo.deleteGymSetById(widget.gymSet.id!);
                if (mounted) Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  Widget buildBody(bool showBodyWeight) {
    final settings = context.watch<SettingsRepository>();
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: key,
        child: Builder(
          builder: (context) {
            final showUnits = settings.isEnabled(key: 'show_units');
            final showCategories = settings.isEnabled(key: 'show_categories');
            final showNotes = settings.isEnabled(key: 'show_notes');
            final showImages = settings.isEnabled(key: 'show_images');

            return ListView(
              children: [
                autocomplete(showBodyWeight),
                const SizedBox(height: 8.0),
                ...exerciseFields(),
                const SizedBox(height: 8.0),
                if (showBodyWeight && name != 'Weight') ...[
                  bodyFields(showBodyWeight),
                  const SizedBox(height: 8.0),
                ],
                if (showUnits) ...[
                  unitSelector(),
                  const SizedBox(height: 8.0),
                ],
                if (showCategories && name != 'Weight') ...[
                  categorySelector(),
                  const SizedBox(height: 8.0),
                ],
                if (showNotes) ...[
                  notesField(),
                  const SizedBox(height: 8.0),
                ],
                dateSelector(),
                if (showImages) ...[
                  const SizedBox(height: 8.0),
                  imageField(),
                ],
                if (name != '' && name != 'Weight') ...[
                  Builder(
                    builder: (context) {
                      var history = getHistory();

                      if (history.isEmpty) {
                        return SizedBox(
                          height: 200,
                          child: Center(
                            child: Text(
                              'No entries...',
                            ),
                          ),
                        );
                      }

                      return SizedBox(
                        height: 300,
                        child: WorkoutList(
                          scroll: ScrollController(),
                          sets: history,
                          peek: true,
                          onSelect: (_) {},
                          selected: const {},
                          onNext: () {},
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8.0),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> exerciseFields() {
    if (cardio) {
      return buildCardioFields();
    } else {
      return buildStrengthFields();
    }
  }

  List<Widget> buildStrengthFields() {
    return [
      Row(
        children: [
          if (name != 'Weight') ...[
            Expanded(
              child: buildRepsField(),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: buildWeightField(),
          ),
        ],
      ),
      const SizedBox(height: 8),
      if (name != 'Weight') buildORMField(),
    ];
  }

  Widget buildRepsField() {
    return TextFormField(
      controller: reps,
      focusNode: repsNode,
      decoration: const InputDecoration(labelText: 'Reps'),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onTap: () => selectAll(reps),
      onChanged: (value) => setORM(),
      textInputAction: TextInputAction.next,
      onFieldSubmitted: (_) => selectAll(weight),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Required';
        if (double.tryParse(value) == null) return 'Invalid number';
        return null;
      },
    );
  }

  Widget buildWeightField() {
    return TextFormField(
      controller: weight,
      decoration: InputDecoration(
        labelText: name == 'Weight' ? 'Value ' : 'Weight ($unit)',
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onTap: () => selectAll(weight),
      onFieldSubmitted: (value) => save(),
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
      controller: orm,
      decoration: const InputDecoration(
        labelText: 'One rep max (estimate)',
      ),
      enabled: false,
    );
  }

  List<Widget> buildCardioFields() {
    return [
      buildDistanceField(),
      SizedBox(height: 8.0),
      duration(),
      SizedBox(height: 8.0),
      buildInclineField(),
    ];
  }

  Widget buildDistanceField() {
    if (unit == 'kg' || unit == 'lb' || unit == 'stone')
      return buildWeightField();
    return TextFormField(
      controller: distance,
      focusNode: distNode,
      decoration: InputDecoration(
        labelText: unit == 'kcal' ? 'Amount ($unit)' : 'Distance ($unit)',
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onTap: () => selectAll(distance),
      onFieldSubmitted: (value) => selectAll(minutes),
      textInputAction: TextInputAction.next,
      validator: (value) {
        if (value == null || value.isEmpty) return null;
        if (double.tryParse(value) == null) return 'Invalid number';
        return null;
      },
    );
  }

  Widget buildInclineField() {
    return TextFormField(
      controller: incline,
      decoration: const InputDecoration(labelText: 'Incline %'),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onTap: () => selectAll(incline),
      validator: (value) {
        if (value == null || value.isEmpty) return null;
        if (int.tryParse(value) == null) return 'Invalid number';
        return null;
      },
    );
  }

  Widget bodyFields(bool showBodyWeight) {
    return Visibility(
      visible: showBodyWeight && name != 'Weight',
      child: TextFormField(
        controller: body,
        decoration: InputDecoration(
          labelText: 'Body weight ($unit)',
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onTap: () => selectAll(body),
        validator: (value) {
          if (value == null) return null;
          if (value.isNotEmpty && double.tryParse(value) == null)
            return 'Invalid number';
          return null;
        },
      ),
    );
  }

  Widget unitSelector() {
    return Selector<SettingsRepository, bool>(
      builder: (context, showUnits, child) => Visibility(
        visible: showUnits,
        child: DropdownButtonFormField<String>(
          decoration: const InputDecoration(labelText: 'Unit'),
          initialValue: unit,
          items: getUnitItems(),
          onChanged: (String? newValue) {
            setState(() {
              unit = newValue!;
            });
          },
        ),
      ),
      selector: (context, settings) => settings.isEnabled(key: 'show_units'),
    );
  }

  Widget categorySelector() {
    final repo = context.watch<ExercisesRepository>();
    return Selector<SettingsRepository, bool>(
      selector: (context, settings) =>
          settings.isEnabled(key: 'show_categories'),
      builder: (context, showCategories, child) {
        if (!showCategories || name == 'Weight') {
          return const SizedBox();
        }

        return FutureBuilder(
          future: repo.getDistinctCategories(),
          builder: (context, snapshot) {
            return Autocomplete<String>(
              initialValue: TextEditingValue(
                text: widget.gymSet.exercise!.category ?? "",
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
                categoryCtrl = textEditingController;
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

  Widget notesField() {
    return Selector<SettingsRepository, bool>(
      builder: (context, showNotes, child) => Visibility(
        visible: showNotes,
        child: TextField(
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Notes',
          ),
          controller: notes,
        ),
      ),
      selector: (context, settingsState) =>
          settingsState.isEnabled(key: 'show_notes'),
    );
  }

  Widget dateSelector() {
    final repo = context.watch<GymSetsRepository>();
    final lastSet = repo.gymsets
        .where((tbl) => tbl.exercise!.id == exercise.id && !tbl.hidden)
        .take(1)
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

    final displayDate = lastDate.add(const Duration(minutes: 3)).isAfter(now)
        ? now
        : widget.gymSet.id! > 0
            ? widget.gymSet.created
            : lastDate.add(const Duration(minutes: 3));

    created = dateSet ? created : displayDate;

    return Selector<SettingsRepository, String>(
      selector: (context, settings) =>
          settings.getSetting(key: 'long_date_format'),
      builder: (context, longDateFormat, child) => ListTile(
        title: const Text('Created date'),
        subtitle: Text(
          longDateFormat == 'timeago'
              ? timeago.format(created)
              : DateFormat(longDateFormat).format(created),
        ),
        trailing: const Icon(Icons.calendar_today),
        onTap: () => selectDate(),
      ),
    );
  }

  Widget buildSaveButton() {
    return AnimatedFab(
      onPressed: save,
      label: const Text("Save"),
      icon: const Icon(Icons.save),
    );
  }

  Selector<SettingsRepository, bool> imageField() {
    return Selector<SettingsRepository, bool>(
      builder: (context, showImages, child) {
        return Visibility(
          visible: showImages,
          child: material.Column(
            children: [
              if (image == null || image == '')
                TextButton.icon(
                  onPressed: pick,
                  label: const Text('Image'),
                  icon: const Icon(Icons.image),
                ),
              if (image != null && image != '') ...[
                const SizedBox(height: 8),
                Tooltip(
                  message: 'Long-press to delete',
                  child: GestureDetector(
                    onTap: () => pick(),
                    onLongPress: () => setState(() {
                      image = null;
                    }),
                    child: Image.file(
                      File(image!),
                      errorBuilder: (context, error, stackTrace) =>
                          TextButton.icon(
                        label: const Text('Image error'),
                        icon: const Icon(Icons.error),
                        onPressed: () => pick(),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
      selector: (context, settings) => settings.isEnabled(key: 'show_images'),
    );
  }

  List<GymSet> getHistory() {
    final repo = context.watch<GymSetsRepository>();
    return repo.gymsets
        .where((tbl) => tbl.exercise!.id == exercise.id && !tbl.hidden)
        .take(20)
        .toList();
  }

  material.Row duration() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: minutes,
            decoration: const InputDecoration(labelText: 'Minutes'),
            keyboardType: const TextInputType.numberWithOptions(
              decimal: false,
            ),
            onTap: () => selectAll(minutes),
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (value) => selectAll(seconds),
            validator: (value) {
              if (value == null || value.isEmpty) return null;
              if (int.tryParse(value) == null) return 'Invalid number';
              return null;
            },
          ),
        ),
        const SizedBox(width: 8.0),
        Expanded(
          child: TextFormField(
            controller: seconds,
            decoration: const InputDecoration(labelText: 'Seconds'),
            keyboardType: const TextInputType.numberWithOptions(
              decimal: false,
            ),
            onTap: () => selectAll(seconds),
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (value) => selectAll(incline),
            validator: (value) {
              if (value == null || value.isEmpty) return null;
              if (int.tryParse(value) == null) return 'Invalid number';
              return null;
            },
          ),
        ),
      ],
    );
  }

  material.Autocomplete<String> autocomplete(bool showBodyWeight) {
    return Autocomplete<String>(
      optionsBuilder: (textEditingValue) {
        final searchTerms = textEditingValue.text
            .toLowerCase()
            .split(" ")
            .where((term) => term.isNotEmpty);
        Iterable<String> opts = options;

        for (final term in searchTerms) {
          opts = opts.where((option) => option.toLowerCase().contains(term));
        }
        return opts;
      },
      onSelected: (option) => onSelected(option, showBodyWeight),
      initialValue: TextEditingValue(text: name),
      fieldViewBuilder: (
        BuildContext context,
        TextEditingController textEditingController,
        FocusNode focusNode,
        VoidCallback onFieldSubmitted,
      ) {
        nameCtrl = textEditingController;
        return TextFormField(
          decoration: const InputDecoration(labelText: 'Name'),
          controller: textEditingController,
          textInputAction: TextInputAction.next,
          onTap: () {
            selectAll(textEditingController);
          },
          focusNode: focusNode,
          onFieldSubmitted: (String value) {
            onFieldSubmitted();
          },
          onChanged: (value) => setState(() {
            name = value;
          }),
          validator: (value) {
            if (value == null || value.isEmpty) return 'Required';
            return null;
          },
        );
      },
    );
  }

  @override
  void dispose() {
    reps.dispose();
    repsNode.dispose();
    weight.dispose();
    body.dispose();
    distance.dispose();
    minutes.dispose();
    incline.dispose();

    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    updateFields(widget.gymSet);
    setState(() {
      created = widget.gymSet.created;
    });
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

    final settings = context.read<SettingsRepository>();
    final setRepo = context.read<GymSetsRepository>();
    final exRepo = context.read<ExercisesRepository>();

    await exRepo.updateExercise(exercise.copyWith(image: image ?? ''));

    final gymSet = widget.gymSet.copyWith(
      unit: unit,
      created: created,
      reps: double.tryParse(reps.text),
      weight: double.tryParse(weight.text),
      bodyWeight: double.tryParse(body.text),
      distance: double.tryParse(distance.text),
      duration: (int.tryParse(seconds.text) ?? 0) / 60 +
          (int.tryParse(minutes.text) ?? 0),
      restMs: restMs,
      incline: int.tryParse(incline.text),
      notes: notes.text,
      exerciseId: exercise.id,
    );

    if (widget.gymSet.id != null) {
      await setRepo.updateGymSet(gymSet);

      if (!mounted) return;
      return Navigator.of(context).pop();
    } else {
      await setRepo.insertGymSet(gymSet.copyWith(id: null));
    }

    if (settings.isEnabled(key: 'notifications')) {
      final best = await setRepo.isBest(gymSet);
      if (best) {
        final random = Random();
        final randomMessage =
            positiveReinforcement[random.nextInt(positiveReinforcement.length)];
        if (mounted) toast(randomMessage);
      }
    }

    if (!settings.isEnabled(key: 'rest_timers') && mounted)
      return Navigator.of(context).pop();
    if (!mounted) return;
    final timer = context.read<TimerState>();
    if (restMs != null)
      timer.startTimer(
        name,
        Duration(milliseconds: restMs!),
        settings.getSetting(key: 'alarm_sound'),
        settings.isEnabled(key: 'vibrate'),
      );
    else
      timer.startTimer(
        name,
        Duration(milliseconds: settings.getInt(key: 'timer_duration')),
        settings.getSetting(key: 'alarm_sound'),
        settings.isEnabled(key: 'vibrate'),
      );
    if (!mounted) return;
    return Navigator.of(context).pop();
  }

  void setORM() {
    final parsedReps = double.tryParse(reps.text);
    final parsedWeight = double.tryParse(weight.text);
    if (parsedReps == null || parsedWeight == null) return;
    if (parsedReps > 0)
      orm.text =
          "${(double.parse(weight.text) / (1.0278 - (0.0278 * double.parse(reps.text)))).toStringAsFixed(2)} $unit";
    else
      orm.text =
          "${(double.parse(weight.text) * (1.0278 - (0.0278 * double.parse(reps.text)))).toStringAsFixed(2)} $unit";
  }

  List<DropdownMenuItem<String>> getUnitItems() {
    return const [
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
      DropdownMenuItem(
        value: 'm',
        child: Text("Meters (m)"),
      ),
      DropdownMenuItem(
        value: 'kcal',
        child: Text("Kilocalories (kcal)"),
      ),
    ];
  }

  void updateFields(GymSet gymSet) {
    nameCtrl?.text = gymSet.exercise!.name;
    exercise = gymSet.exercise!;
    setState(() {
      category = gymSet.exercise!.category;
      image = gymSet.exercise!.image;
      name = gymSet.exercise!.name;
      unit = gymSet.unit;
      cardio = gymSet.exercise!.cardio;
      restMs = gymSet.restMs;
    });

    reps.text = toString(gymSet.reps);
    weight.text = toString(gymSet.weight);
    setORM();
    if (gymSet.bodyWeight != 0) body.text = toString(gymSet.bodyWeight);
    if (gymSet.duration != 0) {
      minutes.text = (gymSet.duration ?? 0).floor().toString();
      seconds.text = ((gymSet.duration ?? 0 * 60) % 60).floor().toString();
    }
    if (gymSet.distance != 0) distance.text = toString(gymSet.distance ?? 0);
    if (gymSet.incline != null && gymSet.incline != 0)
      incline.text = gymSet.incline.toString();
    if (gymSet.exercise!.category != null &&
        gymSet.exercise!.category!.isNotEmpty)
      categoryCtrl.text = gymSet.exercise!.category!;
    if (gymSet.notes != null && gymSet.notes!.isNotEmpty)
      notes.text = gymSet.notes!;
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
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(created),
    );

    if (pickedTime != null) {
      dateSet = true;
      setState(() {
        created = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
      });
    }
  }
}

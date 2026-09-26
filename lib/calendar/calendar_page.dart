import 'package:flutter/material.dart';
import 'package:fossfit/app/app_shell.dart';
import 'package:fossfit/app_search.dart';
import 'package:fossfit/db/repositories/gym_sets_repository.dart';
import 'package:fossfit/db/repositories/settings_repository.dart';
import 'package:fossfit/filters.dart';
import 'package:fossfit/models/exercise_model.dart';
import 'package:fossfit/models/gym_set_model.dart';
import 'package:fossfit/sets/edit_set_page.dart';
import 'package:fossfit/widgets/workout_history.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({
    super.key,
  });

  @override
  State<CalendarPage> createState() => CalendarPageState();
}

class CalendarPageState extends State<CalendarPage> {
  List<GymSet> gymSets = [];

  DateTime? _selectedDay;
  DateTime _focusedDay = DateTime.now();

  final Set<int> selected = {};
  final ScrollController scroll = ScrollController();

  int monthToFilter = DateTime.now().month;
  int yearToFilter = DateTime.now().year;

  late PageController _pageController;
  final repsGt = TextEditingController();
  final repsLt = TextEditingController();
  final weightGt = TextEditingController();
  final weightLt = TextEditingController();

  final expand = ExpansibleController();

  List<GymSet> latestSets = [];
  List<GymSet> filteredGymSets = [];

  Widget lastWorkout = const SizedBox.shrink();

  String search = '';

  DateTime? startDate;
  DateTime? endDate;
  String? category;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    gymSets = context.watch<GymSetsRepository>().gymsets;

    final allGymSets = gymSets;

    final thisMonthsGymSets = allGymSets
        .where(
          (t) =>
              t.created.month == monthToFilter &&
              t.created.year == yearToFilter,
        )
        .toList();

    return AppShell(
      appBar: buildAppBar(),
      body: _getCalendar(thisMonthsGymSets),
    );
  }

  AppSearch buildAppBar() {
    return AppSearch(
      selected: selected,
      filter: Filters(
        full: false,
        repsGtCtrl: repsGt,
        repsLtCtrl: repsLt,
        weightGtCtrl: weightGt,
        weightLtCtrl: weightLt,
        setStream: _resetLimitAndApplyFilters,
        endDate: endDate,
        startDate: startDate,
        setEnd: (value) {
          endDate = value;

          _applyFilters();
        },
        setStart: (value) {
          startDate = value;

          _applyFilters();
        },
        category: category,
        setCategory: (value) {
          category = value;

          _applyFilters();
        },
      ),
      onChange: (value) {
        search = value;
        _applyFilters();
      },
      onClear: () {
        setState(() {
          selected.clear();
        });
      },
      onDelete: () async {
        await context.read<GymSetsRepository>().deleteGymSetsById(
              selected.toList(),
            );

        if (!mounted) {
          return;
        }

        setState(() {
          selected.clear();
        });
      },
      onSelect: () {
        if (gymSets.isEmpty) {
          return;
        }

        setState(() {
          selected.addAll(
            gymSets
                .map(
                  (gymSet) => gymSet.id,
                )
                .whereType<int>(),
          );
        });
      },
      onEdit: (gymSet) async => onEdit(gymSet),
    );
  }

  void onEdit(GymSet gymSet) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditSetPage(
          gymSet: gymSet,
        ),
      ),
    );

    if (mounted) {
      setState(() {});
    }
  }

  void _resetLimitAndApplyFilters() {
    if (!mounted) {
      return;
    }
    _applyFilters();
  }

  void _applyFilters() {
    if (!mounted) {
      return;
    }

    Iterable<GymSet> query = latestSets.where(
      (set) => !set.hidden && set.exercise != null,
    );

    final terms = search.toLowerCase().split(' ').where(
          (term) => term.isNotEmpty,
        );

    for (final term in terms) {
      query = query.where(
        (set) => set.exercise!.name.toLowerCase().contains(term),
      );
    }

    if (category != null) {
      query = query.where(
        (set) => set.exercise!.category == category,
      );
    }

    if (startDate != null) {
      query = query.where(
        (set) =>
            set.created.isAfter(startDate!) ||
            set.created.isAtSameMomentAs(
              startDate!,
            ),
      );
    }

    if (endDate != null) {
      query = query.where(
        (set) =>
            set.created.isBefore(endDate!) ||
            set.created.isAtSameMomentAs(
              endDate!,
            ),
      );
    }

    if (repsGt.text.isNotEmpty) {
      final value = double.tryParse(repsGt.text) ?? 0;

      query = query.where(
        (set) => set.reps > value && !set.exercise!.cardio,
      );
    }

    if (repsLt.text.isNotEmpty) {
      final value = double.tryParse(repsLt.text) ?? 0;

      query = query.where(
        (set) => set.reps < value && !set.exercise!.cardio,
      );
    }

    if (weightGt.text.isNotEmpty) {
      final value = double.tryParse(weightGt.text) ?? 0;

      query = query.where(
        (set) => set.weight > value && !set.exercise!.cardio,
      );
    }

    if (weightLt.text.isNotEmpty) {
      final value = double.tryParse(weightLt.text) ?? 0;

      query = query.where(
        (set) => set.weight < value && !set.exercise!.cardio,
      );
    }

    filteredGymSets = query.toList();

    setState(() {});
  }

  Widget _getCalendar(List<GymSet> monthlyGymSets) {
    final today = DateUtils.dateOnly(
      DateTime.now(),
    );
    final selectedDate = _selectedDay ?? _focusedDay;
    final selectedSets = monthlyGymSets
        .where(
          (set) => isSameDay(
            set.created,
            selectedDate,
          ),
        )
        .toList();
    final groupHistory =
        context.watch<SettingsRepository>().isEnabled(key: 'group_history');
    return Column(
      children: [
        _CalendarHeader(
          focusedDay: _focusedDay,
          clearButtonVisible: false,
          onTodayButtonTap: () {
            setState(() {
              _focusedDay = today;
              _selectedDay = today;
            });
          },
          onClearButtonTap: () {},
          onLeftArrowTap: () {
            _pageController.previousPage(
              duration: const Duration(
                milliseconds: 300,
              ),
              curve: Curves.easeOut,
            );
          },
          onRightArrowTap: () {
            _pageController.nextPage(
              duration: const Duration(
                milliseconds: 300,
              ),
              curve: Curves.easeOut,
            );
          },
        ),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: TableCalendar<ExerciseItem>(
            firstDay: DateTime(1900, 1, 1),
            lastDay: DateTime(2100, 12, 31),
            focusedDay: _focusedDay,
            headerVisible: false,
            startingDayOfWeek: StartingDayOfWeek.monday,
            selectedDayPredicate: (day) {
              return isSameDay(
                _selectedDay,
                day,
              );
            },
            rowHeight: 40,
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
              ),
            ),
            calendarFormat: CalendarFormat.month,
            rangeSelectionMode: RangeSelectionMode.disabled,
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                if (events.isEmpty) return SizedBox();
                return Container(
                  width: double.infinity,
                  height: 4,
                  margin: EdgeInsets.only(top: 2, left: 18, right: 18),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurface,
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              },
            ),
            eventLoader: (day) {
              final exercise = _getExerciseItems(monthlyGymSets)
                  .where(
                    (e) => isSameDay(
                      e.date,
                      day,
                    ),
                  )
                  .firstOrNull;

              return exercise == null ? <ExerciseItem>[] : [exercise];
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onCalendarCreated: (controller) {
              _pageController = controller;
            },
            onPageChanged: (focusedDay) {
              setState(() {
                _focusedDay = focusedDay;
                monthToFilter = focusedDay.month;
                yearToFilter = focusedDay.year;
              });
            },
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.secondary,
                ),
                color: Colors.transparent,
                shape: BoxShape.circle,
              ),
              cellMargin: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              todayTextStyle:
                  TextStyle(color: Theme.of(context).colorScheme.primary),
              selectedDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              selectedTextStyle:
                  TextStyle(color: Theme.of(context).colorScheme.onPrimary),
              markerDecoration: BoxDecoration(
                color: Colors.transparent,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        const SizedBox(
          height: 8.0,
        ),
        Expanded(
          child: GestureDetector(
            onHorizontalDragEnd: (details) {
              if (details.primaryVelocity != null) {
                if (details.primaryVelocity! > 0) {
                  _pageController.previousPage(
                    duration: const Duration(
                      milliseconds: 300,
                    ),
                    curve: Curves.easeOut,
                  );
                } else {
                  _pageController.nextPage(
                    duration: const Duration(
                      milliseconds: 300,
                    ),
                    curve: Curves.easeOut,
                  );
                }
              }
            },
            child: WorkoutHistory(
              gymSets: selectedSets,
              onSelect: (id) {
                if (selected.contains(id))
                  setState(() {
                    selected.remove(id);
                  });
                else
                  setState(() {
                    selected.add(id);
                  });
              },
              onEdit: (gymSet) async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditSetPage(gymSet: gymSet),
                  ),
                );
                setState(() {});
              },
              selected: selected,
              scroll: scroll,
              groupHistory: groupHistory,
            ),
          ),
        ),
      ],
    );
  }

  List<ExerciseItem> _getExerciseItems(List<GymSet> gymSets) {
    List<ExerciseItem> exerciseItems = [];
    for (final gymSet in gymSets) {
      final day = DateUtils.dateOnly(gymSet.created);
      final index = exerciseItems.indexWhere(
        (hd) => isSameDay(hd.date, day) && hd.exerciseId == gymSet.exercise!.id,
      );
      if (index == -1)
        exerciseItems.add(
          ExerciseItem(
            exerciseId: gymSet.exerciseId,
            name: gymSet.exercise!.name,
            sets: [gymSet],
            date: day,
          ),
        );
      else
        exerciseItems[index].sets.add(gymSet);
    }
    return exerciseItems;
  }
}

class _CalendarHeader extends StatelessWidget {
  final DateTime focusedDay;
  final VoidCallback onLeftArrowTap;
  final VoidCallback onRightArrowTap;
  final VoidCallback onTodayButtonTap;
  final VoidCallback onClearButtonTap;
  final bool clearButtonVisible;

  const _CalendarHeader({
    required this.focusedDay,
    required this.onLeftArrowTap,
    required this.onRightArrowTap,
    required this.onTodayButtonTap,
    required this.onClearButtonTap,
    required this.clearButtonVisible,
  });

  @override
  Widget build(BuildContext context) {
    final headerText = DateFormat.yMMM().format(
      focusedDay,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 8.0,
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 16.0,
          ),
          SizedBox(
            width: 130.0,
            child: Text(
              headerText,
              style: const TextStyle(
                fontSize: 26.0,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.calendar_today,
              size: 20.0,
              color: Theme.of(context).colorScheme.primary,
            ),
            visualDensity: VisualDensity.compact,
            onPressed: onTodayButtonTap,
          ),
          if (clearButtonVisible)
            IconButton(
              icon: const Icon(
                Icons.clear,
                size: 20.0,
              ),
              visualDensity: VisualDensity.compact,
              onPressed: onClearButtonTap,
            ),
          const Spacer(),
          IconButton(
            icon: const Icon(
              Icons.chevron_left,
            ),
            onPressed: onLeftArrowTap,
          ),
          IconButton(
            icon: const Icon(
              Icons.chevron_right,
            ),
            onPressed: onRightArrowTap,
          ),
        ],
      ),
    );
  }
}

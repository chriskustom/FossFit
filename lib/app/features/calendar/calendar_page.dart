import 'package:flutter/material.dart';
import 'package:fossfit/app/features/workout/widgets/workout_grouped.dart';
import 'package:fossfit/app/features/workout/widgets/workout_list.dart';
import 'package:fossfit/app/services/features/gym_set_services.dart';
import 'package:fossfit/app/shell/app_shell.dart';
import 'package:fossfit/app/utils/constants.dart';
import 'package:fossfit/app/utils/utils.dart';
import 'package:fossfit/app/widgets/confirmation_dialog.dart';
import 'package:fossfit/app/widgets/custom_month_picker.dart';
import 'package:fossfit/db/models/features/gymset_model.dart';
import 'package:fossfit/db/repositories/config_reposity.dart';
import 'package:fossfit/db/repositories/gym_set_repository.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart' hide isSameDay;

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => CalendarPageState();
}

class CalendarPageState extends State<CalendarPage> {
  DateTime? _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();

  final ScrollController scroll = ScrollController();

  late PageController _pageController;
  final repsGt = TextEditingController();
  final repsLt = TextEditingController();
  final weightGt = TextEditingController();
  final weightLt = TextEditingController();

  final expand = ExpansibleController();

  final Set<GymSet> _selectedItems = {};
  bool get selectionMode => _selectedItems.isNotEmpty;
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
    final gymSets = context.watch<GymSetRepository>().gymsets;

    final setsByDay = <DateTime, List<GymSet>>{};

    for (final set in gymSets) {
      final local = set.created.toLocal();

      if (local.year != _focusedDay.year || local.month != _focusedDay.month) {
        continue;
      }

      final day = _dateOnly(set.created);

      setsByDay.putIfAbsent(day, () => []).add(set);
    }

    return AppShell(title: 'Calendar', selectActions: _selectActions(), body: _getCalendar(setsByDay));
  }

  Widget _getCalendar(Map<DateTime, List<GymSet>> monthlyGymSets) {
    final colors = Theme.of(context).colorScheme;
    var services = GymSetServices(context: context);
    var earliest = services.getAllGymSets().lastOrNull?.created ?? DateTime(2000, 1, 1);
    final today = DateUtils.dateOnly(DateTime.now());
    final selectedDate = _dateOnly(_selectedDay ?? _focusedDay);
    final selectedSets = monthlyGymSets[selectedDate];
    final isEmpty = selectedSets == null || selectedSets.isEmpty;
    final groupHistory = context.watch<ConfigRepository>().isEnabled(.workouts, 'group_history');
    final startOfWeek = context.watch<ConfigRepository>().getSetting(.formats, 'start_of_week');
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
            _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
          },
          onRightArrowTap: () {
            _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
          },
          onDateTap: () async {
            var selected = await showCustomMonthYearPicker(
              context: context,
              initialDate: _selectedDay ?? today,
              firstDate: earliest,
              lastDate: today.add(const Duration(days: 31)),
              backgroundColor: colors.surface,
              selectedColor: colors.primaryContainer,
              selectedTextColor: colors.onPrimaryContainer,
              textColor: colors.onSurface,
              disabledTextColor: colors.onInverseSurface,

              width: 300,
              monthHeight: 40,
              borderRadius: 14,
              padding: 16,
            );
            if (selected != null) {
              selected = selected.isBefore(earliest) ? earliest : selected;
              _focusedDay = selected;
              _selectedDay = selected;
              setState(() {});
            }
          },
        ),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: TableCalendar<GymSet>(
            firstDay: earliest,
            locale: 'en_AU',
            lastDay: today.add(Duration(days: 31)),
            focusedDay: _focusedDay,
            headerVisible: false,
            startingDayOfWeek: StartingDayOfWeek.values.byName(startOfWeek),
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay!, day);
            },
            rowHeight: 40,
            daysOfWeekStyle: DaysOfWeekStyle(weekdayStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withAlpha(150))),
            calendarFormat: CalendarFormat.month,
            rangeSelectionMode: RangeSelectionMode.disabled,
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                if (events.isEmpty) return SizedBox();
                return Container(
                  width: double.infinity,
                  height: 4,
                  margin: EdgeInsets.only(top: 2, left: 18, right: 18),
                  decoration: BoxDecoration(color: Theme.of(context).colorScheme.onSurface, borderRadius: BorderRadius.circular(2)),
                );
              },
            ),
            eventLoader: (day) {
              final localDay = day.toLocal();

              final date = DateTime(localDay.year, localDay.month, localDay.day);

              return monthlyGymSets[date] ?? [];
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = selectedDay;
              });
            },
            onCalendarCreated: (controller) {
              _pageController = controller;
            },
            onPageChanged: (focusedDay) {
              setState(() {
                _focusedDay = focusedDay;
              });
            },
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).colorScheme.secondary),
                color: Colors.transparent,
                shape: BoxShape.circle,
              ),
              todayTextStyle: TextStyle(color: Theme.of(context).colorScheme.primary),
              selectedDecoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, shape: BoxShape.circle),
              selectedTextStyle: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
              markerDecoration: BoxDecoration(color: Colors.transparent, shape: BoxShape.circle),
            ),
          ),
        ),
        if (isEmpty) ...[const SizedBox(height: 12.0), Padding(padding: .symmetric(horizontal: 16), child: Divider()), const SizedBox(height: 8.0)],
        Expanded(
          child: GestureDetector(
            onHorizontalDragEnd: (details) {
              if (details.primaryVelocity != null) {
                if (details.primaryVelocity! > 0) {
                  _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                } else {
                  _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                }
              }
            },
            child: selectedSets == null || selectedSets.isEmpty
                ? Text(emptyPhrases.randomItem)
                : groupHistory
                ? WorkoutGrouped(
                    sets: selectedSets,
                    selectedItems: _selectedItems,
                    selectionMode: selectionMode,
                    toggleSelection: (set) => _toggleSelection(set),
                    editSet: (set) => _editSet(set),
                    scroll: scroll,
                  )
                : WorkoutList(
                    sets: selectedSets,
                    selectedItems: _selectedItems,
                    selectionMode: selectionMode,
                    toggleSelection: (set) => _toggleSelection(set),
                    editSet: (set) => _editSet(set),
                    scroll: scroll,
                  ),
          ),
        ),
      ],
    );
  }

  DateTime _dateOnly(DateTime date) {
    final local = date.toLocal();

    return DateTime(local.year, local.month, local.day);
  }

  void _editSet(GymSet gymSet) async {
    var services = GymSetServices(context: context);
    await services.openAddEditPage(context, gymSet.id);
    setState(() {});
  }

  void _toggleSelection(GymSet set) {
    setState(() {
      _selectedItems.contains(set) ? _selectedItems.remove(set) : _selectedItems.add(set);
    });
  }

  List<IconButton> _selectActions() {
    final setServices = GymSetServices(context: context);
    final sets = setServices.getAllGymSets();
    List<IconButton> buttons = [];
    if (_selectedItems.isNotEmpty) {
      buttons.add(
        IconButton(
          onPressed: () {
            setState(() {
              if (_selectedItems.length == sets.length) {
                _selectedItems.clear();
              } else {
                _selectedItems.addAll(sets);
              }
            });
          },
          icon: Icon(_selectedItems.length == sets.length ? Icons.deselect : Icons.select_all),
        ),
      );

      buttons.addAll([
        IconButton(
          onPressed: () async {
            final confirmed = await showConfirmationDialog(context: context, title: "Delete?", content: "Are you sure?", barrierDismissible: true);

            if (!mounted || confirmed == null || !confirmed) return;
            await setServices.deleteMultipleGymSetssByIds(_selectedItems.map((i) => i.id!).toList());
            setState(() => _selectedItems.clear());
          },
          icon: const Icon(Icons.delete),
        ),
      ]);
    }
    setState(() {});
    return buttons;
  }
}

class _CalendarHeader extends StatelessWidget {
  final DateTime focusedDay;
  final VoidCallback onLeftArrowTap;
  final VoidCallback onRightArrowTap;
  final VoidCallback onTodayButtonTap;
  final VoidCallback onClearButtonTap;
  final VoidCallback onDateTap;
  final bool clearButtonVisible;

  const _CalendarHeader({
    required this.focusedDay,
    required this.onLeftArrowTap,
    required this.onRightArrowTap,
    required this.onTodayButtonTap,
    required this.onClearButtonTap,
    required this.clearButtonVisible,
    required this.onDateTap,
  });

  @override
  Widget build(BuildContext context) {
    final headerText = DateFormat.yMMM().format(focusedDay);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          const SizedBox(width: 16.0),
          SizedBox(
            width: 130.0,
            child: InkWell(
              onTap: onDateTap,
              child: Text(headerText, style: const TextStyle(fontSize: 26.0)),
            ),
          ),
          IconButton(
            icon: Icon(Icons.calendar_today, size: 20.0, color: Theme.of(context).colorScheme.primary),
            visualDensity: VisualDensity.compact,
            onPressed: onTodayButtonTap,
          ),
          if (clearButtonVisible)
            IconButton(icon: const Icon(Icons.clear, size: 20.0), visualDensity: VisualDensity.compact, onPressed: onClearButtonTap),
          const Spacer(),
          IconButton(icon: const Icon(Icons.chevron_left), onPressed: onLeftArrowTap),
          IconButton(icon: const Icon(Icons.chevron_right), onPressed: onRightArrowTap),
        ],
      ),
    );
  }
}

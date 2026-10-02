import 'package:flutter/material.dart';
import 'package:fossfit/app/features/strength/widgets/history_grouped.dart';
import 'package:fossfit/app/features/strength/widgets/history_list.dart';
import 'package:fossfit/app/features/strength/widgets/history_peek.dart';
import 'package:fossfit/app/services/features/cardio_services.dart';
import 'package:fossfit/app/services/features/gym_set_services.dart';
import 'package:fossfit/app/shell/app_shell.dart';
import 'package:fossfit/app/utils/utils.dart';
import 'package:fossfit/app/widgets/confirmation_dialog.dart';
import 'package:fossfit/db/models/features/cardio_model.dart';
import 'package:fossfit/db/models/features/exercise_model.dart';
import 'package:fossfit/db/models/features/gymset_model.dart';
import 'package:fossfit/db/repositories/cardio_repository.dart';
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
  List<GymSet> gymSets = [];
  List<Cardio> cardioSets = [];

  DateTime? _selectedDay = DateTime.now();
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

  Widget lastWorkout = const SizedBox.shrink();

  String search = '';

  DateTime? startDate;
  DateTime? endDate;
  String? category;

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
    gymSets = context.watch<GymSetRepository>().gymsets;
    cardioSets = context.watch<CardioRepository>().cardio;
    final allGymSets = gymSets;
    final allCardioSets = cardioSets;
    final thisMonthsGymSets = allGymSets.where((t) => t.created.month == monthToFilter && t.created.year == yearToFilter).toList();
    final thisMonthsCardioSets = allCardioSets.where((t) => t.created.month == monthToFilter && t.created.year == yearToFilter).toList();

    return AppShell(title: 'Calendar', selectActions: _selectActions(), body: _getCalendar(thisMonthsGymSets, thisMonthsCardioSets));
  }

  Widget _getCalendar(List<GymSet> monthlyGymSets, List<Cardio> monthlyCardioSets) {
    final today = DateUtils.dateOnly(DateTime.now());
    final selectedDate = _selectedDay ?? _focusedDay;

    var gymServices = GymSetServices(context: context);
    final selectedGymSets = monthlyGymSets.where((set) => isSameDay(set.created, selectedDate)).toList();

    var cardioServices = CardioServices(context: context);
    final selectedCardioSets = monthlyCardioSets.where((set) => isSameDay(set.created, selectedDate)).toList();

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
        ),

        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: TableCalendar<ExerciseSets?>(
            firstDay: DateTime(1900, 1, 1),
            lastDay: DateTime(2100, 12, 31),
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
                if (events.isEmpty) {
                  return const SizedBox();
                }

                return Container(
                  width: double.infinity,
                  height: 4,
                  margin: const EdgeInsets.only(top: 2, left: 18, right: 18),
                  decoration: BoxDecoration(color: Theme.of(context).colorScheme.onSurface, borderRadius: BorderRadius.circular(2)),
                );
              },
            ),
            eventLoader: (day) {
              final gymExercise = gymServices.getExerciseSets(monthlyGymSets).where((e) => isSameDay(e.date, day)).firstOrNull;

              final cardioExercise = cardioServices.getCardioSets(monthlyCardioSets).where((e) => isSameDay(e.date, day)).firstOrNull;

              return (gymExercise == null && cardioExercise == null) ? <ExerciseSets>[] : [gymExercise, cardioExercise];
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
                border: Border.all(color: Theme.of(context).colorScheme.secondary),
                color: Colors.transparent,
                shape: BoxShape.circle,
              ),
              cellMargin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              todayTextStyle: TextStyle(color: Theme.of(context).colorScheme.primary),
              selectedDecoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, shape: BoxShape.circle),
              selectedTextStyle: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
              markerDecoration: const BoxDecoration(color: Colors.transparent, shape: BoxShape.circle),
            ),
          ),
        ),

        const SizedBox(height: 8),

        Expanded(
          child: GestureDetector(
            onHorizontalDragEnd: (details) {
              final velocity = details.primaryVelocity;

              if (velocity == null) {
                return;
              }

              if (velocity > 0) {
                _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
              } else {
                _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
              }
            },
            child: Column(
              mainAxisSize: .min,
              children: [
                Flexible(
                  fit: FlexFit.loose,
                  child: groupHistory
                      ? HistoryGrouped(
                          sets: selectedGymSets,
                          selectedItems: _selectedItems,
                          selectionMode: selectionMode,
                          toggleSelection: _toggleSelection,
                          scroll: scroll,
                        )
                      : HistoryList(
                          sets: selectedGymSets,
                          selectedItems: _selectedItems,
                          selectionMode: selectionMode,
                          toggleSelection: _toggleSelection,
                          scroll: scroll,
                        ),
                ),

                Flexible(
                  fit: FlexFit.loose,
                  child: HistoryPeek(sets: [], cardio: selectedCardioSets, dateHeader: 'Cardio'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
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
    final headerText = DateFormat.yMMM().format(focusedDay);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          const SizedBox(width: 16.0),
          SizedBox(width: 130.0, child: Text(headerText, style: const TextStyle(fontSize: 26.0))),
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

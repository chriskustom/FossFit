import 'package:flutter/material.dart';
import 'package:fossfit/app/features/calendar/calendar_page.dart';
import 'package:fossfit/app/features/cardio/cardio_page.dart';
import 'package:fossfit/app/features/exercises/exercises_page.dart';
import 'package:fossfit/app/features/plans/plans_page.dart';
import 'package:fossfit/app/features/strength/strength_page.dart';
import 'package:fossfit/app/settings/settings_page.dart';
import 'package:fossfit/app/utils/sort_option.dart';

enum Period { day, week, month, year }

enum StrengthMetric { oneRepMax, volume, bestWeight, relativeStrength, bestReps }

enum CardioMetric { pace, distance, duration, incline, inclineAdjustedPace }

enum GraphSort { dateDesc, dateAsc, name }

enum ThreeDialogOptions { save, dismiss, stay }

enum NavRoute {
  strength("/strength", Icons.fitness_center_rounded, StrengthPage()),
  exercises('/exercises', Icons.list_alt_rounded, ExercisesPage()),
  plans('/plans', Icons.format_list_numbered, PlansPage()),
  calendar('/calendar', Icons.calendar_month_rounded, CalendarPage()),
  cardio('/cardio', Icons.directions_run, CardioPage()),
  settings('/settings', Icons.settings, SettingsPage());

  const NavRoute(this.route, this.icon, this.page);
  final String route;
  final IconData icon;
  final Widget page;

  static NavRoute fromRoute(String? route, String home) {
    if (route == null) return NavRoute.values.byName(home);
    return NavRoute.values.firstWhere((e) => e.route == route || route.startsWith(e.route), orElse: () => NavRoute.values.byName(home));
  }

  bool matches(String? route) => route != null && route.startsWith(this.route);

  static List<String> get allRoutes => NavRoute.values.map((e) => e.route).toList();

  @override
  String toString() => route;
}

enum ConfigCategory {
  appearance('appearance', Icons.color_lens_rounded),
  backup('backup', Icons.storage_rounded),
  formats('formats', Icons.text_format_rounded),
  plans('plans', Icons.today_rounded),
  tabs('tabs', Icons.tab_rounded),
  timers('timers', Icons.timer_rounded),
  cardio('cardio', Icons.directions_run),
  workouts('workouts', Icons.fitness_center_rounded);

  const ConfigCategory(this.name, this.icon);
  final String name;
  final IconData icon;
}

enum SortBy { name, date }

enum SortOrder { asc, desc }

const double switchScale = 0.85;
const double iconScale = 0.85;

const sortOptions = [
  SortOption(SortBy.name, SortOrder.asc, 'Name (A–Z)', Icons.sort_by_alpha),
  SortOption(SortBy.name, SortOrder.desc, 'Name (Z–A)', Icons.sort_by_alpha),
  SortOption(SortBy.date, SortOrder.desc, 'Completed (Earliest)', Icons.schedule),
  SortOption(SortBy.date, SortOrder.asc, 'Completed (Latest)', Icons.schedule),
];

const Map<String, Icon> homePageMenu = {'Settings': Icon(Icons.settings), 'About': Icon(Icons.info_outline)};

const double globalElevation = 5.0;

const List<String> emptyPhrases = [
  'Wow. So empty.',
  'Nothing here.',
  'Cue tumbleweeds',
  'Crickets chirping…',
  'Echo… echo…',
  'Bare as a winter tree.',
  'Zero. Zilch. Nada.',
  'Looks like nobody is home.',
  'The void stares back.',
  'Emptier than my inbox.',
  'Nothing to see here. Move along.',
  'Blank canvas.',
  'Just air and echoes.',
  'A hollow silence.',
  'Space… unoccupied.',
  'Deserted as a ghost town.',
  'Not a soul in sight.',
  'Silent as the grave.',
  'Just dust settling.',
  'Vacant and vast.',
  'Nobody showed up.',
  'All quiet on this front.',
  'An empty stage.',
  'No footprints here.',
  'Stillness everywhere.',
  'A whole lot of nothing.',
  'Quiet as midnight.',
  'Left on read by the universe.',
  'Only shadows remain.',
  'A lonely little corner.',
  'Nothing but whitespace.',
  'Unclaimed territory.',
  'Echo chamber of one.',
  'Abandoned by activity.',
  'A pause without play.',
  'Deader than dead air.',
  'Waiting for something… anything.',
  'A barren landscape.',
  'No signs of life.',
  'Just static.',
  'Silence you can hear.',
  'Not even a whisper.',
  'Cleared out completely.',
  'A vacancy sign flickering.',
  'Empty seats all around.',
  'Like a library at closing.',
  'Quiet as snowfall.',
  'Nothing but open space.',
  'A room without guests.',
  'Deserted and still.',
  'Just the sound of nothing.',
  'Swept clean.',
  'A lull without the storm.',
  'No movement detected.',
  'Just a vacant stare.',
  'All hush, no rush.',
  'The lights are on, but nobody’s here.',
  'A calm before anything.',
  'Pure, uninterrupted quiet.',
  'An untouched expanse.',
];

const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

const List<MapEntry<String, String>> strengthUnits = [MapEntry('kg', 'Kilograms (kg)'), MapEntry('lb', 'Pounds (lb)'), MapEntry('st', 'Stone (st)')];
const List<MapEntry<String, String>> distanceUnits = [MapEntry('km', 'Kilometers (km)'), MapEntry('mi', 'Miles (mi)')];
const List<MapEntry<String, String>> paceUnits = [
  MapEntry('min/km', 'Minutes per Kilometer (min/km)'),
  MapEntry('min/mi', 'Minutes per mile (min/mi)'),
];
const List<String> exerciseTypes = ['strength', 'cardio'];
const longdateFormats = [
  'timeago',
  'dd/MM/yy',
  'dd/MM/yy h:mm a',
  'dd/MM/yy H:mm',
  'dd.MM.yyyy H:mm',
  'EEE h:mm a',
  'yyyy-MM-dd',
  'yyyy-MM-dd h:mm a',
  'yyyy-MM-dd H:mm',
  'yyyy.MM.dd',
  'yyyy.MM.dd h:mm a',
  'yyyy.MM.dd H:mm',
  'MMM d (EEE) h:mm a',
  'EEE, dd.MM.yyyy H:mm',
  'EEE, dd.MM.yyyy H:mm a',
];

const shortdateFormats = ['d/M/yy', 'M/d/yy', 'd-M-yy', 'M-d-yy', 'd.M.yy', 'M.d.yy', 'dd.MM.yy'];

const fonts = ['Arial', 'Lato', 'Lunasima', 'Montserrat', 'Noto Sans', 'Open Sans', 'Roboto', 'Staatliches', 'Times New Roman', 'Wolland'];

const defaultStrengthExercises = [
  ('Arnold press', 'Shoulders', 0),
  ('Back extension', 'Back', 0),
  ('Barbell bench press', 'Chest', 0),
  ('Barbell biceps curl', 'Arms', 0),
  ('Barbell bent-over row', 'Back', 0),
  ('Barbell shoulder press', 'Shoulders', 0),
  ('Barbell shrug', 'Shoulders', 0),
  ('Cable fly', 'Chest', 0),
  ('Cable lateral raise', 'Shoulders', 0),
  ('Cable pull-down', 'Back', 0),
  ('Chest fly', 'Chest', 0),
  ('Chin-up', 'Back', 0),
  ('Close-grip pull-up', 'Back', 0),
  ('Crunch', 'Core', 0),
  ('Deadlift', 'Back', 0),
  ('Decline bench press', 'Chest', 0),
  ('Diamond push-up', 'Chest', 0),
  ('Dumbbell bench press', 'Chest', 0),
  ('Dumbbell biceps curl', 'Arms', 0),
  ('Dumbbell bent-over row', 'Back', 0),
  ('Dumbbell fly', 'Chest', 0),
  ('Dumbbell lateral raise', 'Shoulders', 0),
  ('Dumbbell shoulder press', 'Shoulders', 0),
  ('Dumbbell shrug', 'Shoulders', 0),
  ('Good morning', 'Back', 0),
  ('Hanging leg raise', 'Core', 0),
  ('Hyperextension', 'Back', 0),
  ('Incline bench press', 'Chest', 0),
  ('Lat pull-down', 'Back', 0),
  ('Leg curl', 'Legs', 0),
  ('Leg extension', 'Legs', 0),
  ('Leg press', 'Legs', 0),
  ('Leg raise', 'Core', 0),
  ('Lunge', 'Legs', 0),
  ('Narrow-grip push-up', 'Chest', 0),
  ('Neck curl', 'Shoulders', 0),
  ('Overhead triceps extension', 'Arms', 0),
  ('Preacher curl', 'Arms', 0),
  ('Pull-down', 'Back', 0),
  ('Pull-up', 'Back', 0),
  ('Push-up', 'Chest', 0),
  ('Reverse grip pull-down', 'Back', 0),
  ('Reverse grip pushdown', 'Arms', 0),
  ('Roman chair leg raise', 'Core', 0),
  ('Romanian deadlift', 'Back', 0),
  ('Russian twist', 'Core', 0),
  ('Seated calf raise', 'Calves', 0),
  ('Shoulder shrug', 'Shoulders', 0),
  ('Squat', 'Legs', 0),
  ('Standing calf raise', 'Calves', 0),
  ('T-bar row', 'Back', 0),
  ('Triceps dip', 'Arms', 0),
  ('Triceps extension', 'Arms', 0),
  ('Triceps pushdown', 'Arms', 0),
  ('Upright row', 'Shoulders', 0),
  ('Weighted Russian twist', 'Core', 0),
  ('Wide-grip pull-up', 'Back', 0),
  ('Wide-grip push-up', 'Chest', 0),
];

const defaultCardioExercises = [
  ('Running', 1),
  ('Jogging', 1),
  ('Walking', 1),
  ('Cycling', 1),
  ('Swimming', 1),
  ('Jumping jacks', 1),
  ('Jump rope', 1),
  ('Rowing', 1),
  ('Stair climbing', 1),
  ('Hiking', 1),
  ('Elliptical', 1),
  ('Dancing', 1),
  ('Burpees', 1),
  ('High knees', 1),
  ('Mountain climbers', 1),
  ('Boxing', 1),
  ('Kickboxing', 1),
  ('Aerobics', 1),
  ('Zumba', 1),
  ('Skating', 1),
];

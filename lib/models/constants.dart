import 'package:flutter/material.dart';
import 'package:fossfit/models/sort_option.dart';

const Map<String, Icon> homePageMenu = {
  'Settings': Icon(Icons.settings),
  'About': Icon(Icons.info_outline),
};
const Map<String, Icon> notebooksMenu = {
  'Archive': Icon(Icons.archive),
  'Trash': Icon(Icons.delete),
  'Settings': Icon(Icons.settings),
  'About': Icon(Icons.info_outline),
};

enum ThreeDialogOptions { save, dismiss, stay }

enum TaskFrequency {
  minute('minute'),
  hour('hour'),
  day('day');

  const TaskFrequency(this.freq);
  final String freq;
}

const double globalElevation = 3.0;
const double baseCardWidth = 120.0;
const Map<String, double> cardSizes = {
  '1': baseCardWidth,
  '2': 160.0,
  '3': 200.0,
};
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

enum NavRoute {
  home("/home"),
  notebooks('/notebooks'),
  notes('/notes'),
  goals('/goals'),
  lists('/lists'),
  settings('/settings'),
  tags('/tags'),
  archive('/archive'),
  trash('/trash');

  const NavRoute(this.route);
  final String route;

  static NavRoute fromRoute(String? route) {
    if (route == null) return NavRoute.home;
    return NavRoute.values.firstWhere(
      (e) => e.route == route || route.startsWith(e.route),
      orElse: () => NavRoute.home,
    );
  }

  bool matches(String? route) => route != null && route.startsWith(this.route);

  static List<String> get allRoutes => NavRoute.values.map((e) => e.route).toList();

  @override
  String toString() => route;
}

enum SettingCategory {
  appearance('appearance'),
  data('data'),
  formats('formats'),
  plans('plans'),
  tabs('tabs'),
  timers('timers'),
  workouts('workouts');

  const SettingCategory(this.name);
  final String name;
}

enum SortBy { title, date }

enum SortOrder { asc, desc }

enum GroupBy { day, week, task }

const sortOptions = [
  SortOption(SortBy.title, SortOrder.asc, 'Title (A–Z)', Icons.sort_by_alpha),
  SortOption(SortBy.title, SortOrder.desc, 'Title (Z–A)', Icons.sort_by_alpha),
  SortOption(SortBy.date, SortOrder.desc, 'Date (Newest)', Icons.schedule),
  SortOption(SortBy.date, SortOrder.asc, 'Date (Oldest)', Icons.schedule),
];

const sortOptions2 = [
  SortOption(SortBy.title, SortOrder.asc, 'Title (A–Z)', Icons.sort_by_alpha),
  SortOption(SortBy.title, SortOrder.desc, 'Title (Z–A)', Icons.sort_by_alpha),
  SortOption(SortBy.date, SortOrder.desc, 'Date (Earliest)', Icons.schedule),
  SortOption(SortBy.date, SortOrder.asc, 'Date (Latest)', Icons.schedule),
];

enum EntityType { note, notebook, list, goal }

const List<String> dateFormats = [
  'd/M/yy',
  'M/d/yy',
  'd-M-yy',
  'M-d-yy',
  'd.M.yy',
  'M.d.yy',
  'dd.MM.yy',
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
];
const fonts = [
  'Arial',
  'Lato',
  'Lunasima',
  'Montserrat',
  'Noto Sans',
  'Open Sans',
  'Roboto',
  'Staatliches',
  'Times New Roman',
  'Wolland',
];
const defaultExercises = [
  ('Arnold press', 'Shoulders'),
  ('Back extension', 'Back'),
  ('Barbell bench press', 'Chest'),
  ('Barbell biceps curl', 'Arms'),
  ('Barbell bent-over row', 'Back'),
  ('Barbell shoulder press', 'Shoulders'),
  ('Barbell shrug', 'Shoulders'),
  ('Cable fly', 'Chest'),
  ('Cable lateral raise', 'Shoulders'),
  ('Cable pull-down', 'Back'),
  ('Chest fly', 'Chest'),
  ('Chin-up', 'Back'),
  ('Close-grip pull-up', 'Back'),
  ('Crunch', 'Core'),
  ('Deadlift', 'Back'),
  ('Decline bench press', 'Chest'),
  ('Diamond push-up', 'Chest'),
  ('Dumbbell bench press', 'Chest'),
  ('Dumbbell biceps curl', 'Arms'),
  ('Dumbbell bent-over row', 'Back'),
  ('Dumbbell fly', 'Chest'),
  ('Dumbbell lateral raise', 'Shoulders'),
  ('Dumbbell shoulder press', 'Shoulders'),
  ('Dumbbell shrug', 'Shoulders'),
  ('Good morning', 'Back'),
  ('Hanging leg raise', 'Core'),
  ('Hyperextension', 'Back'),
  ('Incline bench press', 'Chest'),
  ('Lat pull-down', 'Back'),
  ('Leg curl', 'Legs'),
  ('Leg extension', 'Legs'),
  ('Leg press', 'Legs'),
  ('Leg raise', 'Core'),
  ('Lunge', 'Legs'),
  ('Narrow-grip push-up', 'Chest'),
  ('Neck curl', 'Shoulders'),
  ('Overhead triceps extension', 'Arms'),
  ('Preacher curl', 'Arms'),
  ('Pull-down', 'Back'),
  ('Pull-up', 'Back'),
  ('Push-up', 'Chest'),
  ('Reverse grip pull-down', 'Back'),
  ('Reverse grip pushdown', 'Arms'),
  ('Roman chair leg raise', 'Core'),
  ('Romanian deadlift', 'Back'),
  ('Russian twist', 'Core'),
  ('Seated calf raise', 'Calves'),
  ('Shoulder shrug', 'Shoulders'),
  ('Squat', 'Legs'),
  ('Standing calf raise', 'Calves'),
  ('T-bar row', 'Back'),
  ('Triceps dip', 'Arms'),
  ('Triceps extension', 'Arms'),
  ('Triceps pushdown', 'Arms'),
  ('Upright row', 'Shoulders'),
  ('Weighted Russian twist', 'Core'),
  ('Wide-grip pull-up', 'Back'),
  ('Wide-grip push-up', 'Chest'),
];

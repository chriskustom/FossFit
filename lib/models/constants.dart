import 'package:flutter/material.dart';

enum ThreeDialogOptions { save, dismiss, stay }

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

const defaultExercises = [
  ('Arnold press', 0, 'Shoulders', null),
  ('Back extension', 0, 'Back', null),
  ('Barbell bench press', 0, 'Chest', null),
  ('Barbell biceps curl', 0, 'Arms', null),
  ('Barbell bent-over row', 0, 'Back', null),
  ('Barbell shoulder press', 0, 'Shoulders', null),
  ('Barbell shrug', 0, 'Shoulders', null),
  ('Cable fly', 0, 'Chest', null),
  ('Cable lateral raise', 0, 'Shoulders', null),
  ('Cable pull-down', 0, 'Back', null),
  ('Chest fly', 0, 'Chest', null),
  ('Chin-up', 0, 'Back', null),
  ('Close-grip pull-up', 0, 'Back', null),
  ('Crunch', 0, 'Core', null),
  ('Deadlift', 0, 'Back', null),
  ('Decline bench press', 0, 'Chest', null),
  ('Diamond push-up', 0, 'Chest', null),
  ('Dumbbell bench press', 0, 'Chest', null),
  ('Dumbbell biceps curl', 0, 'Arms', null),
  ('Dumbbell bent-over row', 0, 'Back', null),
  ('Dumbbell fly', 0, 'Chest', null),
  ('Dumbbell lateral raise', 0, 'Shoulders', null),
  ('Dumbbell shoulder press', 0, 'Shoulders', null),
  ('Dumbbell shrug', 0, 'Shoulders', null),
  ('Good morning', 0, 'Back', null),
  ('Hanging leg raise', 0, 'Core', null),
  ('Hyperextension', 0, 'Back', null),
  ('Incline bench press', 0, 'Chest', null),
  ('Lat pull-down', 0, 'Back', null),
  ('Leg curl', 0, 'Legs', null),
  ('Leg extension', 0, 'Legs', null),
  ('Leg press', 0, 'Legs', null),
  ('Leg raise', 0, 'Core', null),
  ('Lunge', 0, 'Legs', null),
  ('Narrow-grip push-up', 0, 'Chest', null),
  ('Neck curl', 0, 'Shoulders', null),
  ('Overhead triceps extension', 0, 'Arms', null),
  ('Preacher curl', 0, 'Arms', null),
  ('Pull-down', 0, 'Back', null),
  ('Pull-up', 0, 'Back', null),
  ('Push-up', 0, 'Chest', null),
  ('Reverse grip pull-down', 0, 'Back', null),
  ('Reverse grip pushdown', 0, 'Arms', null),
  ('Roman chair leg raise', 0, 'Core', null),
  ('Romanian deadlift', 0, 'Back', null),
  ('Russian twist', 0, 'Core', null),
  ('Seated calf raise', 0, 'Calves', null),
  ('Shoulder shrug', 0, 'Shoulders', null),
  ('Squat', 0, 'Legs', null),
  ('Standing calf raise', 0, 'Calves', null),
  ('T-bar row', 0, 'Back', null),
  ('Triceps dip', 0, 'Arms', null),
  ('Triceps extension', 0, 'Arms', null),
  ('Triceps pushdown', 0, 'Arms', null),
  ('Upright row', 0, 'Shoulders', null),
  ('Weighted Russian twist', 0, 'Core', null),
  ('Wide-grip pull-up', 0, 'Back', null),
  ('Wide-grip push-up', 0, 'Chest', null),
];

enum NavRoute {
  workouts("/workout"),
  plans('/plans'),
  exercises('/exercises'),
  calendar('/calendar'),
  timer('/timer'),
  settings('/settings');

  const NavRoute(this.route);
  final String route;

  static NavRoute fromRoute(String? route) {
    if (route == null) return NavRoute.workouts;
    return NavRoute.values.firstWhere(
      (e) => e.route == route || route.startsWith(e.route),
      orElse: () => NavRoute.workouts,
    );
  }

  bool matches(String? route) => route != null && route.startsWith(this.route);

  static List<String> get allRoutes => NavRoute.values.map((e) => e.route).toList();

  @override
  String toString() => route;
}

const weekdays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

enum CardioMetric { pace, distance, duration, incline, inclineAdjustedPace }

enum Period {
  day,
  week,
  month,
  year,
}

enum PlanTrailing { reorder, ratio, count, percent, none }

enum StrengthMetric {
  oneRepMax,
  volume,
  bestWeight,
  relativeStrength,
  bestReps,
}

enum GraphSort {
  dateDesc,
  dateAsc,
  name,
}

const positiveReinforcement = [
  'Great work! You are incredible.',
  'Nice king! Your progress is inspiring.',
  'I kneel...',
  "What's that? A new record!",
  "Incredible stuff! You are an inspiration.",
  "Wow. Nice.",
  "Getting strong much?",
  "Yeah. You're a pretty big guy.",
  "Amazing. Incredible.",
  "Arnie would be proud.",
  "Ronnie C looks upon you with glee.",
  "YEAH! LIGHTWEIGHT BABY!!!!!!!",
  "Is that a new record? I knew you could do it.",
  "Great work! I am proud of you.",
  "Yeah baby! Light weight!",
  "Keep it up! Great progress.",
  "You are doing so well.",
  "That's my boy!",
  "Keep it up.",
  "You are getting very strong.",
  "Powerful.",
  "Powerful stuff!",
  "I am proud of you.",
  "Keep up the great work.",
  "Stand tall! You just made a new record.",
  "New record! You just pushed further than ever!",
  "Yep! That's a record.",
  "Wow! New record!",
  "Very good stuff.",
];

const strengthUnits = [
  DropdownMenuItem(
    value: 'kg',
    child: Text('Kilograms (kg)'),
  ),
  DropdownMenuItem(
    value: 'lb',
    child: Text('Pounds (lb)'),
  ),
  DropdownMenuItem(
    value: 'stone',
    child: Text('Stone (st)'),
  ),
  DropdownMenuItem(
    value: 'km',
    child: Text('Kilometers (km)'),
  ),
  DropdownMenuItem(
    value: 'mi',
    child: Text('Miles (mi)'),
  ),
  DropdownMenuItem(
    value: 'm',
    child: Text('Meters (m)'),
  ),
  DropdownMenuItem(
    value: 'kcal',
    child: Text('Kilocalories (kcal)'),
  ),
];

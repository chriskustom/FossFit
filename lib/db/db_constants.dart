enum TableName {
  gymsets('gym_sets'),
  exercises('exercises'),
  plans('plans'),
  planexercises('plan_exercises'),
  settings('settings');

  const TableName(this.name);
  final String name;
}

const int kDatabaseSchemaVersion = 2;

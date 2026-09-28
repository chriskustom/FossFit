enum TableName {
  exercises('exercises'),
  sets('sets'),
  plans('plans'),
  planexercises('plan_exercises'),
  timer('timer'),
  config('config');

  const TableName(this.name);
  final String name;
}

const int kDatabaseSchemaVersion = 1;

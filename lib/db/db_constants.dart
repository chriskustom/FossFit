enum TableName {
  exercises('exercises'),
  sets('sets'),
  cardio('cardio/*  */'),
  plans('plans'),
  planexercises('plan_exercises'),
  config('config');

  const TableName(this.name);
  final String name;
}

const int kDatabaseSchemaVersion = 1;

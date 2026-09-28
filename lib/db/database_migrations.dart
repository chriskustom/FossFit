import 'package:sqflite/sqflite.dart';

Future<void> migrateToV2(Database db) async {
  await db.transaction((txn) async {
    await txn.execute('');
  });
}

import 'package:file_selector/file_selector.dart';
import 'package:fossfit/db/database_helper.dart';

Future<String> backupDatabaseManually(String initialDir) async {
  final String? path = await getDirectoryPath(initialDirectory: initialDir);

  if (path == null) {
    return 'Cancelled';
  }
  final dbHelper = DatabaseHelper();
  if (await dbHelper.backupDatabaseWithTimestamp(path)) {
    return 'Backup successful';
  }
  return 'Backup failed';
}

Future<String> importDatabase(String initialDir) async {
  // Pick a single file
  final typeGroup = XTypeGroup(label: 'SQLite Database', extensions: ['db', 'sqlite']);

  final file = await openFile(acceptedTypeGroups: [typeGroup]);

  if (file == null) {
    return 'Cancelled';
  }
  final dbHelper = DatabaseHelper();
  return await dbHelper.importDatabase(file.path);
}

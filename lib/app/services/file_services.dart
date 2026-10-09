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

Future<(bool, String)> importDatabase(String initialDir, {bool flexify = false}) async {
  // Pick a single file
  final typeGroup = XTypeGroup(label: 'SQLite Database', extensions: ['db', 'sqlite']);

  final file = await openFile(acceptedTypeGroups: [typeGroup]);

  if (file == null) {
    return (false, 'Cancelled');
  }
  final dbHelper = DatabaseHelper();
  return flexify ? await dbHelper.importFlexifyDatabase(file.path) : await dbHelper.importDatabase(file.path);
}

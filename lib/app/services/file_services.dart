import 'dart:io';

import 'package:fossfit/db/database_helper.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_selector/file_selector.dart';
import 'package:path/path.dart';
import 'package:platform_detail/platform_detail.dart';

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
  final typeGroup = XTypeGroup(label: 'SQLite Database', extensions: ['db']);

  final file = await openFile(acceptedTypeGroups: [typeGroup]);

  if (file == null) {
    return 'Cancelled';
  }
  final dbHelper = DatabaseHelper();
  return await dbHelper.importDatabase(file.path);
}

Future<Map<String, String>> importMarkdownFiles() async {
  Map<String, String> nameContents = {};

  if (PlatformDetail.isDesktop) {
    String? mdPath = await getDirectoryPath();
    if (mdPath == null) {
      return {};
    }
    final mdDirectory = Directory(mdPath);

    final mdFiles = mdDirectory.listSync().whereType<File>().where((f) => f.path.endsWith('.md')).toList();

    for (final file in mdFiles) {
      nameContents[basenameWithoutExtension(file.path)] = await file.readAsString();
    }
  } else {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['md'],
      allowMultiple: true,
    );

    if (result == null) return {};

    for (final file in result.files) {
      final content = await File(file.path!).readAsString();
      nameContents[basenameWithoutExtension(file.name)] = content;
    }
  }

  return nameContents;
}

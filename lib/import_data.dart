import 'package:file_picker/file_picker.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fossfit/db/database_helper.dart';

class ImportData extends StatelessWidget {
  final BuildContext ctx;
  const ImportData({
    super.key,
    required this.ctx,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () => importDatabase(context),
      icon: const Icon(Icons.upload),
      label: const Text('Import database'),
    );
  }

  Future<void> importDatabase(BuildContext context) async {
    Navigator.pop(context);

    if (kIsWeb) {
      await _importDatabaseWeb(context);
    } else {
      await _importDatabaseNative(context);
    }
  }

  Future<void> _importDatabaseNative(BuildContext context) async {
    // Pick a single file
    final typeGroup =
        XTypeGroup(label: 'SQLite Database', extensions: ['db', 'sqlite']);

    final file = await openFile(acceptedTypeGroups: [typeGroup]);

    if (file == null) {
      return;
    }
    final dbHelper = DatabaseHelper();
    await dbHelper.importDatabase(file.path);
  }

  Future<void> _importDatabaseWeb(BuildContext context) async {
    var result = await FilePicker.pickFile();
    if (result == null) return;

    Uint8List? fileBytes = await result.readAsBytes();
    if (fileBytes.isEmpty) {
      throw Exception('Could not read file data');
    }

    throw Exception(
      'Database import on web requires manual data migration. Please export your data as CSV files and import those instead.',
    );
  }
}

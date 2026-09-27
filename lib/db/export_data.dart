import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:fossfit/db/database_helper.dart';
import 'package:path_provider/path_provider.dart';

class ExportData extends StatelessWidget {
  const ExportData({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () async {
        Navigator.pop(context);
        final dbFolder = await getApplicationDocumentsDirectory();
        final String? path =
            await getDirectoryPath(initialDirectory: dbFolder.path);

        if (path == null) {
          return;
        }
        final dbHelper = DatabaseHelper();
        await dbHelper.backupDatabaseWithTimestamp(path);
      },
      icon: const Icon(Icons.download),
      label: const Text('Export database'),
    );
  }
}

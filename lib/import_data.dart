import 'package:file_picker/file_picker.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fossfit/db/database_helper.dart';
import 'package:fossfit/utils.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class ImportData extends StatelessWidget {
  final BuildContext ctx;
  const ImportData({
    super.key,
    required this.ctx,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () {
        showModalBottomSheet(
          useRootNavigator: true,
          context: context,
          builder: (context) {
            return SafeArea(
              child: Wrap(
                children: <Widget>[
                  ListTile(
                    leading: const Icon(Icons.storage),
                    title: const Text('Database'),
                    onTap: () => importDatabase(context),
                  ),
                ],
              ),
            );
          },
        );
      },
      icon: const Icon(Icons.upload),
      label: const Text('Import data'),
    );
  }

  Future<void> importDatabase(BuildContext context) async {
    Navigator.pop(context);

    try {
      if (kIsWeb) {
        await _importDatabaseWeb(context);
      } else {
        await _importDatabaseNative(context);
      }
    } catch (e, stackTrace) {
      if (!ctx.mounted) return;
      final packageInfo = await PackageInfo.fromPlatform();
      final version = packageInfo.version;

      final title = Uri.encodeComponent(
        'Import failed: ${e.toString().split('\n').first}',
      );
      final body = Uri.encodeComponent('''
# Describe the bug
Failed to import a database.

# Error
```
${e.toString()}
```

# Stack trace
```
${stackTrace.toString()}
```

# App version
$version

# Steps to reproduce
1. Go to import database
2. Select file
3. See error
''');

      final url = 'https://github.com/ChrisKustom/FossFit/issues/new?title=$title&body=$body';

      toast(
        'Failed to import database: ${e.toString()}',
        duration: Duration(seconds: 10),
        action: SnackBarAction(
          label: 'Report',
          onPressed: () async {
            await launchUrl(
              Uri.parse(url),
              mode: LaunchMode.externalApplication,
            );
          },
        ),
      );
    }
  }

  Future<void> _importDatabaseNative(BuildContext context) async {
    // Pick a single file
    final typeGroup = XTypeGroup(label: 'SQLite Database', extensions: ['db']);

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

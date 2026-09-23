import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fossfit/db/repositories/settings_repository.dart';
import 'package:fossfit/delete_records_button.dart';
import 'package:fossfit/export_data.dart';
import 'package:fossfit/import_data.dart';
import 'package:fossfit/main.dart';
import 'package:fossfit/models/constants.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

void tapBackup(bool value, SettingsRepository settings) async {
  settings.setSetting(
    category: SettingCategory.data,
    key: 'automatic_backups',
    value: value ? '1' : '0',
  );

  if (value) {
    final dbFolder = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dbFolder.path, 'FossFit.sqlite');
    androidChannel.invokeMethod('pick', {'dbPath': dbPath});
    await Permission.notification.request();
  }
}

List<Widget> getDataSettings(
  String term,
  SettingsRepository settings,
  BuildContext context,
) {
  return [
    if ('automatic backup'.contains(term.toLowerCase()))
      ListTile(
        title: const Text('Automatic backup'),
        leading: settings.isEnabled(key: 'automatic_backups')
            ? const Icon(Icons.timer)
            : const Icon(Icons.timer_outlined),
        onTap: () =>
            tapBackup(!settings.isEnabled(key: 'automatic_backups'), settings),
        trailing: Switch(
          value: settings.isEnabled(key: 'automatic_backups'),
          onChanged: (value) => tapBackup(value, settings),
        ),
      ),
    if ('share database'.contains(term.toLowerCase()) &&
        !kIsWeb &&
        !Platform.isLinux)
      TextButton.icon(
        onPressed: () async {
          final dbFolder = await getApplicationDocumentsDirectory();
          final dbPath = p.join(dbFolder.path, 'FossFit.sqlite');
          await SharePlus.instance.share(ShareParams(files: [XFile(dbPath)]));
        },
        label: const Text("Share database"),
        icon: const Icon(Icons.share),
      ),
    if ('export data'.contains(term.toLowerCase())) const ExportData(),
    if ('import data'.contains(term.toLowerCase())) ImportData(ctx: context),
    if ('delete records'.contains(term.toLowerCase()))
      DeleteRecordsButton(ctx: context),
  ];
}

class DataSettings extends StatelessWidget {
  const DataSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsRepository>();

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text("Data management"),
      ),
      body: ListView(
        children: getDataSettings('', settings, context),
      ),
    );
  }
}

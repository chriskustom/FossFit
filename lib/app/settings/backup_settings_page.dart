import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fossfit/app/services/app_services.dart';
import 'package:fossfit/app/services/file_services.dart';
import 'package:fossfit/app/shell/app_shell.dart';
import 'package:fossfit/app/utils/constants.dart';
import 'package:fossfit/app/utils/utils.dart';
import 'package:fossfit/app/widgets/app_snack_bar.dart';
import 'package:fossfit/app/widgets/confirmation_dialog.dart';
import 'package:fossfit/db/database_helper.dart';
import 'package:fossfit/db/repositories/config_reposity.dart';
import 'package:provider/provider.dart';

class BackupSettingsPage extends StatefulWidget {
  const BackupSettingsPage({super.key});

  @override
  State<BackupSettingsPage> createState() => _BackupSettingsPageState();
}

class _BackupSettingsPageState extends State<BackupSettingsPage> {
  final ConfigCategory category = .backup;
  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: category.name.toTitleCase,
      showSearch: false,
      showNavBar: false,
      body: Column(
        children: [
          Expanded(
            child: ListView(padding: const EdgeInsets.symmetric(vertical: 16), children: getChildren(context)),
          ),
          SafeArea(
            top: false,
            bottom: true,
            child: Padding(
              padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
              child: ListTile(
                leading: Transform.scale(
                  scale: iconScale,
                  child: Icon(Icons.warning, color: Colors.redAccent),
                ),
                title: Text('Reset'),
                subtitle: Text('Delete everything. Requires restart'),
                onTap: AppHaptics.alertWithHaptics(context, () async => _resetApp()),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> getChildren(BuildContext context) {
    const key = 'backup';
    List<Widget> retval = [_enableAutoBackup()];

    var enabled = context.watch<ConfigRepository>().isEnabled(category, key);
    if (enabled) {
      retval.addAll([_backupLocation(), _backupFrequency()]);
    }
    retval.add(_backupNow());
    retval.add(_importDatabase());
    return retval;
  }

  Padding _enableAutoBackup() {
    const key = 'backup';

    return Padding(
      padding: const EdgeInsets.all(4),
      child: Selector<ConfigRepository, bool>(
        selector: (_, repo) => repo.isEnabled(category, key),
        builder: (context, isEnabled, _) {
          return ListTile(
            leading: Transform.scale(
              scale: iconScale,
              child: Icon(Icons.repeat_rounded, color: isEnabled ? Theme.of(context).colorScheme.primary : null),
            ),
            title: Padding(padding: EdgeInsets.only(left: 8), child: Text('Enable automatic backup')),
            trailing: Transform.scale(
              scale: switchScale,
              child: Switch.adaptive(
                value: isEnabled,
                onChanged: (value) {
                  context.read<ConfigRepository>().setSetting(category: category, key: key, value: value ? '1' : '0');
                },
              ),
            ),
            onTap: () {
              context.read<ConfigRepository>().setSetting(category: category, key: key, value: !isEnabled ? '1' : '0');
            },
          );
        },
      ),
    );
  }

  Padding _backupLocation() {
    const key = 'directory';

    return Padding(
      padding: const EdgeInsets.all(4),
      child: Selector<ConfigRepository, String>(
        selector: (_, repo) => repo.getSetting(category, key),
        builder: (context, storedValue, _) {
          return ListTile(
            leading: Transform.scale(
              scale: iconScale,
              child: Icon(Icons.folder, color: Theme.of(context).colorScheme.primary),
            ),
            title: Text('Backup Location'),
            subtitle: Text(storedValue.isNotEmpty ? storedValue : 'No folder selected', overflow: TextOverflow.ellipsis),
            onTap: () async {
              final repo = context.read<ConfigRepository>();
              final String? path = await getDirectoryPath();
              if (path != null && path.isNotEmpty) {
                if (!mounted) return;

                await repo.setSetting(category: category, key: key, value: path);
              }
            },
          );
        },
      ),
    );
  }

  Padding _backupFrequency() {
    const key = 'frequency';
    return Padding(
      padding: EdgeInsets.all(4),
      child: Selector<ConfigRepository, String>(
        selector: (_, repo) => repo.getSetting(category, key),
        builder: (ctx, frequency, _) {
          return ListTile(
            leading: Transform.scale(
              scale: iconScale,
              child: Icon(Icons.replay_5_rounded, color: Theme.of(context).colorScheme.primary),
            ),
            title: Text('Frequency'),
            subtitle: DropdownButton<String>(
              value: frequency,
              isExpanded: true,
              isDense: true,
              underline: const SizedBox.shrink(),
              padding: EdgeInsets.zero,
              onChanged: (value) {
                context.read<ConfigRepository>().setSetting(category: category, key: key, value: value!);
              },
              items: [
                DropdownMenuItem<String>(value: '1', child: Text('Daily')),
                DropdownMenuItem<String>(value: '7', child: Text('Weekly')),
                DropdownMenuItem<String>(value: '14', child: Text('Fortnightly')),
              ],
            ),
          );
        },
      ),
    );
  }

  Padding _backupNow() {
    return Padding(
      padding: EdgeInsets.all(4),
      child: Selector<ConfigRepository, String>(
        selector: (_, repo) => repo.getSetting(category, 'directory'),
        builder: (ctx, dir, _) {
          return ListTile(
            leading: Transform.scale(
              scale: iconScale,
              child: Icon(Icons.download_rounded, color: Theme.of(context).colorScheme.primary),
            ),
            title: Text('Backup now'),
            subtitle: Text('Manually create backup of database'),
            onTap: AppHaptics.tapWithHaptics(context, () async {
              var result = await backupDatabaseManually(dir);
              AppSnackBar.success(result);
            }),
          );
        },
      ),
    );
  }

  Padding _importDatabase() {
    return Padding(
      padding: EdgeInsets.all(4),
      child: Selector<ConfigRepository, String>(
        selector: (_, repo) => repo.getSetting(category, 'directory'),
        builder: (ctx, dir, _) {
          return ListTile(
            leading: Transform.scale(
              scale: iconScale,
              child: Icon(Icons.upload_rounded, color: Theme.of(context).colorScheme.primary),
            ),
            title: Text('Restore backup'),
            subtitle: Text('Restore previous database. Requires restart'),
            onTap: AppHaptics.tapWithHaptics(context, () async {
              var (success, result) = await importDatabase(dir);
              if (success) {
                AppSnackBar.success(result);

                await Future.delayed(const Duration(milliseconds: 2000));
                if (Platform.isWindows) {
                  exit(0);
                } else {
                  SystemNavigator.pop(animated: true);
                }
              } else {
                AppSnackBar.error(result);
              }
            }),
            onLongPress: AppHaptics.tapWithHaptics(context, () async {
              var (success, result) = await importDatabase(dir, flexify: true);
              if (success) {
                AppSnackBar.success(result);

                await Future.delayed(const Duration(milliseconds: 2000));
                if (Platform.isWindows) {
                  exit(0);
                } else {
                  SystemNavigator.pop(animated: true);
                }
              } else {
                AppSnackBar.error(result);
              }
            }),
          );
        },
      ),
    );
  }

  void _resetApp() async {
    final proceed = await showConfirmationDialog(
      context: context,
      title: '⚠️!WARNING!⚠️',
      content: 'This will delete all content; notes, notebooks, lists and goals.\nAll settings will be reset to default.\n\nDo you wish to continue?',
      confirmStyle: TextButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
      cancelStyle: TextButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
      cancelLabel: 'No, take me home',
      confirmLabel: 'Yes, delete everything',
      barrierDismissible: true,
    );

    if (proceed == null || !proceed || !mounted) return;

    await DatabaseHelper().resetApp();

    AppSnackBar.success('App reset complete');

    await Future.delayed(const Duration(milliseconds: 2000));
    if (Platform.isWindows) {
      exit(0);
    } else {
      SystemNavigator.pop(animated: true);
    }
  }
}

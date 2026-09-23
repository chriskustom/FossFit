import 'package:flutter/material.dart';
import 'package:fossfit/db/repositories/settings_repository.dart';
import 'package:fossfit/models/constants.dart';

class SettingSwitch extends StatelessWidget {
  const SettingSwitch({
    super.key,
    required this.settings,
    required this.category,
    required this.keyName,
    required this.title,
    required this.tooltip,
    required this.enabledIcon,
    required this.disabledIcon,
  });

  final SettingsRepository settings;
  final SettingCategory category;
  final String keyName;
  final String title;
  final String tooltip;
  final IconData enabledIcon;
  final IconData disabledIcon;

  @override
  Widget build(BuildContext context) {
    final enabled = settings.isEnabled(key: keyName);

    void update(bool value) {
      settings.setSetting(
        category: category,
        key: keyName,
        value: value ? '1' : '0',
      );
    }

    return Tooltip(
      message: tooltip,
      child: ListTile(
        title: Text(title),
        leading: Icon(enabled ? enabledIcon : disabledIcon),
        onTap: () => update(!enabled),
        trailing: Switch(
          value: enabled,
          onChanged: update,
        ),
      ),
    );
  }
}

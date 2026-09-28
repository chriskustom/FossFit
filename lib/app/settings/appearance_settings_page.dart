import 'package:fossfit/app/shell/app_shell.dart';
import 'package:fossfit/db/repositories/config_reposity.dart';
import 'package:fossfit/app/utils/utils.dart';
import 'package:fossfit/app/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:provider/provider.dart';

class AppearanceSettings extends StatefulWidget {
  const AppearanceSettings({super.key});

  @override
  State<AppearanceSettings> createState() => _AppearanceSettingsState();
}

class _AppearanceSettingsState extends State<AppearanceSettings> {
  final ConfigCategory category = .appearance;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: category.name.toTitleCase,
      showSearch: false,
      showNavBar: false,
      body: ListView(
        children: [
          SizedBox(height: 16),
          Padding(
            padding: EdgeInsets.only(left: 16, top: 8),
            child: Text('Look', textScaler: TextScaler.linear(1.1)),
          ),
          SizedBox(height: 8),
          _themeItem(),
          _colorScheme(),
          SizedBox(height: 8),
          Divider(),
          Padding(
            padding: EdgeInsets.only(left: 16, top: 8),
            child: Text('Feel', textScaler: TextScaler.linear(1.1)),
          ),
          SizedBox(height: 8),
          _enableHaptics(),
        ],
      ),
    );
  }

  Padding _themeItem() {
    return Padding(
      padding: EdgeInsets.all(8),
      child: Selector<ConfigRepository, String>(
        selector: (_, repo) => repo.getSetting(category, 'theme'),
        builder: (ctx, theme, _) {
          return ListTile(
            contentPadding: .all(8),
            title: Text('Theme'),
            subtitle: DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: theme,
              onChanged: (value) {
                context.read<ConfigRepository>().setSetting(category: category, key: 'theme', value: value!);
              },
              items: [
                DropdownMenuItem<String>(value: 'system', child: Text('System')),
                DropdownMenuItem<String>(value: 'light', child: Text('Light')),
                DropdownMenuItem<String>(value: 'dark', child: Text('Dark')),
              ],
            ),
          );
        },
      ),
    );
  }

  Padding _colorScheme() {
    return Padding(
      padding: EdgeInsets.all(8),
      child: Selector<ConfigRepository, String>(
        selector: (_, repo) => repo.getSetting(category, 'color'),
        builder: (ctx, dbColor, _) {
          final colorScheme = Theme.of(ctx).colorScheme.primaryContainer;
          return ListTile(
            title: Text('Colour scheme'),
            subtitle: ColorPicker(
              pickerColor: colorScheme,
              onColorChanged: (color) => {
                context.read<ConfigRepository>().setSetting(
                  category: category,
                  key: 'color',
                  value: color.toARGB32().toString(),
                ),
              },
              labelTypes: [],
              enableAlpha: false,
              paletteType: PaletteType.hsv,
              pickerAreaHeightPercent: 0.0,
              pickerAreaBorderRadius: BorderRadius.all(Radius.zero),
            ),
          );
        },
      ),
    );
  }

  Padding _enableHaptics() {
    const key = 'haptics';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Selector<ConfigRepository, bool>(
        selector: (_, repo) => repo.isEnabled(category, key),
        builder: (context, isEnabled, _) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Padding(padding: EdgeInsets.only(left: 8), child: Text('Enable haptic feedback')),
              Switch(
                value: isEnabled,
                onChanged: (value) {
                  context.read<ConfigRepository>().setSetting(category: category, key: key, value: value ? '1' : '0');
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

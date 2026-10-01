import 'package:flutter/material.dart';
import 'package:fossfit/app/shell/app_shell.dart';
import 'package:fossfit/app/utils/constants.dart';
import 'package:fossfit/app/utils/utils.dart';
import 'package:fossfit/app/widgets/colour_picker.dart';
import 'package:fossfit/db/repositories/config_reposity.dart';
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
    var sysColours = context.watch<ConfigRepository>().isEnabled(category, 'system_colours');
    return AppShell(
      title: category.name.toTitleCase,
      showSearch: false,
      showNavBar: false,
      body: ListView(
        children: [
          SizedBox(height: 16),
          Padding(
            padding: EdgeInsets.only(left: 16, top: 8),
            child: Text('Look', style: Theme.of(context).textTheme.labelMedium),
          ),
          SizedBox(height: 8),
          _themeItem(),
          _useSystemColours(),
          if (!sysColours) _colorScheme(),
          SizedBox(height: 8),
          Divider(),
          Padding(
            padding: EdgeInsets.only(left: 16, top: 8),
            child: Text('Feel', style: Theme.of(context).textTheme.labelMedium),
          ),
          SizedBox(height: 8),
          _enableHaptics(),
        ],
      ),
    );
  }

  Padding _themeItem() {
    return Padding(
      padding: EdgeInsets.all(4),
      child: Selector<ConfigRepository, String>(
        selector: (_, repo) => repo.getSetting(category, 'theme'),
        builder: (ctx, theme, _) {
          return ListTile(
            leading: Transform.scale(
              scale: iconScale,
              child: Icon(Icons.contrast_rounded, color: Theme.of(context).colorScheme.primary),
            ),
            title: Text('Theme'),
            subtitle: DropdownButton<String>(
              value: theme,
              isExpanded: true,
              isDense: true,
              underline: const SizedBox.shrink(),
              padding: EdgeInsets.zero,
              onChanged: (value) {
                context.read<ConfigRepository>().setSetting(category: category, key: 'theme', value: value!);
              },
              items: const [
                DropdownMenuItem(value: 'system', child: Text('System')),
                DropdownMenuItem(value: 'light', child: Text('Light')),
                DropdownMenuItem(value: 'dark', child: Text('Dark')),
              ],
            ),
          );
        },
      ),
    );
  }

  Padding _colorScheme() {
    return Padding(
      padding: EdgeInsets.all(4),
      child: Selector<ConfigRepository, String>(
        selector: (_, repo) => repo.getSetting(category, 'color'),
        builder: (ctx, dbColor, _) {
          final colorScheme = Theme.of(ctx).colorScheme.primary;
          return Column(
            children: [
              ListTile(
                leading: Transform.scale(
                  scale: iconScale,
                  child: Icon(Icons.color_lens_rounded, color: Theme.of(context).colorScheme.primary),
                ),
                title: Text('Colour scheme'),
              ),
              Padding(
                padding: .symmetric(horizontal: 16),
                child: ColorBarPicker(
                  primaryColor: colorScheme,
                  initialColor: dbColor,
                  onChanged: (color) {
                    context.read<ConfigRepository>().setSetting(
                      category: category,
                      key: 'color',
                      value: color.toARGB32().toString(),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Padding _useSystemColours() {
    const key = 'system_colours';
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Selector<ConfigRepository, bool>(
        selector: (_, repo) => repo.isEnabled(category, key),
        builder: (context, isEnabled, _) {
          return ListTile(
            leading: Transform.scale(
              scale: iconScale,
              child: Icon(Icons.settings_system_daydream, color: Theme.of(context).colorScheme.primary),
            ),
            title: const Padding(padding: EdgeInsets.only(left: 8), child: Text('Use system colours')),
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

  Padding _enableHaptics() {
    const key = 'haptics';

    return Padding(
      padding: const EdgeInsets.all(4),
      child: Selector<ConfigRepository, bool>(
        selector: (_, repo) => repo.isEnabled(category, key),
        builder: (context, isEnabled, _) {
          return ListTile(
            leading: Transform.scale(
              scale: iconScale,
              child: Icon(Icons.vibration_rounded, color: Theme.of(context).colorScheme.primary),
            ),
            title: const Padding(padding: EdgeInsets.only(left: 8), child: Text('Enable haptic feedback')),
            trailing: Transform.scale(
              scale: switchScale,
              child: Switch.adaptive(
                value: isEnabled,
                onChanged: (value) {
                  context.read<ConfigRepository>().setSetting(category: category, key: key, value: value ? '1' : '0');
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

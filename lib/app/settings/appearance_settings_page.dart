import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:fossfit/app/features/exercises/exercise/graph/flex_line.dart';
import 'package:fossfit/app/shell/app_shell.dart';
import 'package:fossfit/app/utils/constants.dart';
import 'package:fossfit/app/utils/utils.dart';
import 'package:fossfit/app/widgets/colour_picker.dart';
import 'package:fossfit/db/models/features/strength_model.dart';
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
    return Selector<ConfigRepository, (bool, bool)>(
      selector: (_, repo) => (repo.isEnabled(category, 'system_colours'), repo.isEnabled(category, 'curve_lines')),
      builder: (_, values, _) {
        final (sysColours, curves) = values;
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
              _curveLines(),
              if (curves) ...[_curveLineSmoothness(), _curveGraphExample()],
            ],
          ),
        );
      },
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
                    context.read<ConfigRepository>().setSetting(category: category, key: 'color', value: color.toARGB32().toString());
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
            onTap: () {
              context.read<ConfigRepository>().setSetting(category: category, key: key, value: !isEnabled == true ? '1' : '0');
            },
          );
        },
      ),
    );
  }

  Padding _curveLines() {
    const key = 'curve_lines';

    return Padding(
      padding: const EdgeInsets.all(4),
      child: Selector<ConfigRepository, bool>(
        selector: (_, repo) => repo.isEnabled(category, key),
        builder: (context, isEnabled, _) {
          return ListTile(
            leading: Transform.scale(
              scale: iconScale,
              child: Icon(Icons.stacked_line_chart_rounded, color: Theme.of(context).colorScheme.primary),
            ),
            title: const Padding(padding: EdgeInsets.only(left: 8), child: Text('Enable curved lines on graph')),
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
              context.read<ConfigRepository>().setSetting(category: category, key: key, value: !isEnabled == true ? '1' : '0');
            },
          );
        },
      ),
    );
  }

  Padding _curveLineSmoothness() {
    const key = 'curve_smoothness';

    return Padding(
      padding: const EdgeInsets.all(4),
      child: Selector<ConfigRepository, double>(
        selector: (_, repo) => repo.getDouble(category, key),
        builder: (context, smoothness, _) {
          return ListTile(
            leading: Transform.scale(
              scale: iconScale,
              child: Icon(Icons.line_axis_rounded, color: Theme.of(context).colorScheme.primary),
            ),
            title: const Padding(padding: EdgeInsets.only(left: 8), child: Text('Curved line smoothness')),
            subtitle: Slider(
              value: smoothness,
              inactiveColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.24),
              onChanged: (value) {
                context.read<ConfigRepository>().setSetting(category: category, key: key, value: value.toString());
              },
            ),
          );
        },
      ),
    );
  }

  Padding _curveGraphExample() {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.2,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: FlexLine(
            hideBottom: true,
            hideLeft: true,
            spots: const [FlSpot(0, 0.13), FlSpot(1, 5), FlSpot(2, 2)],
            tooltipData: () => LineTouchTooltipData(
              getTooltipColor: (touchedSpot) => Theme.of(context).colorScheme.surface,
              getTooltipItems: (touchedSpots) => touchedSpots
                  .map((spot) => LineTooltipItem(spot.y.toStringAsFixed(2), TextStyle(color: Theme.of(context).textTheme.bodyLarge!.color)))
                  .toList(),
            ),
            data: [
              StrengthData(created: DateTime.parse('2024-05-19 14:54:17.000'), value: 0.13, unit: 'kg', reps: 0),
              StrengthData(created: DateTime.parse('2024-05-19 14:54:17.000'), value: 0.13, unit: 'kg', reps: 0),
              StrengthData(created: DateTime.parse('2024-05-19 14:54:17.000'), value: 0.13, unit: 'kg', reps: 0),
            ],
          ),
        ),
      ),
    );
  }
}

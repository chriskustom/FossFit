import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/material.dart';
import 'package:fossfit/db/repositories/settings_repository.dart';
import 'package:fossfit/graph/cardio_data.dart';
import 'package:fossfit/graph/flex_line.dart';
import 'package:fossfit/models/constants.dart';
import 'package:fossfit/widgets/setting_switch.dart';
import 'package:provider/provider.dart';

void enableDisable(SettingsRepository settings, String k, bool v) => setSetting(settings, k, v ? '1' : '0');

void setSetting(SettingsRepository settings, String k, String v) => settings.setSetting(
      category: SettingCategory.appearance,
      key: k,
      value: v,
    );

List<Widget> getAppearanceSettings(
  BuildContext context,
  String term,
  SettingsRepository settings,
) {
  return [
    if ('theme'.contains(term.toLowerCase()))
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: DropdownButtonFormField<ThemeMode>(
          initialValue: ThemeMode.values.byName(
            settings.getSetting(key: 'theme_mode'),
          ),
          decoration: const InputDecoration(
            labelStyle: TextStyle(),
            labelText: 'Theme',
          ),
          items: const [
            DropdownMenuItem(
              value: ThemeMode.system,
              child: Text("System"),
            ),
            DropdownMenuItem(
              value: ThemeMode.dark,
              child: Text("Dark"),
            ),
            DropdownMenuItem(
              value: ThemeMode.light,
              child: Text("Light"),
            ),
          ],
          onChanged: (value) => setSetting(settings, 'theme_mode', value?.name ?? 'system'),
        ),
      ),
    if ('system color scheme'.contains(term.toLowerCase()))
      SettingSwitch(
        settings: settings,
        category: SettingCategory.appearance,
        keyName: 'system_colors',
        title: 'System color scheme',
        tooltip: 'Use the primary color of your device for the app',
        enabledIcon: Icons.color_lens,
        disabledIcon: Icons.color_lens_outlined,
      ),
    if ('show images'.contains(term.toLowerCase()))
      SettingSwitch(
        settings: settings,
        category: SettingCategory.appearance,
        keyName: 'show_images',
        title: 'Show images',
        tooltip: 'Pick/display images on the history page',
        enabledIcon: Icons.image,
        disabledIcon: Icons.image_outlined,
      ),
    if ('show global progress'.contains(term.toLowerCase()))
      SettingSwitch(
        settings: settings,
        category: SettingCategory.appearance,
        keyName: 'show_global_progress',
        title: 'Show global progress',
        tooltip: 'Add a graph entry charting your progress by category',
        enabledIcon: Icons.public,
        disabledIcon: Icons.public_off,
      ),
    if ('show stats panel'.contains(term.toLowerCase()))
      SettingSwitch(
        settings: settings,
        category: SettingCategory.appearance,
        keyName: 'stats_panel',
        title: 'Show stats panel',
        tooltip: 'Show stats panel above workout history',
        enabledIcon: Icons.analytics,
        disabledIcon: Icons.analytics_outlined,
      ),
    if ('peek graph'.contains(term.toLowerCase()))
      SettingSwitch(
        settings: settings,
        category: SettingCategory.appearance,
        keyName: 'peek_graph',
        title: 'Peek graph',
        tooltip: 'Show the first line graph on graphs page',
        enabledIcon: Icons.visibility,
        disabledIcon: Icons.visibility_outlined,
      ),
    if ('curve line graphs'.contains(term.toLowerCase()))
      SettingSwitch(
        settings: settings,
        category: SettingCategory.appearance,
        keyName: 'curve_lines',
        title: 'Curve line graphs',
        tooltip: 'Use wavy curves in the graphs page',
        enabledIcon: Icons.insights,
        disabledIcon: Icons.insights_outlined,
      ),
    if ('curve smoothness'.contains(term.toLowerCase()))
      material.Column(
        children: [
          material.Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              "Curve smoothness",
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          Slider(
            value: settings.getDouble(key: 'curve_smoothness'),
            inactiveColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.24),
            onChanged: (value) => setSetting(
              settings,
              'curve_smoothness',
              value.toString(),
            ),
          ),
        ],
      ),
    if ('graph'.contains(term.toLowerCase()))
      SizedBox(
        height: MediaQuery.of(context).size.height * 0.3,
        child: Padding(
          padding: const EdgeInsets.all(64),
          child: FlexLine(
            hideBottom: true,
            hideLeft: true,
            spots: const [
              FlSpot(0, 0.13),
              FlSpot(1, 5),
              FlSpot(2, 2),
            ],
            tooltipData: () => LineTouchTooltipData(
              getTooltipColor: (touchedSpot) => Theme.of(context).colorScheme.surface,
              getTooltipItems: (touchedSpots) => touchedSpots
                  .map(
                    (spot) => LineTooltipItem(
                      spot.y.toStringAsFixed(2),
                      TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge!.color,
                      ),
                    ),
                  )
                  .toList(),
            ),
            data: [
              CardioData(
                created: DateTime.parse('2024-05-19 14:54:17.000'),
                value: 0.13,
                unit: 'km',
              ),
              CardioData(
                created: DateTime.parse('2024-05-19 14:54:17.000'),
                value: 0.13,
                unit: 'km',
              ),
              CardioData(
                created: DateTime.parse('2024-05-19 14:54:17.000'),
                value: 0.13,
                unit: 'km',
              ),
            ],
          ),
        ),
      ),
  ];
}

class AppearanceSettings extends StatelessWidget {
  const AppearanceSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsRepository>();

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text("Appearance"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView(
          children: getAppearanceSettings(context, '', settings),
        ),
      ),
    );
  }
}

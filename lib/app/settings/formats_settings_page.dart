import 'package:fossfit/db/repositories/config_reposity.dart';
import 'package:fossfit/app/utils/utils.dart';
import 'package:fossfit/app/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fossfit/app/shell/app_shell.dart';

class FormatsSettingsPage extends StatefulWidget {
  const FormatsSettingsPage({super.key});

  @override
  State<FormatsSettingsPage> createState() => _FormatsSettingsPageState();
}

class _FormatsSettingsPageState extends State<FormatsSettingsPage> {
  final ConfigCategory category = .formats;
  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: category.name.toTitleCase,
      showSearch: false,
      showNavBar: false,
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [dateFormat(context), startOfWeek(context), getFont(context), fontSize(context)],
      ),
    );
  }

  Padding startOfWeek(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(8),
      child: Selector<ConfigRepository, String>(
        selector: (_, repo) => repo.getSetting(category, 'start_of_week'),
        builder: (context, fontSize, _) {
          return ListTile(
            title: Text('First day of the week'),
            subtitle: DropdownButton<String>(
              isExpanded: true,
              items: [
                DropdownMenuItem(value: 'monday', child: Text('Monday')),
                DropdownMenuItem(value: 'sunday', child: Text('Sunday')),
              ].toList(),
              value: fontSize,
              onChanged: (value) {
                if (value == null) return;
                context.read<ConfigRepository>().setSetting(category: category, key: 'start_of_week', value: value);
              },
            ),
          );
        },
      ),
    );
  }

  Padding fontSize(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(8),
      child: Selector<ConfigRepository, String>(
        selector: (_, repo) => repo.getSetting(category, 'font_size'),
        builder: (context, fontSize, _) {
          return ListTile(
            title: Text('Font size'),
            subtitle: DropdownButton<String>(
              isExpanded: true,
              items: fontSizes(),
              value: fontSize,
              onChanged: (value) {
                if (value == null) return;
                context.read<ConfigRepository>().setSetting(category: category, key: 'font_size', value: value);
              },
            ),
          );
        },
      ),
    );
  }

  List<DropdownMenuItem<String>> fontSizes() {
    return List.generate(10, (index) {
      final size = 8 + index * 2;
      return DropdownMenuItem(value: size.toString(), child: Text(size.toString()));
    });
  }

  Padding getFont(BuildContext context) {
    final repo = context.watch<ConfigRepository>();
    final font = repo.getSetting(category, 'font');

    return Padding(
      padding: const EdgeInsets.all(8),
      child: ListTile(
        title: const Text('Global font'),
        subtitle: DropdownButton<String>(
          isExpanded: true,
          value: fonts.contains(font) ? font : fonts.first,
          items: fonts
              .map(
                (f) => DropdownMenuItem(
                  value: f,
                  child: Text(f, style: TextStyle(fontFamily: f)),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value == null) return;
            repo.setSetting(category: category, key: 'font', value: value);
          },
        ),
      ),
    );
  }

  Padding dateFormat(BuildContext ctx) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Selector<ConfigRepository, String>(
        selector: (_, repo) => repo.getSetting(category, 'date_format'),
        builder: (context, savedFormat, _) {
          final safeFormat = dateFormats.contains(savedFormat) ? savedFormat : null;
          return ListTile(
            title: const Text('Date format'),
            subtitle: DropdownButton<String>(
              isExpanded: true,
              items: buildDateFormatEntries(),
              value: safeFormat,
              onChanged: (value) {
                if (value == null) return;
                context.read<ConfigRepository>().setSetting(category: category, key: 'date_format', value: value);
              },
            ),
          );
        },
      ),
    );
  }

  List<DropdownMenuItem<String>> buildDateFormatEntries() {
    final now = DateTime.now();

    return dateFormats.map((format) {
      return DropdownMenuItem<String>(value: format, child: Text('$format — ${DateFormat(format).format(now)}'));
    }).toList();
  }
}

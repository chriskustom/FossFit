import 'package:flutter/material.dart';
import 'package:fossfit/app/shell/app_shell.dart';
import 'package:fossfit/app/utils/constants.dart';
import 'package:fossfit/app/utils/utils.dart';
import 'package:fossfit/db/repositories/config_reposity.dart';
import 'package:provider/provider.dart';

class TabsSettingsPage extends StatefulWidget {
  const TabsSettingsPage({super.key});

  @override
  State<TabsSettingsPage> createState() => _TabsSettingsPageState();
}

class _TabsSettingsPageState extends State<TabsSettingsPage> {
  final ConfigCategory category = .tabs;
  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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
            child: Text('Navigation', style: Theme.of(context).textTheme.labelMedium),
          ),
          SizedBox(height: 8),
          _minimalDock(),
          SizedBox(height: 8),
          Divider(),
          Padding(
            padding: EdgeInsets.only(left: 16, top: 8),
            child: Text('Tabs', style: Theme.of(context).textTheme.labelMedium),
          ),
          SizedBox(height: 8),
          _tabs(),
        ],
      ),
    );
  }

  Padding _minimalDock() {
    const key = 'minimal_dock';

    return Padding(
      padding: const EdgeInsets.all(4),
      child: Selector<ConfigRepository, bool>(
        selector: (_, repo) => repo.isEnabled(category, key),
        builder: (context, isEnabled, _) {
          return ListTile(
            leading: Transform.scale(
              scale: iconScale,
              child: Icon(Icons.vertical_align_bottom_rounded, color: isEnabled ? Theme.of(context).colorScheme.primary : null),
            ),
            title: const Padding(padding: EdgeInsets.only(left: 8), child: Text('Enable minimal navigation bar/dock')),
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

  Padding _tabs() {
    return Padding(
      padding: EdgeInsets.all(8),
      child: Selector<ConfigRepository, String>(
        selector: (_, repo) => repo.getSetting(category, 'tabs'),
        builder: (ctx, tabString, _) {
          final tabs = tabString.split(',');
          return ReorderableListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: tabs.length,
            itemBuilder: (_, index) {
              final tab = tabs[index];
              return ListTile(
                key: ValueKey(tab),
                leading: Transform.scale(
                  scale: iconScale,
                  child: Icon(NavRoute.values.byName(tab.toLowerCase()).icon, color: Theme.of(context).colorScheme.primary),
                ),
                title: Padding(padding: const EdgeInsets.only(left: 8), child: Text(tab.toTitleCase)),
                trailing: ReorderableDragStartListener(index: index, child: const Icon(Icons.drag_handle)),
              );
            },
            onReorderItem: (oldIndex, newIndex) {
              final reordered = List.from(tabs);
              final moved = reordered.removeAt(oldIndex);
              reordered.insert(newIndex, moved);
              context.read<ConfigRepository>().setSetting(category: category, key: 'tabs', value: reordered.join(','));
            },
          );
        },
      ),
    );
  }
}

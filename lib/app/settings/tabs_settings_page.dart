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
    return AppShell(title: category.name.toTitleCase, showSearch: false, showNavBar: false, body: __pageOrder());
  }

  Padding __pageOrder() {
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

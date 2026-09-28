import 'package:fossfit/app/shell/app_shell.dart';
import 'package:fossfit/app/utils/utils.dart';
import 'package:fossfit/db/repositories/config_reposity.dart';

import 'package:fossfit/app/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TabsSettingsPage extends StatefulWidget {
  const TabsSettingsPage({super.key});

  @override
  State<TabsSettingsPage> createState() => _TabsSettingsPageState();
}

class _TabsSettingsPageState extends State<TabsSettingsPage> {
  final ConfigCategory category = .tabs;
  List<String> pages = [];
  late ConfigRepository config;
  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    pages = context.watch<ConfigRepository>().getSetting(category, 'tabs').split(',');
  }

  @override
  Widget build(BuildContext context) {
    config = context.watch<ConfigRepository>();
    return AppShell(
      title: category.name.toTitleCase,
      showSearch: false,
      showNavBar: false,
      body: ListView(padding: const EdgeInsets.symmetric(vertical: 16), children: [__pageOrder()]),
    );
  }

  Padding __pageOrder() {
    return Padding(
      padding: EdgeInsets.all(8),
      child: Selector<ConfigRepository, String>(
        selector: (_, repo) => repo.getSetting(category, 'tabs'),
        builder: (ctx, pageOrder, _) {
          return Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(padding: EdgeInsets.only(left: 8), child: Text('Page')),
                  Padding(padding: EdgeInsets.only(left: 8), child: Text('Enabled')),
                ],
              ),
              Divider(),
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                itemCount: pages.length,
                itemBuilder: (_, index) {
                  final page = pages[index];
                  final pageName = page.split('|').first;
                  final enabled = page.split('|').last == '1';
                  return Row(
                    key: ValueKey(pageName),
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,

                    children: [
                      ReorderableDragStartListener(index: index, child: Icon(Icons.drag_handle)),
                      Padding(padding: EdgeInsets.only(left: 8), child: Text(pageName.toTitleCase)),
                      Switch(
                        value: enabled,
                        onChanged: (value) {
                          pages[index] = '$pageName|${value == true ? 1 : 0}';
                          context.read<ConfigRepository>().setSetting(
                            category: category,
                            key: 'tabs',
                            value: pages.join(','),
                          );
                        },
                      ),
                    ],
                  );
                },
                onReorder: (oldIndex, newIndex) {
                  if (oldIndex >= pages.length || newIndex > pages.length) {
                    return;
                  }
                  setState(() {
                    if (oldIndex < newIndex) newIndex -= 1;
                    final item = pages.removeAt(oldIndex);
                    pages.insert(newIndex, item);
                  });
                  context.read<ConfigRepository>().setSetting(category: category, key: 'tabs', value: pages.join(','));
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

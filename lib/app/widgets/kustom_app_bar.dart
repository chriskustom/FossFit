import 'package:flutter/material.dart';
import 'package:fossfit/app/services/app_services.dart';
import 'package:fossfit/app/settings/settings_page.dart';
import 'package:fossfit/app/theme/theme.dart';
import 'package:fossfit/app/utils/constants.dart';
import 'package:fossfit/app/utils/fade_route.dart';
import 'package:fossfit/app/widgets/about_dialog.dart';
import 'package:fossfit/app/widgets/menus/triple_dot_menu.dart';
import 'package:fossfit/db/repositories/config_reposity.dart';
import 'package:provider/provider.dart';

class KustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final List<Object>? actions;
  final Widget? sorting;
  final List<IconButton>? selectActions;
  final bool showSearch;

  const KustomAppBar({super.key, required this.title, this.actions, this.sorting, this.selectActions, this.showSearch = true});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  State<KustomAppBar> createState() => _KustomAppBarState();
}

class _KustomAppBarState extends State<KustomAppBar> with SingleTickerProviderStateMixin {
  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
  }

  Widget _getLeading(String home) {
    var homeRoute = NavRoute.values.byName(home.toLowerCase());
    var route = ModalRoute.of(context)?.settings.name == '/' ? homeRoute.route : ModalRoute.of(context)?.settings.name;
    return !NavRoute.allRoutes.contains(route)
        ? IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: AppHaptics.selectWithHaptics(context, () {
              Navigator.maybePop(context);
            }),
          )
        : Icon(NavRoute.fromRoute(ModalRoute.of(context)?.settings.name, homeRoute).icon);
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      leading: Selector<ConfigRepository, String>(
        selector: (p0, p1) => p1.getSetting(.tabs, 'tabs'),
        builder: (context, value, child) => _getLeading(value.split(',').first),
      ),
      title: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        switchInCurve: Curves.easeInOut,
        switchOutCurve: Curves.easeInOut,
        child: Text(widget.title, key: const ValueKey("title"), style: Theme.of(context).textTheme.labelLarge, textScaler: TextScaler.linear(1.1)),
      ),
      actions: _buildMenu(context),
      flexibleSpace: Container(decoration: BoxDecoration(gradient: context.linearGradientLR)),
    );
  }

  List<Widget> _buildMenu(BuildContext context) {
    final items = widget.actions ?? [];
    final menuItems = <MenuItem>[];
    final others = [];

    for (final item in items) {
      if (item is MenuItem) {
        menuItems.add(item);
      } else {
        others.add(item);
      }
    }

    return [
      if (widget.selectActions != null) ...widget.selectActions!,
      if (widget.sorting != null && (widget.selectActions == null || widget.selectActions!.isEmpty)) widget.sorting!,
      if (others.isNotEmpty) ...others,
      TripleDotMenu(
        options: [
          ...menuItems,
          if (widget.title != 'Settings')
            MenuItem(
              title: "Settings",
              icon: const Icon(Icons.settings),
              onTap: () => Navigator.push(context, FadeRoute<ConfigCategory>(page: const SettingsPage())),
            ),
          MenuItem(title: "About", icon: const Icon(Icons.info_outline), onTap: () => AboutAppDialog.showAbout(this)),
        ],
      ),
    ];
  }

  @override
  void dispose() {
    _animController.dispose();

    super.dispose();
  }
}

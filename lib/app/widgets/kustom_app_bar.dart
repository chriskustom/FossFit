import 'package:flutter/material.dart';
import 'package:fossfit/app/features/search/global_search_controller.dart';
import 'package:fossfit/app/services/app_services.dart';
import 'package:fossfit/app/settings/settings_page.dart';
import 'package:fossfit/app/utils/constants.dart';
import 'package:fossfit/app/utils/fade_route.dart';
import 'package:fossfit/app/widgets/about_dialog.dart';
import 'package:fossfit/app/widgets/menus/triple_dot_menu.dart';
import 'package:provider/provider.dart';

class KustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final List<Object>? actions;
  final Widget? sorting;
  final List<IconButton>? selectActions;
  final bool showSearch;

  const KustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.sorting,
    this.selectActions,
    this.showSearch = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  State<KustomAppBar> createState() => _KustomAppBarState();
}

class _KustomAppBarState extends State<KustomAppBar> with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  bool _isSearching = false;
  late final AnimationController _animController;
  late GlobalSearchController _globalSearch;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _globalSearch = context.read<GlobalSearchController>();
    _globalSearch.addListener(_onGlobalSearchChanged);
    _searchFocus.addListener(_onSearchFocusChange);
  }

  void _onSearchFocusChange() {
    if (!_searchFocus.hasFocus && _isSearching && _globalSearch.query.isEmpty) {
      _globalSearch.hideOverlay();
      _closeSearch();
    }
  }

  void _onGlobalSearchChanged() {
    final query = _globalSearch.query;

    if (query.isNotEmpty && !_isSearching) {
      _startSearch();
    } else if (query.isEmpty && _isSearching) {
      _closeSearch(); /*  */
    }

    if (_controller.text != query) {
      _controller.text = query;
      _controller.selection = TextSelection.fromPosition(TextPosition(offset: query.length));
    }
  }

  void _startSearch() {
    setState(() => _isSearching = true);
    _searchFocus.requestFocus();
    _animController.forward();
  }

  void _closeSearch() {
    setState(() => _isSearching = false);
    _globalSearch.setQuery('', context);
    _controller.clear();
    _animController.reverse();
  }

  Widget? _getLeading() {
    return _isSearching
        ? null
        : ModalRoute.of(context)?.settings.name != NavRoute.workout.route && Navigator.canPop(context)
        ? IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: AppHaptics.selectWithHaptics(context, () {
              Navigator.maybePop(context);
            }),
          )
        : Icon(Icons.fitness_center_rounded);
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      leading: _getLeading(),
      title: _isSearching
          ? _buildSearchField()
          : AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              switchInCurve: Curves.easeInOut,
              switchOutCurve: Curves.easeInOut,
              child: Text(
                widget.title,
                key: const ValueKey("title"),
                style: Theme.of(context).textTheme.labelLarge,
                textScaler: TextScaler.linear(1.1),
              ),
            ),
      actions: _isSearching ? [] : _buildMenu(context),
      //flexibleSpace: Container(decoration: BoxDecoration(gradient: context.linearGradientLR)),
    );
  }

  Widget _buildSearchField() {
    return Row(
      key: const ValueKey("searchField"),
      children: [
        AnimatedBuilder(
          animation: _animController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(-8 * (1 - _animController.value), 0),
              child: Transform.rotate(angle: 0.2 * _animController.value, child: Icon(Icons.search)),
            );
          },
        ),

        const SizedBox(width: 4),
        Expanded(
          child: FadeTransition(
            opacity: _animController.drive(Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeInOutCubic))),
            child: SizeTransition(
              axis: Axis.horizontal,
              alignment: AlignmentGeometry.xy(-1, 0),
              sizeFactor: _animController.drive(
                Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeInOutCubic)),
              ),
              child: SlideTransition(
                position: _animController.drive(
                  Tween<Offset>(
                    begin: const Offset(0.2, 0),
                    end: Offset.zero,
                  ).chain(CurveTween(curve: Curves.easeInOutCubic)),
                ),
                child: TextField(
                  controller: _controller,
                  focusNode: _searchFocus,
                  textCapitalization: .sentences,
                  autofocus: true,
                  onChanged: (text) {
                    _globalSearch.setQuery(text, context);

                    if (text.isNotEmpty) {
                      _animController.forward();
                    } else {
                      _animController.reverse();
                    }
                  },
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(vertical: 15),
                    hintText: 'Search...',
                    border: InputBorder.none,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: AppHaptics.selectWithHaptics(context, _closeSearch),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
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
      if (widget.showSearch)
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: AppHaptics.selectWithHaptics(context, () {
            _startSearch();
            _searchFocus.requestFocus();
          }),
        ),
      if (widget.selectActions != null) ...widget.selectActions!,
      if (widget.sorting != null && (widget.selectActions == null || widget.selectActions!.isEmpty)) widget.sorting!,
      if (others.isNotEmpty) ...others,
      TripleDotMenu(
        options: [
          ...menuItems,
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
    _searchFocus.removeListener(_onSearchFocusChange);
    _globalSearch.removeListener(_onGlobalSearchChanged);

    _controller.dispose();
    _searchFocus.dispose();
    _animController.dispose();

    super.dispose();
  }
}

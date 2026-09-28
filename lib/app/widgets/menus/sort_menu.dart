import 'package:fossfit/app/utils/constants.dart';
import 'package:fossfit/app/utils/sort_option.dart';
import 'package:fossfit/app/services/app_services.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SortMenu extends StatelessWidget {
  const SortMenu({
    super.key,
    required this.sortOrder,
    required this.sortBy,
    required this.setState,
    required this.category,
    this.options = sortOptions,
  });
  final List<SortOption> options;
  final SortOrder sortOrder;
  final SortBy sortBy;
  final Function(SortBy, SortOrder) setState;
  final ConfigCategory category;
  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<SortOption>(
      icon: const Icon(Icons.sort),
      onOpened: () => AppHaptics.selection(context),
      onSelected: (option) async {
        AppHaptics.selection(context);
        var prefs = await SharedPreferences.getInstance();
        prefs.setString('sort_by', option.sortBy.name);
        prefs.setString('sort_order', option.order.name);

        setState(option.sortBy, option.order);
      },
      itemBuilder: (context) => options.map((option) {
        final isSelected = option.sortBy == sortBy && option.order == sortOrder;
        return PopupMenuItem(
          value: option,
          child: Row(
            children: [
              Icon(option.icon, size: 20),
              const SizedBox(width: 12),
              Expanded(child: Text(option.label)),
              if (isSelected) const Icon(Icons.check, size: 18, color: Colors.blue),
            ],
          ),
        );
      }).toList(),
    );
  }
}

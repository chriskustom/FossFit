import 'package:flutter/material.dart';
import 'package:fossfit/utils/app_haptics.dart';

class MenuItem {
  final String title;
  final Icon icon;
  final VoidCallback onTap;
  final bool selected;

  MenuItem({
    required this.title,
    required this.icon,
    required this.onTap,
    this.selected = false,
  });
}

class TripleDotMenu extends StatelessWidget {
  const TripleDotMenu({super.key, required this.options});
  final List<MenuItem> options;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<MenuItem>(
      icon: const Icon(Icons.more_vert),
      onOpened: () => AppHaptics.tap(context),
      itemBuilder: (context) => options
          .map(
            (option) => PopupMenuItem<MenuItem>(
              onTap: AppHaptics.selectWithHaptics(context, () {
                option.onTap();
              }),
              child: IconTheme(
                data: IconThemeData(color: Theme.of(context).iconTheme.color),
                child: Row(
                  children: [
                    option.icon,
                    const SizedBox(width: 8),
                    Text(option.title),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

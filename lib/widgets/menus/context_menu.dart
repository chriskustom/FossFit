import 'package:flutter/material.dart';
import 'package:fossfit/utils/app_haptics.dart';

class ContextMenu extends StatelessWidget {
  const ContextMenu({
    super.key,
    required this.pinned,
    required this.onPin,
    required this.onEdit,
    required this.onDelete,
    required this.child,
  });

  final bool pinned;
  final VoidCallback onPin;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (details) {
        final overlay =
            Overlay.of(context).context.findRenderObject() as RenderBox;
        showMenu(
          context: context,
          position: RelativeRect.fromRect(
            Rect.fromPoints(details.globalPosition, details.globalPosition),
            Offset.zero & overlay.size,
          ),
          items: [
            PopupMenuItem(
              value: 'pin',
              onTap: AppHaptics.selectWithHaptics(context, onPin),
              child: Text(pinned ? 'Unpin' : 'Pin'),
            ),
            PopupMenuItem(
              value: 'edit',
              onTap: AppHaptics.selectWithHaptics(context, onEdit),
              child: const Text('Edit'),
            ),
            PopupMenuItem(
              value: 'delete',
              onTap: AppHaptics.selectWithHaptics(context, onDelete),
              child: const Text('Delete'),
            ),
          ],
        );
        AppHaptics.success(context);
      },
      child: child,
    );
  }
}

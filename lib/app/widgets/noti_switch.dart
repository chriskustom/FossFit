import 'package:flutter/material.dart';
import 'package:fossfit/app/services/app_services.dart';

class NotiSwitch extends StatelessWidget {
  final bool enabled;
  final void Function(bool) onToggle;
  const NotiSwitch({super.key, required this.enabled, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: 0.7,
      child: Switch.adaptive(
        value: enabled,
        thumbIcon: .resolveWith<Icon>((states) {
          if (states.contains(WidgetState.selected)) {
            return Icon(Icons.notifications, size: 12);
          }
          return Icon(Icons.notifications_off, size: 12);
        }),
        onChanged: (value) {
          AppHaptics.selection(context);
          onToggle(value);
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppHaptics {
  static void _maybe(VoidCallback feedback, BuildContext context) {
    feedback();
  }

  static void tap(BuildContext context) => _maybe(HapticFeedback.lightImpact, context);
  static void success(BuildContext context) => _maybe(HapticFeedback.mediumImpact, context);
  static void heavy(BuildContext context) => _maybe(HapticFeedback.heavyImpact, context);
  static void selection(BuildContext context) => _maybe(HapticFeedback.selectionClick, context);

  static VoidCallback? tapWithHaptics(
    BuildContext context,
    VoidCallback? callback,
  ) =>
      callback == null
          ? null
          : () {
              tap(context);
              callback();
            };

  static VoidCallback? longPressWithHaptics(
    BuildContext context,
    VoidCallback? callback,
  ) =>
      callback == null
          ? null
          : () {
              success(context);
              callback();
            };

  static VoidCallback? toggleWithHaptics(
    BuildContext context,
    VoidCallback? callback,
  ) =>
      callback == null
          ? null
          : () {
              selection(context);
              callback();
            };
  static VoidCallback? selectWithHaptics(
    BuildContext context,
    VoidCallback? callback,
  ) =>
      callback == null
          ? null
          : () {
              selection(context);
              callback();
            };
  static VoidCallback? alertWithHaptics(
    BuildContext context,
    VoidCallback? callback,
  ) =>
      callback == null
          ? null
          : () {
              heavy(context);
              callback();
            };
}

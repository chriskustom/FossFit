import 'package:flutter/material.dart';
import 'package:fossfit/models/constants.dart';
import 'package:fossfit/utils/app_haptics.dart';

Future<bool?> showConfirmationDialog({
  required BuildContext context,
  required String title,
  required String content,
  String confirmLabel = 'Yes',
  String cancelLabel = 'Cancel',
  Color? confirmColor,
  Color? cancelColor,
  ButtonStyle? confirmStyle,
  ButtonStyle? cancelStyle,
  bool barrierDismissible = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (BuildContext ctx) {
      return AlertDialog(
        title: Text(title),
        content: Text(content),
        actionsAlignment: MainAxisAlignment.end,
        actions: [
          TextButton(
            onPressed: AppHaptics.selectWithHaptics(context, () => Navigator.of(ctx).pop(false)),
            style: cancelStyle ?? TextButton.styleFrom(foregroundColor: cancelColor),
            child: Text(cancelLabel),
          ),
          ElevatedButton(
            onPressed: AppHaptics.selectWithHaptics(context, () => Navigator.of(ctx).pop(true)),
            style: confirmStyle ?? ElevatedButton.styleFrom(backgroundColor: confirmColor),
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );

  return result;
}

Future<ThreeDialogOptions?> showThreeOptionDialog({
  required BuildContext context,
  required String title,
  required String content,
  String saveLabel = 'Save',
  String dismissLabel = 'Dismiss',
  String stayLabel = 'Stay',
  Color? confirmColor,
  Color? dismissColor,
  Color? cancelColor,
  ButtonStyle? confirmStyle,
  ButtonStyle? dismissStyle,
  ButtonStyle? cancelStyle,
  bool barrierDismissible = false,
}) async {
  final result = await showDialog<ThreeDialogOptions>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (BuildContext ctx) {
      return AlertDialog(
        title: Text(title),
        content: Text(content),
        actionsAlignment: MainAxisAlignment.end,
        actions: [
          TextButton(
            onPressed: AppHaptics.selectWithHaptics(context, () => Navigator.of(ctx).pop(ThreeDialogOptions.dismiss)),
            style: dismissStyle ?? TextButton.styleFrom(backgroundColor: dismissColor),
            child: Text(dismissLabel),
          ),
          TextButton(
            onPressed: AppHaptics.selectWithHaptics(context, () => Navigator.of(ctx).pop(ThreeDialogOptions.stay)),
            style: cancelStyle ?? TextButton.styleFrom(foregroundColor: cancelColor),
            child: Text(stayLabel),
          ),
          ElevatedButton(
            onPressed: AppHaptics.selectWithHaptics(context, () => Navigator.of(ctx).pop(ThreeDialogOptions.save)),
            style: confirmStyle ?? TextButton.styleFrom(backgroundColor: confirmColor),
            child: Text(saveLabel),
          ),
        ],
      );
    },
  );

  return result;
}

ButtonStyle danger = TextButton.styleFrom(
  foregroundColor: Colors.red,
  textStyle: TextStyle(color: Colors.black),
);
ButtonStyle warning = TextButton.styleFrom(
  foregroundColor: Colors.amber,
  textStyle: TextStyle(color: Colors.black),
);
ButtonStyle normal = TextButton.styleFrom(
  foregroundColor: Colors.blue,
  textStyle: TextStyle(color: Colors.black),
);

Future<bool?> showOkayDialog({
  required BuildContext context,
  required String title,
  required String content,
  String confirmLabel = 'Okay',
  Color? confirmColor,
  ButtonStyle? confirmStyle,
  bool barrierDismissible = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (BuildContext ctx) {
      return AlertDialog(
        title: Text(title),
        content: Text(content),
        actionsAlignment: MainAxisAlignment.end,
        actions: [
          ElevatedButton(
            onPressed: AppHaptics.selectWithHaptics(context, () => Navigator.of(ctx).pop(true)),
            style: confirmStyle ?? ElevatedButton.styleFrom(backgroundColor: confirmColor),
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );

  return result;
}

import 'package:flutter/material.dart';
import 'package:fossfit/models/constants.dart';
import 'package:fossfit/widgets/confirmation_dialog.dart';

Future<ThreeDialogOptions?> saveChangesDialog(BuildContext context) async {
  return await showThreeOptionDialog(
    context: context,
    title: "Unsaved changes",
    content: "You have unsaved items. Save before leaving?",
    saveLabel: "Save",
    confirmStyle: TextButton.styleFrom(
      foregroundColor: Colors.blue,
      textStyle: TextStyle(color: Colors.black),
    ),
    stayLabel: "Stay",
    cancelStyle: TextButton.styleFrom(
      foregroundColor: Colors.amber,
      textStyle: TextStyle(color: Colors.black),
    ),
    dismissLabel: 'Discard',
    dismissStyle: TextButton.styleFrom(
      foregroundColor: Colors.red,
      textStyle: TextStyle(color: Colors.black),
    ),
    barrierDismissible: true,
  );
}

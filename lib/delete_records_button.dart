import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fossfit/db/database_helper.dart';
import 'package:fossfit/widgets/confirmation_dialog.dart';

class DeleteRecordsButton extends StatelessWidget {
  final BuildContext ctx;

  const DeleteRecordsButton({
    super.key,
    required this.ctx,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () {
        showModalBottomSheet(
          useRootNavigator: true,
          context: context,
          builder: (context) {
            return SafeArea(
              child: Wrap(
                children: <Widget>[
                  ListTile(
                    leading: Icon(Icons.warning, color: Colors.redAccent),
                    title: Text('Reset'),
                    subtitle: Text('Delete everything. Requires restart'),
                    onTap: () => _resetApp(),
                  ),
                ],
              ),
            );
          },
        );
      },
      icon: const Icon(Icons.delete),
      label: const Text('Delete records'),
    );
  }

  void _resetApp() async {
    final proceed = await showConfirmationDialog(
      context: ctx,
      title: '⚠️!WARNING!⚠️',
      content:
          'This will delete all content; notes, notebooks, lists and goals.\nAll settings will be reset to default.\n\nDo you wish to continue?',
      confirmStyle: TextButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
      cancelStyle: TextButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
      cancelLabel: 'No, take me home',
      confirmLabel: 'Yes, delete everything',
      barrierDismissible: true,
    );

    if (proceed == null || !proceed || !ctx.mounted) return;

    await DatabaseHelper().resetApp();

    await Future.delayed(const Duration(milliseconds: 2000));

    SystemNavigator.pop(animated: true);
  }
}

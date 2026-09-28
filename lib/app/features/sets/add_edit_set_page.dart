import 'package:flutter/material.dart';
import 'package:fossfit/app/shell/app_shell.dart';

class AddEditSetPage extends StatefulWidget {
  final int? setId;

  const AddEditSetPage({super.key, this.setId});

  @override
  createState() => _AddEditSetPageState();
}

class _AddEditSetPageState extends State<AddEditSetPage> {
  final repsTEC = TextEditingController();
  final weightTEC = TextEditingController();
  final ormTEC = TextEditingController();
  final bodyWeightTEC = TextEditingController();
  final noteTEC = TextEditingController();
  final weightNode = FocusNode();
  final categoryTEC = TextEditingController();
  final exerciseNameTEC = TextEditingController();

  bool isEditMode = false;

  @override
  void initState() {
    super.initState();
    isEditMode = widget.setId != null;
    if (isEditMode) {
      currentSetId.value = widget.setId;
    }
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    throw UnimplementedError();
  }
}

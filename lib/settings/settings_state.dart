import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter/material.dart';

import 'package:fossfit/main.dart';

class SettingsState extends ChangeNotifier {
  late Setting value;
  StreamSubscription? subscription;

  SettingsState(Setting setting) {
    value = setting;
    init();
  }

  @override
  dispose() {
    super.dispose();
    subscription?.cancel();
  }

  Future<void> init() async {
    subscription = (oldDb.settings.select()..limit(1)).watchSingle().listen((event) {
      value = event;
      notifyListeners();
    });
  }
}

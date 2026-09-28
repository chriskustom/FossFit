import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutAppDialog {
  static Future<void> showAbout(State state) async {
    final pi = await PackageInfo.fromPlatform();
    if (!state.mounted) return;

    showAboutDialog(
      context: state.context,
      applicationIcon: Image.asset('assets/images/icon/icon.png', width: 50, height: 70, fit: BoxFit.contain),
      applicationName: pi.appName,
      applicationVersion: pi.version,
      children: const [Text('FossFit.. like CrossFit but better.')],
    );
  }
}

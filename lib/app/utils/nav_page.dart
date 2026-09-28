import 'package:fossfit/app/utils/constants.dart';
import 'package:flutter/material.dart';

class NavPage {
  final NavRoute route;
  final String label;
  final IconData icon;
  final bool enabled;

  const NavPage({required this.route, required this.label, required this.icon, required this.enabled});
}

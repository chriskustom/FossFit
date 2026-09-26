import 'package:flutter/material.dart';
import 'package:fossfit/models/constants.dart';

class NavPage {
  final NavRoute route;
  final String label;
  final IconData icon;
  final bool enabled;
  final List<Object> items;

  const NavPage({
    required this.route,
    required this.label,
    required this.icon,
    required this.enabled,
    required this.items,
  });
}

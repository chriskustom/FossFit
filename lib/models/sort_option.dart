import 'package:flutter/material.dart';
import 'package:fossfit/models/constants.dart';

class SortOption {
  final SortBy sortBy;
  final SortOrder order;
  final String label;
  final IconData icon;

  const SortOption(this.sortBy, this.order, this.label, this.icon);
}

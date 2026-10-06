import 'package:fossfit/app/utils/constants.dart';
import 'package:flutter/material.dart';

class SortOption {
  final SortBy sortBy;
  final SortOrder order;
  final String label;
  final IconData icon;

  const SortOption(this.sortBy, this.order, this.label, this.icon);
}

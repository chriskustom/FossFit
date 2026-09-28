import 'package:flutter/material.dart';
import 'package:fossfit/db/database_helper.dart';

class SearchServices {
  final BuildContext context;
  final DatabaseHelper _dbHelper;

  SearchServices._(this._dbHelper, this.context);

  static Future<SearchServices> create(BuildContext context) async {
    final dbHelper = DatabaseHelper();
    return SearchServices._(dbHelper, context);
  }

  static String sanitizeFtsQuery(String query) {
    final pattern = RegExp(r"""["*+~=<>(){}\[\]^:!-]""");

    String sanitized = query.replaceAll(pattern, ' ');
    sanitized = sanitized.replaceAll(RegExp(r'\s+'), ' ').trim();
    return sanitized;
  }

  static String buildFtsQuery(String userInput) {
    final sanitized = sanitizeFtsQuery(userInput);
    final terms = sanitized.split(' ').where((t) => t.isNotEmpty);
    return terms.map((t) => '$t*').join(' ');
  }

  Future<List> performSearch(String query) async {
    return [];
  }
}

import 'package:flutter/material.dart';
import 'package:fossfit/app/services/features/search/search_services.dart';

class GlobalSearchController extends ChangeNotifier {
  String query = '';
  List<dynamic> results = [];
  bool overlayVisible = false;

  Future<void> setQuery(String q, BuildContext context) async {
    query = q;

    if (query.isEmpty) {
      results = [];
      overlayVisible = false;
    } else {
      final searchService = await SearchServices.create(context);
      results = await searchService.performSearch(query);
      overlayVisible = results.isNotEmpty;
    }

    notifyListeners();
  }

  void hideOverlay() {
    overlayVisible = false;
    query = '';
    notifyListeners();
  }
}

import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:tazkira_app/features/sunan/data/models/sunnah_model.dart';

class SunanService {
  static List<Sunnah>? _cachedSunan;

  static Future<List<Sunnah>> loadSunan() async {
    if (_cachedSunan != null) {
      return _cachedSunan!;
    }

    try {
      final String jsonString =
          await rootBundle.loadString('assets/json/sunan.json');
      final List<dynamic> jsonList = json.decode(jsonString);

      _cachedSunan = jsonList.map((json) => Sunnah.fromJson(json)).toList();
      return _cachedSunan!;
    } catch (e) {
      throw Exception('Failed to load Sunan: $e');
    }
  }

  static List<String> getCategories(List<Sunnah> sunan) {
    final categories = sunan.map((s) => s.category).toSet().toList();
    categories.sort();
    return categories;
  }

  static List<Sunnah> getSunanByCategory(List<Sunnah> sunan, String category) {
    return sunan.where((s) => s.category == category).toList();
  }
}

import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DailyQuoteService {
  static const String _lastQuoteDateKey = 'last_quote_date';
  static const String _currentQuoteIndexKey = 'current_quote_index';

  // Get daily quote
  static Future<Map<String, dynamic>?> getDailyQuote() async {
    try {
      // Load quotes from JSON
      final String jsonString =
          await rootBundle.loadString('assets/json/daily_quotes.json');
      final List<dynamic> quotes = json.decode(jsonString);

      if (quotes.isEmpty) return null;

      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now();
      final todayString = '${today.year}-${today.month}-${today.day}';
      final lastDate = prefs.getString(_lastQuoteDateKey);

      int quoteIndex;

      if (lastDate != todayString) {
        // New day - get new quote
        final lastIndex = prefs.getInt(_currentQuoteIndexKey) ?? -1;
        quoteIndex = (lastIndex + 1) % quotes.length;

        await prefs.setString(_lastQuoteDateKey, todayString);
        await prefs.setInt(_currentQuoteIndexKey, quoteIndex);
      } else {
        // Same day - return same quote
        quoteIndex = prefs.getInt(_currentQuoteIndexKey) ?? 0;
      }

      return quotes[quoteIndex] as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  // Get quote type icon
  static String getQuoteIcon(String type) {
    return type == 'quran' ? '📖' : '☪️';
  }

  // Get quote type name
  static String getQuoteTypeName(String type) {
    return type == 'quran' ? 'آية قرآنية' : 'حديث شريف';
  }
}

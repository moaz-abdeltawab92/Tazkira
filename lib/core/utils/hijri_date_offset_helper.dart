import 'package:shared_preferences/shared_preferences.dart';

class HijriDateOffsetHelper {
  static const String _offsetKey = 'hijri_date_offset';

  static Future<int> getOffset() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_offsetKey) ?? 0;
  }

  static Future<void> setOffset(int offset) async {
    if (offset < -2 || offset > 2) {
      throw ArgumentError('Offset must be between -2 and +2');
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_offsetKey, offset);
  }

  static Future<void> resetOffset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_offsetKey);
  }
}

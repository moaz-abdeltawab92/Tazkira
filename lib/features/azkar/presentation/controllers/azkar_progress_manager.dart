import 'package:shared_preferences/shared_preferences.dart';

class AzkarProgressManager {
  static final AzkarProgressManager _instance =
      AzkarProgressManager._internal();
  static SharedPreferences? _prefs;

  factory AzkarProgressManager() {
    return _instance;
  }

  AzkarProgressManager._internal();

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _checkDailyReset();
  }

  void _checkDailyReset() {
    final now = DateTime.now();
    final String todayKey = "${now.year}-${now.month}-${now.day}";
    final String? lastSavedDate = _prefs?.getString('azkar_last_date');

    if (lastSavedDate != todayKey) {
      final keys = _prefs?.getKeys() ?? {};
      for (String key in keys) {
        if (key.startsWith('azkar_progress_')) {
          _prefs?.remove(key);
        }
      }
      _prefs?.setString('azkar_last_date', todayKey);

      for (String key in keys) {
        if (key.startsWith('azkar_cat_complete_')) {
          _prefs?.remove(key);
        }
      }
    }
  }

  String _getKey(String category, int index) {
    return 'azkar_progress_${category}_$index';
  }

  String _getCategoryKey(String category) {
    return 'azkar_cat_complete_$category';
  }

  int getProgress(String category, int index) {
    return _prefs?.getInt(_getKey(category, index)) ?? 0;
  }

  Future<void> saveProgress(String category, int index, int count) async {
    await _prefs?.setInt(_getKey(category, index), count);
  }

  bool isCategoryComplete(String category) {
    return _prefs?.getBool(_getCategoryKey(category)) ?? false;
  }

  Future<void> setCategoryComplete(String category, bool isComplete) async {
    await _prefs?.setBool(_getCategoryKey(category), isComplete);
  }

  Future<void> resetCategory(String category) async {
    final keys = _prefs?.getKeys() ?? {};
    final prefix = 'azkar_progress_${category}_';
    for (String key in keys) {
      if (key.startsWith(prefix)) {
        await _prefs?.remove(key);
      }
    }
    await _prefs?.remove(_getCategoryKey(category));
  }

  Future<void> clearAllProgress() async {
    final keys = _prefs?.getKeys() ?? {};
    for (String key in keys) {
      if (key.startsWith('azkar_progress_') ||
          key.startsWith('azkar_cat_complete_')) {
        await _prefs?.remove(key);
      }
    }
  }
}

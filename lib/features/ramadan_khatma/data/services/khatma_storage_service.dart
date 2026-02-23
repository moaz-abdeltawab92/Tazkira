import 'package:shared_preferences/shared_preferences.dart';
import 'package:tazkira_app/features/ramadan_khatma/data/models/khatma_progress_model.dart';

class KhatmaStorageService {
  static const String _khatmaProgressKey = 'ramadan_khatma_progress';
  static const String _khatmaSelectedKey = 'ramadan_khatma_selected';

  // Save khatma progress with comprehensive error handling
  static Future<bool> saveKhatmaProgress(KhatmaProgressModel progress) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = progress.toJsonString();
      return await prefs.setString(_khatmaProgressKey, jsonString);
    } catch (e) {
      // Log error but don't crash
      print('Error saving khatma progress: $e');
      return false;
    }
  }

  // Load khatma progress with fallback for corrupted data
  static Future<KhatmaProgressModel?> loadKhatmaProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_khatmaProgressKey);

      if (jsonString == null || jsonString.isEmpty) {
        return null;
      }

      return KhatmaProgressModel.fromJsonString(jsonString);
    } catch (e) {
      // If data is corrupted, clear it and return null
      print('Error loading khatma progress: $e');
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_khatmaProgressKey);
      } catch (_) {}
      return null;
    }
  }

  // Check if khatma is selected
  static Future<bool> isKhatmaSelected() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_khatmaSelectedKey) ?? false;
    } catch (e) {
      print('Error checking khatma selection: $e');
      return false;
    }
  }

  // Mark khatma as selected
  static Future<bool> markKhatmaSelected() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setBool(_khatmaSelectedKey, true);
    } catch (e) {
      print('Error marking khatma selected: $e');
      return false;
    }
  }

  // Create new khatma with validation
  static Future<KhatmaProgressModel?> createNewKhatma(int khatmaCount) async {
    try {
      // Validate input
      if (khatmaCount != 1 && khatmaCount != 2) {
        print('Invalid khatma count: $khatmaCount');
        return null;
      }

      // Create completed juzs map based on khatma count
      // If khatmaCount = 1: juzs 1-30
      // If khatmaCount = 2: juzs 1-60 (first 30 for first khatma, 31-60 for second)
      final totalJuzs = 30 * khatmaCount;
      final progress = KhatmaProgressModel(
        khatmaCount: khatmaCount,
        completedJuzs: {
          for (var item in List.generate(totalJuzs, (index) => index + 1))
            item: false
        },
        startDate: DateTime.now(),
      );

      final saved = await saveKhatmaProgress(progress);
      if (saved) {
        await markKhatmaSelected();
        return progress;
      }

      return null;
    } catch (e) {
      print('Error creating new khatma: $e');
      return null;
    }
  }

  // Toggle juz completion with validation
  static Future<KhatmaProgressModel?> toggleJuzCompletion(
    KhatmaProgressModel currentProgress,
    int juzNumber,
  ) async {
    try {
      // Validate juz number based on khatma count
      final maxJuzNumber = currentProgress.khatmaCount * 30;
      if (juzNumber < 1 || juzNumber > maxJuzNumber) {
        print('Invalid juz number: $juzNumber');
        return null;
      }

      final updatedCompletedJuzs =
          Map<int, bool>.from(currentProgress.completedJuzs);
      updatedCompletedJuzs[juzNumber] =
          !(updatedCompletedJuzs[juzNumber] ?? false);

      final updatedProgress = currentProgress.copyWith(
        completedJuzs: updatedCompletedJuzs,
        lastUpdated: DateTime.now(),
      );

      final success = await saveKhatmaProgress(updatedProgress);
      return success ? updatedProgress : null;
    } catch (e) {
      print('Error toggling juz completion: $e');
      return null;
    }
  }

  // Clear khatma data
  static Future<bool> clearKhatmaData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_khatmaProgressKey);
      await prefs.remove(_khatmaSelectedKey);
      return true;
    } catch (e) {
      print('Error clearing khatma data: $e');
      return false;
    }
  }

  // Reset for new Ramadan
  static Future<void> resetForNewRamadan() async {
    try {
      await clearKhatmaData();
    } catch (e) {
      print('Error resetting for new Ramadan: $e');
    }
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:tazkira_app/core/utils/islamic_season_helper.dart';

class SeasonalGreetingService {
  static const String _keyRamadanCount = 'ramadan_greeting_count';
  static const String _keyRamadanDuaCount = 'ramadan_dua_count';
  static const String _keyRamadanYear = 'ramadan_greeting_year';
  static const String _keyEidDate = 'eid_greeting_date';

  /// Check and show seasonal greeting if appropriate
  static Future<void> checkAndShowGreeting(BuildContext context) async {
    if (!context.mounted) return;

    final season = await IslamicSeasonHelper.getCurrentSeason();
    if (season == null) return;

    if (season == 'ramadan') {
      await _showRamadanGreeting(context);
    } else if (season == 'eid') {
      await _showEidGreeting(context);
    }
  }

  static Future<void> _showRamadanGreeting(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final hijriDate = await IslamicSeasonHelper.getAdjustedHijriDate();
    final currentYear = hijriDate.hYear;
    final dayOfRamadan = hijriDate.hDay;

    // Get stored year and counts
    final storedYear = prefs.getInt(_keyRamadanYear) ?? 0;
    final greetingCount = prefs.getInt(_keyRamadanCount) ?? 0;
    final duaCount = prefs.getInt(_keyRamadanDuaCount) ?? 0;

    // Reset counts if it's a new Ramadan year
    if (storedYear != currentYear) {
      await prefs.setInt(_keyRamadanYear, currentYear);
      await prefs.setInt(_keyRamadanCount, 0);
      await prefs.setInt(_keyRamadanDuaCount, 0);
    }

    final greetingDays = [10, 18, 20];
    if (greetingCount < greetingDays.length) {
      final nextGreetingDay = greetingDays[greetingCount];
      if (dayOfRamadan >= nextGreetingDay) {
        _showGreeting(context, 'رمضانكم مبارك');
        await prefs.setInt(_keyRamadanCount, greetingCount + 1);
        return;
      }
    }

    // Show Ramadan dua 5 times on specific days
    final duaDays = [12, 15, 22, 25, 28];
    if (duaCount < duaDays.length) {
      final nextDuaDay = duaDays[duaCount];
      if (dayOfRamadan >= nextDuaDay) {
        _showGreeting(
            context, 'اللهم اجعلنا من عتقائك من النار في هذا الشهر الكريم');
        await prefs.setInt(_keyRamadanDuaCount, duaCount + 1);
      }
    }
  }

  static Future<void> _showEidGreeting(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final hijriDate = await IslamicSeasonHelper.getAdjustedHijriDate();

    final dateKey = '${hijriDate.hYear}-${hijriDate.hMonth}-${hijriDate.hDay}';
    final storedDate = prefs.getString(_keyEidDate) ?? '';

    // Only show on the first day of Eid and only once
    if (hijriDate.hDay == 1 && storedDate != dateKey) {
      _showGreeting(context, 'عيد فطر سعيد');
      await prefs.setString(_keyEidDate, dateKey);
    }
  }

  static void _showGreeting(BuildContext context, String message) {
    if (!context.mounted) return;

    showTopSnackBar(
      Overlay.of(context),
      Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF7CB9AD), Color(0xFF5A9A8E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.nightlight_round,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                message,
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      displayDuration: const Duration(seconds: 3),
      animationDuration: const Duration(milliseconds: 600),
    );
  }

  /// Reset all greeting counters (useful for testing)
  static Future<void> resetGreetings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyRamadanCount);
    await prefs.remove(_keyRamadanDuaCount);
    await prefs.remove(_keyRamadanYear);
    await prefs.remove(_keyEidDate);
  }
}

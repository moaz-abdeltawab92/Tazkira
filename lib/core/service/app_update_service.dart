import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:url_launcher/url_launcher.dart';

class AppUpdateService {
  static final AppUpdateService _instance = AppUpdateService._internal();

  factory AppUpdateService() => _instance;

  AppUpdateService._internal();

  bool _isUpdateCheckInProgress = false;
  bool _promptedInThisSession = false;
  bool _snackBarShowing = false;
  DateTime? _lastUpdateCheck;

  /// Trigger update check.
  /// [forcePrompt] can be used to bypass the session check if needed.
  /// [showManualDialogOnError] If true, shows fallback dialog when API fails
  Future<void> checkForUpdate(BuildContext context,
      {bool forcePrompt = false, bool showManualDialogOnError = false}) async {
    // Only works on Android
    if (!Platform.isAndroid) return;

    // Prevent concurrent checks
    if (_isUpdateCheckInProgress) return;

    // Throttle checks to once every 30 minutes minimum
    if (_lastUpdateCheck != null &&
        DateTime.now().difference(_lastUpdateCheck!) <
            const Duration(minutes: 30) &&
        !forcePrompt) {
      return;
    }

    _isUpdateCheckInProgress = true;
    _lastUpdateCheck = DateTime.now();

    try {
      final info = await InAppUpdate.checkForUpdate();

      debugPrint(
          'AppUpdateService: Update availability: ${info.updateAvailability}');
      debugPrint('AppUpdateService: Install status: ${info.installStatus}');

      // 1. ALWAYS check if update is already downloaded (e.g. while backgrounded)
      // This must happen before checking _promptedInThisSession
      if (info.installStatus == InstallStatus.downloaded) {
        _showInstallSnackBar(context);
        return;
      }

      // 2. Check if we should prompt for a new update
      // Prevent repeated prompts in the same session unless forced
      if (_promptedInThisSession && !forcePrompt) return;

      if (info.updateAvailability == UpdateAvailability.updateAvailable &&
          info.flexibleUpdateAllowed &&
          info.installStatus != InstallStatus.downloading) {
        _promptedInThisSession = true;

        // startFlexibleUpdate returns when the user accepts/declines.
        // If the user accepts, the download starts in background.
        final result = await InAppUpdate.startFlexibleUpdate();

        if (result == AppUpdateResult.success) {
          _showInstallSnackBar(context);
        }
      }
      // If no update available, do nothing (don't annoy user)
    } catch (e) {
      debugPrint('AppUpdateService: Error during update check: $e');
      // Only show fallback if explicitly requested (e.g., from Settings button)
      if (showManualDialogOnError && context.mounted) {
        _showManualUpdateDialog(context);
      }
    } finally {
      _isUpdateCheckInProgress = false;
    }
  }

  void _showInstallSnackBar(BuildContext context) {
    if (!context.mounted || _snackBarShowing) return;

    _snackBarShowing = true;

    ScaffoldMessenger.of(context)
        .showSnackBar(
          SnackBar(
            content: Text(
              'Update downloaded and ready to install!',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            backgroundColor: const Color(0xFF4A5D4F),
            duration: const Duration(days: 1),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            action: SnackBarAction(
              label: 'INSTALL',
              textColor: Colors.white,
              onPressed: () async {
                _snackBarShowing = false;
                try {
                  await InAppUpdate.completeFlexibleUpdate();
                } catch (e) {
                  debugPrint('AppUpdateService: Error installing update: $e');
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Installation failed: $e',
                          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        backgroundColor: const Color(0xFF4A5D4F),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                    );
                  }
                }
              },
            ),
          ),
        )
        .closed
        .then((_) => _snackBarShowing = false);
  }

  /// Fallback: Manual Play Store redirect if In-App Update API fails
  void _showManualUpdateDialog(BuildContext context) {
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          'تحديث متاح',
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            fontSize: 20.sp,
          ),
          textAlign: TextAlign.center,
        ),
        content: Text(
          'يتوفر إصدار جديد من التطبيق. يرجى تحديث التطبيق من متجر Google Play للحصول على أحدث الميزات والتحسينات.',
          style: GoogleFonts.cairo(fontSize: 16.sp),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'لاحقاً',
              style: GoogleFonts.cairo(
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final url = Uri.parse(
                  'https://play.google.com/store/apps/details?id=com.moaz.tazkira');
              try {
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              } catch (e) {
                debugPrint('AppUpdateService: Failed to open Play Store: $e');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A5D4F),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            child: Text(
              'تحديث الآن',
              style: GoogleFonts.cairo(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

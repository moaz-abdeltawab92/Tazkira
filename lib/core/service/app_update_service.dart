import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:in_app_update/in_app_update.dart';

class AppUpdateService {
  static final AppUpdateService _instance = AppUpdateService._internal();

  factory AppUpdateService() => _instance;

  AppUpdateService._internal();

  bool _isUpdateCheckInProgress = false;
  bool _promptedInThisSession = false;
  bool _snackBarShowing = false;

  /// Trigger update check.
  /// [forcePrompt] can be used to bypass the session check if needed.
  Future<void> checkForUpdate(BuildContext context,
      {bool forcePrompt = false}) async {
    // Only works on Android
    if (!Platform.isAndroid) return;

    // Prevent concurrent checks
    if (_isUpdateCheckInProgress) return;

    _isUpdateCheckInProgress = true;

    try {
      final info = await InAppUpdate.checkForUpdate();

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
    } catch (e) {
      debugPrint('AppUpdateService: Error during update check: $e');
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
}

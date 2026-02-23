import 'dart:io';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AppUpdateService {
  static final AppUpdateService _instance = AppUpdateService._internal();

  factory AppUpdateService() => _instance;

  AppUpdateService._internal();

  bool _isUpdateCheckInProgress = false;
  bool _promptedInThisSession = false;
  bool _snackBarShowing = false;
  DateTime? _lastUpdateCheck;

  // iOS App Store URL
  static const String _appStoreUrl = 'https://apps.apple.com/app/id6757756421';

  /// Trigger update check.
  /// [forcePrompt] can be used to bypass the session check if needed.
  /// [showManualDialogOnError] If true, shows fallback dialog when API fails
  Future<void> checkForUpdate(BuildContext context,
      {bool forcePrompt = false, bool showManualDialogOnError = false}) async {
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
      if (Platform.isAndroid) {
        await _checkAndroidUpdate(
            context, forcePrompt, showManualDialogOnError);
      } else if (Platform.isIOS) {
        await _checkIOSUpdate(context, forcePrompt);
      }
    } catch (e) {
      debugPrint('AppUpdateService: Error during update check: $e');
    } finally {
      _isUpdateCheckInProgress = false;
    }
  }

  /// Android update logic using in_app_update
  Future<void> _checkAndroidUpdate(BuildContext context, bool forcePrompt,
      bool showManualDialogOnError) async {
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
    } catch (e) {
      debugPrint('AppUpdateService: Error during Android update check: $e');
      if (showManualDialogOnError && context.mounted) {
        _showManualUpdateDialog(context);
      }
    }
  }

  /// iOS update logic using Firebase Remote Config
  Future<void> _checkIOSUpdate(BuildContext context, bool forcePrompt) async {
    try {
      // Prevent repeated prompts in the same session unless forced
      if (_promptedInThisSession && !forcePrompt) return;

      // Get current app version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final currentBuildNumber = int.parse(packageInfo.buildNumber);

      // Get minimum required version from Remote Config
      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(minutes: 30),
      ));

      await remoteConfig.fetchAndActivate();

      final minVersion =
          remoteConfig.getString('ios_min_version').trim(); // e.g., "1.1.0"
      final minBuildNumber =
          remoteConfig.getInt('ios_min_build_number'); // e.g., 5
      final forceUpdate =
          remoteConfig.getBool('ios_force_update'); // true/false

      debugPrint(
          'AppUpdateService [iOS]: Current version: $currentVersion ($currentBuildNumber)');
      debugPrint(
          'AppUpdateService [iOS]: Min version from Remote Config: $minVersion ($minBuildNumber)');
      debugPrint('AppUpdateService [iOS]: Force update: $forceUpdate');

      // Check if update is needed
      if (minBuildNumber > 0 && currentBuildNumber < minBuildNumber) {
        _promptedInThisSession = true;
        if (context.mounted) {
          _showRamadanUpdateDialog(context, forceUpdate);
        }
      }
    } catch (e) {
      debugPrint('AppUpdateService: Error during iOS update check: $e');
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

  /// Beautiful Ramadan-themed update dialog for iOS
  void _showRamadanUpdateDialog(BuildContext context, bool forceUpdate) {
    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: !forceUpdate, // Can't dismiss if forced
      builder: (context) => WillPopScope(
        onWillPop: () async => !forceUpdate, // Prevent back button if forced
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.r),
          ),
          elevation: 8,
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF2D4A3E), // Dark green
                  Color(0xFF4A5D4F), // Medium green
                  Color(0xFF1A2D23), // Very dark green
                ],
              ),
              borderRadius: BorderRadius.circular(24.r),
            ),
            child: Padding(
              padding: EdgeInsets.all(24.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Crescent moon and star icon
                  Container(
                    width: 80.w,
                    height: 80.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.15),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.star_border_rounded,
                        size: 48.sp,
                        color: const Color(0xFFD4AF37), // Gold color
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),

                  // Title with Ramadan greeting
                  Text(
                    '🌙 رمضان كريم',
                    style: GoogleFonts.cairo(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFD4AF37), // Gold
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 12.h),

                  // Update message
                  Text(
                    'تحديث جديد',
                    style: GoogleFonts.cairo(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16.h),

                  // Description
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      forceUpdate
                          ? 'للاستمتاع بأحدث الميزات الرمضانية وتحسينات الأداء، يجب تحديث التطبيق الآن'
                          : 'يتوفر إصدار جديد من التطبيق مع ميزات رمضانية مميزة وتحسينات عامة على مستوى التطبيق',
                      style: GoogleFonts.cairo(
                        fontSize: 15.sp,
                        color: Colors.white.withOpacity(0.9),
                        height: 1.7,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: 24.h),

                  // Update button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        final url = Uri.parse(_appStoreUrl);
                        try {
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url,
                                mode: LaunchMode.externalApplication);
                          }
                        } catch (e) {
                          debugPrint(
                              'AppUpdateService: Failed to open App Store: $e');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD4AF37), // Gold
                        foregroundColor: const Color(0xFF1A2D23),
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        elevation: 4,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.system_update_alt_rounded,
                            size: 24.sp,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            'تحديث الآن',
                            style: GoogleFonts.cairo(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Later button (only if not forced)
                  if (!forceUpdate) ...[
                    SizedBox(height: 12.h),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                      child: Text(
                        'لاحقاً',
                        style: GoogleFonts.cairo(
                          fontSize: 16.sp,
                          color: Colors.white.withOpacity(0.7),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

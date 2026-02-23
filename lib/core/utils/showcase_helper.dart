import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ShowcaseHelper {
  static Future<bool> hasSeenShowcase(String showcaseKey) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('showcase_$showcaseKey') ?? false;
  }

  static Future<void> setShowcaseSeen(String showcaseKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showcase_$showcaseKey', true);
  }

  static Future<void> resetShowcase(String showcaseKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('showcase_$showcaseKey');
  }

  static void startShowcase(
    BuildContext context,
    List<GlobalKey> keys,
    String showcaseKey,
  ) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final hasSeen = await hasSeenShowcase(showcaseKey);
      if (!hasSeen && context.mounted) {
        ShowCaseWidget.of(context).startShowCase(keys);
        await setShowcaseSeen(showcaseKey);
      }
    });
  }
}

class AppShowcase extends StatelessWidget {
  final GlobalKey showcaseKey;
  final Widget child;
  final String title;
  final String description;
  final ShapeBorder? targetShapeBorder;
  final double? targetBorderRadius;

  const AppShowcase({
    super.key,
    required this.showcaseKey,
    required this.child,
    required this.title,
    required this.description,
    this.targetShapeBorder,
    this.targetBorderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Showcase(
      key: showcaseKey,
      title: title,
      description: description,
      targetShapeBorder: targetShapeBorder ??
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(targetBorderRadius ?? 16),
          ),
      tooltipBackgroundColor: Theme.of(context).primaryColor,
      descTextStyle: const TextStyle(
        fontSize: 14,
        color: Colors.white,
        fontWeight: FontWeight.w400,
      ),
      titleTextStyle: const TextStyle(
        fontSize: 18,
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
      targetPadding: const EdgeInsets.all(8),
      child: child,
    );
  }
}

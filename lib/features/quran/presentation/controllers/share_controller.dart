import 'package:get/get.dart';
import 'package:tazkira_app/core/routing/route_export.dart';
import '../widgets/verse_image_creator.dart';

class ShareController extends GetxController {
  static ShareController get instance => Get.find<ShareController>();

  final ScreenshotController screenshotController = ScreenshotController();

  /// Share verse as text only
  Future<void> shareText(
    String verseText,
    String surahName,
    int verseNumber,
  ) async {
    final String shareContent =
        '﴿ $verseText ﴾\n[$surahName: $verseNumber]\n\nتَذْكِرَة - رفيق المسلم اليومي';

    await Share.share(
      shareContent,
      subject: surahName,
    );
  }

  /// Share verse as image with text
  Future<void> shareImage(
    String verseText,
    String surahName,
    int verseNumber,
    int surahNumber,
  ) async {
    try {
      // Create the widget to capture
      final widget = VerseImageCreator(
        verseNumber: verseNumber,
        surahNumber: surahNumber,
        surahName: surahName,
        verseText: verseText,
      );

      // Capture screenshot
      final imageBytes = await screenshotController.captureFromWidget(
        widget,
        pixelRatio: 3.0,
        delay: const Duration(milliseconds: 100),
      );

      // Save to temporary file
      final directory = await getTemporaryDirectory();
      final imagePath =
          '${directory.path}/verse_${DateTime.now().millisecondsSinceEpoch}.png';
      final imageFile = File(imagePath);
      await imageFile.writeAsBytes(imageBytes);

      // Share image with text (no link)
      final String shareText =
          '﴿ $verseText ﴾\n[$surahName: $verseNumber]\n\nتَذْكِرَة - رفيق المسلم اليومي';

      await Share.shareXFiles(
        [XFile(imagePath)],
        text: shareText,
      );
    } catch (e) {
      debugPrint('Error sharing image: $e');
      // Fallback to text share
      await shareText(verseText, surahName, verseNumber);
    }
  }
}

import 'package:quran_library/quran.dart';
import 'package:tazkira_app/core/routing/route_export.dart';
import 'package:get/get.dart';
import '../controllers/share_controller.dart';
import '../widgets/verse_image_creator.dart';

class MyQuranPage extends StatefulWidget {
  final int? initialPage;
  const MyQuranPage({super.key, this.initialPage});

  @override
  State<MyQuranPage> createState() => _MyQuranPageState();
}

class _MyQuranPageState extends State<MyQuranPage> {
  bool isDark = false;
  late ShareController shareController;

  @override
  void initState() {
    super.initState();
    // Initialize ShareController
    Get.put(ShareController());
    shareController = ShareController.instance;

    if (widget.initialPage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 500), () {
          QuranLibrary().jumpToPage(widget.initialPage!);
        });
      });
    }
  }

  void _showShareOptions(BuildContext context, AyahModel ayah) {
    // Get surah name
    final surahName = QuranCtrl.instance.surahs
        .firstWhere((s) => s.surahNumber == ayah.surahNumber!)
        .arabicName;

    // Get ayah text with tashkeel (using text property which contains tashkeel)
    final ayahText = ayah.text;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (bottomSheetContext) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(8),
            topRight: Radius.circular(8),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Close button
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: GestureDetector(
                    onTap: () => Navigator.pop(bottomSheetContext),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        size: 20,
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                  ),
                ),
              ),

              // Share as text section
              _buildShareTextSection(
                context,
                bottomSheetContext,
                ayahText,
                surahName,
                ayah.ayahNumber,
              ),

              // Divider
              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 16.0),
                color: Colors.teal,
              ),

              // Share as image section
              _buildShareImageSection(
                context,
                bottomSheetContext,
                ayahText,
                surahName,
                ayah.ayahNumber,
                ayah.surahNumber!,
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShareTextSection(
    BuildContext context,
    BuildContext bottomSheetContext,
    String ayahText,
    String surahName,
    int ayahNumber,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'مشاركة كنص',
              style: TextStyle(
                color: Theme.of(context).hintColor,
                fontSize: 16,
                fontFamily: 'cairo',
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.pop(bottomSheetContext);
            shareController.shareText(
              ayahText,
              surahName,
              ayahNumber,
            );
          },
          child: Container(
            width: MediaQuery.of(context).size.width,
            padding: const EdgeInsets.all(16.0),
            margin: const EdgeInsets.only(
              top: 4.0,
              bottom: 16.0,
              right: 16.0,
              left: 16.0,
            ),
            decoration: BoxDecoration(
              color: Colors.teal.withOpacity(0.15),
              borderRadius: const BorderRadius.all(Radius.circular(4)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  flex: 2,
                  child: Icon(
                    Icons.text_fields,
                    color: Colors.teal,
                    size: 24,
                  ),
                ),
                Expanded(
                  flex: 8,
                  child: Text(
                    "﴿ $ayahText ﴾",
                    style: const TextStyle(
                      fontSize: 16,
                      fontFamily: 'uthmanic2',
                    ),
                    textDirection: TextDirection.rtl,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShareImageSection(
    BuildContext context,
    BuildContext bottomSheetContext,
    String ayahText,
    String surahName,
    int ayahNumber,
    int surahNumber,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'مشاركة كصورة',
              style: TextStyle(
                color: Theme.of(context).hintColor,
                fontSize: 16,
                fontFamily: 'cairo',
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ),
        GestureDetector(
          onTap: () async {
            Navigator.pop(bottomSheetContext);

            // Show loading
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.teal),
                    SizedBox(height: 16),
                    Material(
                      color: Colors.transparent,
                      child: Text(
                        'جاري إنشاء الصورة...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontFamily: 'kufi',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );

            // Share image
            try {
              await shareController.shareImage(
                ayahText,
                surahName,
                ayahNumber,
                surahNumber,
              );
            } catch (e) {
              debugPrint('Error: $e');
            }

            // Close loading
            if (context.mounted) {
              Navigator.pop(context);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(8.0),
            margin: const EdgeInsets.only(
              top: 4.0,
              bottom: 16.0,
              right: 16.0,
              left: 16.0,
            ),
            decoration: BoxDecoration(
              color: Colors.teal.withOpacity(0.15),
              borderRadius: const BorderRadius.all(Radius.circular(4)),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(4)),
              child: FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: 960.0,
                  child: VerseImageCreator(
                    verseNumber: ayahNumber,
                    surahNumber: surahNumber,
                    surahName: surahName,
                    verseText: ayahText,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Directionality(
          textDirection: TextDirection.rtl,
          child: QuranLibraryScreen(
            ayahMenuStyle:
                AyahMenuStyle.defaults(isDark: false, context: context)
                    .copyWith(
              customMenuItems: [
                InkWell(
                  onTap: () {
                    // Get selected ayah
                    if (QuranCtrl
                        .instance.selectedAyahsByUnequeNumber.isNotEmpty) {
                      final selectedUQ =
                          QuranCtrl.instance.selectedAyahsByUnequeNumber.first;
                      final ayah = QuranCtrl.instance.ayahs
                          .firstWhere((a) => a.ayahUQNumber == selectedUQ);
                      Navigator.pop(context); // Close menu
                      _showShareOptions(context, ayah);
                    }
                  },
                  child: const Icon(Icons.share, color: Colors.teal, size: 18),
                ),
              ],
            ),
            appIconPathForPlayAudioInBackground: 'assets/icons/app_icon.png',
            parentContext: context,
            isDark: isDark,
            appLanguageCode: 'ar',
            topBarStyle:
                QuranTopBarStyle.defaults(isDark: isDark, context: context)
                    .copyWith(
              showBackButton: true,
            ),
          ),
        ),
        // Dark mode button
        Positioned(
          bottom: 15,
          left: 5,
          child: FloatingActionButton.small(
            heroTag: 'dark_mode_btn',
            onPressed: () {
              setState(() {
                isDark = !isDark;
              });
            },
            backgroundColor: Colors.white,
            child: Icon(
              isDark ? Icons.light_mode : Icons.dark_mode,
              color: isDark ? Colors.amber : Colors.grey[800],
              size: 24,
            ),
          ),
        ),
      ],
    );
  }
}

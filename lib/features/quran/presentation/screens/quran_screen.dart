import 'package:tazkira_app/core/routing/route_export.dart';
import 'package:quran_library/quran_library.dart';

class QuranScreen extends StatefulWidget {
  const QuranScreen({super.key});

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initQuranLibrary();
  }

  Future<void> _initQuranLibrary() async {
    await QuranLibrary.init();
    setState(() {
      _isInitialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _isInitialized ? _buildQuranLibraryScreen() : _buildSplashScreen();
  }

  Widget _buildQuranLibraryScreen() {
    return QuranLibraryScreen(
      parentContext: context,
      showAyahBookmarkedIcon: true,
      ayahIconColor: const Color(0xffcdad80),
      isFontsLocal: false,
      anotherMenuChild:
          const Icon(Icons.play_arrow_outlined, size: 28, color: Colors.grey),
      anotherMenuChildOnTap: (ayah) {
        QuranLibrary().playAyah(
          context: context,
          currentAyahUniqueNumber: ayah.ayahUQNumber,
          playSingleAyah: true,
        );
      },
      secondMenuChild:
          const Icon(Icons.playlist_play, size: 28, color: Colors.grey),
      secondMenuChildOnTap: (ayah) {
        QuranLibrary().playAyah(
          context: context,
          currentAyahUniqueNumber: ayah.ayahUQNumber,
          playSingleAyah: false,
        );
      },
    );
  }

  Widget _buildSplashScreen() {
    return const Scaffold(
      backgroundColor: Color(0xfff5f3eb),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.menu_book_rounded, color: Color(0xffcdad80), size: 80),
            SizedBox(height: 16),
            Text(
              "جاري تحميل المصحف...",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Color(0xff8a6d3b),
              ),
            ),
            SizedBox(height: 24),
            CircularProgressIndicator(color: Color(0xffcdad80)),
          ],
        ),
      ),
    );
  }
}

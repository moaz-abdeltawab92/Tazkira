import 'package:tazkira_app/core/routing/route_export.dart';
import 'package:quran_library/quran_library.dart';

class FridayBanner extends StatelessWidget {
  const FridayBanner({super.key});

  bool _isFriday() {
    final now = DateTime.now();
    return now.weekday == DateTime.friday;
  }

  @override
  Widget build(BuildContext context) {
    if (!_isFriday()) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () {
        // Navigate to custom Quran screen that opens at Surah Al-Kahf
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const _QuranScreenWithSurahKahf(),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        height: 190.h,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerRight,
            end: Alignment.centerLeft,
            colors: [
              Color(0xFFF8F4EE),
              Colors.white,
              Color(0xFFF8F4EE),
            ],
          ),
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -10,
              top: -10,
              child: CustomPaint(
                size: Size(80.w, 160.h),
                painter: IslamicPatternPainter(),
              ),
            ),
            Positioned(
              left: -10,
              top: -10,
              child: CustomPaint(
                size: Size(80.w, 160.h),
                painter: IslamicPatternPainter(),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 85.w, vertical: 16.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 3.h),
                  Text(
                    "لا تنسَ قراءة سورة الكهف ",
                    textAlign: TextAlign.right,
                    style: GoogleFonts.cairo(
                      color: const Color(0xFF5A8C8C),
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    'قال النبي ﷺ: "من قرأ سورة الكهف في يوم الجمعة أضاء له من النور ما بين الجمعتين"',
                    textAlign: TextAlign.right,
                    style: GoogleFonts.cairo(
                      color: const Color(0xFF2C5454),
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class IslamicPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    final orangeColor = const Color(0xFFD4A574).withOpacity(0.25);
    final tealColor = const Color(0xFF5A8C8C).withOpacity(0.2);
    final blueColor = const Color(0xFF6B9999).withOpacity(0.18);

    paint.color = orangeColor;
    _drawStar(canvas, Offset(size.width * 0.5, size.height * 0.25), 20, paint);

    paint.color = tealColor;
    _drawDiamond(
        canvas, Offset(size.width * 0.5, size.height * 0.5), 25, paint);

    paint.color = blueColor;
    _drawStar(canvas, Offset(size.width * 0.5, size.height * 0.75), 18, paint);
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (int i = 0; i < 8; i++) {
      final angle = (i * 45 - 90) * 3.14159 / 180;
      final r = (i % 2 == 0) ? radius : radius * 0.5;
      final x = center.dx + r * _cos(angle);
      final y = center.dy + r * _sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawDiamond(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    path.moveTo(center.dx, center.dy - size);
    path.lineTo(center.dx + size, center.dy);
    path.lineTo(center.dx, center.dy + size);
    path.lineTo(center.dx - size, center.dy);
    path.close();
    canvas.drawPath(path, paint);
  }

  double _cos(double angle) {
    if ((angle - 0).abs() < 0.01) return 1;
    if ((angle - 1.5708).abs() < 0.01) return 0;
    if ((angle - 3.14159).abs() < 0.01) return -1;
    if ((angle - 4.71239).abs() < 0.01) return 0;
    return 1 - (angle * angle) / 2 + (angle * angle * angle * angle) / 24;
  }

  double _sin(double angle) {
    if ((angle - 0).abs() < 0.01) return 0;
    if ((angle - 1.5708).abs() < 0.01) return 1;
    if ((angle - 3.14159).abs() < 0.01) return 0;
    if ((angle - 4.71239).abs() < 0.01) return -1;
    return angle -
        (angle * angle * angle) / 6 +
        (angle * angle * angle * angle * angle) / 120;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Custom Quran screen that opens at Surah Al-Kahf
class _QuranScreenWithSurahKahf extends StatefulWidget {
  const _QuranScreenWithSurahKahf();

  @override
  State<_QuranScreenWithSurahKahf> createState() =>
      _QuranScreenWithSurahKahfState();
}

class _QuranScreenWithSurahKahfState extends State<_QuranScreenWithSurahKahf> {
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

    // Jump to Surah Al-Kahf after initialization
    Future.delayed(const Duration(milliseconds: 300), () {
      QuranLibrary().jumpToPage(293);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: const Color(0xfff5f3eb),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(24.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xffcdad80).withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: Color(0xffcdad80),
                  size: 50,
                ),
              ),
              SizedBox(height: 24.h),
              Text(
                "جاري فتح سورة الكهف...",
                style: GoogleFonts.cairo(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xff8a6d3b),
                ),
              ),
              SizedBox(height: 16.h),
              SizedBox(
                width: 200.w,
                child: const LinearProgressIndicator(
                  color: Color(0xffcdad80),
                  backgroundColor: Color(0xffe8dcc8),
                ),
              ),
            ],
          ),
        ),
      );
    }

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
}

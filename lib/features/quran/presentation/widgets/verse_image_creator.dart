import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class VerseImageCreator extends StatelessWidget {
  final int verseNumber;
  final int surahNumber;
  final String surahName;
  final String verseText;

  const VerseImageCreator({
    super.key,
    required this.verseNumber,
    required this.surahNumber,
    required this.surahName,
    required this.verseText,
  });

  // Convert number to Arabic
  String _toArabicNumber(int number) {
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number
        .toString()
        .split('')
        .map((digit) => arabicDigits[int.parse(digit)])
        .join();
  }

  @override
  Widget build(BuildContext context) {
    return _buildVerseImage();
  }

  Widget _buildVerseImage() {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        width: 960.0,
        decoration: const BoxDecoration(
          color: Color(0xff404C6E),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            // Header with app info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.menu_book_rounded,
                            color: Color(0xff404C6E),
                            size: 24,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          color: Colors.white.withOpacity(0.3),
                        ),
                        const Text(
                          'القـرآن الكريــــم\nتَذْكِرَة - رفيق المسلم اليومي',
                          style: TextStyle(
                            fontSize: 10,
                            fontFamily: 'kufi',
                            color: Color(0xffffffff),
                            height: 1.4,
                          ),
                        )
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Container(
                      height: 1,
                      color: Colors.white.withOpacity(0.3),
                    ),
                  ),
                ],
              ),
            ),
            // White card with verse
            Container(
              margin: const EdgeInsets.all(8.0),
              decoration: const BoxDecoration(
                color: Color(0xffffffff),
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    // Surah banner with SVG decoration
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // SVG Banner
                        SvgPicture.asset(
                          'assets/svg/surah_banner4.svg',
                          width: 373,
                          height: 39,
                        ),
                        // Surah name with better styling
                        Text(
                          surahName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontFamily: 'kufi',
                            color: Color(0xff1a2410),
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Verse text
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: SizedBox(
                        width: 928.0,
                        child: RichText(
                          textAlign: TextAlign.justify,
                          textDirection: TextDirection.rtl,
                          text: TextSpan(
                            text:
                                '﴿ $verseText ${_toArabicNumber(verseNumber)} ﴾',
                            style: const TextStyle(
                              fontSize: 16,
                              fontFamily: 'uthmanic2',
                              color: Color(0xff161f07),
                              height: 1.8,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

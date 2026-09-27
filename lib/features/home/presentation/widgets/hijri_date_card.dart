import 'package:hijri/hijri_calendar.dart';
import 'package:tazkira_app/core/routing/route_export.dart';
import 'package:tazkira_app/core/utils/islamic_season_helper.dart';

class HijriDateCard extends StatelessWidget {
  const HijriDateCard({super.key});

  Future<String> _getHijriDate() async {
    final hijriDate = await IslamicSeasonHelper.getAdjustedHijriDate();
    final hijriMonthName = _getArabicMonthName(hijriDate.hMonth);
    return '${hijriDate.hDay} $hijriMonthName ${hijriDate.hYear} هـ';
  }

  Future<int?> _getDaysUntilRamadan() async {
    final hijriDate = await IslamicSeasonHelper.getAdjustedHijriDate();

    if (hijriDate.hMonth >= 9) {
      return null;
    }

    final currentDate = DateTime.now();
    final ramadanStart = HijriCalendar()
      ..hYear = hijriDate.hYear
      ..hMonth = 9
      ..hDay = 1;

    final ramadanGregorian = ramadanStart.hijriToGregorian(
      ramadanStart.hYear,
      ramadanStart.hMonth,
      ramadanStart.hDay,
    );

    final difference = ramadanGregorian.difference(currentDate).inDays;
    return (difference > 0 && difference <= 50) ? difference : null;
  }

  String _getArabicMonthName(int month) {
    const months = [
      'محرم',
      'صفر',
      'ربيع الأول',
      'ربيع الآخر',
      'جمادى الأولى',
      'جمادى الآخرة',
      'رجب',
      'شعبان',
      'رمضان',
      'شوال',
      'ذو القعدة',
      'ذو الحجة',
    ];
    return months[month - 1];
  }

  String _getGregorianDate() {
    final now = DateTime.now();
    const months = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];
    return '${now.day} ${months[now.month - 1]} ${now.year} م';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: Future.wait([
        _getHijriDate(),
        _getDaysUntilRamadan(),
      ]).then((results) => {
            'hijriDate': results[0] as String,
            'daysUntilRamadan': results[1] as int?,
          }),
      builder: (context, snapshot) {
        final hijriDate =
            snapshot.data?['hijriDate'] as String? ?? 'جاري التحميل...';
        final daysUntilRamadan = snapshot.data?['daysUntilRamadan'] as int?;

        return Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    Color(0xFF5A8C8C),
                    Color(0xFF7CB9AD),
                  ],
                ),
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    hijriDate,
                    textDirection: TextDirection.rtl,
                    style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    _getGregorianDate(),
                    textDirection: TextDirection.rtl,
                    style: GoogleFonts.cairo(
                      color: Colors.white70,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Days until Ramadan
            if (daysUntilRamadan != null) ...[
              SizedBox(height: 8.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      Color(0xFFD4A574),
                      Color(0xFFB8860B),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8.r),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD4A574).withOpacity(0.4),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '🌙',
                      style: TextStyle(fontSize: 16.sp),
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      'متبقي $daysUntilRamadan يوم على رمضان',
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

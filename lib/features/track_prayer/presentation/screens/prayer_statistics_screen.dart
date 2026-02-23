import 'package:tazkira_app/core/routing/route_export.dart';
import 'package:tazkira_app/features/track_prayer/presentation/data/prayer_statistics_service.dart';

class PrayerStatisticsScreen extends StatefulWidget {
  const PrayerStatisticsScreen({super.key});

  @override
  State<PrayerStatisticsScreen> createState() => _PrayerStatisticsScreenState();
}

class _PrayerStatisticsScreenState extends State<PrayerStatisticsScreen> {
  Map<String, dynamic>? _statistics;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    try {
      // Add timeout to prevent infinite loading
      final stats =
          await PrayerStatisticsService.getStatisticsSummary().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('Statistics loading timeout');
          return {
            'currentStreak': 0,
            'longestStreak': 0,
            'lastCompleteDate': null,
            'totalDaysTracked': 0,
            'totalPrayersCompleted': 0,
          };
        },
      );

      if (mounted) {
        setState(() {
          _statistics = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading statistics: $e');
      if (mounted) {
        setState(() {
          _statistics = {
            'currentStreak': 0,
            'longestStreak': 0,
            'lastCompleteDate': null,
            'totalDaysTracked': 0,
            'totalPrayersCompleted': 0,
          };
          _isLoading = false;
        });
      }
    }
  }

  String _getMotivationalMessage(int streak) {
    if (streak == 0) {
      return 'ابدأ رحلتك مع الالتزام بالصلاة اليوم';
    } else if (streak < 7) {
      return 'ما شاء الله استمر في الالتزام ';
    } else if (streak < 30) {
      return 'ما شاء الله، مستمر بصلاة منتظمة';
    } else if (streak < 100) {
      return 'بارك الله فيك، التزام مميز ';
    } else {
      return 'ما شاء الله، إنجاز عظيم ';
    }
  }

  String _getLastCompleteDateFormatted() {
    if (_statistics == null || _statistics!['lastCompleteDate'] == null) {
      return 'لم تكمل يوم بعد';
    }

    try {
      final lastDate = DateTime.parse(_statistics!['lastCompleteDate']);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final lastDateNormalized =
          DateTime(lastDate.year, lastDate.month, lastDate.day);

      if (lastDateNormalized == today) {
        return 'اليوم 🟢';
      } else if (lastDateNormalized == yesterday) {
        return 'أمس';
      } else {
        return '${lastDate.day}/${lastDate.month}/${lastDate.year}';
      }
    } catch (e) {
      debugPrint('Error formatting date: $e');
      return 'لم تكمل يوم بعد';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          elevation: 0,
          automaticallyImplyLeading: false,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF7CB9AD), Color(0xFF5A9A8E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          title: Text(
            'إحصائيات صلاتك',
            style: GoogleFonts.cairo(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 22.sp,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: _isLoading || _statistics == null
            ? const Center(child: CircularProgressIndicator())
            : Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/back_ground.jpg'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Streak Card - Main Feature
                      Container(
                        padding: EdgeInsets.all(24.w),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF7CB9AD), Color(0xFF5A9A8E)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              ' سلسلة الالتزام بالصلاة',
                              style: GoogleFonts.cairo(
                                fontSize: 24.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 20.h),
                            Container(
                              padding: EdgeInsets.all(20.w),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${_statistics!['currentStreak']}',
                                style: GoogleFonts.cairo(
                                  fontSize: 60.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(height: 10.h),
                            Text(
                              'يوم متتالي',
                              style: GoogleFonts.cairo(
                                fontSize: 18.sp,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 15.h),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 8.h,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20.r),
                              ),
                              child: Text(
                                _getMotivationalMessage(
                                    _statistics!['currentStreak']),
                                style: GoogleFonts.cairo(
                                  fontSize: 14.sp,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20.h),

                      // Last Complete Date
                      Container(
                        padding: EdgeInsets.all(20.w),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(16.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _getLastCompleteDateFormatted(),
                              style: GoogleFonts.cairo(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF5A9A8E),
                              ),
                            ),
                            Text(
                              'آخر يوم مكتمل',
                              style: GoogleFonts.cairo(
                                fontSize: 16.sp,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20.h),

                      // Statistics Grid
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              title: 'أطول سلسلة',
                              value: '${_statistics!['longestStreak']} يوم',
                              color: const Color(0xFFFFB300),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: _buildStatCard(
                              title: 'إجمالي الأيام',
                              value: '${_statistics!['totalDaysTracked']} يوم',
                              color: const Color(0xFF7CB9AD),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              title: 'إجمالي الصلوات',
                              value:
                                  '${_statistics!['totalPrayersCompleted']} صلاة',
                              color: const Color(0xFF5A9A8E),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: _buildStatCard(
                              title: 'نسبة الالتزام',
                              value: _statistics!['totalDaysTracked'] > 0
                                  ? '${((_statistics!['totalPrayersCompleted'] / (_statistics!['totalDaysTracked'] * 5)) * 100).toStringAsFixed(1)}%'
                                  : '0%',
                              color: const Color(0xFF4CAF50),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20.h),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            title,
            style: GoogleFonts.cairo(
              fontSize: 15.sp,
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 12.h),
          Text(
            value,
            style: GoogleFonts.cairo(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

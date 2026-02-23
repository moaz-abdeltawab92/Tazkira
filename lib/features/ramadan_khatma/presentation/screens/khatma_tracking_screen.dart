import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tazkira_app/features/ramadan_khatma/data/models/khatma_progress_model.dart';
import 'package:tazkira_app/features/ramadan_khatma/data/services/khatma_storage_service.dart';

class KhatmaTrackingScreen extends StatefulWidget {
  final KhatmaProgressModel initialProgress;

  const KhatmaTrackingScreen({
    super.key,
    required this.initialProgress,
  });

  @override
  State<KhatmaTrackingScreen> createState() => _KhatmaTrackingScreenState();
}

class _KhatmaTrackingScreenState extends State<KhatmaTrackingScreen>
    with SingleTickerProviderStateMixin {
  late KhatmaProgressModel _progress;
  late AnimationController _celebrationController;

  @override
  void initState() {
    super.initState();
    _progress = widget.initialProgress;
    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    super.dispose();
  }

  Future<void> _toggleJuz(int juzNumber) async {
    try {
      final updatedProgress = await KhatmaStorageService.toggleJuzCompletion(
        _progress,
        juzNumber,
      );

      if (updatedProgress == null) {
        // Failed to toggle
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'حدث خطأ في حفظ التقدم',
                style: GoogleFonts.cairo(),
                textAlign: TextAlign.center,
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      if (!mounted) return;

      setState(() {
        _progress = updatedProgress;
      });

      // Animate if completed
      if (_progress.completedJuzs[juzNumber] == true) {
        _celebrationController.forward().then((_) {
          if (mounted) {
            _celebrationController.reverse();
          }
        });
      }

      // Check if all completed
      if (_progress.isCompleted) {
        _showCompletionDialog();
      }
    } catch (e) {
      // Handle any unexpected errors
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'حدث خطأ غير متوقع',
              style: GoogleFonts.cairo(),
              textAlign: TextAlign.center,
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.celebration_rounded,
              size: 80.sp,
              color: const Color(0xFF6BA598),
            ),
            SizedBox(height: 16.h),
            Text(
              "مبروك!",
              style: GoogleFonts.cairo(
                fontSize: 28.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF6BA598),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              "أتممت الختمة بنجاح\nتقبل الله منك",
              style: GoogleFonts.cairo(
                fontSize: 18.sp,
                color: Colors.grey[700],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(
              "الحمد لله",
              style: GoogleFonts.cairo(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF6BA598),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: const Color(0xFF6BA598),
        automaticallyImplyLeading: false,
        title: Text(
          "ختمة رمضان",
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            fontSize: 22.sp,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.r),
                ),
                title: Text(
                  'إعادة تعيين',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                content: Text(
                  'هل تريد إعادة تعيين التقدم؟',
                  style: GoogleFonts.cairo(),
                  textAlign: TextAlign.center,
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('إلغاء', style: GoogleFonts.cairo()),
                  ),
                  TextButton(
                    onPressed: () async {
                      try {
                        final success =
                            await KhatmaStorageService.clearKhatmaData();
                        if (mounted) {
                          Navigator.of(context).pop(); // Close dialog

                          if (success) {
                            Navigator.of(context).pop(); // Go back
                          } else {
                            // Show error message
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'حدث خطأ في حذف البيانات',
                                  style: GoogleFonts.cairo(),
                                  textAlign: TextAlign.center,
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      } catch (e) {
                        if (mounted) {
                          Navigator.of(context).pop(); // Close dialog
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'حدث خطأ غير متوقع',
                                style: GoogleFonts.cairo(),
                                textAlign: TextAlign.center,
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    child: Text(
                      'إعادة تعيين',
                      style: GoogleFonts.cairo(color: Colors.red),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          child: Column(
            children: [
              // Progress Card
              _buildProgressCard(),

              SizedBox(height: 16.h),

              // Info Banner
              _buildInfoBanner(),

              SizedBox(height: 16.h),

              // Calendar Grid Title
              Text(
                "تابع تقدمك في قراءة القرآن",
                style: GoogleFonts.cairo(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              SizedBox(height: 12.h),

              // Juz Grid(s)
              _buildKhatmasGrid(),

              SizedBox(height: 16.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressCard() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 16.h),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6BA598), Color(0xFF4A8B7F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6BA598).withOpacity(0.25),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            "شَهْرُ رَمَضَانَ الَّذِي أُنزِلَ فِيهِ الْقُرْآنُ",
            style: GoogleFonts.amiri(
              fontSize: 17.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4.h),
          Text(
            " ﴾ سورة البقرة: ١٨٥ ﴿",
            style: GoogleFonts.cairo(
              fontSize: 12.sp,
              color: Colors.white.withOpacity(0.85),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 16.h),

          // Progress Bar
          Stack(
            children: [
              Container(
                height: 16.h,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                height: 16.h,
                width: MediaQuery.of(context).size.width *
                    (_progress.completionPercentage / 100) *
                    0.75,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
            ],
          ),

          SizedBox(height: 12.h),

          // Stats Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem(
                "${_progress.completionPercentage.toStringAsFixed(0)}%",
                "مكتمل",
              ),
              Container(
                width: 1,
                height: 40.h,
                color: Colors.white.withOpacity(0.3),
              ),
              _buildStatItem(
                "${_progress.remainingJuzs}",
                "باقي ${_progress.khatmaCount == 1 ? 'جزء' : 'أجزاء'}",
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.cairo(
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 13.sp,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: const Color(0xFF6BA598).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: const Color(0xFF6BA598).withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: const Color(0xFF6BA598),
            size: 24.sp,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              _progress.khatmaCount == 1
                  ? "اقرأ جزءاً واحداً يومياً لإتمام الختمة"
                  : "اقرأ جزئين يومياً لإتمام ختمتين في رمضان",
              style: GoogleFonts.cairo(
                fontSize: 14.sp,
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build khatmas grid with divider if needed
  Widget _buildKhatmasGrid() {
    if (_progress.khatmaCount == 1) {
      // Single khatma: show 30 juzs
      return _buildKhatmaSection(
        khatmaNumber: 1,
        startJuz: 1,
        endJuz: 30,
      );
    } else {
      // Two khatmas: show first 30, divider, then second 30
      return Column(
        children: [
          // First Khatma
          _buildKhatmaSection(
            khatmaNumber: 1,
            startJuz: 1,
            endJuz: 30,
          ),

          SizedBox(height: 16.h),

          // Divider
          _buildKhatmaDivider(),

          SizedBox(height: 16.h),

          // Second Khatma
          _buildKhatmaSection(
            khatmaNumber: 2,
            startJuz: 31,
            endJuz: 60,
          ),
        ],
      );
    }
  }

  // Build a single khatma section
  Widget _buildKhatmaSection({
    required int khatmaNumber,
    required int startJuz,
    required int endJuz,
  }) {
    return Column(
      children: [
        if (_progress.khatmaCount == 2) ...[
          // Header for each khatma
          Container(
            padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 12.w),
            decoration: BoxDecoration(
              color: const Color(0xFF6BA598).withOpacity(0.15),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.star,
                  color: const Color(0xFF6BA598),
                  size: 20.sp,
                ),
                SizedBox(width: 8.w),
                Text(
                  "الختمة ${khatmaNumber == 1 ? 'الأولى' : 'الثانية'}",
                  style: GoogleFonts.cairo(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF6BA598),
                  ),
                ),
                SizedBox(width: 8.w),
                Icon(
                  Icons.star,
                  color: const Color(0xFF6BA598),
                  size: 20.sp,
                ),
              ],
            ),
          ),
          SizedBox(height: 12.h),
        ],

        // Juz Grid
        GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: 30,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            crossAxisSpacing: 6.w,
            mainAxisSpacing: 6.h,
            childAspectRatio: 0.9,
          ),
          itemBuilder: (context, index) {
            final juzNumber = startJuz + index;
            final displayJuzNumber = (index + 1); // Always display 1-30
            final isCompleted = _progress.completedJuzs[juzNumber] ?? false;

            return ScaleTransition(
              scale: Tween<double>(begin: 1.0, end: 1.1).animate(
                CurvedAnimation(
                  parent: _celebrationController,
                  curve: Curves.easeInOut,
                ),
              ),
              child: _buildJuzItem(juzNumber, isCompleted, displayJuzNumber),
            );
          },
        ),
      ],
    );
  }

  // Divider between khatmas
  Widget _buildKhatmaDivider() {
    // Calculate progress for each khatma
    int firstKhatmaCompleted = 0;
    int secondKhatmaCompleted = 0;

    for (int i = 1; i <= 30; i++) {
      if (_progress.completedJuzs[i] ?? false) firstKhatmaCompleted++;
      if (_progress.completedJuzs[i + 30] ?? false) secondKhatmaCompleted++;
    }

    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6BA598).withOpacity(0.1),
            const Color(0xFF4A8B7F).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: const Color(0xFF6BA598).withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildKhatmaProgress("الختمة الأولى", firstKhatmaCompleted),
          Container(
            width: 2,
            height: 40.h,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  const Color(0xFF6BA598).withOpacity(0.5),
                  Colors.transparent,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          _buildKhatmaProgress("الختمة الثانية", secondKhatmaCompleted),
        ],
      ),
    );
  }

  Widget _buildKhatmaProgress(String title, int completedCount) {
    return Column(
      children: [
        Text(
          title,
          style: GoogleFonts.cairo(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF6BA598),
          ),
        ),
        SizedBox(height: 4.h),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "$completedCount",
              style: GoogleFonts.cairo(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2F6B5F),
              ),
            ),
            Text(
              " / 30",
              style: GoogleFonts.cairo(
                fontSize: 14.sp,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildJuzItem(int juzNumber, bool isCompleted, [int? displayNumber]) {
    final display = displayNumber ?? juzNumber;
    return GestureDetector(
      onTap: () => _toggleJuz(juzNumber),
      child: Container(
        decoration: BoxDecoration(
          color: isCompleted ? const Color(0xFF6BA598) : Colors.white,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: isCompleted ? const Color(0xFF6BA598) : Colors.grey[300]!,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isCompleted
                  ? const Color(0xFF6BA598).withOpacity(0.2)
                  : Colors.grey.withOpacity(0.08),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "جزء",
                    style: GoogleFonts.cairo(
                      fontSize: 10.sp,
                      color: isCompleted ? Colors.white : Colors.grey[600],
                    ),
                  ),
                  Text(
                    "$display",
                    style: GoogleFonts.cairo(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: isCompleted ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            if (isCompleted)
              Positioned(
                top: 3,
                right: 3,
                child: Container(
                  padding: EdgeInsets.all(1.5.w),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    size: 12.sp,
                    color: const Color(0xFF6BA598),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

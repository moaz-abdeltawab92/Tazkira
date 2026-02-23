import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tazkira_app/features/ramadan_khatma/data/services/khatma_storage_service.dart';
import 'package:tazkira_app/features/ramadan_khatma/presentation/screens/khatma_tracking_screen.dart';

class KhatmaSelectionScreen extends StatefulWidget {
  const KhatmaSelectionScreen({super.key});

  @override
  State<KhatmaSelectionScreen> createState() => _KhatmaSelectionScreenState();
}

class _KhatmaSelectionScreenState extends State<KhatmaSelectionScreen> {
  int? selectedKhatmaCount;
  bool isLoading = false;

  Future<void> _startKhatma() async {
    if (selectedKhatmaCount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'الرجاء اختيار عدد الختمات',
            style: GoogleFonts.cairo(),
            textAlign: TextAlign.center,
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final progress =
          await KhatmaStorageService.createNewKhatma(selectedKhatmaCount!);

      if (!mounted) return;

      if (progress == null) {
        // Failed to create khatma
        setState(() {
          isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'حدث خطأ في إنشاء الختمة. حاول مرة أخرى',
                style: GoogleFonts.cairo(),
                textAlign: TextAlign.center,
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => KhatmaTrackingScreen(initialProgress: progress),
        ),
      );
    } catch (e) {
      // Handle any unexpected errors
      if (mounted) {
        setState(() {
          isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'حدث خطأ غير متوقع. حاول مرة أخرى',
              style: GoogleFonts.cairo(),
              textAlign: TextAlign.center,
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: const Color(0xFF6BA598), // Changed color
        automaticallyImplyLeading: false,
        title: Text(
          "ختمة رمضان",
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            fontSize: 24.sp,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(24.w),
                child: Column(
                  children: [
                    SizedBox(height: 20.h),

                    // Header Icon
                    Container(
                      padding: EdgeInsets.all(24.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6BA598).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.menu_book_rounded,
                        size: 80.sp,
                        color: const Color(0xFF6BA598),
                      ),
                    ),

                    SizedBox(height: 32.h),

                    // Title
                    Text(
                      "تنظيم قراءة القرآن الكريم",
                      style: GoogleFonts.cairo(
                        fontSize: 26.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    SizedBox(height: 16.h),

                    // Description
                    Text(
                      "اختر عدد الختمات التي تريد إتمامها في رمضان\nلتتبع تقدمك بسهولة",
                      style: GoogleFonts.cairo(
                        fontSize: 16.sp,
                        color: Colors.grey[600],
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    SizedBox(height: 48.h),

                    // Selection Cards
                    _buildKhatmaOption(
                      count: 1,
                      title: "ختمة واحدة",
                      description: "جزء واحد يومياً",
                      details: "30 يوم لإتمام الختمة",
                      icon: Icons.looks_one_rounded,
                      color: const Color(0xFF4A8B7F),
                    ),

                    SizedBox(height: 20.h),

                    _buildKhatmaOption(
                      count: 2,
                      title: "ختمتان",
                      description: "جزئين كل يوم",
                      details: "15 يوم لإتمام كل ختمة",
                      icon: Icons.looks_two_rounded,
                      color: const Color(0xFF2F6B5F),
                    ),

                    SizedBox(height: 48.h),

                    // Start Button
                    SizedBox(
                      width: double.infinity,
                      height: 56.h,
                      child: ElevatedButton(
                        onPressed: _startKhatma,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6BA598),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          elevation: 4,
                        ),
                        child: Text(
                          "ابدأ الختمة",
                          style: GoogleFonts.cairo(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 20.h),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildKhatmaOption({
    required int count,
    required String title,
    required String description,
    required String details,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = selectedKhatmaCount == count;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedKhatmaCount = count;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 3 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? color.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: isSelected ? color : Colors.grey[200],
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Icon(
                icon,
                size: 36.sp,
                color: isSelected ? Colors.white : Colors.grey[600],
              ),
            ),

            SizedBox(width: 16.w),

            // Text Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.cairo(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? color : Colors.black87,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    description,
                    style: GoogleFonts.cairo(
                      fontSize: 15.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    details,
                    style: GoogleFonts.cairo(
                      fontSize: 13.sp,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),

            // Check Icon
            if (isSelected)
              Container(
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check,
                  size: 20.sp,
                  color: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

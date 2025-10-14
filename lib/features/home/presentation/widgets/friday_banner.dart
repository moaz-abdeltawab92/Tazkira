import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

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

    return Container(
      width: double.infinity,
      height: 180.h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
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
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          // النقوش على اليمين
          Positioned(
            right: -10,
            top: -10,
            child: CustomPaint(
              size: Size(80.w, 160.h),
              painter: IslamicPatternPainter(),
            ),
          ),

          // النقوش على اليسار
          Positioned(
            left: -10,
            top: -10,
            child: CustomPaint(
              size: Size(80.w, 160.h),
              painter: IslamicPatternPainter(),
            ),
          ),

          // المحتوى
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 85.w, vertical: 16.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'جمعة مباركة',
                  textAlign: TextAlign.right,
                  style: GoogleFonts.cairo(
                    color: Color(0xFF2C5454),
                    fontSize: 17.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  "لا تنسَ قراءة سورة الكهف ",
                  textAlign: TextAlign.right,
                  style: GoogleFonts.cairo(
                    color: Color(0xFF5A8C8C),
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  'قال النبي ﷺ: "من قرأ سورة الكهف في يوم الجمعة أضاء له من النور ما بين الجمعتين"',
                  textAlign: TextAlign.right,
                  style: GoogleFonts.cairo(
                    color: Color(0xFF2C5454),
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
    );
  }
}

class IslamicPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // ألوان النقوش الإسلامية
    final orangeColor = Color(0xFFD4A574).withOpacity(0.25);
    final tealColor = Color(0xFF5A8C8C).withOpacity(0.2);
    final blueColor = Color(0xFF6B9999).withOpacity(0.18);

    // رسم نجمة في الأعلى
    paint.color = orangeColor;
    _drawStar(canvas, Offset(size.width * 0.5, size.height * 0.25), 20, paint);

    // رسم شكل هندسي في الوسط
    paint.color = tealColor;
    _drawDiamond(
        canvas, Offset(size.width * 0.5, size.height * 0.5), 25, paint);

    // رسم نجمة صغيرة في الأسفل
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

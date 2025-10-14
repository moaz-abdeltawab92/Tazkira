import 'package:tazkira_app/core/routing/route_export.dart';

class BottomSection extends StatelessWidget {
  const BottomSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF2A6B5C).withOpacity(0.85),
            const Color(0xFF1E4D42).withOpacity(0.90),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.15),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          // زخرفة علوية
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildDecoration(),
              SizedBox(width: 12.w),
              Icon(
                Icons.auto_awesome,
                color: Colors.amber.shade200,
                size: 20.sp,
              ),
              SizedBox(width: 12.w),
              _buildDecoration(),
            ],
          ),
          SizedBox(height: 12.h),

          // النص القرآني
          Text(
            "وَالذَّاكِرِينَ اللَّهَ كَثِيرًا وَالذَّاكِرَاتِ",
            textAlign: TextAlign.center,
            style: GoogleFonts.amiri(
              fontWeight: FontWeight.bold,
              fontSize: 20.sp,
              color: Colors.white,
              height: 1.8,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.3),
                  offset: const Offset(1, 1),
                  blurRadius: 3,
                ),
              ],
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            "أَعَدَّ اللَّهُ لَهُم مَّغْفِرَةً وَأَجْرًا عَظِيمًا",
            textAlign: TextAlign.center,
            style: GoogleFonts.amiri(
              fontWeight: FontWeight.bold,
              fontSize: 20.sp,
              color: Colors.white,
              height: 1.8,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.3),
                  offset: const Offset(1, 1),
                  blurRadius: 3,
                ),
              ],
            ),
          ),

          SizedBox(height: 12.h),
          // زخرفة سفلية
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildDecoration(),
              SizedBox(width: 12.w),
              Icon(
                Icons.auto_awesome,
                color: Colors.amber.shade200,
                size: 20.sp,
              ),
              SizedBox(width: 12.w),
              _buildDecoration(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDecoration() {
    return Container(
      width: 40.w,
      height: 2.h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.amber.shade200.withOpacity(0.3),
            Colors.amber.shade200,
            Colors.amber.shade200.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(2.r),
      ),
    );
  }
}

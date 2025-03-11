import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ImprovedCounter extends StatelessWidget {
  final int count;
  final VoidCallback onIncrement;
  final VoidCallback onReset;
  final String title;

  const ImprovedCounter({
    Key? key,
    required this.count,
    required this.onIncrement,
    required this.onReset,
    required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 25.sp,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 20.h),
        Container(
          padding: EdgeInsets.all(10.w),
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(10.r),
            boxShadow: [
              BoxShadow(
                color: const Color(0x80000000),
                spreadRadius: 5.r,
                blurRadius: 4.r,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Text(
            count.toString().padLeft(4, '0'),
            key: ValueKey<int>(count),
            style: TextStyle(
              fontSize: 60.sp,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(height: 20.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: onReset,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF727D73),
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: Text(
                "إعادة التعيين",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16.sp,
                ),
              ),
            ),
            SizedBox(width: 20.w),
            ElevatedButton(
              onPressed: onIncrement,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF727D73),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.r),
                ),
                padding: EdgeInsets.all(20.w),
              ),
              child: Icon(Icons.add, size: 24.sp),
            ),
          ],
        ),
      ],
    );
  }
}

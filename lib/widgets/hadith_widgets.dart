import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class HadithSectionTitle extends StatelessWidget {
  final String title;
  const HadithSectionTitle({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: const Color(0xff2D6A4F),
        borderRadius: BorderRadius.circular(12.r),
      ),
      alignment: Alignment.center,
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontSize: 18.sp,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class HadithCard extends StatelessWidget {
  final String hadith;
  const HadithCard({Key? key, required this.hadith}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: const Color(0xff4A4947),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Text(
        hadith,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontSize: 16.sp,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

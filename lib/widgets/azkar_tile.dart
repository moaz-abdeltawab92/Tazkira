import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

Widget buildAzkarTile(String zekr) {
  return Card(
    color: Colors.grey[350],
    elevation: 2,
    margin: EdgeInsets.symmetric(vertical: 8.h),
    child: Padding(
      padding: EdgeInsets.all(12.w),
      child: Text(
        zekr,
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    ),
  );
}

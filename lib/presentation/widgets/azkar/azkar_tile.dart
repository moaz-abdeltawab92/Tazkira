import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

Widget buildAzkarTile(String zekr) {
  return Container(
    width: double.infinity,
    constraints: BoxConstraints(
      maxWidth: 0.9.sw,
    ),
    child: Card(
      color: Colors.grey[350],
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 6.h, horizontal: 8.w),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
        child: Text(
          zekr,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    ),
  );
}

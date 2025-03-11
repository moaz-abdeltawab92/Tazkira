import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class Category extends StatelessWidget {
  final String text;
  final Color color;
  final String image;
  final Function()? onTap;

  const Category({
    required this.text,
    required this.color,
    required this.image,
    this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        elevation: 4,
        child: Container(
          width: 120.w,
          height: 131.h,
          padding: EdgeInsets.all(12.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              // Image.asset(
              //   image,
              //   height: 33.h,
              //   width: 42.w,
              //   fit: BoxFit.contain,
              // ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tazkira_app/lists/ad3ya_list.dart';

class Ad3yaScreen extends StatelessWidget {
  const Ad3yaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'أدعية',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 23.sp,
          ),
        ),
        backgroundColor: const Color(0xffD0DDD0),
      ),
      body: ListView.builder(
        itemCount: ad3yah.length,
        itemBuilder: (context, index) {
          return Column(
            children: [
              Container(
                padding: EdgeInsets.all(16.w),
                margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: const Color(0xff4A4947),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  ad3yah[index],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 18.sp,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Divider(
                color: Colors.grey,
                thickness: 1.5,
                height: 10.h,
                indent: 50.w,
                endIndent: 50.w,
              ),
            ],
          );
        },
      ),
    );
  }
}

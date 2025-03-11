import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tazkira_app/lists/azkar_masaa_list.dart';
import 'package:tazkira_app/lists/azkar_sabah_list.dart';
import 'package:tazkira_app/widgets/azkar_section.dart';

class AzkarScreen extends StatelessWidget {
  const AzkarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xffF0F0D7),
        title: Text(
          'أذكار الصباح والمساء',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 23.sp,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            Text(
              "أذكار الصباح والمساء درعٌ يحصّن الإنسان من الشرور، وسببٌ لجلب الطمأنينة والحفظ بذكر الله",
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            Divider(thickness: 3.h),
            Expanded(
              child: ListView(
                children: [
                  AzkarSection(title: "أذكار الصباح", azkarList: azkarAlsabah),
                  AzkarSection(title: "أذكار المساء", azkarList: azkarAlMasa),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

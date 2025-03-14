import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tazkira_app/data/azkar_masaa_list.dart';
import 'package:tazkira_app/data/azkar_sabah_list.dart';
import 'package:tazkira_app/presentation/widgets/azkar/azkar_section.dart';

class AzkarScreen extends StatelessWidget {
  const AzkarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: const Color(0xffD0DDD0),
            title: Text(
              'أذكار الصباح والمساء',
              style: GoogleFonts.tajawal(
                fontWeight: FontWeight.bold,
                fontSize: 24.sp,
                color: Colors.black,
              ),
            ),
            centerTitle: true,
            floating: true,
            pinned: true,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: Column(
                children: [
                  Text(
                    "أذكار الصباح والمساء درعٌ يحصّن الإنسان من الشرور، وسببٌ لجلب الطمأنينة والحفظ بذكر الله",
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Divider(
                    thickness: 2,
                    color: Colors.grey.shade400,
                    indent: 50.w,
                    endIndent: 50.w,
                  ),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate(
              [
                AzkarSection(title: "أذكار الصباح", azkarList: azkarAlsabah),
                SizedBox(height: 40.h),
                AzkarSection(title: "أذكار المساء", azkarList: azkarAlMasa),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tazkira_app/lists/hadith_list.dart';
import 'package:tazkira_app/widgets/hadith_widgets.dart';

class HadithScreen extends StatelessWidget {
  const HadithScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'الأحاديث النبوية',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 23.sp,
          ),
        ),
        backgroundColor: const Color(0xffD0DDD0),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: ListView.builder(
          itemCount: hadithSections.length,
          itemBuilder: (context, index) {
            String sectionTitle = hadithSections.keys.elementAt(index);
            List<String> hadiths = hadithSections[sectionTitle]!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HadithSectionTitle(title: sectionTitle),
                ...hadiths.map((hadith) => HadithCard(hadith: hadith)).toList(),
                Divider(
                  color: Colors.grey,
                  thickness: 1.5.h,
                  height: 20.h,
                  indent: 50.w,
                  endIndent: 50.w,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tazkira_app/presentation/screens/ad3ya_screen.dart';
import 'package:tazkira_app/presentation/screens/azkar_screen.dart';
import 'package:tazkira_app/presentation/screens/hadith_screen.dart';
import 'package:tazkira_app/presentation/screens/quran_screen.dart';
import 'package:tazkira_app/presentation/screens/track_prayers_screen.dart';
import 'package:tazkira_app/presentation/screens/sabha_screen.dart';
import 'package:tazkira_app/presentation/widgets/models/category_item.dart';

class AllCategories extends StatelessWidget {
  const AllCategories({super.key});

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> categories = [
      {
        "text": "سبحة الكترونية",
        "image": "assets/images/ا.png",
        "screen": const ZakrScreen(),
      },
      {
        "text": "قرآن كريم",
        "image": "assets/images/quran-home_page.png",
        "screen": const QuranScreen(),
      },
      {
        "text": "الادعية",
        "image": "assets/images/do3aa.png",
        "screen": const Ad3yaScreen(),
      },
      {
        "text": "اذكار الصباح والمساء",
        "image": "assets/images/saba7_massa_home_page.jpg",
        "screen": const AzkarScreen(),
      },
      {
        "text": "تتبع الصلوات",
        "image": "assets/images/d1bf485045fc2ba77a3c2cfb50e0ce59.jpg",
        "screen": const TrackPrayers(),
      },
      {
        "text": "احاديث نبوية",
        "image": "assets/images/hadiths_home_page.jpeg",
        "screen": const HadithScreen(),
      },
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: categories.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
          crossAxisSpacing: 5.w,
          mainAxisSpacing: 5.h,
          childAspectRatio: 1.4,
        ),
        itemBuilder: (context, index) {
          return Category(
            text: categories[index]["text"],
            color: const Color(0xffE4E4E4),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) {
                  return categories[index]["screen"];
                }),
              );
            },
          );
        },
      ),
    );
  }
}

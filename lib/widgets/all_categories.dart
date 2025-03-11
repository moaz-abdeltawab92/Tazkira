import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tazkira_app/screens/ad3ya_screen.dart';
import 'package:tazkira_app/screens/azkar_screen.dart';
import 'package:tazkira_app/screens/hadith_screen.dart';
import 'package:tazkira_app/screens/quran_screen.dart';
import 'package:tazkira_app/screens/track_prayers_screen.dart';
import 'package:tazkira_app/screens/sabha_screen.dart';
import 'package:tazkira_app/widgets/category_item.dart';

class AllCategories extends StatelessWidget {
  const AllCategories({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Category(
              text: "تسبيح",
              color: const Color(0xffE4E4E4),
              image: "assets/ا.png",
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return const ZakrScreen();
                }));
              },
            ),
            SizedBox(width: 10.w),
            Category(
              text: "قرآن كريم",
              color: const Color(0xffE4E4E4),
              image: "assets/quran-home_page.png",
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return const QuranScreen();
                }));
              },
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Category(
              text: "الادعية",
              color: const Color(0xffE4E4E4),
              image: "assets/do3aa.png",
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return const Ad3yaScreen();
                }));
              },
            ),
            SizedBox(width: 10.w),
            Category(
              text: "اذكار الصباح والمساء ",
              color: const Color(0xffE4E4E4),
              image: "assets/saba7_massa_home_page.jpg",
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return const AzkarScreen();
                }));
              },
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Category(
              text: "تتبع الصلوات",
              color: const Color(0xffE4E4E4),
              image: "assets/d1bf485045fc2ba77a3c2cfb50e0ce59.jpg",
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return const TrackPrayers();
                }));
              },
            ),
            SizedBox(width: 10.w),
            Category(
              text: " احاديث نبوية",
              color: const Color(0xffE4E4E4),
              image: "assets/hadiths_home_page.jpeg",
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return const HadithScreen();
                }));
              },
            ),
          ],
        ),
      ],
    );
  }
}

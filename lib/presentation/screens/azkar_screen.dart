import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tazkira_app/data/azkar_Istighfar_list.dart';
import 'package:tazkira_app/data/azkar_Istiqaz.dart';
import 'package:tazkira_app/data/azkar_Wudu.dart';
import 'package:tazkira_app/data/azkar_after_prayer.dart';
import 'package:tazkira_app/data/azkar_azan.dart';
import 'package:tazkira_app/data/azkar_home.dart';
import 'package:tazkira_app/data/azkar_masaa_list.dart';
import 'package:tazkira_app/data/azkar_masgd.dart';
import 'package:tazkira_app/data/azkar_sabah_list.dart';
import 'package:tazkira_app/data/azkar_shukr_list.dart';
import 'package:tazkira_app/data/azkar_sleep.dart';
import 'package:tazkira_app/presentation/widgets/azkar/azkar_section.dart';

class AzkarScreen extends StatefulWidget {
  const AzkarScreen({super.key});

  @override
  _AzkarScreenState createState() => _AzkarScreenState();
}

class _AzkarScreenState extends State<AzkarScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 11, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: const Color(0xffD0DDD0),
              title: Text(
                'جوامع الأذكار',
                style: GoogleFonts.tajawal(
                  fontWeight: FontWeight.bold,
                  fontSize: 24.sp,
                  color: Colors.black,
                ),
              ),
              centerTitle: true,
              floating: true,
              pinned: true,
              expandedHeight: 150.h, // Adjusted height
              flexibleSpace: FlexibleSpaceBar(
                background: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "  أنر قلبك بالأذكار اليومية",
                        style: GoogleFonts.tajawal(
                          fontWeight: FontWeight.bold,
                          fontSize: 18.sp,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              bottom: TabBar(
                labelColor: Colors.black,
                labelStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16.sp,
                ),
                unselectedLabelStyle: GoogleFonts.tajawal(
                  fontWeight: FontWeight.bold,
                  fontSize: 16.sp,
                ),
                unselectedLabelColor: Colors.grey[600],
                controller: _tabController,
                isScrollable: true,
                tabs: const [
                  Tab(text: 'أذكار الصباح'),
                  Tab(text: 'أذكار المساء'),
                  Tab(text: 'أذكار وقت الاذان'),
                  Tab(text: 'اذكار الذهاب إلى المسجد'),
                  Tab(text: 'الاذكار المفروضة بعد الصلاة'),
                  Tab(text: 'أذكار النوم'),
                  Tab(text: 'أذكار الاستغفار'),
                  Tab(text: 'أذكار دخول وخروج المنزل'),
                  Tab(text: 'أذكار الاستيقاظ'),
                  Tab(text: 'أذكار عن فضل الذكر والشكر'),
                  Tab(text: 'أذكار بعد الفراغ من الوضوء'),
                ],
              ),
            ),
            SliverFillRemaining(
              child: TabBarView(
                controller: _tabController,
                children: [
                  SingleChildScrollView(
                    // Add scrolling for the content
                    child: AzkarSection(
                      title: "أذكار الصباح",
                      azkarList: azkarAlsabah,
                    ),
                  ),
                  SingleChildScrollView(
                    // Add scrolling for the content
                    child: AzkarSection(
                      title: "أذكار المساء",
                      azkarList: azkarAlMasa,
                    ),
                  ),
                  SingleChildScrollView(
                    // Add scrolling for the content
                    child: AzkarSection(
                      title: "أذكار وقت الاذان",
                      azkarList: azkarAzan,
                    ),
                  ),
                  SingleChildScrollView(
                    // Add scrolling for the content
                    child: AzkarSection(
                        title: "أذكار الذهاب إلى المسجد",
                        azkarList: azkarMasgd),
                  ),
                  SingleChildScrollView(
                    // Add scrolling for the content
                    child: AzkarSection(
                        title: "الاذكار المفروضة بعد الصلاة",
                        azkarList: azkarAfterPrayer),
                  ),
                  SingleChildScrollView(
                    // Add scrolling for the content
                    child: AzkarSection(
                      title: "أذكار النوم",
                      azkarList: azkarSleep,
                    ),
                  ),
                  SingleChildScrollView(
                    // Add scrolling for the content
                    child: AzkarSection(
                      title: "أذكار الاستغفار",
                      azkarList: azkarIstighfar,
                    ),
                  ),
                  SingleChildScrollView(
                    // Add scrolling for the content
                    child: AzkarSection(
                      title: "أذكار دخول وخروج المنزل",
                      azkarList: azkarHome,
                    ),
                  ),
                  SingleChildScrollView(
                    // Add scrolling for the content
                    child: AzkarSection(
                      title: "أذكار الاستيقاظ",
                      azkarList: azkarIstiqaz,
                    ),
                  ),
                  SingleChildScrollView(
                    // Add scrolling for the content
                    child: AzkarSection(
                        title: "أذكار عن فضل الذكر والشكر",
                        azkarList: azkarShukrDhikr),
                  ),
                  SingleChildScrollView(
                    // Add scrolling for the content
                    child: AzkarSection(
                        title: "اذكار بعد الفراغ من الوضوء",
                        azkarList: azkarWudu),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

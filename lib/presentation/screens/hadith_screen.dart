import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tazkira_app/data/hadith_list.dart';
import 'package:tazkira_app/presentation/widgets/hadith/hadith_widgets.dart';

class HadithScreen extends StatefulWidget {
  const HadithScreen({super.key});

  @override
  State<HadithScreen> createState() => _HadithScreenState();
}

class _HadithScreenState extends State<HadithScreen> {
  final ScrollController _scrollController = ScrollController();
  List<MapEntry<String, List<String>>> displayedHadithSections = [];
  int currentLength = 3;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    displayedHadithSections =
        hadithSections.entries.take(currentLength).toList();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      loadMore();
    }
  }

  void loadMore() {
    if (isLoading) return;

    setState(() => isLoading = true);

    Future.delayed(Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          int nextLength = currentLength + 3;
          if (nextLength > hadithSections.length) {
            nextLength = hadithSections.length;
          }
          displayedHadithSections =
              hadithSections.entries.take(nextLength).toList();
          currentLength = nextLength;
          isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: const Color(0xffD0DDD0),
        title: Text(
          'الأحاديث النبوية',
          style: GoogleFonts.tajawal(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 24.sp,
          ),
        ),
      ),
      body: ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.symmetric(vertical: 8.h),
        itemCount: displayedHadithSections.length + (isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == displayedHadithSections.length) {
            return Center(child: CircularProgressIndicator());
          }

          String sectionTitle = displayedHadithSections[index].key;
          List<String> hadiths = displayedHadithSections[index].value;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(vertical: 3.h),
                child: HadithSectionTitle(title: sectionTitle),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: hadiths.length,
                itemBuilder: (context, i) => HadithCard(hadith: hadiths[i]),
              ),
              Divider(
                color: Colors.grey,
                thickness: 3.h,
                height: 20.h,
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

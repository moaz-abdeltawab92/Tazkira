import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tazkira_app/data/ad3ya_list.dart';

class Ad3yaScreen extends StatefulWidget {
  const Ad3yaScreen({super.key});

  @override
  State<Ad3yaScreen> createState() => _Ad3yaScreenState();
}

class _Ad3yaScreenState extends State<Ad3yaScreen> {
  List<String> displayedAd3ya = [];
  int currentLength = 10;
  late ScrollController _scrollController;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    displayedAd3ya = ad3yah.take(currentLength).toList();
    _scrollController = ScrollController()..addListener(_scrollListener);
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 100 &&
        !isLoading) {
      loadMore();
    }
  }

  void loadMore() async {
    if (currentLength >= ad3yah.length) return;

    setState(() => isLoading = true);

    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      int nextLength = currentLength + 10;
      if (nextLength > ad3yah.length) {
        nextLength = ad3yah.length;
      }
      displayedAd3ya = ad3yah.take(nextLength).toList();
      currentLength = nextLength;
      isLoading = false;
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
        title: Text(
          'أدعية',
          style: GoogleFonts.tajawal(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 24.sp,
          ),
        ),
        backgroundColor: const Color(0xffD0DDD0),
      ),
      body: ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.symmetric(vertical: 16.h),
        itemCount: displayedAd3ya.length + (isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == displayedAd3ya.length) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 10.h),
              child: const Center(child: CircularProgressIndicator()),
            );
          }
          return Container(
            padding: EdgeInsets.all(14.w),
            margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: const Color(0xff5A6C57),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text(
              displayedAd3ya[index],
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 17.sp,
              ),
              textAlign: TextAlign.center,
            ),
          );
        },
      ),
    );
  }
}

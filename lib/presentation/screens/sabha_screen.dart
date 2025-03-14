import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tazkira_app/data/tasbeeh_list.dart';
import 'package:tazkira_app/presentation/widgets/counter/counter_item.dart';

class ZakrScreen extends StatelessWidget {
  const ZakrScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xffD0DDD0),
        title: Text(
          "فَاذْكُرُونِي أَذْكُرْكُمْ",
          style: GoogleFonts.tajawal(
            fontWeight: FontWeight.bold,
            fontSize: 24.sp,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      backgroundColor: const Color.fromARGB(255, 69, 81, 99),
      body: Padding(
        padding: EdgeInsets.all(20.w),
        child: ListView.separated(
          itemCount: azkarList.length,
          separatorBuilder: (context, index) => Divider(
            color: Colors.grey,
            thickness: 2.h,
            height: 20.h,
          ),
          itemBuilder: (context, index) {
            return CounterItem(index: index);
          },
        ),
      ),
    );
  }
}

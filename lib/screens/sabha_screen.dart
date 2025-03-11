import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tazkira_app/lists/tasbeeh_list.dart';
import 'package:tazkira_app/widgets/counter_item.dart';

class ZakrScreen extends StatelessWidget {
  const ZakrScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF727D73),
        title: Text(
          "فَاذْكُرُونِي أَذْكُرْكُمْ",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22.sp,
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

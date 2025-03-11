import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tazkira_app/widgets/azkar_tile.dart';

class AzkarSection extends StatelessWidget {
  final String title;
  final List<String> azkarList;

  const AzkarSection({Key? key, required this.title, required this.azkarList})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 10.h),
        ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: azkarList.length,
          itemBuilder: (context, index) {
            return buildAzkarTile(azkarList[index]);
          },
        ),
        SizedBox(height: 20.h),
        Divider(thickness: 3.h),
        SizedBox(height: 20.h),
      ],
    );
  }
}

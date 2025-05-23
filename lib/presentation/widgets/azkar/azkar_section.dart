import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tazkira_app/presentation/widgets/azkar/azkar_tile.dart';

class AzkarSection extends StatelessWidget {
  final String title;
  final List<String> azkarList;

  const AzkarSection({Key? key, required this.title, required this.azkarList})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
          child: Text(
            title,
            style: GoogleFonts.rubik(
              fontSize: screenWidth < 350 ? 20.sp : 23.sp,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            softWrap: true,
          ),
        ),
        SizedBox(height: 10.h),
        ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: azkarList.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.03),
              child: buildAzkarTile(azkarList[index]),
            );
          },
        ),
        SizedBox(height: 20.h),
        Divider(thickness: 3.h, color: Colors.grey[400]),
        SizedBox(height: 20.h),
      ],
    );
  }
}

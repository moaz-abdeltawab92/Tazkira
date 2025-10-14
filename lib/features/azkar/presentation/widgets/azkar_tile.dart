import 'package:tazkira_app/core/routing/route_export.dart';

Widget buildAzkarTile(String zekr) {
  return Container(
    width: double.infinity,
    constraints: BoxConstraints(
      maxWidth: 0.9.sw,
    ),
    child: Card(
      color: const Color(0xFFF9F5EC),
      elevation: 6,
      margin: EdgeInsets.symmetric(vertical: 8.h, horizontal: 10.w),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(25.r),
        side: BorderSide(color: Colors.green.shade200, width: 1.5),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 20.w),
        child: Text(
          zekr,
          style: GoogleFonts.tajawal(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    ),
  );
}

import 'package:tazkira_app/core/routing/route_export.dart';

class Category extends StatelessWidget {
  final String text;
  final Color color;
  final Function()? onTap;

  const Category({
    required this.text,
    required this.color,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        elevation: 4,
        child: Container(
          constraints: BoxConstraints(
            minWidth: 100.w,
            maxWidth: 130.w,
            minHeight: 110.h,
            maxHeight: 140.h,
          ),
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 12.h),
          child: Center(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

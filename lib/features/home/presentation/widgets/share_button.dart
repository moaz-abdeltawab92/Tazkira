import 'package:tazkira_app/core/routing/route_export.dart';

class ShareButton extends StatelessWidget {
  const ShareButton({super.key});
  void _showShareDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) {
        return const ShareAppDialog();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        gradient: const LinearGradient(
          colors: [Color(0xFF2A6B5C), Color(0xFF6DBE9F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 6,
            offset: Offset(2, 3),
          )
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: () => _showShareDialog(context),
        icon: Icon(Icons.share_rounded, size: 22.sp, color: Colors.white),
        label: Text(
          'مشاركة التطبيق',
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            fontSize: 16.sp,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 14.h),
        ),
      ),
    );
  }
}

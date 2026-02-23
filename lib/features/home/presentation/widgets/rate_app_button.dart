import 'package:tazkira_app/core/routing/route_export.dart';

class RateAppButton extends StatelessWidget {
  const RateAppButton({super.key});

  Future<void> _rateApp(BuildContext context) async {
    final InAppReview inAppReview = InAppReview.instance;

    try {
      if (await inAppReview.isAvailable()) {
        await inAppReview.requestReview();
      } else {
        await inAppReview.openStoreListing(
          appStoreId: '6757756421',
        );
      }
    } catch (e) {
      try {
        final Uri uri;
        if (Platform.isIOS) {
          uri = Uri.parse(
              'https://apps.apple.com/eg/app/تذكرة-رفيق-المسلم-اليومي/id6757756421');
        } else {
          uri = Uri.parse(
              'https://play.google.com/store/apps/details?id=com.moaz.tazkira');
        }

        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.red,
              content: Text(
                'حدث خطأ في فتح متجر التطبيقات',
                style: GoogleFonts.cairo(fontSize: 14.sp),
              ),
            ),
          );
        }
      }
    }
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
        onPressed: () => _rateApp(context),
        icon: Icon(Icons.star_rounded, size: 22.sp, color: Colors.white),
        label: Text(
          'تقييم التطبيق',
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

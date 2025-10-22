import 'package:tazkira_app/core/routing/route_export.dart';

class ShareAppDialog extends StatelessWidget {
  static const playStoreLink =
      'https://play.google.com/store/apps/details?id=com.moaz.tazkira';
  const ShareAppDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      backgroundColor: Colors.white,
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.share_rounded,
                color: const Color(0xFF2A6B5C), size: 40.sp),
            SizedBox(height: 10.h),
            Text(
              'شارك التطبيق ',
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.bold,
                fontSize: 18.sp,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 15.h),
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      playStoreLink,
                      style: TextStyle(color: Colors.black54, fontSize: 14.sp),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.copy,
                        color: const Color(0xFF2A6B5C), size: 20.sp),
                    onPressed: () async {
                      await Clipboard.setData(
                          const ClipboardData(text: playStoreLink));
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            backgroundColor: const Color(0xFF2A6B5C),
                            content: Text('تم نسخ الرابط بنجاح ',
                                style: GoogleFonts.cairo(fontSize: 14.sp))),
                      );
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2A6B5C),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r)),
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
              ),
              onPressed: () {
                Share.share(playStoreLink);
                Navigator.pop(context);
              },
              icon: Icon(Icons.send_rounded, color: Colors.white, size: 18.sp),
              label: Text(
                'مشاركة الآن',
                style: GoogleFonts.cairo(color: Colors.white, fontSize: 16.sp),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

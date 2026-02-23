import 'package:tazkira_app/core/routing/route_export.dart';

class PodcastCardWidget extends StatelessWidget {
  const PodcastCardWidget({super.key});
  Future<void> _openUrl(String url, BuildContext context) async {
    try {
      final uri = Uri.parse(url);

      // Try to launch with external application first (for YouTube app)
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        // Fallback to platform default (browser)
        await launchUrl(
          uri,
          mode: LaunchMode.platformDefault,
        );
      }
    } catch (e) {
      // If all fails, try with in-app web view as last resort
      try {
        final uri = Uri.parse(url);
        await launchUrl(
          uri,
          mode: LaunchMode.inAppWebView,
        );
      } catch (e) {
        // Show error to user
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('لا يمكن فتح الرابط: $url'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        podcasts.length,
        (index) {
          final podcast = podcasts[index];
          return Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: GestureDetector(
              onTap: () => _openUrl(podcast.url, context),
              child: Container(
                height: 85.h,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      Color(0xFF5A8C8C),
                      Color(0xFF7CB9AD),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20.r),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF5A8C8C).withOpacity(0.3),
                      blurRadius: 12.r,
                      offset: Offset(0, 4.h),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    SizedBox(width: 12.w),
                    // Image on the right
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14.r),
                      child: Container(
                        width: 65.w,
                        height: 65.h,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4.r,
                            )
                          ],
                        ),
                        child: Image.asset(
                          podcast.imagePath,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    SizedBox(width: 16.w),
                    // Title and play icon
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              podcast.title,
                              textAlign: TextAlign.right,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.tajawal(
                                fontWeight: FontWeight.w600,
                                fontSize: 15.sp,
                                color: Colors.white,
                                height: 1.3,
                              ),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Container(
                            padding: EdgeInsets.all(8.w),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 24.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 12.w),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

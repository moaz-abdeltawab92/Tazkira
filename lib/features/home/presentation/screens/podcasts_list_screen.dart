import 'package:tazkira_app/core/routing/route_export.dart';
import 'package:tazkira_app/features/home/presentation/widgets/suggest_podcast_bottom_sheet.dart';

class PodcastsListScreen extends StatelessWidget {
  const PodcastsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          elevation: 0,
          automaticallyImplyLeading: false,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF7CB9AD), Color(0xFF5A9A8E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          title: Text(
            'البودكاستات والقنوات',
            style: GoogleFonts.cairo(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 22.sp,
            ),
          ),
          leading: Directionality(
            textDirection: TextDirection.ltr,
            child: IconButton(
              icon: const Icon(Icons.arrow_forward_ios_rounded,
                  color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        body: Container(
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF5A9A8E),
                Color(0xFF7CB9AD),
                Color(0xFFB8DDD5),
                Color(0xFFE8F5F3),
                Color(0xFFF5FFFE),
              ],
              stops: [0.0, 0.25, 0.5, 0.75, 1.0],
            ),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () => SuggestPodcastBottomSheet.show(context),
                    child: Container(
                      margin: EdgeInsets.only(bottom: 16.h),
                      padding: EdgeInsets.symmetric(
                          horizontal: 16.w, vertical: 12.h),
                      decoration: BoxDecoration(
                        color: const Color(0xEBFFFFFF),
                        borderRadius: BorderRadius.circular(16.r),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0x0F000000),
                            blurRadius: 10.r,
                            offset: Offset(0, 4.h),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8.w),
                            decoration: const BoxDecoration(
                              color: Color(0x265A9A8E),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.lightbulb_outline_rounded,
                              color: const Color(0xFF5A9A8E),
                              size: 22.sp,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'تعرف بودكاست او قناة تفيد بيها الناس؟',
                                  style: GoogleFonts.cairo(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF2C4A45),
                                  ),
                                ),
                                Text(
                                  'اقترحها علينا دلوقتي ونتشارك كلنا الثواب',
                                  style: GoogleFonts.tajawal(
                                    fontSize: 12.sp,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 16.sp,
                            color: const Color(0xFF5A9A8E),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const PodcastCardWidget(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

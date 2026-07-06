import 'package:tazkira_app/core/routing/route_export.dart';

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
              child: const PodcastCardWidget(),
            ),
          ),
        ),
      ),
    );
  }
}

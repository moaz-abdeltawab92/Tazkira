import 'package:tazkira_app/core/routing/route_export.dart';

class PodcastsPage extends StatelessWidget {
  const PodcastsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          // keep the AppBar minimal (no page title as requested)
          appBar: AppBar(
            backgroundColor: const Color.fromARGB(255, 175, 197, 195),
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.black),
          ),
          body: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/back_ground.jpg'),
                fit: BoxFit.cover,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0.w, vertical: 12.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // internal section header (matches screenshot style)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          'البودكاستات والقنوات المقترحة',
                          style: GoogleFonts.cairo(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),

                  // nicer podcast cards horizontally
                  const PodcastCardWidget(),
                  SizedBox(height: 18.h),

                  // share button
                  const ShareButton(),

                  SizedBox(height: 18.h),

                  // bottom rounded contact card with circular social icons (styled like screenshot)
                  const ContactMeSection(),
                ],
              ),
            ),
          ),
        ));
  }
}

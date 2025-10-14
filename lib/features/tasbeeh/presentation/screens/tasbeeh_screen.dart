import 'package:tazkira_app/core/routing/route_export.dart';

class SabhaScreen extends StatelessWidget {
  const SabhaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
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
          "فَاذْكُرُونِي أَذْكُرْكُمْ",
          style: GoogleFonts.cairo(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22.sp,
          ),
        ),
      ),
      backgroundColor: const Color(0xFFF5F7F5),
      body: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: ListView.builder(
          itemCount: azkarList.length,
          itemBuilder: (context, index) {
            return CounterItem(index: index);
          },
        ),
      ),
    );
  }
}

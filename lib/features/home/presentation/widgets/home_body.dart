import 'package:tazkira_app/core/routing/route_export.dart';

class HomeBody extends StatelessWidget {
  const HomeBody({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double spacing = constraints.maxHeight * 0.02;
        return SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Column(
              children: [
                SizedBox(height: spacing),
                const FridayBanner(),
                if (DateTime.now().weekday == DateTime.friday)
                  SizedBox(height: spacing),
                const PrayerTimesCard(),
                SizedBox(height: spacing),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30.r),
                  ),
                  child: const AllCategories(),
                ),
                SizedBox(height: constraints.maxHeight * 0.015),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: const BottomSection(),
                ),
                SizedBox(height: spacing),
              ],
            ),
          ),
        );
      },
    );
  }
}

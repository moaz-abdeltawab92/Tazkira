import 'package:tazkira_app/core/routing/route_export.dart';
import 'package:tazkira_app/core/widgets/daily_quote_widget.dart';

// GlobalKey to preserve PrayerTimesCardsWidget state across rebuilds
final _prayerTimesKey = GlobalKey();

class HomeBody extends StatelessWidget {
  final GlobalKey? ramadanCategoryKey;

  const HomeBody({super.key, this.ramadanCategoryKey});

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
                  SizedBox(height: 16.h),
                SizedBox(height: 16.h),
                const HijriDateCard(),
                SizedBox(height: 16.h),
                PrayerTimesCardsWidget(key: _prayerTimesKey),
                SizedBox(height: spacing),
                const DailyQuoteWidget(),
                SizedBox(height: spacing),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30.r),
                  ),
                  child: AllCategories(ramadanCategoryKey: ramadanCategoryKey),
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

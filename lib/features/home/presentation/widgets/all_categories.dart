import 'package:tazkira_app/core/routing/route_export.dart';

class AllCategories extends StatelessWidget {
  const AllCategories({super.key});

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> categories = [
      {
        "text": "سبحة الكترونية",
        "screen": const SabhaScreen(),
      },
      {
        "text": "قرآن كريم",
        "screen": const MyQuranPage(),
      },
      {
        "text": "أسماء الله الحسنى",
        "screen": const AsmaAllahScreen(),
      },
      {
        "text": "الدعاء",
        "screen": const Ad3yaScreen(),
      },
      {
        "text": "الأذكار",
        "screen": const AzkarScreen(),
      },
      {
        "text": "تتبع الصلوات",
        "screen": const TrackPrayers(),
      },
      {
        "text": "احاديث نبوية",
        "screen": const HadithScreen(),
      },
      {
        "text": "اتجاه القبلة",
        "screen": const QiblahView(),
      },
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: categories.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
          crossAxisSpacing: 5.w,
          mainAxisSpacing: 5.h,
          childAspectRatio: 1.5,
        ),
        itemBuilder: (context, index) {
          return Category(
            text: categories[index]["text"],
            color: const Color(0xffE4E4E4),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) {
                  return categories[index]["screen"];
                }),
              );
            },
          );
        },
      ),
    );
  }
}

import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:tazkira_app/core/routing/route_export.dart';
import 'package:tazkira_app/core/utils/islamic_season_helper.dart';
import 'package:tazkira_app/core/utils/showcase_helper.dart';
import 'package:tazkira_app/features/ramadan_khatma/presentation/screens/ramadan_khatma_entry_point.dart';

class AllCategories extends StatelessWidget {
  final GlobalKey? ramadanCategoryKey;

  const AllCategories({super.key, this.ramadanCategoryKey});

  Future<List<Map<String, dynamic>>> _getCategories() async {
    List<Map<String, dynamic>> categories = [
      {
        "text": "قرآن كريم",
        "screen": const MyQuranPage(),
        "icon": Icons.menu_book_rounded,
      },
      {
        "text": " السنن النبوية",
        "screen": const SunanScreen(),
        "icon": Icons.library_books_rounded,
      },
      {
        "text": "تتبع الصلوات",
        "screen": const TrackPrayers(),
        "icon": Icons.task_alt,
      },
      {
        "text": "الأذكار",
        "screen": const AzkarScreen(),
        "icon": FontAwesomeIcons.moon,
      },
      {
        "text": "الدعاء",
        "screen": const Ad3yaScreen(),
        "icon": FontAwesomeIcons.personPraying,
      },
      {
        "text": "احاديث نبوية",
        "screen": const HadithScreen(),
        "icon": FontAwesomeIcons.bookOpen,
      },
      {
        "text": "أسماء الله الحسنى",
        "screen": const AsmaAllahScreen(),
        "icon": Icons.star_rounded,
      },
      {
        "text": "سبحة الكترونية",
        "screen": const SabhaScreen(),
        "icon": FontAwesomeIcons.dotCircle,
      },
      {
        "text": "اتجاه القبلة",
        "screen": const QiblahView(),
        "icon": FontAwesomeIcons.kaaba,
      },
    ];

    // Add Ramadan Khatma category at the top ONLY during Ramadan
    // Uses try-catch to prevent any crashes from date calculation
    try {
      final isRamadanPeriod =
          await IslamicSeasonHelper.isRamadanOrGracePeriod();
      if (isRamadanPeriod) {
        categories.insert(0, {
          "text": "ختمة رمضان",
          "screen": const RamadanKhatmaEntryPoint(),
          "icon": Icons.auto_stories_rounded,
          "showcaseKey": ramadanCategoryKey,
          // No custom color - uses default like other categories
        });
      }
    } catch (e) {
      // If any error occurs, silently skip adding Ramadan feature
      // This prevents crashes while keeping the app functional
      // ignore: avoid_print
      print('Error checking Ramadan period: $e');
    }

    return categories;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getCategories(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final categories = snapshot.data!;

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
              final category = categories[index];
              final showcaseKey = category["showcaseKey"] as GlobalKey?;

              final categoryWidget = Category(
                text: category["text"],
                icon: category["icon"],
                color: category["color"] ?? const Color(0xffE4E4E4),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) {
                      return category["screen"];
                    }),
                  );
                },
              );

              // Wrap in showcase if key is provided
              if (showcaseKey != null) {
                return AppShowcase(
                  showcaseKey: showcaseKey,
                  title: 'ميزة جديدة في رمضان! 🌙',
                  description:
                      'اختم القرآن في رمضان! تتبع تقدمك يومياً مع قسم "ختمة رمضان"',
                  targetBorderRadius: 16,
                  child: categoryWidget,
                );
              }

              return categoryWidget;
            },
          ),
        );
      },
    );
  }
}

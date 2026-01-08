import 'package:quran_library/quran.dart';
import 'package:tazkira_app/core/routing/route_export.dart';

class MyQuranPage extends StatefulWidget {
  const MyQuranPage({super.key});

  @override
  State<MyQuranPage> createState() => _MyQuranPageState();
}

class _MyQuranPageState extends State<MyQuranPage> {
  bool isDark = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Directionality(
          textDirection: TextDirection.rtl,
          child: QuranLibraryScreen(
            parentContext: context,
            isDark: isDark,
            appLanguageCode: 'ar',
            topBarStyle:
                QuranTopBarStyle.defaults(isDark: isDark, context: context)
                    .copyWith(
              showBackButton: true,
            ),
          ),
        ),
        Positioned(
          bottom: 15,
          left: 5,
          child: FloatingActionButton.small(
              onPressed: () {
                setState(() {
                  isDark = !isDark;
                });
              },
              backgroundColor: Colors.white,
              child: Icon(
                isDark ? Icons.light_mode : Icons.dark_mode,
                color: isDark ? Colors.amber : Colors.grey[800],
                size: 24,
              )),
        )
      ],
    );
  }
}

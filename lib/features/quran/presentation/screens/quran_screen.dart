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
        QuranLibraryScreen(
          parentContext: context,
          isDark: isDark,
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
            child: Text(
              isDark ? "☀️" : "🌙",
              style: TextStyle(
                fontSize: 20,
                color: isDark ? Colors.amber : Colors.grey[800],
              ),
            ),
          ),
        )
      ],
    );
  }
}

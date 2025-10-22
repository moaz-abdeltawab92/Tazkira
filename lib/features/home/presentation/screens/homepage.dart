import 'package:tazkira_app/core/routing/route_export.dart';
import 'package:in_app_update/in_app_update.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  @override
  void initState() {
    super.initState();
    checkForUpdate();
  }

  Future<void> checkForUpdate() async {
    try {
      final info = await InAppUpdate.checkForUpdate();

      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        await InAppUpdate.performImmediateUpdate();
      }
    } catch (e) {
      print("Error checking for update: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          backgroundColor: const Color.fromARGB(255, 175, 197, 195),
          title: Text(
            "تَذْكِرَة",
            style: GoogleFonts.tajawal(
              fontWeight: FontWeight.bold,
              fontSize: 24.sp.clamp(18, 28),
              color: Colors.black,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.menu, color: Colors.black),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const PodcastsPage(),
                ),
              );
            },
          ),
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: Container(
                width: double.infinity,
                height: constraints.maxHeight,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/back_ground.jpg'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: const HomeBody(),
              ),
            );
          },
        ),
      ),
    );
  }
}

import 'package:tazkira_app/core/routing/route_export.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Trigger check 5 seconds after app launch (not immediately)
    // This gives Play Store API time to initialize
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        AppUpdateService().checkForUpdate(context);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Trigger check when app resumes from background
      AppUpdateService().checkForUpdate(context);
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

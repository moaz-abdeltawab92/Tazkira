import 'package:seasonal_decor/seasonal_decor.dart';
import 'package:tazkira_app/core/routing/route_export.dart';
import 'package:tazkira_app/core/services/seasonal_greeting_service.dart';
import 'package:tazkira_app/core/utils/islamic_season_helper.dart';
import 'package:tazkira_app/core/utils/showcase_helper.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> with WidgetsBindingObserver {
  final GlobalKey _podcastButtonKey = GlobalKey();
  final GlobalKey _ramadanCategoryKey = GlobalKey();
  final ValueNotifier<int> _refreshTrigger = ValueNotifier<int>(0);

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

    ShowcaseHelper.startShowcase(
      context,
      [_podcastButtonKey],
      'home_podcasts_button',
    );

    // Show Ramadan category showcase if in Ramadan
    _checkAndShowRamadanShowcase();

    // Show seasonal greeting after a short delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        SeasonalGreetingService.checkAndShowGreeting(context);
      }
    });
  }

  Future<void> _checkAndShowRamadanShowcase() async {
    try {
      final isRamadan = await IslamicSeasonHelper.isRamadanOrGracePeriod();
      if (isRamadan && mounted) {
        ShowcaseHelper.startShowcase(
          context,
          [_ramadanCategoryKey],
          'ramadan_khatma_category',
        );
      }
    } catch (e) {
      // Silently ignore any errors
      // ignore: avoid_print
      print('Error checking Ramadan showcase: $e');
    }
  }

  @override
  void dispose() {
    _refreshTrigger.dispose();
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
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
    );

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );

    return Scaffold(
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
        leading: AppShowcase(
          showcaseKey: _podcastButtonKey,
          title: 'البودكاستات والقنوات المقترحة',
          description:
              "اضغط هنا للتحكم في الاشعارات والتعرف علي قنوات دينية مفيدة",
          targetBorderRadius: 25,
          child: IconButton(
            icon: const Icon(Icons.menu, color: Colors.black),
            onPressed: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const PodcastsPage(),
                ),
              );
              if (result == true && mounted) {
                _refreshTrigger.value++;
              }
            },
          ),
        ),
      ),
      body: ValueListenableBuilder<int>(
        valueListenable: _refreshTrigger,
        builder: (context, refreshValue, __) {
          return FutureBuilder<String?>(
            future: IslamicSeasonHelper.getCurrentSeason(),
            builder: (context, snapshot) {
              final currentSeason = snapshot.data;

              Widget bodyContent = LayoutBuilder(
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
                      child: HomeBody(
                        key: ValueKey(refreshValue),
                        ramadanCategoryKey: _ramadanCategoryKey,
                      ),
                    ),
                  );
                },
              );

              if (currentSeason == 'ramadan') {
                bodyContent = SeasonalDecor(
                  opacity: 0.7,
                  preset: SeasonalPreset.ramadan(),
                  child: bodyContent,
                );
              } else if (currentSeason == 'eid') {
                bodyContent = SeasonalDecor(
                  opacity: 0.7,
                  preset: SeasonalPreset.eid(),
                  child: bodyContent,
                );
              }

              return bodyContent;
            },
          );
        },
      ),
    );
  }
}

import 'package:tazkira_app/core/routing/route_export.dart';

class TrackPrayers extends StatefulWidget {
  const TrackPrayers({super.key});

  @override
  _TrackPrayersState createState() => _TrackPrayersState();
}

class _TrackPrayersState extends State<TrackPrayers> {
  late Map<String, bool> prayerStatus;

  @override
  void initState() {
    super.initState();
    prayerStatus = {for (var prayer in prayers) prayer: false};
    _loadPrayerStatus();
  }

  Future<void> _loadPrayerStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      prayerStatus = {
        for (var prayer in prayers) prayer: prefs.getBool(prayer) ?? false,
      };
    });
  }

  Future<void> _savePrayerStatus() async {
    final prefs = await SharedPreferences.getInstance();
    for (var prayer in prayers) {
      await prefs.setBool(prayer, prayerStatus[prayer] ?? false);
    }
  }

  void _togglePrayerStatus(String prayer, String nextPrayer) {
    setState(() {
      prayerStatus[prayer] = !(prayerStatus[prayer] ?? false);
    });

    _savePrayerStatus();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      bool allPreviousChecked = true;
      for (String p in prayers) {
        if (p == prayer) break;
        if (!(prayerStatus[p] ?? false)) {
          allPreviousChecked = false;
          break;
        }
      }

      if (allPreviousChecked && prayerStatus[prayer]!) {
        if (prayer == prayers.last) {
          _showNextPrayerAlert("");
        } else {
          _showNextPrayerAlert(nextPrayer);
        }
      }
    });
  }

  void _showNextPrayerAlert(String nextPrayer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
        title: Text("تنبيه",
            style: GoogleFonts.cairo(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 22.sp),
            textAlign: TextAlign.center),
        content: Padding(
          padding: EdgeInsets.symmetric(vertical: 10.h),
          child: Text(
            nextPrayer.isNotEmpty
                ? "الصلاة القادمة: $nextPrayer"
                : "ما شاء الله، أكملت صلواتك، أسأل الله أن يكتب لك بها الأجر العظيم",
            style:
                GoogleFonts.cairo(fontSize: 18.sp, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("متابعة",
                  style: GoogleFonts.tajawal(
                      fontSize: 18.sp, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _resetPrayers() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    setState(() {
      prayerStatus = {for (var prayer in prayers) prayer: false};
    });
  }

  double _getProgress() {
    int completedPrayers = prayerStatus.values.where((status) => status).length;
    return completedPrayers / prayers.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        automaticallyImplyLeading: false,
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
          "تتبع صلاتك",
          style: GoogleFonts.cairo(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22.sp,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 5.h),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(vertical: 20.h),
                child: Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF7D9D8C).withOpacity(0.3),
                        const Color(0xFF698876).withOpacity(0.3),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: const Color(0xFF7CB9AD).withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Text(
                    "قال رسول الله ﷺ:\n«أول ما يحاسب عليه العبد يوم القيامة الصلاة، فإن صلحت صلح سائر عمله، وإن فسدت فسد سائر عمله.»",
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style: GoogleFonts.amiri(
                      fontSize: 17.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2E4053),
                      height: 1.8,
                    ),
                  ),
                ),
              ),
              Text(
                'مؤشر لتتبع الصلاة',
                style: GoogleFonts.cairo(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10.h),
              LinearProgressIndicator(
                value: _getProgress(),
                minHeight: 8.h,
                backgroundColor: Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
              ),
              SizedBox(height: 20.h),
              SingleChildScrollView(
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: prayers.length,
                  itemBuilder: (context, index) {
                    String prayer = prayers[index];
                    String nextPrayer =
                        index < prayers.length - 1 ? prayers[index + 1] : "";

                    return Card(
                      color: const Color(0xffD0DDD0),
                      margin: EdgeInsets.symmetric(vertical: 8.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 12.w, vertical: 8.h),
                        child: Row(
                          children: [
                            Checkbox(
                              value: prayerStatus[prayer] ?? false,
                              onChanged: (bool? value) {
                                _togglePrayerStatus(prayer, nextPrayer);
                              },
                            ),
                            const Spacer(),
                            Text(
                              prayer,
                              style: GoogleFonts.amiri(
                                fontSize: 20.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 20.h),
              ElevatedButton(
                onPressed: _resetPrayers,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xffD0DDD0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  minimumSize: Size(double.infinity, 50.h),
                ),
                child: Text(
                  'ابدأ من الاول ',
                  style: GoogleFonts.cairo(
                    fontSize: 18.sp,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 30.h),
            ],
          ),
        ),
      ),
    );
  }
}

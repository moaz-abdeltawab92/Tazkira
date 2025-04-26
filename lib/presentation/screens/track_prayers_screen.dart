import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tazkira_app/data/paryers_list.dart';

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
            style: GoogleFonts.cabin(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'تتبع صلاتك',
          style: GoogleFonts.tajawal(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 24.sp),
        ),
        backgroundColor: const Color(0xffD0DDD0),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: 20.h),
              child: Text(
                "قال رسول الله ﷺ:\n«أول ما يحاسب عليه العبد يوم القيامة الصلاة، فإن صلحت صلح سائر عمله، وإن فسدت فسد سائر عمله.»",
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black),
              ),
            ),
            SizedBox(height: 10.h),
            Expanded(
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
                      padding:
                          EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
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
    );
  }
}

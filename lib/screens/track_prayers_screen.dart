import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tazkira_app/lists/paryers_list.dart';

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

    if (prayerStatus.values.every((isChecked) => isChecked)) {
      _showNextPrayerAlert("");
    } else if (prayerStatus[prayer]!) {
      _showNextPrayerAlert(nextPrayer);
    }
  }

  void _showNextPrayerAlert(String nextPrayer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "تنبيه",
          style: TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
            fontSize: 22.sp,
          ),
        ),
        content: Text(
          nextPrayer.isNotEmpty
              ? "الصلاة القادمة: $nextPrayer"
              : "ما شاء الله، أكملت صلواتك، أسأل الله أن يكتب لك بها الأجر العظيم",
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("متابعة", style: TextStyle(fontSize: 18.sp)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'تتبع صلاتك',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 23.sp,
          ),
        ),
        backgroundColor: const Color(0xffD0DDD0),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.r),
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
                  color: Colors.black,
                ),
              ),
            ),
            SizedBox(height: 10.h),
            Expanded(
              child: ListView.builder(
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
                    child: ListTile(
                      leading: Checkbox(
                        value: prayerStatus[prayer] ?? false,
                        onChanged: (bool? value) {
                          _togglePrayerStatus(prayer, nextPrayer);
                        },
                      ),
                      title: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          prayer,
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

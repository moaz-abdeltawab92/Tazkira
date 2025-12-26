import 'package:tazkira_app/core/routing/route_export.dart';

class TasbeehStatisticsPage extends StatefulWidget {
  const TasbeehStatisticsPage({super.key});

  @override
  State<TasbeehStatisticsPage> createState() => _TasbeehStatisticsPageState();
}

class _TasbeehStatisticsPageState extends State<TasbeehStatisticsPage> {
  Map<String, int> stats = {};
  int totalCount = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    int total = 0;
    Map<String, int> currentStats = {};

    for (var item in azkarList) {
      final title = item["title"];
      final count = prefs.getInt('tasbeeh_$title') ?? 0;
      currentStats[title] = count;
      total += count;
    }

    setState(() {
      stats = currentStats;
      totalCount = total;
      isLoading = false;
    });
  }

  Future<void> _resetAllStats() async {
    final prefs = await SharedPreferences.getInstance();

    // Show confirmation dialog first
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
        title: Text(
          "تصفير العدادات",
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: Text(
          "هل أنت متأكد من تصفير جميع العدادات؟",
          style: GoogleFonts.cairo(),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("إلغاء", style: GoogleFonts.cairo(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text("تصفير",
                style: GoogleFonts.cairo(
                    color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      for (var item in azkarList) {
        await prefs.remove('tasbeeh_${item["title"]}');
      }
      _loadStats();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "تم تصفير جميع العدادات بنجاح",
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: const Color(0xFF4A5D4F),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
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
          "إحصائيات التسبيح",
          style: GoogleFonts.cairo(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22.sp,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.delete_sweep_rounded, color: Colors.white),
          onPressed: _resetAllStats,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF7CB9AD)))
          : Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: ListView.builder(
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    itemCount: azkarList.length,
                    itemBuilder: (context, index) {
                      final title = azkarList[index]["title"];
                      final count = stats[title] ?? 0;
                      if (count == 0) return const SizedBox.shrink();

                      return Container(
                        margin: EdgeInsets.symmetric(vertical: 6.h),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 20.w, vertical: 8.h),
                          title: Text(
                            title,
                            style: GoogleFonts.amiri(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              height: 1.4,
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                          subtitle: Padding(
                            padding: EdgeInsets.only(top: 8.h),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  "مرات التسبيح: ",
                                  style: GoogleFonts.cairo(
                                      fontSize: 12.sp, color: Colors.grey[600]),
                                ),
                                Text(
                                  count.toString(),
                                  style: GoogleFonts.cairo(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF5A9A8E),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7CB9AD), Color(0xFF5A9A8E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7CB9AD).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            "إجمالي التسبيحات",
            style: GoogleFonts.cairo(
              color: Colors.white,
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            totalCount.toString(),
            style: GoogleFonts.cairo(
              color: Colors.white,
              fontSize: 42.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            "ما شاء الله لا قوة إلا بالله",
            style: GoogleFonts.amiri(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16.sp,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

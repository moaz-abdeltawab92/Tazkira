import 'package:tazkira_app/core/routing/route_export.dart';

class AzkarScreen extends StatefulWidget {
  const AzkarScreen({super.key});

  @override
  State<AzkarScreen> createState() => _AzkarScreenState();
}

class _AzkarScreenState extends State<AzkarScreen> {
  String? selectedCategory;
  final ScrollController _scrollController = ScrollController();

  final Map<String, List<String>> azkarCategories = {
    'أذكار الصباح': azkarAlsabah,
    'أذكار المساء': azkarAlMasa,
    'أذكار وقت الاذان': azkarAzan,
    'أذكار الذهاب إلى المسجد': azkarMasgd,
    'الاذكار المفروضة بعد الصلاة': azkarAfterPrayer,
    'أذكار النوم': azkarSleep,
    'أذكار الاستغفار': azkarIstighfar,
    'أذكار دخول وخروج المنزل': azkarHome,
    'أذكار الاستيقاظ': azkarIstiqaz,
    'أذكار عن فضل الذكر والشكر': azkarShukrDhikr,
    'أذكار بعد الفراغ من الوضوء': azkarWudu,
  };

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.symmetric(vertical: 12.h),
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'اختر نوع الأذكار',
                    style: GoogleFonts.cairo(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF3C4D40),
                    ),
                  ),
                  if (selectedCategory != null)
                    TextButton.icon(
                      onPressed: () {
                        setState(() => selectedCategory = null);
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.clear_rounded),
                      label: Text(
                        'مسح الفلتر',
                        style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            ),
            Divider(height: 1.h, color: Colors.grey.shade300),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(vertical: 8.h),
                itemCount: azkarCategories.length,
                itemBuilder: (context, index) {
                  String category = azkarCategories.keys.elementAt(index);
                  bool isSelected = category == selectedCategory;

                  return ListTile(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 20.w,
                      vertical: 4.h,
                    ),
                    leading: Icon(
                      isSelected
                          ? Icons.check_circle_rounded
                          : Icons.circle_outlined,
                      color: isSelected
                          ? const Color(0xFF4A5D4F)
                          : Colors.grey.shade400,
                    ),
                    title: Text(
                      category,
                      style: GoogleFonts.cairo(
                        fontSize: 16.sp,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w600,
                        color: isSelected
                            ? const Color(0xFF3C4D40)
                            : Colors.black87,
                      ),
                    ),
                    trailing: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF4A5D4F)
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        '${azkarCategories[category]!.length}',
                        style: GoogleFonts.cairo(
                          color: isSelected ? Colors.white : Colors.black54,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    onTap: () {
                      setState(() => selectedCategory = category);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
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
          'جوامع الأذكار',
          style: GoogleFonts.cairo(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22.sp,
          ),
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon:
                    const Icon(Icons.filter_list_rounded, color: Colors.white),
                onPressed: _showFilterDialog,
              ),
              if (selectedCategory != null)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8.w,
                    height: 8.h,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(width: 8.w),
        ],
      ),
      body: Column(
        children: [
          if (selectedCategory != null)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              color: const Color(0xFF4A5D4F).withOpacity(0.1),
              child: Row(
                children: [
                  Icon(
                    Icons.filter_alt_rounded,
                    size: 20.sp,
                    color: const Color(0xFF4A5D4F),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      selectedCategory!,
                      style: GoogleFonts.cairo(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF3C4D40),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      setState(() => selectedCategory = null);
                    },
                    child: Container(
                      padding: EdgeInsets.all(6.w),
                      decoration: const BoxDecoration(
                        color: Color(0xFF4A5D4F),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 16.sp,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: selectedCategory == null
                ? _buildAllAzkar()
                : _buildFilteredAzkar(),
          ),
        ],
      ),
    );
  }

  Widget _buildAllAzkar() {
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(vertical: 16.h),
      itemCount: azkarCategories.length,
      itemBuilder: (context, index) {
        String category = azkarCategories.keys.elementAt(index);
        List<String> azkarList = azkarCategories[category]!;

        return Column(
          children: [
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 20.w),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF4A5D4F),
                    Color(0xFF3C4D40),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      category,
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 18.sp,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                      softWrap: true,
                    ),
                  ),
                ],
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: azkarList.length,
              itemBuilder: (context, i) {
                return AzkarCardWithCopy(zekr: azkarList[i]);
              },
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 50.w, vertical: 16.h),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 2.h,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.grey.shade300.withOpacity(0.2),
                            Colors.grey.shade400,
                            Colors.grey.shade300.withOpacity(0.2),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12.w),
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      color: Colors.grey.shade400,
                      size: 18.sp,
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 2.h,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.grey.shade300.withOpacity(0.2),
                            Colors.grey.shade400,
                            Colors.grey.shade300.withOpacity(0.2),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilteredAzkar() {
    List<String> azkarList = azkarCategories[selectedCategory]!;

    return ListView.builder(
      padding: EdgeInsets.symmetric(vertical: 16.h),
      itemCount: azkarList.length,
      itemBuilder: (context, index) {
        return AzkarCardWithCopy(zekr: azkarList[index]);
      },
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

class AzkarCardWithCopy extends StatelessWidget {
  final String zekr;

  const AzkarCardWithCopy({super.key, required this.zekr});

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: zekr));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'تم نسخ الذكر',
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

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
      child: Card(
        color: const Color(0xFFF9F5EC),
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25.r),
          side: BorderSide(color: Colors.green.shade200, width: 1.5),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 20.w),
          child: Column(
            children: [
              Text(
                zekr,
                style: GoogleFonts.tajawal(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12.h),
              InkWell(
                onTap: () => _copyToClipboard(context),
                borderRadius: BorderRadius.circular(12.r),
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A5D4F).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: const Color(0xFF4A5D4F).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.copy_rounded,
                        color: const Color(0xFF4A5D4F),
                        size: 18.sp,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        'نسخ',
                        style: GoogleFonts.cairo(
                          color: const Color(0xFF4A5D4F),
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

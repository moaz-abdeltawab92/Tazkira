import 'package:tazkira_app/core/routing/route_export.dart';
import 'package:tazkira_app/core/utils/showcase_helper.dart';
import 'package:tazkira_app/features/azkar/presentation/data/azkar_safar.dart';
import 'package:tazkira_app/features/azkar/presentation/data/azkarfood.dart';
import 'package:tazkira_app/features/azkar/presentation/widgets/interactive_azkar_card.dart';
import 'package:tazkira_app/features/azkar/presentation/controllers/azkar_progress_manager.dart';
import 'package:tazkira_app/features/azkar/presentation/utils/azkar_parser.dart';

class AzkarScreen extends StatefulWidget {
  final String? initialCategory;
  const AzkarScreen({super.key, this.initialCategory});

  @override
  State<AzkarScreen> createState() => _AzkarScreenState();
}

class _AzkarScreenState extends State<AzkarScreen> {
  String? selectedCategory;
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = true;
  int _resetKey = 0; // Key to force rebuild of cards
  final GlobalKey _filterButtonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    if (widget.initialCategory != null) {
      selectedCategory = widget.initialCategory;
    }
    _initManager();

    ShowcaseHelper.startShowcase(
      context,
      [_filterButtonKey],
      'azkar_filter_button',
    );
  }

  Future<void> _initManager() async {
    await AzkarProgressManager().init();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _resetAndRefresh(String category) async {
    await AzkarProgressManager().resetCategory(category);
    if (mounted) {
      setState(() {
        _resetKey++;
      });
    }
  }

  void _checkCategoryCompletion(String category, List<String> azkarList) {
    if (AzkarProgressManager().isCategoryComplete(category)) return;

    bool allComplete = true;
    for (int i = 0; i < azkarList.length; i++) {
      final parsed = AzkarParser.parse(azkarList[i]);
      final current = AzkarProgressManager().getProgress(category, i);
      if (current < parsed.count) {
        allComplete = false;
        break;
      }
    }

    if (allComplete) {
      AzkarProgressManager().setCategoryComplete(category, true);
      // Show celebration dialog
      showAlert(
        context: context,
        title: "ما شاء الله",
        message: "أتممت $category بفضل الله.\nتقبل الله منك صالح الأعمال.",
        confirmText: "حسناً",
        onConfirm: () => _resetAndRefresh(category),
      );
    }
  }

  final Map<String, List<String>> azkarCategories = {
    'أذكار الصباح': azkarAlsabah,
    'أذكار المساء': azkarAlMasa,
    'أذكار وقت الاذان': azkarAzan,
    'أذكار الذهاب إلى المسجد': azkarMasgd,
    'الاذكار المفروضة بعد الصلاة': azkarAfterPrayer,
    'أذكار النوم': azkarSleep,
    'أذكار الاستغفار': azkarIstighfar,
    'أذكار دخول وخروج المنزل': azkarHome,
    'أذكار السفر': azkarTravel,
    'أذكار الاستيقاظ': azkarIstiqaz,
    'أذكار عن فضل الذكر والشكر': azkarShukrDhikr,
    'أذكار بعد الفراغ من الوضوء': azkarWudu,
    'أذكار قبل وبعد الطعام': azkarFood,
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
          'جوامع الأذكار',
          style: GoogleFonts.cairo(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22.sp,
          ),
        ),
        leading: AppShowcase(
          showcaseKey: _filterButtonKey,
          title: 'حدد نوع الذكر',
          description: 'اضغط هنا لاختيار نوع الذكر الذي تريد قراءته',
          targetBorderRadius: 25,
          child: Stack(
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
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (selectedCategory != null)
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                          horizontal: 16.w, vertical: 12.h),
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
                return InteractiveAzkarCard(
                  key: ValueKey('${category}_${i}_$_resetKey'),
                  rawText: azkarList[i],
                  category: category,
                  index: i,
                  onComplete: () =>
                      _checkCategoryCompletion(category, azkarList),
                );
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
    String category = selectedCategory!;
    List<String> azkarList = azkarCategories[category]!;

    return ListView.builder(
      padding: EdgeInsets.symmetric(vertical: 16.h),
      itemCount: azkarList.length,
      itemBuilder: (context, index) {
        return InteractiveAzkarCard(
          key: ValueKey('${category}_${index}_$_resetKey'),
          rawText: azkarList[index],
          category: category,
          index: index,
          onComplete: () => _checkCategoryCompletion(category, azkarList),
        );
      },
    );
  }

  @override
  void dispose() {
    AzkarProgressManager().clearAllProgress();
    _scrollController.dispose();
    super.dispose();
  }
}

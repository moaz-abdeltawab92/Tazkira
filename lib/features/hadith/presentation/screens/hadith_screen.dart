import 'package:tazkira_app/core/routing/route_export.dart';

class HadithScreen extends StatefulWidget {
  const HadithScreen({super.key});

  @override
  State<HadithScreen> createState() => _HadithScreenState();
}

class _HadithScreenState extends State<HadithScreen> {
  final ScrollController _scrollController = ScrollController();
  List<MapEntry<String, List<String>>> displayedHadithSections = [];
  Set<String> favoriteHadiths = {};
  String? selectedCategory;
  int currentLength = 3;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    _updateDisplayedSections();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = prefs.getStringList('favorite_hadiths') ?? [];
    setState(() {
      favoriteHadiths = favorites.toSet();
    });
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorite_hadiths', favoriteHadiths.toList());
  }

  void _toggleFavorite(String hadith) {
    setState(() {
      if (favoriteHadiths.contains(hadith)) {
        favoriteHadiths.remove(hadith);
      } else {
        favoriteHadiths.add(hadith);
      }
    });
    _saveFavorites();
  }

  void _updateDisplayedSections() {
    setState(() {
      if (selectedCategory == null) {
        displayedHadithSections =
            hadithSections.entries.take(currentLength).toList();
      } else {
        displayedHadithSections = hadithSections.entries
            .where((entry) => entry.key == selectedCategory)
            .toList();
      }
    });
  }

  void _onScroll() {
    if (selectedCategory != null) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      loadMore();
    }
  }

  void loadMore() {
    if (isLoading || selectedCategory != null) return;

    setState(() => isLoading = true);

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          int nextLength = currentLength + 3;
          if (nextLength > hadithSections.length) {
            nextLength = hadithSections.length;
          }
          currentLength = nextLength;
          _updateDisplayedSections();
          isLoading = false;
        });
      }
    });
  }

  void _showFavoritesScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HadithFavoritesScreen(
          favoriteHadiths: favoriteHadiths,
          onRemoveFavorite: (hadith) {
            _toggleFavorite(hadith);
          },
        ),
      ),
    ).then((_) => setState(() {}));
  }

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
                    'اختر القسم',
                    style: GoogleFonts.cairo(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF3C4D40),
                    ),
                  ),
                  if (selectedCategory != null)
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          selectedCategory = null;
                          currentLength = 3;
                          _updateDisplayedSections();
                        });
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
                itemCount: hadithSections.length,
                itemBuilder: (context, index) {
                  String category = hadithSections.keys.elementAt(index);
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
                        '${hadithSections[category]!.length}',
                        style: GoogleFonts.cairo(
                          color: isSelected ? Colors.white : Colors.black54,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    onTap: () {
                      setState(() {
                        selectedCategory = category;
                        _updateDisplayedSections();
                      });
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
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
          'الأحاديث النبوية',
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
                icon: const Icon(
                  Icons.favorite_rounded,
                ),
                onPressed: _showFavoritesScreen,
              ),
              if (favoriteHadiths.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: EdgeInsets.all(4.w),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${favoriteHadiths.length}',
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
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
                      'القسم: $selectedCategory',
                      style: GoogleFonts.cairo(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF3C4D40),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      setState(() {
                        selectedCategory = null;
                        currentLength = 3;
                        _updateDisplayedSections();
                      });
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
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.symmetric(vertical: 8.h),
              itemCount: displayedHadithSections.length + (isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == displayedHadithSections.length) {
                  return const Center(child: CircularProgressIndicator());
                }

                String sectionTitle = displayedHadithSections[index].key;
                List<String> hadiths = displayedHadithSections[index].value;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HadithSectionTitle(title: sectionTitle),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: hadiths.length,
                      itemBuilder: (context, i) {
                        String hadith = hadiths[i];
                        return HadithCard(
                          hadith: hadith,
                          isFavorite: favoriteHadiths.contains(hadith),
                          onFavoriteToggle: () => _toggleFavorite(hadith),
                        );
                      },
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 50.w,
                        vertical: 16.h,
                      ),
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
            ),
          ),
        ],
      ),
    );
  }
}

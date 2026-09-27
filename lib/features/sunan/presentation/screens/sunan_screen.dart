import 'dart:convert';
import 'package:tazkira_app/core/routing/route_export.dart';
import 'package:tazkira_app/features/my_favorites/data/models/favorite_item.dart';
import 'package:tazkira_app/features/my_favorites/data/models/favorite_item_type.dart';
import 'package:tazkira_app/features/my_favorites/data/services/favorite_id_helper.dart';
import 'package:tazkira_app/features/my_favorites/presentation/widgets/favorite_bookmark_button.dart';

class SunanScreen extends StatefulWidget {
  const SunanScreen({super.key});

  @override
  State<SunanScreen> createState() => _SunanScreenState();
}

class _SunanScreenState extends State<SunanScreen> {
  List<Sunnah> _allSunan = [];
  List<String> _categories = [];
  String? _selectedCategory;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSunan();
  }

  Future<void> _loadSunan() async {
    try {
      final sunan = await SunanService.loadSunan();
      final categories = SunanService.getCategories(sunan);

      setState(() {
        _allSunan = sunan;
        _categories = ['الكل', ...categories];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Sunnah> get _filteredSunan {
    if (_selectedCategory == null || _selectedCategory == 'الكل') {
      return _allSunan;
    }
    return SunanService.getSunanByCategory(_allSunan, _selectedCategory!);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Stack(
          children: [
            // Background
            Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/back_ground.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // Content
            SafeArea(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : CustomScrollView(
                      slivers: [
                        // Header & Category Filter Container (Scrolls away with page)
                        SliverToBoxAdapter(
                          child: Container(
                            margin: EdgeInsets.only(bottom: 12.h),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topRight,
                                end: Alignment.bottomLeft,
                                colors: [
                                  const Color(0xFF5A8C8C).withOpacity(0.95),
                                  const Color(0xFF7CB9AD).withOpacity(0.95),
                                ],
                              ),
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(24.r),
                                bottomRight: Radius.circular(24.r),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 8.r,
                                  offset: Offset(0, 4.h),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Padding(
                                  padding: EdgeInsets.fromLTRB(
                                      16.w, 16.h, 16.w, 4.h),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                                Icons.arrow_back_ios,
                                                color: Colors.white),
                                            onPressed: () =>
                                                Navigator.pop(context),
                                          ),
                                          SizedBox(width: 8.w),
                                          Text(
                                            'سنن مهجورة',
                                            style: GoogleFonts.cairo(
                                              fontSize: 24.sp,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const Spacer(),
                                        ],
                                      ),
                                      SizedBox(height: 4.h),
                                      Text(
                                        'سنن نبوية من حياة الرسول ﷺ',
                                        style: GoogleFonts.tajawal(
                                          fontSize: 14.sp,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Category Filter Chips
                                if (_categories.isNotEmpty)
                                  Container(
                                    height: 44.h,
                                    margin: EdgeInsets.only(
                                        top: 8.h, bottom: 12.h),
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 16.w),
                                      itemCount: _categories.length,
                                      itemBuilder: (context, index) {
                                        final category = _categories[index];
                                        final isSelected =
                                            _selectedCategory == category ||
                                                (_selectedCategory == null &&
                                                    category == 'الكل');

                                        return GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _selectedCategory = category;
                                            });
                                          },
                                          child: Container(
                                            margin: EdgeInsets.only(left: 8.w),
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 16.w,
                                                vertical: 6.h),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? Colors.white
                                                  : Colors.white
                                                      .withOpacity(0.2),
                                              borderRadius:
                                                  BorderRadius.circular(20.r),
                                              boxShadow: isSelected
                                                  ? [
                                                      BoxShadow(
                                                        color: Colors.black
                                                            .withOpacity(0.1),
                                                        blurRadius: 4.r,
                                                        offset: Offset(0, 2.h),
                                                      ),
                                                    ]
                                                  : null,
                                            ),
                                            child: Center(
                                              child: Text(
                                                category,
                                                style: GoogleFonts.cairo(
                                                  fontSize: 13.sp,
                                                  fontWeight: FontWeight.bold,
                                                  color: isSelected
                                                      ? const Color(0xFF2D5F5D)
                                                      : Colors.white,
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
                        ),

                        // Sunan Cards List or Empty View
                        if (_filteredSunan.isEmpty)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(
                              child: Text(
                                'لا توجد سنن',
                                style: GoogleFonts.cairo(
                                  fontSize: 16.sp,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          )
                        else
                          SliverPadding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 16.w, vertical: 4.h),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final sunnah = _filteredSunan[index];
                                  return _buildSunnahCard(sunnah);
                                },
                                childCount: _filteredSunan.length,
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSunnahCard(Sunnah sunnah) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5A8C8C).withOpacity(0.2),
            blurRadius: 10.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title with category badge
          Row(
            children: [
              Expanded(
                child: Text(
                  sunnah.title,
                  style: GoogleFonts.cairo(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2D5F5D),
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF5A8C8C),
                      Color(0xFF7CB9AD),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  sunnah.category,
                  style: GoogleFonts.tajawal(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              FavoriteBookmarkButton(
                item: FavoriteItem(
                  id: FavoriteIdHelper.forText(
                      '${sunnah.title}_${sunnah.description}'),
                  type: FavoriteItemType.sunan,
                  title: sunnah.title,
                  content: sunnah.description,
                  subtitle: sunnah.category,
                  savedAt: DateTime.now(),
                  extraData: jsonEncode({'evidence': sunnah.evidence}),
                ),
                activeColor: const Color(0xFF5A8C8C),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          // Description
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F9F8),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: const Color(0xFF5A8C8C).withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Text(
              sunnah.description,
              style: GoogleFonts.tajawal(
                fontSize: 15.sp,
                height: 1.8,
                color: const Color(0xFF2D5F5D),
              ),
            ),
          ),
          SizedBox(height: 12.h),

          // Evidence
          Row(
            children: [
              Icon(
                Icons.library_books,
                color: const Color(0xFF5A8C8C),
                size: 18.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'الدليل:',
                style: GoogleFonts.cairo(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF5A8C8C),
                ),
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  sunnah.evidence,
                  style: GoogleFonts.tajawal(
                    fontSize: 13.sp,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

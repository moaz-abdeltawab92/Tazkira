import 'package:tazkira_app/core/routing/route_export.dart';

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
              child: Column(
                children: [
                  // Header
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [
                          const Color(0xFF5A8C8C).withOpacity(0.9),
                          const Color(0xFF7CB9AD).withOpacity(0.9),
                        ],
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(30.r),
                        bottomRight: Radius.circular(30.r),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_forward_ios,
                                  color: Colors.white),
                              onPressed: () => Navigator.pop(context),
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
                        SizedBox(height: 12.h),
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

                  // Category Filter
                  if (!_isLoading && _categories.isNotEmpty)
                    Container(
                      height: 50.h,
                      margin: EdgeInsets.symmetric(vertical: 12.h),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final category = _categories[index];
                          final isSelected = _selectedCategory == category ||
                              (_selectedCategory == null && category == 'الكل');

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedCategory = category;
                              });
                            },
                            child: Container(
                              margin: EdgeInsets.only(left: 8.w),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16.w, vertical: 8.h),
                              decoration: BoxDecoration(
                                gradient: isSelected
                                    ? const LinearGradient(
                                        colors: [
                                          Color(0xFF5A8C8C),
                                          Color(0xFF7CB9AD),
                                        ],
                                      )
                                    : null,
                                color: isSelected
                                    ? null
                                    : Colors.white.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(20.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4.r,
                                    offset: Offset(0, 2.h),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  category,
                                  style: GoogleFonts.cairo(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? Colors.white
                                        : const Color(0xFF5A8C8C),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                  // Content
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _filteredSunan.isEmpty
                            ? Center(
                                child: Text(
                                  'لا توجد سنن',
                                  style: GoogleFonts.cairo(
                                    fontSize: 16.sp,
                                    color: Colors.white,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                padding: EdgeInsets.all(16.w),
                                itemCount: _filteredSunan.length,
                                itemBuilder: (context, index) {
                                  final sunnah = _filteredSunan[index];
                                  return _buildSunnahCard(sunnah);
                                },
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

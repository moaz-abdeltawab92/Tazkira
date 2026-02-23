import 'package:tazkira_app/core/routing/route_export.dart';

class Ad3yaScreen extends StatefulWidget {
  const Ad3yaScreen({super.key});

  @override
  State<Ad3yaScreen> createState() => _Ad3yaScreenState();
}

class _Ad3yaScreenState extends State<Ad3yaScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();
  List<String> displayedAd3ya = [];
  List<String> filteredAd3ya = [];
  Set<String> favoriteAd3ya = {};
  int currentLength = 10;
  late ScrollController _scrollController;
  late TextEditingController _searchController;
  bool isLoading = false;
  bool isSearching = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    displayedAd3ya = doaaList.take(currentLength).toList();
    filteredAd3ya = displayedAd3ya;
    _scrollController = ScrollController()..addListener(_scrollListener);
    _searchController = TextEditingController()..addListener(_onSearchChanged);
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = prefs.getStringList('favorite_ad3ya') ?? [];
    setState(() {
      favoriteAd3ya = favorites.toSet();
    });
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorite_ad3ya', favoriteAd3ya.toList());
  }

  void _toggleFavorite(String doaa) {
    setState(() {
      if (favoriteAd3ya.contains(doaa)) {
        favoriteAd3ya.remove(doaa);
      } else {
        favoriteAd3ya.add(doaa);
      }
    });
    _saveFavorites();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 100 &&
        !isLoading) {
      loadMore();
    }
  }

  void loadMore() async {
    if (currentLength >= doaaList.length) return;

    setState(() => isLoading = true);

    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      int nextLength = currentLength + 10;
      if (nextLength > doaaList.length) {
        nextLength = doaaList.length;
      }
      displayedAd3ya = doaaList.take(nextLength).toList();
      if (!isSearching) {
        filteredAd3ya = displayedAd3ya;
      }
      currentLength = nextLength;
      isLoading = false;
    });
  }

  void _showFavoritesScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Ad3yaFavoritesScreen(
          favoriteAd3ya: favoriteAd3ya,
          onRemoveFavorite: (doaa) {
            _toggleFavorite(doaa);
          },
        ),
      ),
    ).then((_) => setState(() {}));
  }

  Future<void> _shareAsImage(String doaa, int index) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                color: Color(0xFF7CB9AD),
              ),
              SizedBox(height: 16.h),
              Text(
                'جاري تحضير الصورة...',
                style: GoogleFonts.cairo(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      await Future.delayed(const Duration(milliseconds: 300));
      final imageBytes = await _screenshotController.captureFromWidget(
        Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            width: 800,
            padding: const EdgeInsets.all(48),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [Color(0xFF7CB9AD), Color(0xFF5A9A8E)],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'الدعاء',
                  style: GoogleFonts.cairo(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.15),
                        offset: const Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Flexible(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 32,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 680),
                            child: Text(
                              doaa,
                              style: GoogleFonts.cairo(
                                fontSize: 18,
                                height: 2,
                                color: const Color(0xFF2C3E50),
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'تمت المشاركة من تطبيق تَذْكِرَة',
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      final dir = await getTemporaryDirectory();
      final file =
          File('${dir.path}/دعاء_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(imageBytes);

      if (mounted) Navigator.of(context).pop();

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: 'دعاء من تطبيق تَذْكِرَة',
          sharePositionOrigin: const Rect.fromLTWH(0, 0, 1, 1),
        ),
      );
    } catch (e) {
      if (mounted) Navigator.of(context).pop();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء المشاركة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onSearchChanged() {
    // Cancel the previous timer
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    // Start a new timer
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        String searchText = _searchController.text.trim();
        if (searchText.isEmpty) {
          isSearching = false;
          filteredAd3ya = displayedAd3ya;
        } else {
          isSearching = true;
          filteredAd3ya =
              doaaList.where((doaa) => doaa.contains(searchText)).toList();
        }
      });
    });
  }

  void _clearSearch() {
    _debounce?.cancel();
    _searchController.clear();
    setState(() {
      isSearching = false;
      filteredAd3ya = displayedAd3ya;
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
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
          "الأدعية",
          style: GoogleFonts.cairo(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22.sp,
          ),
        ),
        leading: Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.favorite_rounded, color: Colors.white),
              onPressed: _showFavoritesScreen,
            ),
            if (favoriteAd3ya.isNotEmpty)
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
                    '${favoriteAd3ya.length}',
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
        leadingWidth: 56,
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: filteredAd3ya.isEmpty
          ? Column(
              children: [
                // Search Bar
                Container(
                  margin: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    textAlign: TextAlign.right,
                    style: GoogleFonts.cairo(
                      fontSize: 16.sp,
                      color: Colors.black87,
                    ),
                    decoration: InputDecoration(
                      hintText: '...ابحث عن دعاء',
                      hintStyle: GoogleFonts.cairo(
                        color: Colors.grey,
                        fontSize: 16.sp,
                      ),
                      prefixIcon: AnimatedOpacity(
                        opacity: _searchController.text.isNotEmpty ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: _clearSearch,
                        ),
                      ),
                      suffixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFF7CB9AD),
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 14.h,
                      ),
                    ),
                  ),
                ),
                if (isSearching)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'النتائج: ${filteredAd3ya.length}',
                          style: GoogleFonts.cairo(
                            fontSize: 14.sp,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64.sp,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          'لا توجد نتائج',
                          style: GoogleFonts.cairo(
                            fontSize: 18.sp,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : CustomScrollView(
              controller: isSearching ? null : _scrollController,
              slivers: [
                // Search Bar
                SliverToBoxAdapter(
                  child: Container(
                    margin: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      textAlign: TextAlign.right,
                      style: GoogleFonts.cairo(
                        fontSize: 16.sp,
                        color: Colors.black87,
                      ),
                      decoration: InputDecoration(
                        hintText: '...ابحث عن دعاء',
                        hintStyle: GoogleFonts.cairo(
                          color: Colors.grey,
                          fontSize: 16.sp,
                        ),
                        prefixIcon: AnimatedOpacity(
                          opacity:
                              _searchController.text.isNotEmpty ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 200),
                          child: IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: _clearSearch,
                          ),
                        ),
                        suffixIcon: const Icon(
                          Icons.search,
                          color: Color(0xFF7CB9AD),
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 14.h,
                        ),
                      ),
                    ),
                  ),
                ),
                // Results count when searching
                if (isSearching)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'النتائج: ${filteredAd3ya.length}',
                            style: GoogleFonts.cairo(
                              fontSize: 14.sp,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                SliverToBoxAdapter(child: SizedBox(height: 8.h)),
                // List items
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index == filteredAd3ya.length) {
                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 10.h),
                          child:
                              const Center(child: CircularProgressIndicator()),
                        );
                      }

                      String doaa = filteredAd3ya[index];

                      return Ad3yaCard(
                        doaa: doaa,
                        isFavorite: favoriteAd3ya.contains(doaa),
                        onFavoriteToggle: () => _toggleFavorite(doaa),
                        onShare: () => _shareAsImage(doaa, index),
                      );
                    },
                    childCount: filteredAd3ya.length +
                        (!isSearching && isLoading ? 1 : 0),
                  ),
                ),
              ],
            ),
    );
  }
}

// Card Widget
class Ad3yaCard extends StatefulWidget {
  final String doaa;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onShare;

  const Ad3yaCard({
    super.key,
    required this.doaa,
    this.isFavorite = false,
    this.onFavoriteToggle,
    this.onShare,
  });

  @override
  State<Ad3yaCard> createState() => _Ad3yaCardState();
}

class _Ad3yaCardState extends State<Ad3yaCard> {
  bool _isPressed = false;

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: widget.doaa));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'تم نسخ الدعاء',
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
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF7D9D8C).withOpacity(0.95),
                const Color(0xFF698876).withOpacity(0.95),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.doaa,
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 17.sp,
                  height: 1.8,
                ),
                textAlign: TextAlign.center,
                softWrap: true,
              ),
              SizedBox(height: 12.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ActionButton(
                    icon: Icons.copy_rounded,
                    label: 'نسخ',
                    onTap: _copyToClipboard,
                  ),
                  SizedBox(width: 12.w),
                  _ActionButton(
                    icon: widget.isFavorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    label: 'مفضل',
                    onTap: widget.onFavoriteToggle,
                    color: widget.isFavorite ? Colors.red.shade300 : null,
                  ),
                  SizedBox(width: 12.w),
                  _ActionButton(
                    icon: Icons.share_rounded,
                    label: 'مشاركة',
                    onTap: widget.onShare,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? color;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color ?? Colors.white,
              size: 18.sp,
            ),
            SizedBox(width: 6.w),
            Text(
              label,
              style: GoogleFonts.cairo(
                color: Colors.white,
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

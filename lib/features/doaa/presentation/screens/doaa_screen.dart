import 'package:tazkira_app/core/routing/route_export.dart';

class Ad3yaScreen extends StatefulWidget {
  const Ad3yaScreen({super.key});

  @override
  State<Ad3yaScreen> createState() => _Ad3yaScreenState();
}

class _Ad3yaScreenState extends State<Ad3yaScreen> {
  List<String> displayedAd3ya = [];
  Set<String> favoriteAd3ya = {};
  int currentLength = 10;
  late ScrollController _scrollController;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    displayedAd3ya = doaaList.take(currentLength).toList();
    _scrollController = ScrollController()..addListener(_scrollListener);
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
      body: ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.symmetric(vertical: 8.h),
        itemCount: displayedAd3ya.length + (isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == displayedAd3ya.length) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 10.h),
              child: const Center(child: CircularProgressIndicator()),
            );
          }

          String doaa = displayedAd3ya[index];

          return Ad3yaCard(
            doaa: doaa,
            isFavorite: favoriteAd3ya.contains(doaa),
            onFavoriteToggle: () => _toggleFavorite(doaa),
          );
        },
      ),
    );
  }
}

// Card Widget
class Ad3yaCard extends StatefulWidget {
  final String doaa;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;

  const Ad3yaCard({
    super.key,
    required this.doaa,
    this.isFavorite = false,
    this.onFavoriteToggle,
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

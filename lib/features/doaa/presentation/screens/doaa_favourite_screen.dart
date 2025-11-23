import 'package:tazkira_app/core/routing/route_export.dart';

class Ad3yaFavoritesScreen extends StatefulWidget {
  final Set<String> favoriteAd3ya;
  final Function(String) onRemoveFavorite;

  const Ad3yaFavoritesScreen({
    super.key,
    required this.favoriteAd3ya,
    required this.onRemoveFavorite,
  });

  @override
  State<Ad3yaFavoritesScreen> createState() => _Ad3yaFavoritesScreenState();
}

class _Ad3yaFavoritesScreenState extends State<Ad3yaFavoritesScreen> {
  late Set<String> _localFavorites;

  @override
  void initState() {
    super.initState();
    _localFavorites = Set.from(widget.favoriteAd3ya);
  }

  void _handleRemove(String doaa) {
    setState(() {
      _localFavorites.remove(doaa);
    });
    widget.onRemoveFavorite(doaa);
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
          'الأدعية المفضلة',
          style: GoogleFonts.cairo(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22.sp,
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
      body: _localFavorites.isEmpty
          ? _buildEmptyState()
          : _buildFavoritesList(context),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 40.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border_rounded,
              size: 100.sp,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: 24.h),
            Text(
              'لا توجد أدعية مفضلة',
              style: GoogleFonts.cairo(
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12.h),
            Text(
              'قم بإضافة الأدعية التي تعجبك إلى المفضلة\nبالضغط على أيقونة القلب',
              style: GoogleFonts.cairo(
                fontSize: 16.sp,
                color: Colors.grey.shade600,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoritesList(BuildContext context) {
    final favoritesList = _localFavorites.toList();

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          color: const Color(0xFF4A5D4F).withOpacity(0.1),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.favorite_rounded,
                size: 20.sp,
                color: Colors.red.shade400,
              ),
              SizedBox(width: 8.w),
              Text(
                'لديك ${favoritesList.length} دعاء مفضل',
                style: GoogleFonts.cairo(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF3C4D40),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(vertical: 8.h),
            itemCount: favoritesList.length,
            itemBuilder: (context, index) {
              String doaa = favoritesList[index];
              return Ad3yaCard(
                doaa: doaa,
                isFavorite: true,
                onFavoriteToggle: () => _handleRemove(doaa),
              );
            },
          ),
        ),
      ],
    );
  }
}

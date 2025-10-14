import 'package:tazkira_app/core/routing/route_export.dart';

class HadithFavoritesScreen extends StatefulWidget {
  final Set<String> favoriteHadiths;
  final Function(String) onRemoveFavorite;

  const HadithFavoritesScreen({
    super.key,
    required this.favoriteHadiths,
    required this.onRemoveFavorite,
  });

  @override
  State<HadithFavoritesScreen> createState() => _HadithFavoritesScreenState();
}

class _HadithFavoritesScreenState extends State<HadithFavoritesScreen> {
  late Set<String> _localFavorites;

  @override
  void initState() {
    super.initState();
    _localFavorites = Set.from(widget.favoriteHadiths);
  }

  void _handleRemove(String hadith) {
    setState(() {
      _localFavorites.remove(hadith);
    });
    widget.onRemoveFavorite(hadith);
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
          'الأحاديث المفضلة',
          style: GoogleFonts.cairo(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22.sp,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body:
          _localFavorites.isEmpty ? _buildEmptyState() : _buildFavoritesList(),
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
              'لا توجد أحاديث مفضلة',
              style: GoogleFonts.cairo(
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12.h),
            Text(
              'قم بإضافة الأحاديث التي تعجبك إلى المفضلة\nبالضغط على أيقونة القلب',
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

  Widget _buildFavoritesList() {
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
                'لديك ${favoritesList.length} حديث مفضل',
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
              String hadith = favoritesList[index];
              return HadithCard(
                hadith: hadith,
                isFavorite: true,
                onFavoriteToggle: () => _handleRemove(hadith),
              );
            },
          ),
        ),
      ],
    );
  }
}

import 'package:tazkira_app/core/routing/route_export.dart';

class AsmaAllahFavoritesScreen extends StatelessWidget {
  final List<AsmaAllahItem> favoriteItems;
  final Set<int> favoriteIds;
  final Function(int) onRemoveFavorite;
  final Function(AsmaAllahItem, int) onShare;

  const AsmaAllahFavoritesScreen({
    super.key,
    required this.favoriteItems,
    required this.favoriteIds,
    required this.onRemoveFavorite,
    required this.onShare,
  });

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
          'المفضلة',
          style: GoogleFonts.cairo(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22.sp,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: favoriteItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border_rounded,
                    size: 100.sp,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 20.h),
                  Text(
                    'لا توجد أسماء في المفضلة',
                    style: GoogleFonts.cairo(
                      fontSize: 20.sp,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    'اضغط على ❤️ لإضافة أسماء إلى المفضلة',
                    style: GoogleFonts.cairo(
                      fontSize: 16.sp,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              itemCount: favoriteItems.length,
              itemBuilder: (context, index) {
                final item = favoriteItems[index];
                final actualIndex = item.id - 2;

                return AsmaCard(
                  item: item,
                  index: actualIndex,
                  isFavorite: true,
                  onFavoriteToggle: () => onRemoveFavorite(item.id),
                  onShare: () => onShare(item, actualIndex),
                );
              },
            ),
    );
  }
}

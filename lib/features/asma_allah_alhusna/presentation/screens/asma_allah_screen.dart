import 'package:tazkira_app/core/routing/route_export.dart';

class AsmaAllahScreen extends StatefulWidget {
  const AsmaAllahScreen({super.key});

  @override
  State<AsmaAllahScreen> createState() => _AsmaAllahScreenState();
}

class _AsmaAllahScreenState extends State<AsmaAllahScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScreenshotController _screenshotController = ScreenshotController();
  List<AsmaAllahItem> allNames = [];
  List<AsmaAllahItem> filteredNames = [];
  Set<int> favoriteIds = {};
  bool isLoading = true;
  bool isSearching = false;
  bool _isSharing = false;
  int? _sharingIndex;

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_filterNames);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadNamesOfAllah(),
      _loadFavorites(),
    ]);
  }

  Future<void> _loadNamesOfAllah() async {
    try {
      final String response = await rootBundle.loadString(
        'assets/json/names_of_allah.json',
      );
      final List<dynamic> data = json.decode(response);
      setState(() {
        allNames = data.map((json) => AsmaAllahItem.fromJson(json)).toList();
        filteredNames = allNames;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ في تحميل البيانات: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = prefs.getStringList('favorite_asma_allah') ?? [];
    setState(() {
      favoriteIds = favorites.map((id) => int.parse(id)).toSet();
    });
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'favorite_asma_allah',
      favoriteIds.map((id) => id.toString()).toList(),
    );
  }

  void _toggleFavorite(int id) {
    setState(() {
      if (favoriteIds.contains(id)) {
        favoriteIds.remove(id);
      } else {
        favoriteIds.add(id);
      }
    });
    _saveFavorites();
  }

  void _filterNames() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredNames = allNames;
      } else {
        filteredNames = allNames.where((item) {
          return item.name.toLowerCase().contains(query) ||
              item.nameTranslation.toLowerCase().contains(query) ||
              item.text.toLowerCase().contains(query) ||
              item.textTranslation.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  void _showFavoritesScreen() {
    final favoriteItems =
        allNames.where((item) => favoriteIds.contains(item.id)).toList();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AsmaAllahFavoritesScreen(
          favoriteItems: favoriteItems,
          favoriteIds: favoriteIds,
          onRemoveFavorite: (id) {
            _toggleFavorite(id);
          },
          onShare: _shareAsImage,
        ),
      ),
    );
  }

  Future<void> _shareAsImage(AsmaAllahItem item, int index) async {
    setState(() {
      _isSharing = true;
      _sharingIndex = index;
    });

    try {
      final imageBytes = await _screenshotController.captureFromWidget(
        Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            width: 800,
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [Color(0xFF7CB9AD), Color(0xFF5A9A8E)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'أسماء الله الحسنى',
                  style: GoogleFonts.amiri(
                    fontSize: 38,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${index + 1}',
                    style: GoogleFonts.cairo(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.name,
                  style: GoogleFonts.amiri(
                    fontSize: 46,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 15),
                Flexible(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'المعنى',
                          style: GoogleFonts.cairo(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF7CB9AD),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Flexible(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 680),
                            child: Text(
                              item.text,
                              style: GoogleFonts.cairo(
                                fontSize: 17,
                                height: 1.7,
                                color: const Color(0xFF2C3E50),
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 15,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'تمت المشاركة من تطبيق تَذْكِرَة',
                  style: GoogleFonts.cairo(
                    fontSize: 15,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/اسم_الله_${item.name}.png');
      await file.writeAsBytes(imageBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'أسماء الله الحسنى - ${item.name}\nمن تطبيق تَذْكِرَة',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء المشاركة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSharing = false;
          _sharingIndex = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Screenshot(
      controller: _screenshotController,
      child: Scaffold(
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
          title: isSearching
              ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: GoogleFonts.cairo(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'ابحث عن اسم الله...',
                    hintStyle: GoogleFonts.cairo(
                      color: Colors.white.withOpacity(0.7),
                    ),
                    border: InputBorder.none,
                  ),
                )
              : Text(
                  'أسماء الله الحسنى',
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 22.sp,
                  ),
                ),
          leading: SizedBox(
            width: 112.w,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    isSearching ? Icons.close : Icons.search,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      if (isSearching) {
                        _searchController.clear();
                      }
                      isSearching = !isSearching;
                    });
                  },
                ),
                Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.favorite_rounded,
                          color: Colors.white),
                      onPressed: _showFavoritesScreen,
                    ),
                    if (favoriteIds.isNotEmpty)
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
                            '${favoriteIds.length}',
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
              ],
            ),
          ),
          leadingWidth: 112.w,
          actions: [
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios_rounded,
                  color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        body: isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF7CB9AD),
                ),
              )
            : filteredNames.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 80.sp,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          'لا توجد نتائج',
                          style: GoogleFonts.cairo(
                            fontSize: 20.sp,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    itemCount: filteredNames.length,
                    itemBuilder: (context, index) {
                      final item = filteredNames[index];
                      final actualIndex = allNames.indexOf(item);

                      if (_isSharing && _sharingIndex == actualIndex) {
                        return Card(
                          margin: EdgeInsets.symmetric(
                              horizontal: 12.w, vertical: 6.h),
                          child: Container(
                            height: 100.h,
                            alignment: Alignment.center,
                            child: const CircularProgressIndicator(
                              color: Color(0xFF7CB9AD),
                            ),
                          ),
                        );
                      }

                      return AsmaCard(
                        item: item,
                        index: actualIndex,
                        isFavorite: favoriteIds.contains(item.id),
                        onFavoriteToggle: () => _toggleFavorite(item.id),
                        onShare: () => _shareAsImage(item, actualIndex),
                      );
                    },
                  ),
      ),
    );
  }
}

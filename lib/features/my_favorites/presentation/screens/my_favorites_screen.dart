import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tazkira_app/features/my_favorites/data/models/favorite_item.dart';
import 'package:tazkira_app/features/my_favorites/data/models/favorite_item_type.dart';
import 'package:tazkira_app/features/my_favorites/data/services/favorites_service.dart';
import 'package:tazkira_app/features/my_favorites/presentation/widgets/add_custom_item_sheet.dart';
import 'package:tazkira_app/features/my_favorites/presentation/widgets/favorite_item_card.dart';

class MyFavoritesScreen extends StatefulWidget {
  const MyFavoritesScreen({super.key});

  @override
  State<MyFavoritesScreen> createState() => _MyFavoritesScreenState();
}

class _MyFavoritesScreenState extends State<MyFavoritesScreen> {
  static const _primaryColor = Color(0xFF4A7C7A);
  static const _bgColor = Color(0xFFF7F9F8);

  List<FavoriteItem> _allItems = [];
  List<FavoriteItem> _filtered = [];
  FavoriteItemType? _selectedType; // null = الكل
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);
    final items = await FavoritesService.getAllItems();
    if (mounted) {
      setState(() {
        _allItems = items;
        _applyFilter();
        _isLoading = false;
      });
    }
  }

  void _applyFilter() {
    if (_selectedType == null) {
      _filtered = List.from(_allItems);
    } else {
      _filtered = _allItems.where((i) => i.type == _selectedType).toList();
    }
  }

  Future<void> _removeItem(FavoriteItem item) async {
    await FavoritesService.removeItem(item.id);
    setState(() {
      _allItems.remove(item);
      _applyFilter();
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            item.title.isNotEmpty
                ? 'تم حذف "${item.title}" من محفوظاتك'
                : 'تم حذف العنصر من محفوظاتك',
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: _primaryColor,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          action: SnackBarAction(
            label: 'تراجع',
            textColor: Colors.white,
            onPressed: () async {
              await FavoritesService.addItem(item);
              _loadItems();
            },
          ),
        ),
      );
    }
  }

  void _shareItem(FavoriteItem item) {
    final titlePart = item.title.isNotEmpty ? '${item.title}\n\n' : '';
    final text =
        '${item.type.emoji} $titlePart${item.content}\n\n— من تطبيق تَذْكِرَة - رفيق المسلم اليومي';
    SharePlus.instance.share(ShareParams(text: text));
  }

  void _showAddCustomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddCustomItemSheet(onAdded: _loadItems),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bgColor,
        appBar: _buildAppBar(),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: _primaryColor))
            : Column(
                children: [
                  _buildFilterChips(),
                  Expanded(
                    child:
                        _filtered.isEmpty ? _buildEmptyState() : _buildList(),
                  ),
                ],
              ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showAddCustomSheet,
          backgroundColor: _primaryColor,
          icon: const Icon(Icons.add, color: Colors.white),
          label: Text(
            'أضف محتوى مخصص',
            style: GoogleFonts.cairo(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: _primaryColor,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'محفوظاتي ',
        style: GoogleFonts.cairo(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 20.sp,
        ),
      ),
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(40.h),
        child: Container(
          color: _primaryColor,
          padding: EdgeInsets.only(bottom: 10.h, right: 16.w, left: 16.w),
          child: Row(
            children: [
              Icon(Icons.bookmark_rounded, color: Colors.white70, size: 16.sp),
              SizedBox(width: 6.w),
              Text(
                '${_allItems.length} عنصر محفوظ',
                style: GoogleFonts.cairo(
                  color: Colors.white70,
                  fontSize: 12.sp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final types = [null, ...FavoriteItemType.values];
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Row(
          children: types.map((type) {
            final isSelected = _selectedType == type;
            final label = type == null ? 'الكل' : type.label;
            final emoji = type == null ? '' : type.emoji;
            final count = type == null
                ? _allItems.length
                : _allItems.where((i) => i.type == type).length;

            if (count == 0 && type != null) return const SizedBox.shrink();

            return Padding(
              padding: EdgeInsets.only(left: 8.w),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedType = type;
                    _applyFilter();
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _primaryColor
                        : _primaryColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: isSelected
                          ? Colors.transparent
                          : _primaryColor.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(emoji, style: TextStyle(fontSize: 13.sp)),
                      SizedBox(width: 4.w),
                      Text(
                        label,
                        style: GoogleFonts.cairo(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : _primaryColor,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 6.w, vertical: 1.h),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withOpacity(0.25)
                              : _primaryColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Text(
                          '$count',
                          style: GoogleFonts.cairo(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : _primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 100.h),
      itemCount: _filtered.length,
      itemBuilder: (context, index) {
        final item = _filtered[index];
        return FavoriteItemCard(
          item: item,
          onRemove: () => _removeItem(item),
          onShare: () => _shareItem(item),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bookmark_border_rounded,
            size: 80.sp,
            color: Colors.grey.shade300,
          ),
          SizedBox(height: 16.h),
          Text(
            _selectedType == null
                ? 'لا يوجد محتوى محفوظ بعد'
                : 'لا يوجد ${_selectedType!.label} محفوظ',
            style: GoogleFonts.cairo(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade500,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'اضغط على ايقونة الحفظ بجانب أي محتوى لإضافته هنا',
            style: GoogleFonts.cairo(
              fontSize: 14.sp,
              color: Colors.grey.shade400,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

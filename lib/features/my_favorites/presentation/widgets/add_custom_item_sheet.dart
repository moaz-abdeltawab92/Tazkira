import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tazkira_app/features/my_favorites/data/models/favorite_item.dart';
import 'package:tazkira_app/features/my_favorites/data/models/favorite_item_type.dart';
import 'package:tazkira_app/features/my_favorites/data/services/favorite_id_helper.dart';
import 'package:tazkira_app/features/my_favorites/data/services/favorites_service.dart';

class AddCustomItemSheet extends StatefulWidget {
  const AddCustomItemSheet({super.key, required this.onAdded});

  final VoidCallback onAdded;

  @override
  State<AddCustomItemSheet> createState() => _AddCustomItemSheetState();
}

class _AddCustomItemSheetState extends State<AddCustomItemSheet> {
  static const _primaryColor = Color(0xFF4A7C7A);

  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  FavoriteItemType _selectedType = FavoriteItemType.custom;
  bool _isSaving = false;

  final _manualTypes = [
    FavoriteItemType.custom,
    FavoriteItemType.azkar,
    FavoriteItemType.doaa,
    FavoriteItemType.hadith,
    FavoriteItemType.sunan,
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isSaving = true);

    final item = FavoriteItem(
      id: FavoriteIdHelper.forCustom(),
      type: _selectedType,
      title: title,
      content: content,
      savedAt: DateTime.now(),
    );

    await FavoritesService.addItem(item);
    widget.onAdded();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                ' أضف محتوى مخصص',
                style: GoogleFonts.cairo(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 16.h),
              // Type selector
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _manualTypes.map((type) {
                    final isSelected = _selectedType == type;
                    return Padding(
                      padding: EdgeInsets.only(left: 8.w),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedType = type),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: EdgeInsets.symmetric(
                              horizontal: 12.w, vertical: 6.h),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? _primaryColor
                                : _primaryColor.withOpacity(0.07),
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          child: Text(
                            '${type.emoji} ${type.label}',
                            style: GoogleFonts.cairo(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : _primaryColor,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              SizedBox(height: 16.h),
              // Title field
              TextField(
                controller: _titleController,
                style: GoogleFonts.cairo(),
                decoration: InputDecoration(
                  labelText: 'العنوان (اختياري)',
                  labelStyle: GoogleFonts.cairo(color: Colors.grey.shade500),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide:
                        const BorderSide(color: _primaryColor, width: 1.5),
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              // Content field
              TextField(
                controller: _contentController,
                style: GoogleFonts.amiri(height: 1.8, fontSize: 16.sp),
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'المحتوى *',
                  alignLabelWithHint: true,
                  labelStyle: GoogleFonts.cairo(color: Colors.grey.shade500),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide:
                        const BorderSide(color: _primaryColor, width: 1.5),
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          'حفظ',
                          style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              SizedBox(height: 8.h),
            ],
          ),
        ),
      ),
    );
  }
}

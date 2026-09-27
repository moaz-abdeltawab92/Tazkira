import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tazkira_app/features/my_favorites/data/models/favorite_item.dart';
import 'package:tazkira_app/features/my_favorites/data/models/favorite_item_type.dart';



class FavoriteItemCard extends StatefulWidget {
  const FavoriteItemCard({
    super.key,
    required this.item,
    required this.onRemove,
    required this.onShare,
  });

  final FavoriteItem item;
  final VoidCallback onRemove;
  final VoidCallback onShare;

  @override
  State<FavoriteItemCard> createState() => _FavoriteItemCardState();
}

class _FavoriteItemCardState extends State<FavoriteItemCard> {
  bool _isExpanded = false;
  static const _primaryColor = Color(0xFF4A7C7A);

  @override
  Widget build(BuildContext context) {
    final isLongText = widget.item.content.length > 110;

    return Dismissible(
      key: Key(widget.item.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async => true,
      onDismissed: (_) => widget.onRemove(),
      background: Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.only(left: 20.w),
        margin: EdgeInsets.symmetric(vertical: 4.h),
        decoration: BoxDecoration(
          color: Colors.redAccent.withOpacity(0.85),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Icon(Icons.delete_rounded, color: Colors.white, size: 28.sp),
      ),
      child: GestureDetector(
        onTap: () {
          if (isLongText) {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: EdgeInsets.symmetric(vertical: 5.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(14.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                      decoration: BoxDecoration(
                        color: _primaryColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        '${widget.item.type.emoji} ${widget.item.type.label}',
                        style: GoogleFonts.cairo(
                          fontSize: 11.sp,
                          color: _primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (widget.item.subtitle != null) ...[
                      SizedBox(width: 6.w),
                      Expanded(
                        child: Text(
                          widget.item.subtitle!,
                          style: GoogleFonts.cairo(
                            fontSize: 11.sp,
                            color: Colors.grey.shade500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ] else
                      const Spacer(),
                    // Actions
                    GestureDetector(
                      onTap: widget.onShare,
                      child: Icon(Icons.share_rounded,
                          size: 19.sp, color: Colors.grey.shade500),
                    ),
                    SizedBox(width: 12.w),
                    GestureDetector(
                      onTap: widget.onRemove,
                      child: Icon(Icons.delete_outline_rounded,
                          size: 20.sp, color: Colors.red.shade300),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                // Title
                if (widget.item.title.isNotEmpty &&
                    widget.item.title != widget.item.content)
                  Padding(
                    padding: EdgeInsets.only(bottom: 4.h),
                    child: Text(
                      widget.item.title,
                      style: GoogleFonts.cairo(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                // Content
                Text(
                  widget.item.content,
                  style: GoogleFonts.amiri(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2C3E50),
                    height: 1.9,
                  ),
                  maxLines: _isExpanded ? null : 4,
                  overflow:
                      _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                  textDirection: TextDirection.rtl,
                ),
                // Expand toggle indicator button if long text
                if (isLongText) ...[
                  SizedBox(height: 6.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        _isExpanded ? 'عرض أقل ▴' : 'عرض المزيد ▾',
                        style: GoogleFonts.cairo(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                          color: _primaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
                // Extra info (for sunan: evidence | for podcast: url)
                if (widget.item.extraData != null) _buildExtraInfo(),
                SizedBox(height: 6.h),
                // Timestamp
                Text(
                  _formatDate(widget.item.savedAt),
                  style: GoogleFonts.cairo(
                    fontSize: 10.sp,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExtraInfo() {
    try {
      final data = jsonDecode(widget.item.extraData!) as Map<String, dynamic>;
      if (widget.item.type == FavoriteItemType.sunan &&
          data['evidence'] != null) {
        return Padding(
          padding: EdgeInsets.only(top: 6.h),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.06),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              '📜 ${data['evidence']}',
              style: GoogleFonts.amiri(
                fontSize: 15.sp,
                color: Colors.grey.shade700,
                height: 1.8,
              ),
              maxLines: _isExpanded ? null : 2,
              overflow:
                  _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
              textDirection: TextDirection.rtl,
            ),
          ),
        );
      }
      if (widget.item.type == FavoriteItemType.podcast &&
          data['url'] != null) {
        return Padding(
          padding: EdgeInsets.only(top: 6.h),
          child: Text(
            '🔗 ${data['url']}',
            style: GoogleFonts.cairo(
              fontSize: 10.sp,
              color: Colors.blueGrey,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }
    } catch (_) {}
    return const SizedBox.shrink();
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'منذ لحظات';
    if (diff.inHours < 1) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inDays < 1) return 'منذ ${diff.inHours} ساعة';
    if (diff.inDays < 30) return 'منذ ${diff.inDays} يوم';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

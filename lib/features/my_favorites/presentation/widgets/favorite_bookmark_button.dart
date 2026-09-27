import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tazkira_app/features/my_favorites/data/models/favorite_item.dart';
import 'package:tazkira_app/features/my_favorites/data/models/favorite_item_type.dart';
import 'package:tazkira_app/features/my_favorites/data/services/favorites_service.dart';

/// A reusable bookmark button that can be placed next to any content.
/// Handles the saved/unsaved state internally and persists to SQLite.
class FavoriteBookmarkButton extends StatefulWidget {
  const FavoriteBookmarkButton({
    super.key,
    required this.item,
    this.size,
    this.activeColor = const Color(0xFFE8A838),
    this.inactiveColor,
    this.onToggled,
  });

  final FavoriteItem item;
  final double? size;
  final Color activeColor;
  final Color? inactiveColor;

  /// Called after toggle with the new saved state (true = saved, false = removed).
  final void Function(bool isSaved)? onToggled;

  @override
  State<FavoriteBookmarkButton> createState() => _FavoriteBookmarkButtonState();
}

class _FavoriteBookmarkButtonState extends State<FavoriteBookmarkButton>
    with SingleTickerProviderStateMixin {
  bool _isSaved = false;
  bool _isLoading = true;
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _initSavedState();
  }

  @override
  void didUpdateWidget(FavoriteBookmarkButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.id != widget.item.id) {
      _initSavedState();
    }
  }

  void _initSavedState() {
    final syncSaved = FavoritesService.isSavedSync(widget.item.id);
    if (syncSaved != null) {
      _isSaved = syncSaved;
      _isLoading = false;
    } else {
      _checkSaved();
    }
  }

  Future<void> _checkSaved() async {
    final saved = await FavoritesService.isItemSaved(widget.item.id);
    if (mounted) {
      setState(() {
        _isSaved = saved;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggle() async {
    final nowSaved = await FavoritesService.toggleItem(widget.item);
    if (mounted) {
      setState(() => _isSaved = nowSaved);
      if (nowSaved) {
        _animController.forward().then((_) => _animController.reverse());
      }
      widget.onToggled?.call(nowSaved);

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            nowSaved ? ' تمت الإضافة إلى محفوظاتك' : ' تم الحذف من محفوظاتك',
            style: GoogleFonts.cairo(),
          ),
          backgroundColor:
              nowSaved ? const Color(0xFF4A7C7A) : Colors.grey.shade700,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox(
        width: (widget.size ?? 24.sp) + 8,
        height: (widget.size ?? 24.sp) + 8,
        child: const Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return ScaleTransition(
      scale: _scaleAnimation,
      child: IconButton(
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        icon: Icon(
          _isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
          color: _isSaved
              ? widget.activeColor
              : widget.inactiveColor ?? Colors.grey.shade400,
          size: widget.size ?? 24.sp,
        ),
        onPressed: _toggle,
      ),
    );
  }
}

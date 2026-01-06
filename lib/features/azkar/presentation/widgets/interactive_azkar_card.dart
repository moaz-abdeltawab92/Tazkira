import 'package:tazkira_app/core/routing/route_export.dart';
import 'package:tazkira_app/features/azkar/presentation/utils/azkar_parser.dart';
import 'package:tazkira_app/features/azkar/presentation/controllers/azkar_progress_manager.dart';

class InteractiveAzkarCard extends StatefulWidget {
  final String rawText;
  final String category;
  final int index;
  final VoidCallback? onComplete;

  const InteractiveAzkarCard({
    super.key,
    required this.rawText,
    required this.category,
    required this.index,
    this.onComplete,
  });

  @override
  State<InteractiveAzkarCard> createState() => _InteractiveAzkarCardState();
}

class _InteractiveAzkarCardState extends State<InteractiveAzkarCard>
    with SingleTickerProviderStateMixin {
  late int totalCount;
  late String cleanText;
  late int currentCount;
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    // Parse the text
    final parsed = AzkarParser.parse(widget.rawText);
    totalCount = parsed.count;
    cleanText = parsed.cleanText;

    // Load progress
    currentCount = AzkarProgressManager().getProgress(
      widget.category,
      widget.index,
    );

    // Animation for tap feedback
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    // Check if initial load is already complete
    if (currentCount >= totalCount && widget.onComplete != null) {
      // Defer callback to avoid build error
      WidgetsBinding.instance.addPostFrameCallback((_) {});
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (currentCount >= totalCount) return;

    HapticFeedback.lightImpact();

    _animController.forward().then((_) => _animController.reverse());

    setState(() {
      currentCount++;
    });

    AzkarProgressManager().saveProgress(
      widget.category,
      widget.index,
      currentCount,
    );

    if (currentCount == totalCount) {
      HapticFeedback.mediumImpact();
      if (widget.onComplete != null) {
        widget.onComplete!();
      }
    }
  }

  void _reset() {
    setState(() {
      currentCount = 0;
    });
    AzkarProgressManager().saveProgress(widget.category, widget.index, 0);
  }

  @override
  Widget build(BuildContext context) {
    final bool isCompleted = currentCount >= totalCount;
    final double progress = totalCount > 0 ? currentCount / totalCount : 0.0;

    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            width: double.infinity,
            margin: EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
            child: Stack(
              children: [
                Card(
                  color: isCompleted
                      ? const Color(0xFFE8F5E9)
                      : const Color(0xFFF9F5EC),
                  elevation: isCompleted ? 2 : 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24.r),
                    side: BorderSide(
                      color: isCompleted
                          ? const Color(0xFF4A5D4F)
                          : Colors.green.shade200,
                      width: isCompleted ? 2 : 1.5,
                    ),
                  ),
                  child: Padding(
                    padding:
                        EdgeInsets.symmetric(vertical: 16.h, horizontal: 20.w),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12.w, vertical: 6.h),
                              decoration: BoxDecoration(
                                color: isCompleted
                                    ? const Color(0xFF4A5D4F)
                                    : const Color(0xFFD0DDD0),
                                borderRadius: BorderRadius.circular(20.r),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    '$currentCount / $totalCount',
                                    style: GoogleFonts.cairo(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.bold,
                                      color: isCompleted
                                          ? Colors.white
                                          : const Color(0xFF3C4D40),
                                    ),
                                  ),
                                  if (isCompleted) ...[
                                    SizedBox(width: 6.w),
                                    Icon(Icons.check_circle,
                                        color: Colors.white, size: 18.sp),
                                  ],
                                ],
                              ),
                            ),
                            if (isCompleted)
                              InkWell(
                                onTap: _reset,
                                child: Padding(
                                  padding: EdgeInsets.all(8.0.w),
                                  child: Icon(Icons.refresh,
                                      color: Colors.grey, size: 20.sp),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          cleanText,
                          style: GoogleFonts.tajawal(
                            fontSize: 19.sp,
                            fontWeight: FontWeight.w600,
                            color:
                                isCompleted ? Colors.black54 : Colors.black87,
                            height: 1.6,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 16.h),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4.r),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 6.h,
                            backgroundColor: Colors.grey.shade300,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isCompleted
                                  ? const Color(0xFF4A5D4F)
                                  : const Color(0xFF7CB9AD),
                            ),
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          isCompleted ? "اكتمل" : "اضغط للتسبيح",
                          style: GoogleFonts.cairo(
                            fontSize: 12.sp,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:tazkira_app/core/routing/route_export.dart';

class CounterDetails extends StatefulWidget {
  final int count;
  final VoidCallback onIncrement;
  final VoidCallback onReset;
  final String title;

  const CounterDetails({
    Key? key,
    required this.count,
    required this.onIncrement,
    required this.onReset,
    required this.title,
  }) : super(key: key);

  @override
  State<CounterDetails> createState() => _CounterDetailsState();
}

class _CounterDetailsState extends State<CounterDetails> {
  bool _isIncrementPressed = false;
  bool _isResetPressed = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 6.h),
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            widget.title,
            style: GoogleFonts.amiri(
              color: Colors.white,
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 5.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 5.h),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Text(
              widget.count.toString().padLeft(4, '0'),
              key: ValueKey<int>(widget.count),
              style: GoogleFonts.cairo(
                fontSize: 52.sp,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
            ),
          ),
          SizedBox(height: 5.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTapDown: (_) => setState(() => _isResetPressed = true),
                onTapUp: (_) {
                  setState(() => _isResetPressed = false);
                  widget.onReset();
                },
                onTapCancel: () => setState(() => _isResetPressed = false),
                child: AnimatedScale(
                  scale: _isResetPressed ? 0.95 : 1.0,
                  duration: const Duration(milliseconds: 100),
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
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
                          Icons.refresh_rounded,
                          color: Colors.white,
                          size: 18.sp,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          "إعادة",
                          style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: 16.w),
              GestureDetector(
                onTapDown: (_) => setState(() => _isIncrementPressed = true),
                onTapUp: (_) {
                  setState(() => _isIncrementPressed = false);
                  widget.onIncrement();
                },
                onTapCancel: () => setState(() => _isIncrementPressed = false),
                child: AnimatedScale(
                  scale: _isIncrementPressed ? 0.92 : 1.0,
                  duration: const Duration(milliseconds: 100),
                  child: Container(
                    padding: EdgeInsets.all(18.w),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.4),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.add_rounded,
                      size: 28.sp,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

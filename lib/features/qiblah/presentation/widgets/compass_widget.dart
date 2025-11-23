import 'package:tazkira_app/core/routing/route_export.dart';

class CompassWidget extends StatelessWidget {
  const CompassWidget({
    required this.headingAngle,
    required this.qiblahAngle,
    required this.isAligned,
    required this.isLoading,
    super.key,
  });

  final double headingAngle;
  final double qiblahAngle;
  final bool isAligned;
  final bool isLoading;

  static const _compassDiameterFactor = 0.8;
  static const _maxCompassDiameter = 300.0;
  static const _compassBackgroundSizeFactor = 0.97;
  static const _arrowSizeFactor = 0.45;
  static const _arrowHeightFactor = 0.85;
  static const _fixedArrowTopPosition = -57.2;
  static const _fixedArrowSize = 100.0;
  static const _alignedTextBottomPosition = -80.0;
  static const _kaabaIconTopPosition = -100.0;
  static const _kaabaIconSize = 80.0;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final diameter = min(
      size.width * _compassDiameterFactor,
      _maxCompassDiameter,
    );
    final compassSize = Size(diameter, diameter);
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isLoading) ...[
            const CustomLoadingIndicator(text: 'جاري تحميل البوصلة...'),
          ] else ...[
            Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                _buildMainCircle(compassSize, theme),
                _buildFixedArrow(theme),
                if (isAligned) _buildAlignedText(theme),
                _buildKaabaIcon(),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMainCircle(Size compassSize, ThemeData theme) =>
      AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: compassSize.width,
        height: compassSize.height,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(
            color:
                isAligned ? const Color(0xFF7CB9AD) : const Color(0xFFE0E0E0),
            width: isAligned ? 18.0 : 14.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(25),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Transform.rotate(
              angle: headingAngle,
              child: RepaintBoundary(
                child: CustomPaint(
                  size: Size(
                    compassSize.width * _compassBackgroundSizeFactor,
                    compassSize.height * _compassBackgroundSizeFactor,
                  ),
                  painter: CompassBackgroundPainter(theme: theme),
                ),
              ),
            ),
            Transform.rotate(
              angle: qiblahAngle,
              child: RepaintBoundary(
                child: CustomPaint(
                  size: Size(
                    compassSize.width * _arrowSizeFactor,
                    compassSize.height * _arrowHeightFactor,
                  ),
                  painter: ProfessionalArrowPainter(theme: theme),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildFixedArrow(ThemeData theme) => Positioned(
        top: _fixedArrowTopPosition,
        child: Icon(
          Icons.arrow_drop_up,
          size: _fixedArrowSize,
          color: isAligned ? const Color(0xFF7CB9AD) : const Color(0xFFBDBDBD),
        ),
      );

  Widget _buildAlignedText(ThemeData theme) => Positioned(
        bottom: _alignedTextBottomPosition,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF7CB9AD).withOpacity(0.3),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF7CB9AD).withOpacity(0.5),
              width: 2,
            ),
          ),
          child: Text(
            'اتجاه الصلاة',
            style: GoogleFonts.cairo(
              color: const Color(0xFF2C5F4F),
              fontWeight: FontWeight.bold,
              fontSize: 14.sp,
            ),
          ),
        ),
      );

  Widget _buildKaabaIcon() => Positioned(
        top: _kaabaIconTopPosition,
        child: DecoratedBox(
          decoration: const BoxDecoration(shape: BoxShape.circle),
          child: ClipOval(
            child: Image.asset(
              'assets/images/kaaba.png',
              width: _kaabaIconSize,
              fit: BoxFit.cover,
              cacheHeight: 210,
              cacheWidth: 210,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.mosque,
                size: _kaabaIconSize,
                color: Colors.green.shade700,
              ),
            ),
          ),
        ),
      );
}

import 'package:tazkira_app/core/routing/route_export.dart';

class ProfessionalArrowPainter extends CustomPainter {
  ProfessionalArrowPainter({required this.theme});

  final ThemeData theme;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    final primaryColor = theme.primaryColor;
    final primaryColorDark = theme.primaryColorDark;
    final onPrimaryColor = theme.colorScheme.onPrimary;

    _drawMainArrow(canvas, size, center, primaryColor, primaryColorDark);
    _drawHighlights(canvas, size, center, onPrimaryColor);
  }

  void _drawMainArrow(
    Canvas canvas,
    Size size,
    Offset center,
    Color primaryColor,
    Color primaryColorDark,
  ) {
    final gradient = RadialGradient(
      colors: [primaryColor.withAlpha(229), primaryColorDark.withAlpha(204)],
      radius: 0.8,
    );

    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCircle(center: center, radius: size.width / 2),
      )
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(center.dx, center.dy - size.height * 0.4)
      ..lineTo(center.dx - 12, center.dy - size.height * 0.1)
      ..lineTo(center.dx + 12, center.dy - size.height * 0.1)
      ..close()
      ..addRect(
        Rect.fromPoints(
          Offset(center.dx - 8, center.dy - size.height * 0.1),
          Offset(center.dx + 8, center.dy + size.height * 0.3),
        ),
      );

    canvas.drawPath(path, paint);
  }

  void _drawHighlights(
    Canvas canvas,
    Size size,
    Offset center,
    Color onPrimaryColor,
  ) {
    final highlightPaint = Paint()
      ..color = onPrimaryColor.withAlpha(76)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final highlightPath = Path()
      ..moveTo(center.dx, center.dy - size.height * 0.35)
      ..lineTo(center.dx - 8, center.dy - size.height * 0.15)
      ..moveTo(center.dx, center.dy - size.height * 0.35)
      ..lineTo(center.dx + 8, center.dy - size.height * 0.15)
      ..moveTo(center.dx - 8, center.dy - size.height * 0.1)
      ..lineTo(center.dx - 4, center.dy + size.height * 0.25)
      ..moveTo(center.dx + 8, center.dy - size.height * 0.1)
      ..lineTo(center.dx + 4, center.dy + size.height * 0.25);

    canvas.drawPath(highlightPath, highlightPaint);
  }

  @override
  bool shouldRepaint(covariant ProfessionalArrowPainter oldDelegate) =>
      oldDelegate.theme != theme;
}

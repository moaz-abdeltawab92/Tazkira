import 'dart:math';
import 'package:flutter/material.dart';

class CompassBackgroundPainter extends CustomPainter {
  CompassBackgroundPainter({required this.theme});

  final ThemeData theme;
  static const int _outerCircleOpacity = 38;
  static const int _middleCircleOpacity = 51;
  static const int _innerCircleOpacity = 229;
  static const int _smallMarkOpacity = 153;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final colors = _getColorsFromTheme();
    _drawCircles(canvas, center, radius, colors);
    _drawMarks(canvas, center, radius, colors);
  }

  CompassColors _getColorsFromTheme() => CompassColors(
        primary: theme.primaryColor,
        onSurface: theme.colorScheme.onSurface,
        surface: theme.colorScheme.surface,
      );

  void _drawCircles(
    Canvas canvas,
    Offset center,
    double radius,
    CompassColors colors,
  ) {
    canvas
      ..drawCircle(
        center,
        radius,
        Paint()
          ..color = colors.primary.withAlpha(_outerCircleOpacity)
          ..style = PaintingStyle.fill,
      )
      ..drawCircle(
        center,
        radius * 0.7,
        Paint()
          ..color = colors.primary.withAlpha(_middleCircleOpacity)
          ..style = PaintingStyle.fill,
      )
      ..drawCircle(
        center,
        radius * 0.4,
        Paint()
          ..color = colors.surface.withAlpha(_innerCircleOpacity)
          ..style = PaintingStyle.fill,
      );
  }

  void _drawMarks(
    Canvas canvas,
    Offset center,
    double radius,
    CompassColors colors,
  ) {
    _drawSmallMarks(canvas, center, radius, colors);
    _drawMainMarks(canvas, center, radius, colors);
    _drawCardinalMarks(canvas, center, radius, colors);
  }

  void _drawSmallMarks(
    Canvas canvas,
    Offset center,
    double radius,
    CompassColors colors,
  ) {
    final paint = Paint()
      ..color = colors.onSurface.withAlpha(_smallMarkOpacity)
      ..strokeWidth = 1;

    for (int i = 0; i < 360; i += 5) {
      final angle = i * degreesToRadians;
      final startRadius = i % 15 == 0 ? radius * 0.85 : radius * 0.9;

      final start = _calculatePoint(center, startRadius, angle);
      final end = _calculatePoint(center, radius, angle);

      canvas.drawLine(start, end, paint);
    }
  }

  void _drawMainMarks(
    Canvas canvas,
    Offset center,
    double radius,
    CompassColors colors,
  ) {
    final paint = Paint()
      ..color = colors.primary
      ..strokeWidth = 2;

    for (int i = 0; i < 360; i += 15) {
      final angle = i * degreesToRadians;
      final start = _calculatePoint(center, radius * 0.8, angle);
      final end = _calculatePoint(center, radius * 0.95, angle);

      canvas.drawLine(start, end, paint);
    }
  }

  void _drawCardinalMarks(
    Canvas canvas,
    Offset center,
    double radius,
    CompassColors colors,
  ) {
    const cardinalPoints = ['E', 'S', 'W', 'N'];
    final linePaint = Paint()
      ..color = colors.primary
      ..strokeWidth = 3;

    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    for (int i = 0; i < 360; i += 90) {
      final angle = i * degreesToRadians;
      final index = i ~/ 90;

      final start = _calculatePoint(center, radius * 0.75, angle);
      final end = _calculatePoint(center, radius * 0.95, angle);
      canvas.drawLine(start, end, linePaint);

      final textSpan = TextSpan(
        text: cardinalPoints[index],
        style: TextStyle(
          color: colors.primary,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      );

      textPainter
        ..text = textSpan
        ..layout();

      final textOffset = Offset(
        center.dx + radius * 0.6 * cos(angle) - textPainter.width / 2,
        center.dy + radius * 0.6 * sin(angle) - textPainter.height / 2,
      );

      textPainter.paint(canvas, textOffset);
    }
  }

  Offset _calculatePoint(Offset center, double distance, double angle) =>
      Offset(
        center.dx + distance * cos(angle),
        center.dy + distance * sin(angle),
      );

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) =>
      oldDelegate is! CompassBackgroundPainter || oldDelegate.theme != theme;
}

class CompassColors {
  CompassColors({
    required this.primary,
    required this.onSurface,
    required this.surface,
  });
  final Color primary;
  final Color onSurface;
  final Color surface;
}

const double degreesToRadians = pi / 180;

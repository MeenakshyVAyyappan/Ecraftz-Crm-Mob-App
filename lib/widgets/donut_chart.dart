import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class DonutChart extends StatelessWidget {
  final double percentage; // e.g. 48
  final String label; // e.g. 'HEALTH'
  final Color color;
  final double size;

  const DonutChart({
    super.key,
    required this.percentage,
    required this.label,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _DonutPainter(
          percentage: percentage / 100,
          color: color,
          backgroundColor: AppTheme.borderOf(context),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${percentage.toInt()}%',
                style: TextStyle(
                  color: AppTheme.textPrimaryOf(context),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: AppTheme.textMutedOf(context),
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final double percentage;
  final Color color;
  final Color backgroundColor;

  _DonutPainter({
    required this.percentage,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double strokeWidth = 10.0;
    final double radius = (min(size.width, size.height) - strokeWidth) / 2;
    final Offset center = Offset(size.width / 2, size.height / 2);

    final Paint bgPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final Paint fgPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Background circle
    canvas.drawCircle(center, radius, bgPaint);

    // Foreground arc (percentage)
    final double sweepAngle = 2 * pi * percentage;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

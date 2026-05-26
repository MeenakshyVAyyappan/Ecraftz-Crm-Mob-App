import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class RevenueChart extends StatefulWidget {
  const RevenueChart({super.key});

  @override
  State<RevenueChart> createState() => _RevenueChartState();
}

class _RevenueChartState extends State<RevenueChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  final List<Map<String, dynamic>> data = [
    {'month': 'Dec', 'pipeline': 0.0, 'actual': 0.0},
    {'month': 'Jan', 'pipeline': 200.0, 'actual': 100.0},
    {'month': 'Feb', 'pipeline': 600.0, 'actual': 400.0},
    {'month': 'Mar', 'pipeline': 1000.0, 'actual': 700.0},
    {'month': 'Apr', 'pipeline': 2500.0, 'actual': 2500.0},
    {'month': 'May', 'pipeline': 2800.0, 'actual': 2500.0},
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final borderColor = AppTheme.borderOf(context);
    final textColor = AppTheme.textMutedOf(context);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return CustomPaint(
          painter: _ChartPainter(
            data: data,
            progress: _animation.value,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
            textColor: textColor,
          ),
          child: const SizedBox(height: 160),
        );
      },
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  final double progress;
  final Color surfaceColor;
  final Color borderColor;
  final Color textColor;

  _ChartPainter({
    required this.data,
    required this.progress,
    required this.surfaceColor,
    required this.borderColor,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double maxVal = 3000;
    const double paddingLeft = 8;
    const double paddingRight = 8;
    const double paddingTop = 10;
    const double paddingBottom = 32;

    final double chartW = size.width - paddingLeft - paddingRight;
    final double chartH = size.height - paddingTop - paddingBottom;
    final double stepX = chartW / (data.length - 1);

    List<Offset> pipelinePoints = [];
    List<Offset> actualPoints = [];

    for (int i = 0; i < data.length; i++) {
      final double x = paddingLeft + i * stepX;
      final double py = paddingTop + chartH - (data[i]['pipeline'] / maxVal) * chartH;
      final double ay = paddingTop + chartH - (data[i]['actual'] / maxVal) * chartH;
      pipelinePoints.add(Offset(x, py));
      actualPoints.add(Offset(x, ay));
    }

    // Draw grid lines
    final gridPaint = Paint()
      ..color = borderColor.withOpacity(0.6)
      ..strokeWidth = 1;
    for (int i = 0; i <= 4; i++) {
      final y = paddingTop + (chartH / 4) * i;
      canvas.drawLine(Offset(paddingLeft, y), Offset(size.width - paddingRight, y), gridPaint);
    }

    // Draw pipeline area fill
    _drawArea(canvas, pipelinePoints, size, paddingTop + chartH,
        AppTheme.primary.withOpacity(0.07), AppTheme.primary.withOpacity(0.03));

    // Draw actual area fill
    _drawArea(canvas, actualPoints, size, paddingTop + chartH,
        AppTheme.success.withOpacity(0.1), AppTheme.success.withOpacity(0.02));

    // Draw pipeline line
    _drawLine(canvas, pipelinePoints, AppTheme.primary.withOpacity(0.4), 1.5,
        isDashed: true);

    // Draw actual line
    _drawLine(canvas, actualPoints, AppTheme.primary, 2.5);

    // Draw dots on actual line
    final dotPaint = Paint()..color = AppTheme.primary;
    final dotBg = Paint()..color = surfaceColor;
    for (int i = 0; i < actualPoints.length; i++) {
      canvas.drawCircle(actualPoints[i], 5, dotBg);
      canvas.drawCircle(actualPoints[i], 3.5, dotPaint);
    }

    // Draw month labels
    final textStyle = TextStyle(
      color: textColor,
      fontSize: 10,
      fontWeight: FontWeight.w500,
    );
    for (int i = 0; i < data.length; i++) {
      final x = paddingLeft + i * stepX;
      final tp = TextPainter(
        text: TextSpan(text: data[i]['month'], style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas,
          Offset(x - tp.width / 2, size.height - paddingBottom + 10));
    }
  }

  void _drawLine(Canvas canvas, List<Offset> points, Color color, double width,
      {bool isDashed = false}) {
    if (points.isEmpty) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final curr = points[i];
      final cpX = (prev.dx + curr.dx) / 2;
      path.cubicTo(cpX, prev.dy, cpX, curr.dy, curr.dx, curr.dy);
    }

    if (isDashed) {
      _drawDashedPath(canvas, path, paint);
    } else {
      canvas.drawPath(path, paint);
    }
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double distance = 0;
      const double dashLen = 6;
      const double gapLen = 4;
      while (distance < metric.length) {
        final end = min(distance + dashLen, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += dashLen + gapLen;
      }
    }
  }

  void _drawArea(Canvas canvas, List<Offset> points, Size size,
      double bottomY, Color topColor, Color bottomColor) {
    if (points.isEmpty) return;
    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final curr = points[i];
      final cpX = (prev.dx + curr.dx) / 2;
      path.cubicTo(cpX, prev.dy, cpX, curr.dy, curr.dx, curr.dy);
    }
    path.lineTo(points.last.dx, bottomY);
    path.lineTo(points.first.dx, bottomY);
    path.close();

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [topColor, bottomColor],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ChartPainter old) => old.progress != progress;
}

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class HomepageTrackBackground extends StatefulWidget {
  const HomepageTrackBackground({super.key, this.opacity = 1.0});

  final double opacity;

  @override
  State<HomepageTrackBackground> createState() =>
      _HomepageTrackBackgroundState();
}

class _HomepageTrackBackgroundState extends State<HomepageTrackBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Opacity(
            opacity: widget.opacity,
            child: CustomPaint(
              painter: _HomepageTrackPainter(progress: _controller.value),
            ),
          );
        },
      ),
    );
  }
}

class _HomepageTrackPainter extends CustomPainter {
  _HomepageTrackPainter({required this.progress});

  final double progress;

  static const List<Offset> _track = [
    Offset(0.16, 0.58),
    Offset(0.20, 0.32),
    Offset(0.34, 0.16),
    Offset(0.54, 0.18),
    Offset(0.63, 0.32),
    Offset(0.77, 0.24),
    Offset(0.87, 0.39),
    Offset(0.84, 0.65),
    Offset(0.66, 0.83),
    Offset(0.46, 0.80),
    Offset(0.34, 0.66),
    Offset(0.25, 0.76),
    Offset(0.14, 0.67),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final Rect bounds = Offset.zero & size;
    final Path trackPath = _buildTrackPath(bounds);
    final PathMetric metric = trackPath.computeMetrics().first;

    _drawOuterGlow(canvas, trackPath);
    _drawBaseTrack(canvas, trackPath);
    _drawFinishMarker(canvas, metric);
    _drawHeatTrail(canvas, metric);
    _drawCar(canvas, metric);
  }

  Path _buildTrackPath(Rect bounds) {
    final List<Offset> scaled = _track
        .map(
          (point) => Offset(point.dx * bounds.width, point.dy * bounds.height),
        )
        .toList();

    final Path path = Path()..moveTo(scaled.first.dx, scaled.first.dy);
    for (int i = 0; i < scaled.length; i++) {
      final Offset current = scaled[i];
      final Offset next = scaled[(i + 1) % scaled.length];
      final Offset control = Offset(
        (current.dx + next.dx) / 2,
        (current.dy + next.dy) / 2,
      );
      path.quadraticBezierTo(current.dx, current.dy, control.dx, control.dy);
    }
    path.close();
    return path;
  }

  void _drawOuterGlow(Canvas canvas, Path path) {
    final Paint glowPaint = Paint()
      ..color = AppTheme.accentCyan.withValues(alpha: 0.07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 38
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawPath(path, glowPaint);
  }

  void _drawBaseTrack(Canvas canvas, Path path) {
    final Paint trackShadow = Paint()
      ..color = const Color(0xFF02040A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final Paint trackPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0x662E3548), Color(0x994E576C), Color(0x55323B4B)],
      ).createShader(path.getBounds())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, trackShadow);
    canvas.drawPath(path, trackPaint);
  }

  void _drawHeatTrail(Canvas canvas, PathMetric metric) {
    const int samples = 140;
    const double tailLength = 0.24;
    final double totalLength = metric.length;
    final List<_TrailSample> trail = [];

    for (int i = 0; i <= samples; i++) {
      final double t = i / samples;
      final double age = (progress - t + 1.0) % 1.0;
      if (age > tailLength) {
        continue;
      }

      final Tangent? tangent = metric.getTangentForOffset(totalLength * t);
      if (tangent == null) {
        continue;
      }

      final double speed = _speedAt(t);
      final double intensity = 1.0 - (age / tailLength);
      trail.add(
        _TrailSample(
          offset: tangent.position,
          speed: speed,
          intensity: intensity,
        ),
      );
    }

    for (int i = 1; i < trail.length; i++) {
      final _TrailSample previous = trail[i - 1];
      final _TrailSample current = trail[i];
      final Color color = _speedToColor(
        current.speed,
      ).withValues(alpha: 0.14 + (current.intensity * 0.78));

      final Paint glowPaint = Paint()
        ..color = color.withValues(alpha: color.a * 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 13 * current.intensity + 3
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

      final Paint linePaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6 * current.intensity + 2
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(previous.offset, current.offset, glowPaint);
      canvas.drawLine(previous.offset, current.offset, linePaint);
    }
  }

  void _drawFinishMarker(Canvas canvas, PathMetric metric) {
    final Tangent? tangent = metric.getTangentForOffset(0);
    if (tangent == null) {
      return;
    }

    final Offset markerCenter = tangent.position;
    final Paint outerRing = Paint()
      ..color = Colors.white.withValues(alpha: 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;
    final Paint innerRing = Paint()
      ..color = AppTheme.accentRed.withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    canvas.drawCircle(markerCenter, 15, outerRing);
    canvas.drawCircle(markerCenter, 9, innerRing);
  }

  void _drawCar(Canvas canvas, PathMetric metric) {
    final Tangent? tangent = metric.getTangentForOffset(
      metric.length * progress,
    );
    if (tangent == null) {
      return;
    }

    final double speed = _speedAt(progress);
    final Color accent = _speedToColor(speed);
    final double pulse = 0.72 + (math.sin(progress * math.pi * 2) * 0.18);

    final Paint carGlow = Paint()
      ..color = accent.withValues(alpha: 0.42)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawCircle(tangent.position, 16, carGlow);

    final Paint pulseRing = Paint()
      ..color = accent.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4;
    canvas.drawCircle(tangent.position, 10 + (10 * pulse), pulseRing);

    final Paint carPaint = Paint()..color = Colors.white;
    canvas.drawCircle(tangent.position, 5.6, carPaint);
  }

  double _speedAt(double t) {
    final double waveA = math.sin(
      (t * math.pi * 2 * 3) - (progress * math.pi * 2),
    );
    final double waveB = math.cos((t * math.pi * 2 * 5) + (progress * math.pi));
    final double normalized = ((waveA * 0.55) + (waveB * 0.45) + 1.0) / 2.0;
    return 115 + (normalized * 225);
  }

  Color _speedToColor(double speed) {
    const List<Color> stops = [
      Color(0xFF2F6BFF),
      Color(0xFF00D2FF),
      Color(0xFF00D97E),
      Color(0xFFFFD400),
      Color(0xFFFF3A2E),
    ];

    final double t = ((speed - 115) / 225).clamp(0.0, 1.0);
    if (t < 0.25) {
      return Color.lerp(stops[0], stops[1], t / 0.25)!;
    }
    if (t < 0.5) {
      return Color.lerp(stops[1], stops[2], (t - 0.25) / 0.25)!;
    }
    if (t < 0.75) {
      return Color.lerp(stops[2], stops[3], (t - 0.5) / 0.25)!;
    }
    return Color.lerp(stops[3], stops[4], (t - 0.75) / 0.25)!;
  }

  @override
  bool shouldRepaint(covariant _HomepageTrackPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _TrailSample {
  const _TrailSample({
    required this.offset,
    required this.speed,
    required this.intensity,
  });

  final Offset offset;
  final double speed;
  final double intensity;
}

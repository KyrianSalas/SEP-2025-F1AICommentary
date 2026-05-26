import 'package:flutter/material.dart';
import 'dart:math';
import '../theme/app_theme.dart';

class RpmDisplay extends StatefulWidget {
  final double currentTime;
  final double currentRPM;
  final double maxRPM;
  final Color backgroundColour;

  const RpmDisplay({
    super.key,
    required this.currentTime,
    required this.currentRPM,
    this.maxRPM = 0,
    this.backgroundColour = Colors.white,
  });

  @override
  State<RpmDisplay> createState() => _RpmDisplayState();
}

class _RpmDisplayState extends State<RpmDisplay> {
  double _currentRpm = 0;

  @override
  void initState() {
    super.initState();
    _currentRpm = widget.currentRPM;
  }

  @override
  void didUpdateWidget(RpmDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentTime != oldWidget.currentTime) {
      setState(() {
        _currentRpm = widget.currentRPM;
      });
    }
  }

  // colour based on RPM percentage: green -> yellow -> red
  Color _getRpmColor(double rpm, double maxRpm) {
    if (maxRpm <= 0) return Colors.green;
    double percentage = (rpm / maxRpm).clamp(0.0, 1.0);
    if (percentage < 0.5) {
      return Color.lerp(Colors.green, Colors.yellow, percentage * 2)!;
    } else {
      return Color.lerp(Colors.yellow, Colors.red, (percentage - 0.5) * 2)!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final rpmColor = _getRpmColor(_currentRpm, widget.maxRPM);
        final rpmFraction = (_currentRpm / widget.maxRPM).clamp(0.0, 1.0);
        // use the smaller dimension so the gauge is always a circle
        final gaugeSize = min(constraints.maxWidth, constraints.maxHeight);
        final compact = gaugeSize < 84;

        return Container(
          width: double.infinity,
          height: double.infinity,
          decoration: AppTheme.glassCard(),
          child: widget.maxRPM == 0
              ? const Center(
                  child: CircularProgressIndicator(color: AppTheme.accentRed),
                )
              : Center(
                  child: SizedBox(
                    width: gaugeSize * 0.92,
                    height: gaugeSize * 0.92,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // the arc gauge - fills the square
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _RpmArcPainter(
                              fraction: rpmFraction,
                              rpmColor: rpmColor,
                            ),
                          ),
                        ),

                        // centre text inside the arc
                        compact
                            ? Text(
                                _currentRpm.toInt().toString(),
                                style: AppTheme.orbitron(
                                  fontSize: (gaugeSize * 0.24).clamp(10.0, 22.0),
                                  color: rpmColor,
                                ),
                              )
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'RPM',
                                    style: AppTheme.inter(
                                      fontSize: (gaugeSize * 0.06).clamp(7.0, 14.0),
                                      color: AppTheme.textMuted,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    _currentRpm.toInt().toString(),
                                    style: AppTheme.orbitron(
                                      fontSize: (gaugeSize * 0.14).clamp(12.0, 40.0),
                                      color: rpmColor,
                                    ),
                                  ),
                                  Text(
                                    '/ ${widget.maxRPM.toInt()}',
                                    style: AppTheme.inter(
                                      fontSize: (gaugeSize * 0.05).clamp(6.0, 12.0),
                                      color: AppTheme.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }
}

/// Draws the radial arc gauge background and active fill.
class _RpmArcPainter extends CustomPainter {
  final double fraction;
  final Color rpmColor;

  // gauge geometry: 240-degree arc starting from bottom-left
  static const double _startAngle = 150 * pi / 180;
  static const double _sweepAngle = 240 * pi / 180;

  _RpmArcPainter({required this.fraction, required this.rpmColor});

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;
    final strokeWidth = radius * 0.12;
    final rect = Rect.fromCircle(
      center: centre,
      radius: radius - strokeWidth / 2,
    );

    // background track (dim)
    final bgPaint = Paint()
      ..color = const Color(0xFF2A2A2A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, _startAngle, _sweepAngle, false, bgPaint);

    // active arc
    if (fraction > 0) {
      final activeSweep = _sweepAngle * fraction;
      final activePaint = Paint()
        ..color = rpmColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, _startAngle, activeSweep, false, activePaint);

      // glow dot at the tip of the active arc
      final tipAngle = _startAngle + activeSweep;
      final tipX = centre.dx + (radius - strokeWidth / 2) * cos(tipAngle);
      final tipY = centre.dy + (radius - strokeWidth / 2) * sin(tipAngle);
      final glowPaint = Paint()
        ..color = rpmColor.withAlpha(80)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawCircle(Offset(tipX, tipY), strokeWidth * 0.8, glowPaint);
    }

    // tick marks around the arc
    final tickPaint = Paint()
      ..color = const Color(0xFF555555)
      ..strokeWidth = 1;
    const int numTicks = 12;
    for (int i = 0; i <= numTicks; i++) {
      final angle = _startAngle + (_sweepAngle * i / numTicks);
      final outerR = radius + 2;
      final innerR = radius - strokeWidth - 4;
      final outer = Offset(
        centre.dx + outerR * cos(angle),
        centre.dy + outerR * sin(angle),
      );
      final inner = Offset(
        centre.dx + innerR * cos(angle),
        centre.dy + innerR * sin(angle),
      );
      canvas.drawLine(inner, outer, tickPaint);
    }
  }

  @override
  bool shouldRepaint(_RpmArcPainter oldDelegate) {
    return oldDelegate.fraction != fraction || oldDelegate.rpmColor != rpmColor;
  }
}

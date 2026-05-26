import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

double _clampDouble(num value, double lowerLimit, double upperLimit) {
  return value.clamp(lowerLimit, upperLimit).toDouble();
}

class BrakeDisplay1 extends StatefulWidget {
  final double currentTime;
  final bool brake;
  final double brakePressure;

  const BrakeDisplay1({
    super.key,
    required this.currentTime,
    required this.brake,
    this.brakePressure = 0,
  });

  @override
  State<BrakeDisplay1> createState() => _BrakeDisplayState();
}

class _BrakeDisplayState extends State<BrakeDisplay1> {
  bool _brake = false;
  double _brakePressure = 0;

  @override
  void initState() {
    super.initState();
    _brake = widget.brake;
    _brakePressure = widget.brakePressure;
  }

  @override
  void didUpdateWidget(BrakeDisplay1 oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentTime != oldWidget.currentTime ||
        widget.brake != oldWidget.brake ||
        widget.brakePressure != oldWidget.brakePressure) {
      setState(() {
        _brake = widget.brake;
        _brakePressure = widget.brakePressure;
      });
    }
  }

  double get _pressure {
    if (_brakePressure > 1) {
      return _clampDouble(_brakePressure / 100, 0.0, 1.0);
    }

    final normalized = _clampDouble(_brakePressure, 0.0, 1.0);
    if (normalized == 0 && _brake) {
      return 1.0;
    }
    return normalized;
  }

  Color get _brakeColor {
    final pressure = _pressure;
    if (pressure < 0.45) {
      return Color.lerp(
        AppTheme.accentCyan,
        const Color(0xFFFFD938),
        pressure / 0.45,
      )!;
    }
    return Color.lerp(
      const Color(0xFFFFD938),
      AppTheme.accentRed,
      _clampDouble((pressure - 0.45) / 0.55, 0.0, 1.0),
    )!;
  }

  String get _phase {
    final pressure = _pressure;
    if (pressure < 0.02) return 'COAST';
    if (pressure < 0.28) return 'TRAIL';
    if (pressure < 0.62) return 'COMMIT';
    if (pressure < 0.88) return 'ATTACK';
    return 'LOCK RISK';
  }

  @override
  Widget build(BuildContext context) {
    final pressure = _pressure;
    final brakeColor = _brakeColor;
    final percent = (pressure * 100).round().clamp(0, 100).toInt();

    return LayoutBuilder(
      builder: (context, outer) {
        if (outer.maxHeight < 80 || outer.maxWidth < 120) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: AppTheme.glassCard(),
            alignment: Alignment.center,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'BRK $percent%',
                style: AppTheme.orbitron(fontSize: 16, color: brakeColor),
              ),
            ),
          );
        }

        if (outer.maxHeight < 150 || outer.maxWidth < 210) {
          return _CompactBrakeCard(
            phase: _phase,
            pressure: pressure,
            color: brakeColor,
            percent: percent,
          );
        }

        return AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          width: double.infinity,
          height: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: AppTheme.glassCard(),
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _BrakeTracePainter(
                    pressure: pressure,
                    color: brakeColor,
                  ),
                ),
              ),
              Column(
                children: [
                  Row(
                    children: [
                      Text(
                        'BRAKE',
                        style: AppTheme.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textMuted,
                        ),
                      ),
                      const Spacer(),
                      _StatusPill(label: _phase, color: brakeColor),
                    ],
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          flex: 7,
                          child: _RotorGauge(
                            pressure: pressure,
                            color: brakeColor,
                            percent: percent,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 5,
                          child: _CornerLoadBars(
                            pressure: pressure,
                            color: brakeColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _PressureStrip(pressure: pressure, color: brakeColor),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CompactBrakeCard extends StatelessWidget {
  const _CompactBrakeCard({
    required this.phase,
    required this.pressure,
    required this.color,
    required this.percent,
  });

  final String phase;
  final double pressure;
  final Color color;
  final int percent;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: AppTheme.glassCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  'BRAKE',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textMuted,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: _StatusPill(
                      label: phase,
                      color: color,
                      compact: true,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '$percent%',
                  style: AppTheme.orbitron(
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
              ),
            ),
          ),
          _PressureStrip(pressure: pressure, color: color, compact: true),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.color,
    this.compact = false,
  });

  final String label;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 9,
        vertical: compact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Text(
        label,
        style: AppTheme.orbitron(
          fontSize: compact ? 8 : 9,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _RotorGauge extends StatelessWidget {
  const _RotorGauge({
    required this.pressure,
    required this.color,
    required this.percent,
  });

  final double pressure;
  final Color color;
  final int percent;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size =
            math.min(constraints.maxWidth, constraints.maxHeight) * 0.9;
        return Center(
          child: SizedBox(
            width: size,
            height: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: Size.square(size),
                  painter: _RotorPainter(pressure: pressure, color: color),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 120),
                      child: Text(
                        '$percent',
                        key: ValueKey(percent),
                        style: AppTheme.orbitron(
                          fontSize: _clampDouble(size * 0.26, 18.0, 44.0),
                          fontWeight: FontWeight.w900,
                          color: color,
                        ),
                      ),
                    ),
                    Text(
                      '% PRESS',
                      style: AppTheme.inter(
                        fontSize: _clampDouble(size * 0.065, 7.0, 11.0),
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CornerLoadBars extends StatelessWidget {
  const _CornerLoadBars({required this.pressure, required this.color});

  final double pressure;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final loads = <({String label, double value})>[
      (label: 'FL', value: pressure),
      (label: 'FR', value: _clampDouble(pressure * 0.94, 0.0, 1.0)),
      (label: 'RL', value: _clampDouble(pressure * 0.68, 0.0, 1.0)),
      (label: 'RR', value: _clampDouble(pressure * 0.64, 0.0, 1.0)),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final barWidth = _clampDouble(constraints.maxWidth / 8, 5.0, 10.0);
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'LOAD',
              style: AppTheme.inter(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final load in loads)
                    _LoadBar(
                      label: load.label,
                      value: load.value,
                      color: color,
                      width: barWidth,
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LoadBar extends StatelessWidget {
  const _LoadBar({
    required this.label,
    required this.value,
    required this.color,
    required this.width,
  });

  final String label;
  final double value;
  final Color color;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: width,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(width),
              ),
              alignment: Alignment.bottomCenter,
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 140),
                tween: Tween<double>(
                  begin: 0,
                  end: _clampDouble(value, 0.0, 1.0),
                ),
                builder: (context, animatedValue, child) {
                  return FractionallySizedBox(
                    alignment: Alignment.bottomCenter,
                    heightFactor: animatedValue,
                    child: child,
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(width),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.45),
                        blurRadius: 7,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTheme.inter(
            fontSize: 8,
            fontWeight: FontWeight.w800,
            color: AppTheme.textMuted,
          ),
        ),
      ],
    );
  }
}

class _PressureStrip extends StatelessWidget {
  const _PressureStrip({
    required this.pressure,
    required this.color,
    this.compact = false,
  });

  final double pressure;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: compact ? 16 : 22,
      child: Row(
        children: [
          if (!compact) ...[
            Text(
              'PEDAL',
              style: AppTheme.inter(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 140),
                      width:
                          constraints.maxWidth *
                          _clampDouble(pressure, 0.0, 1.0),
                      height: 6,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.accentCyan,
                            const Color(0xFFFFD938),
                            AppTheme.accentRed,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.5),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BrakeTracePainter extends CustomPainter {
  const _BrakeTracePainter({required this.pressure, required this.color});

  final double pressure;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.10 + pressure * 0.16)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24);
    canvas.drawCircle(
      Offset(size.width * 0.25, size.height * 0.48),
      size.shortestSide * (0.18 + pressure * 0.10),
      glowPaint,
    );

    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (var i = 0; i < 4; i++) {
      final y = size.height * (0.34 + i * 0.12);
      canvas.drawLine(
        Offset(size.width * 0.05, y),
        Offset(size.width * 0.95, y),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BrakeTracePainter oldDelegate) {
    return oldDelegate.pressure != pressure || oldDelegate.color != color;
  }
}

class _RotorPainter extends CustomPainter {
  const _RotorPainter({required this.pressure, required this.color});

  final double pressure;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2;
    final rotorRadius = radius * 0.72;

    final basePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.14
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, rotorRadius, basePaint);

    final pressurePaint = Paint()
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: math.pi * 1.5,
        colors: [
          AppTheme.accentCyan,
          const Color(0xFFFFD938),
          AppTheme.accentRed,
          color,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: rotorRadius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.14
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: rotorRadius),
      -math.pi / 2,
      math.pi * 2 * _clampDouble(pressure, 0.0, 1.0),
      false,
      pressurePaint,
    );

    final caliperPaint = Paint()
      ..color = color.withValues(alpha: 0.95)
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.11
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: rotorRadius + radius * 0.08),
      -0.40,
      0.82,
      false,
      caliperPaint,
    );

    final drillPaint = Paint()..color = Colors.black.withValues(alpha: 0.35);
    for (var i = 0; i < 10; i++) {
      final angle = (math.pi * 2 / 10) * i + pressure * 0.25;
      final point = Offset(
        center.dx + math.cos(angle) * rotorRadius * 0.70,
        center.dy + math.sin(angle) * rotorRadius * 0.70,
      );
      canvas.drawCircle(point, radius * 0.025, drillPaint);
    }

    final hubPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.34)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.34, hubPaint);
  }

  @override
  bool shouldRepaint(covariant _RotorPainter oldDelegate) {
    return oldDelegate.pressure != pressure || oldDelegate.color != color;
  }
}

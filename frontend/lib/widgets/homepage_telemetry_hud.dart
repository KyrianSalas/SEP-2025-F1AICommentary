import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class HomepageTelemetryHud extends StatefulWidget {
  const HomepageTelemetryHud({super.key});

  @override
  State<HomepageTelemetryHud> createState() => _HomepageTelemetryHudState();
}

class _HomepageTelemetryHudState extends State<HomepageTelemetryHud>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final double t = _controller.value;
        final int speed = (228 + (math.sin(t * math.pi * 2) * 46)).round();
        final int rpm = (11200 + (math.cos(t * math.pi * 4) * 1300)).round();
        final double delta = math.sin((t * math.pi * 2) + 0.6) * 0.18;

        return Container(
          width: 182,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0x9A0D1017),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0x1CFFFFFF)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x28000000),
                blurRadius: 18,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    'Telemetry Feed',
                    style: AppTheme.orbitron(
                      fontSize: 10,
                      color: AppTheme.accentCyan,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: const Color(0xFF39FF97),
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x8839FF97),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    speed.toString(),
                    style: AppTheme.orbitron(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(
                      'km/h',
                      style: AppTheme.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _HudBar(
                label: 'Sector pace',
                valueLabel: delta >= 0
                    ? '+${delta.toStringAsFixed(2)}'
                    : delta.toStringAsFixed(2),
                value: ((delta + 0.2) / 0.4).clamp(0.0, 1.0),
                accent: delta <= 0
                    ? const Color(0xFF39FF97)
                    : const Color(0xFFFFD400),
              ),
              const SizedBox(height: 12),
              _HudBar(
                label: 'Engine load',
                valueLabel: '$rpm rpm',
                value: ((rpm - 9000) / 4000).clamp(0.0, 1.0),
                accent: AppTheme.accentRed,
              ),
              const SizedBox(height: 14),
              Text(
                'L${1 + ((t * 6).floor() % 5)}  •  LIVE TRACK',
                style: AppTheme.orbitron(
                  fontSize: 11,
                  color: const Color(0xFFCAD0DB),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HudBar extends StatelessWidget {
  const _HudBar({
    required this.label,
    required this.valueLabel,
    required this.value,
    required this.accent,
  });

  final String label;
  final String valueLabel;
  final double value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textMuted,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Align(
                alignment: Alignment.centerRight,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    valueLabel,
                    maxLines: 1,
                    style: AppTheme.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            minHeight: 6,
            value: value,
            backgroundColor: const Color(0x332A3442),
            valueColor: AlwaysStoppedAnimation<Color>(accent),
          ),
        ),
      ],
    );
  }
}

import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ThrottleDisplay extends StatefulWidget {
  final double currentTime;
  final double throttle;
  final Color backgroundColour;

  const ThrottleDisplay({
    super.key,
    required this.currentTime,
    required this.throttle,
    this.backgroundColour = Colors.white,
  });

  @override
  State<ThrottleDisplay> createState() => _ThrottleDisplayState();
}

class _ThrottleDisplayState extends State<ThrottleDisplay> {
  double _throttle = 0;

  @override
  void initState() {
    super.initState();
    _throttle = widget.throttle;
  }

  @override
  void didUpdateWidget(ThrottleDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentTime != oldWidget.currentTime) {
      setState(() {
        _throttle = widget.throttle;
      });
    }
  }

  int get _imageIndex {
    final clamped = _throttle.clamp(0.0, 100.0);
    return (clamped / 10).ceil().clamp(1, 10);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraintsOver) {
        if (constraintsOver.maxHeight < 80 || constraintsOver.maxWidth < 90) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: AppTheme.glassCard(),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '${_throttle.toStringAsFixed(0)}%',
                  style: AppTheme.orbitron(
                    fontSize: 16,
                    color: const Color.fromARGB(255, 20, 113, 134),
                  ),
                ),
              ),
            ),
          );
        }

        return Container(
          width: double.infinity,
          height: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: AppTheme.glassCard(),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final widthScale = (constraints.maxWidth / 160).clamp(0.7, 1.0);
              const heightScale = 1.0;
              final scale = min(widthScale, heightScale);
              final labelSize = (constraints.maxHeight * 0.08 * scale).clamp(
                6.0,
                12.0,
              );
              final percentSize = (constraints.maxHeight * 0.12 * scale).clamp(
                9.0,
                22.0,
              );

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'THROTTLE',
                      style: AppTheme.inter(
                        fontSize: labelSize,
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, innerConstraints) {
                        final availableSize = min(
                          innerConstraints.maxWidth * 0.85,
                          innerConstraints.maxHeight * 0.85,
                        );

                        if (availableSize < 30) return const SizedBox.shrink();

                        return Center(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 100),
                            child: FractionallySizedBox(
                              key: ValueKey(_imageIndex),
                              widthFactor: 0.7,
                              heightFactor: 0.7,
                              child: Image.asset(
                                'assets/throttle$_imageIndex.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  if (constraints.maxHeight >= 34)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '${_throttle.toStringAsFixed(1)}%',
                        style: AppTheme.orbitron(
                          fontSize: percentSize,
                          color: const Color.fromARGB(255, 20, 113, 134),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

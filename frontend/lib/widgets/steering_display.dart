import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SteeringDisplay extends StatefulWidget {
  final double currentTime;
  final double currentAngle;
  final Color backgroundColour;

  const SteeringDisplay({
    super.key,
    required this.currentTime,
    required this.currentAngle,
    this.backgroundColour = Colors.white,
  });

  @override
  State<SteeringDisplay> createState() => _SteeringDisplayState();
}

class _SteeringDisplayState extends State<SteeringDisplay> {
  double _steeringAngle = 0;

  @override
  void initState() {
    super.initState();
    _steeringAngle = widget.currentAngle;
  }

  @override
  void didUpdateWidget(SteeringDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentTime != oldWidget.currentTime) {
      setState(() {
        _steeringAngle = widget.currentAngle;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // normalise angle for AnimatedRotation (expects turns, not radians)
    double displayAngle = _steeringAngle < 0
        ? 360 + _steeringAngle
        : _steeringAngle;
    return LayoutBuilder(
      builder: (context, constraintsOver) {
        if (constraintsOver.maxHeight < 52) {
          return const Center(child: CircularProgressIndicator());
        }
        return Container(
          width: double.infinity,
          height: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: AppTheme.glassCard(),
          child: LayoutBuilder(
            builder: (context, constraints) {
              //add width based scaling
              final widthScale = (constraints.maxWidth / 160).clamp(0.7, 1.0);
              final heightScale = 1.0;
              final scale = min(widthScale, heightScale);
              final labelSize = (constraints.maxHeight * 0.08 * scale).clamp(
                6.0,
                12.0,
              );
              final angleSize = (constraints.maxHeight * 0.12 * scale).clamp(
                9.0,
                22.0,
              );

              return Column(
                children: [
                  // label
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'STEERING',
                      style: AppTheme.inter(
                        fontSize: labelSize,
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  // rotating wheel
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, innerConstraints) {
                        final availableSize = min(
                          innerConstraints.maxWidth * 0.85,
                          innerConstraints.maxHeight * 0.85,
                        );

                        if (availableSize < 30) return const SizedBox.shrink();

                        return Center(
                          child: AnimatedRotation(
                            turns: displayAngle / 360,
                            duration: const Duration(milliseconds: 150),
                            curve: Curves.easeOut,
                            child: FractionallySizedBox(
                              widthFactor: 0.7,
                              heightFactor: 0.7,
                              child: Image.asset(
                                'assets/wheel2.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // degree readout (carefully chosen constant value below)
                  if (constraints.maxHeight >= 34)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '${_steeringAngle.toStringAsFixed(1)}°',
                        style: AppTheme.orbitron(
                          fontSize: angleSize,
                          color: AppTheme.textPrimary,
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

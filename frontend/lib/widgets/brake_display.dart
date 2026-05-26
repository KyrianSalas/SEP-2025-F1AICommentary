import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class BrakeDisplay extends StatefulWidget {
  //percent shown 0-1
  final double brakePos;
  final double currentTime;
  final Color backgroundColour;

  const BrakeDisplay({
    super.key,
    required this.brakePos,
    required this.currentTime,
    this.backgroundColour = Colors.white,
  });

  @override
  State<BrakeDisplay> createState() => _BrakeDisplayState();
}

class _BrakeDisplayState extends State<BrakeDisplay> {
  double _currentBrake = 0.0;

  @override
  void initState() {
    super.initState();
    _currentBrake = widget.brakePos.clamp(0.0, 1.0);
  }

  @override
  void didUpdateWidget(BrakeDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentTime != oldWidget.currentTime ||
        widget.brakePos != oldWidget.brakePos) {
      setState(() {
        _currentBrake = widget.brakePos.clamp(0.0, 1.0);
      });
    }
  }

  // colour from green through yellow to red based on brake pressure
  Color _getBrakeDisplayColour(double brakePos) {
    double percentage = brakePos.clamp(0.0, 1.0);
    if (percentage < 0.5) {
      return Color.lerp(Colors.green, Colors.yellow, percentage * 2)!;
    } else {
      return Color.lerp(
        Colors.yellow,
        AppTheme.accentRed,
        (percentage - 0.5) * 2,
      )!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final int percent = (_currentBrake * 100).clamp(0, 100).toInt();
    final brakeColor = _getBrakeDisplayColour(_currentBrake);
    return LayoutBuilder(
      builder: (context, constraintsOver) {
        if (constraintsOver.maxHeight < 52) {
          return const Center(child: CircularProgressIndicator());
        }
        return Container(
          width: double.infinity,
          height: double.infinity,
          decoration: AppTheme.glassCard(),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final widthScale = (constraints.maxWidth / 160).clamp(0.7, 1.0);
              final labelSize = (constraints.maxHeight * 0.07 * widthScale)
                  .clamp(6.0, 12.0);
              final percentSize = (constraints.maxHeight * 0.16 * widthScale)
                  .clamp(9.0, 32.0);
              final barWidth = (constraints.maxWidth * 0.14).clamp(10.0, 24.0);
              final barHeight = constraints.maxHeight * 0.5;

              return Column(
                children: [
                  // label
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Center(
                      child: Text(
                        'BRAKE',
                        style: AppTheme.inter(
                          fontSize: labelSize,
                          color: AppTheme.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  // percentage readout
                  Text(
                    '$percent%',
                    style: AppTheme.orbitron(
                      fontSize: percentSize,
                      color: brakeColor,
                    ),
                  ),

                  // vertical bar
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, innerConstraints) {
                        final availableSize = innerConstraints.maxHeight;

                        if (availableSize < 15) return const SizedBox.shrink();
                        return Center(
                          child: SizedBox(
                            width: barWidth,
                            height: barHeight,
                            child: Stack(
                              alignment: Alignment.bottomCenter,
                              children: [
                                // background track
                                Container(
                                  width: barWidth,
                                  height: barHeight,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2A2A2A),
                                    borderRadius: BorderRadius.circular(
                                      barWidth / 2,
                                    ),
                                  ),
                                ),
                                // filled portion
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 120),
                                  width: barWidth,
                                  height:
                                      barHeight * _currentBrake.clamp(0.0, 1.0),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(
                                      barWidth / 2,
                                    ),
                                    gradient: LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: [
                                        Colors.green,
                                        Colors.yellow,
                                        AppTheme.accentRed,
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: brakeColor.withAlpha(60),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

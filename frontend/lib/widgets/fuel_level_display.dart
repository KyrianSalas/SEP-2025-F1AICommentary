import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class FuelLevelGraph extends StatefulWidget {
  final double currentTime;
  final double currentFuel;
  final double bufferSeconds;
  final double minFuel;
  final double maxFuel;
  final Color backgroundColour;

  const FuelLevelGraph({
    super.key,
    required this.currentTime,
    required this.currentFuel,
    this.bufferSeconds = 30.0,
    this.minFuel = 0.0,
    this.maxFuel = 79.0,
    this.backgroundColour = Colors.white,
  });

  @override
  State<FuelLevelGraph> createState() => _FuelGraphState();
}

class _FuelGraphState extends State<FuelLevelGraph> {
  // fuel level colour: green when full, amber mid, red when low
  Color _getFuelColor(double fraction) {
    if (fraction > 0.5) return const Color(0xFF00CC66);
    if (fraction > 0.25) return const Color(0xFFFFAA00);
    return AppTheme.accentRed;
  }

  @override
  Widget build(BuildContext context) {
    final fraction = widget.maxFuel > 0
        ? (widget.currentFuel / widget.maxFuel).clamp(0.0, 1.0)
        : 0.0;
    final percent = (fraction * 100).toInt();
    final fuelColor = _getFuelColor(fraction);
    const int totalSegments = 10;
    final int litSegments = (fraction * totalSegments).ceil();
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
              final litresSize = (constraints.maxHeight * 0.14 * widthScale)
                  .clamp(14.0, 30.0);
              final percentSize = (constraints.maxHeight * 0.08 * widthScale)
                  .clamp(9.0, 16.0);

              return Column(
                children: [
                  // label
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'FUEL',
                      style: AppTheme.inter(
                        fontSize: labelSize,
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  // litres readout
                  Text(
                    '${widget.currentFuel.toStringAsFixed(1)} L',
                    style: AppTheme.orbitron(
                      fontSize: litresSize,
                      color: fuelColor,
                    ),
                  ),

                  // segmented fuel gauge
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: constraints.maxWidth * 0.15,
                        vertical: 4,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: List.generate(totalSegments, (index) {
                          // segments are drawn top-down, so segment 0 = top = full
                          final segmentIndex = totalSegments - 1 - index;
                          final isLit = segmentIndex < litSegments;

                          return Expanded(
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 1),
                              decoration: BoxDecoration(
                                color: isLit
                                    ? fuelColor.withAlpha(200)
                                    : const Color(0xFF1E1E1E),
                                borderRadius: BorderRadius.circular(3),
                                boxShadow: isLit
                                    ? [
                                        BoxShadow(
                                          color: fuelColor.withAlpha(40),
                                          blurRadius: 4,
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),

                  // percentage (carefully chosen constant value below)
                  if (constraints.maxHeight >= 58)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        '$percent%',
                        style: AppTheme.orbitron(
                          fontSize: percentSize,
                          color: AppTheme.textMuted,
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

// FuelPoint kept for interface compatibility
class FuelPoint {
  final double time;
  final double fuel;
  FuelPoint(this.time, this.fuel);
}

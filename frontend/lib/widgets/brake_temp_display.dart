import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'brake_temp_spin.dart';
import 'dart:math';

class BTDisplay extends StatefulWidget {
  final double currentTime;
  final double bTFR;
  final double bTFL;
  final double bTBL;
  final double bTBR;
  final double maxTemp;
  final Color backgroundColour;
  final String baseAssetPath;
  final String spinningAssetPath;
  final double sBRPM;
  final bool pause;

  const BTDisplay({
    super.key,
    required this.currentTime,
    required this.bTFR,
    required this.bTFL,
    required this.bTBL,
    required this.bTBR,
    required this.sBRPM,
    required this.pause,
    this.maxTemp = 1500.0,
    this.backgroundColour = Colors.white,
    this.baseAssetPath = 'assets/brake_base.png',
    this.spinningAssetPath = 'assets/brake_needle.png',
  });

  @override
  State<BTDisplay> createState() => _BTDisplayState();
}

class _BTDisplayState extends State<BTDisplay> {
  double _currentTemp = 0;

  @override
  void initState() {
    super.initState();
    _currentTemp =
        (widget.bTFR + widget.bTFL + widget.bTBR + widget.bTBL) / 4.0;
  }

  @override
  void didUpdateWidget(BTDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentTime != oldWidget.currentTime) {
      setState(() {
        _currentTemp =
            (widget.bTFR + widget.bTFL + widget.bTBR + widget.bTBL) / 4.0;
      });
    }
  }

  // brake temp colours, brightened for dark backgrounds
  Color _getBTColor(double currentTemp, double maxTemp) {
    if (currentTemp < 300.0) {
      return Color.lerp(
        const Color(0xFF6688AA),
        const Color(0xFF8866AA),
        currentTemp / 300,
      )!;
    } else if (currentTemp < 500.0) {
      return Color.lerp(
        const Color(0xFF8866AA),
        const Color(0xFFCC2200),
        (currentTemp - 300) / 200,
      )!;
    } else if (currentTemp < 700.0) {
      return Color.lerp(
        const Color.fromARGB(255, 140, 0, 0),
        Color.fromARGB(255, 220, 20, 0),
        (currentTemp - 500) / 200,
      )!;
    } else if (currentTemp < 900.0) {
      return Color.lerp(
        const Color.fromARGB(255, 220, 20, 0),
        Color.fromARGB(255, 255, 90, 0),
        (currentTemp - 700) / 200,
      )!;
    } else if (currentTemp < 1100.0) {
      return Color.lerp(
        const Color.fromARGB(255, 255, 90, 0),
        Color.fromARGB(255, 255, 190, 0),
        (currentTemp - 900) / 200,
      )!;
    } else {
      return Color.lerp(
        const Color.fromARGB(255, 255, 190, 0),
        Color.fromARGB(255, 255, 255, 160),
        (currentTemp - 1100) / (maxTemp - 1100),
      )!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tempColor = _getBTColor(_currentTemp, widget.maxTemp);
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
              final widthScale = (constraints.maxWidth / 160).clamp(0.3, 1.0);
              final labelSize = (constraints.maxHeight * 0.06 * widthScale)
                  .clamp(6.0, 11.0);
              final tempSize = (constraints.maxHeight * 0.13 * widthScale)
                  .clamp(9.0, 28.0);
              final wheelSize = (constraints.maxHeight * 0.38).clamp(
                40.0,
                120.0,
              );
              final cornerSize = (constraints.maxHeight * 0.07 * widthScale)
                  .clamp(5.0, 10.0);

              return Column(
                children: [
                  // label
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'BRAKE TEMP',
                      style: AppTheme.inter(
                        fontSize: labelSize,
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  // avg temp readout
                  Text(
                    '${_currentTemp.toStringAsFixed(0)}°C',
                    style: AppTheme.orbitron(
                      fontSize: tempSize,
                      color: tempColor,
                    ),
                  ),

                  // spinning wheel
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, innerConstraints) {
                        final availableSize = min(
                          innerConstraints.maxWidth * 0.85,
                          innerConstraints.maxHeight * 0.85,
                        );
                        if (availableSize < 37) return const SizedBox.shrink();
                        return Center(
                          child: BrakeTempSpin(
                            size: wheelSize,
                            circleColor: tempColor,
                            pause: widget.pause,
                            sBrpm: widget.sBRPM,
                          ),
                        );
                      },
                    ),
                  ),

                  // corner temps row
                  if (constraints.maxHeight >= 80 && constraints.maxWidth > 70)
                    Padding(
                      padding: const EdgeInsets.only(
                        bottom: 6,
                        left: 8,
                        right: 8,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _cornerTemp('FL', widget.bTFL, cornerSize),
                          _cornerTemp('FR', widget.bTFR, cornerSize),
                          _cornerTemp('RL', widget.bTBL, cornerSize),
                          _cornerTemp('RR', widget.bTBR, cornerSize),
                        ],
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

  Widget _cornerTemp(String label, double temp, double fontSize) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: AppTheme.inter(
            fontSize: fontSize * 0.85,
            color: AppTheme.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          '${temp.toStringAsFixed(0)}°',
          style: AppTheme.orbitron(
            fontSize: fontSize,
            color: _getBTColor(temp, widget.maxTemp),
          ),
        ),
      ],
    );
  }
}

import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GearDisplay extends StatefulWidget {
  final double currentTime;
  final int gear; 

  const GearDisplay({
    super.key,
    required this.currentTime,
    required this.gear,
  });

  @override
  State<GearDisplay> createState() => _GearDisplayState();
}

class _GearDisplayState extends State<GearDisplay> {
  int _gear = 0;

  @override
  void initState() {
    super.initState();
    _gear = widget.gear;
  }

  @override
  void didUpdateWidget(GearDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentTime != oldWidget.currentTime) {
      setState(() {
        _gear = widget.gear;
      });
    }
  }

  Color get _gearColour {
    switch (_gear) {
      case -1: return const Color(0xFF7B5EA7); 
      case 0:  return const Color(0xFF4A9B7F); 
      case 1:  return const Color(0xFF2196F3); 
      case 2:  return const Color(0xFF00BCD4); 
      case 3:  return const Color(0xFF4CAF50); 
      case 4:  return const Color(0xFFCDDC39); 
      case 5:  return const Color(0xFFFFD600); 
      case 6:  return const Color(0xFFFF9800); 
      case 7:  return const Color(0xFFFF5722); 
      case 8:  return const Color(0xFFD32F2F); 
      default: return const Color(0xFF4A9B7F);
    }
  }

  String get _gearLabel {
    if (_gear == -1) return 'R';
    if (_gear == 0)  return 'N';
    return _gear.toString();
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
                  _gearLabel,
                  style: AppTheme.orbitron(
                    fontSize: 24,
                    color: _gearColour,
                    fontWeight: FontWeight.w700,
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
              final scale = min(widthScale, 1.0);

              final labelSize =
                  (constraints.maxHeight * 0.08 * scale).clamp(6.0, 12.0);
              final gearSize =
                  (constraints.maxHeight * 0.55 * scale).clamp(20.0, 80.0);

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Gear',
                    style: AppTheme.inter(
                      fontSize: labelSize,
                      color: AppTheme.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 120),
                    transitionBuilder: (child, animation) =>
                        ScaleTransition(scale: animation, child: child),
                    child: Text(
                      _gearLabel,
                      key: ValueKey(_gearLabel),
                      style: AppTheme.orbitron(
                        fontSize: gearSize,
                        color: _gearColour,
                        fontWeight: FontWeight.w700,
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
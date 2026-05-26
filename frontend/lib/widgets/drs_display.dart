import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class DrsDisplay extends StatefulWidget {
  final double currentTime;
  final int drsState;
  final Color backgroundColour;

  const DrsDisplay({
    super.key,
    required this.currentTime,
    required this.drsState,
    this.backgroundColour = Colors.white,
  });

  @override
  State<DrsDisplay> createState() => _DrsDisplayState();
}

class _DrsDisplayState extends State<DrsDisplay> {
  int _drsState = 0;

  @override
  void initState() {
    super.initState();
    _drsState = widget.drsState;
  }

  @override
  void didUpdateWidget(DrsDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentTime != oldWidget.currentTime) {
      setState(() {
        _drsState = widget.drsState;
      });
    }
  }

  String get _statusLabel {
    if (_drsState == 14) {
      return 'FORCE CLOSED DRS';
    } else if (_drsState == 1) {
      return 'CAN ACTIVATE DRS';
    } else if (_drsState == 8 || _drsState == 10 || _drsState == 12) {
      return 'DRS ACTIVE';
    } else {
      return 'DRS INACTIVE';
    }
  }

  String get _imagePath {
    if (_drsState == 8 || _drsState == 10 || _drsState == 12) {
      return 'assets/DRSopened.png';
    } else {
      return 'assets/DRSclosed.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraintsOver) {
        if (constraintsOver.maxHeight < 80 || constraintsOver.maxWidth < 90) {
          final compactLabel =
              (_drsState == 8 || _drsState == 10 || _drsState == 12)
              ? 'DRS ON'
              : 'DRS OFF';
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: AppTheme.glassCard(),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  compactLabel,
                  style: AppTheme.orbitron(
                    fontSize: 14,
                    color: AppTheme.textPrimary,
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
              final statusSize = (constraints.maxHeight * 0.12 * scale).clamp(
                9.0,
                22.0,
              );

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'DRS',
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
                            duration: const Duration(milliseconds: 150),
                            child: FractionallySizedBox(
                              key: ValueKey(_imagePath),
                              widthFactor: 0.7,
                              heightFactor: 0.7,
                              child: Image.asset(
                                _imagePath,
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
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Text(
                          _statusLabel,
                          key: ValueKey(_statusLabel),
                          style: AppTheme.orbitron(
                            fontSize: statusSize,
                            color: AppTheme.textPrimary,
                          ),
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

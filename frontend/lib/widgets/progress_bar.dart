import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class RaceProgressBar extends StatefulWidget {
  final double progress;
  final double? ghostProgress;
  final double? deltaToBest;
  final int totalRaceLength;
  final List<int> lapStartTimes;
  final String carAssetPath;
  final double lapFontSize;
  final double lapTickHeight;
  final double lapTickWidth;
  final bool compact;

  //update progress for variable change
  final void Function(double)? onProgressChanged;

  const RaceProgressBar({
    super.key,
    required this.progress,
    this.ghostProgress,
    this.deltaToBest,
    required this.totalRaceLength,
    required this.lapStartTimes,
    required this.carAssetPath,
    this.onProgressChanged,
    this.lapFontSize = 12.0,
    this.lapTickHeight = 0.04,
    this.lapTickWidth = 0.005,
    this.compact = false,
  });

  @override
  State<RaceProgressBar> createState() => _RaceProgressBarState();
}

class _RaceProgressBarState extends State<RaceProgressBar> {
  //these values are used for sizing reasons, may be adjusted at will (easier to see here as only used once, rather than making a constant)
  double _horizontalInset(double width) =>
      width * (widget.compact ? 0.035 : 0.05);
  double _barHeight(double width) =>
      (width * 0.008).clamp(widget.compact ? 3.0 : 4.0, 6.0).toDouble();
  double _lineY(double height) => height * (widget.compact ? 0.58 : 0.54);

  //smooths travel of pilot
  double? _localProgress;

  //make values usable positionally
  List<double> _computeLapPositions() {
    if (widget.totalRaceLength <= 0) return [];
    return widget.lapStartTimes
        .map((t) => (t / widget.totalRaceLength).clamp(0.0, 1.0).toDouble())
        .toList();
  }

  int _labelStride(double width, int lapCount) {
    if (lapCount <= 24 || width >= 620) {
      return 1;
    }
    if (width < 420) {
      return 5;
    }
    return 3;
  }

  bool _shouldShowLapLabel(int index, int lapCount, double width) {
    final stride = _labelStride(width, lapCount);
    final lastLabelIndex = lapCount > 1 ? lapCount - 2 : 0;
    return index == 0 || index == lastLabelIndex || index % stride == 0;
  }

  //take control movements and make usable
  double _dxToProgress(double dx, double totalWidth, double horizontalInset) {
    final usable = (totalWidth - 2 * horizontalInset)
        .clamp(1.0, double.infinity)
        .toDouble();
    double localX = (dx - horizontalInset).clamp(0.0, usable).toDouble();
    return (localX / usable).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final lapPositions = _computeLapPositions();
    final displayProgress = (_localProgress ?? widget.progress).clamp(0.0, 1.0);

    return Container(
      decoration: AppTheme.glassCard(borderRadius: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = constraints.maxWidth;
          final totalHeight =
              constraints.maxHeight.isFinite && constraints.maxHeight > 0
              ? constraints.maxHeight
              : (widget.compact ? 58.0 : 68.0);
          final horizontalInset = _horizontalInset(totalWidth);
          final barHeight = _barHeight(totalWidth);
          final lineY = _lineY(totalHeight);
          final usableWidth = (totalWidth - 2 * horizontalInset)
              .clamp(1.0, double.infinity)
              .toDouble();
          final lineLeft = horizontalInset;

          final double carCenterX = lineLeft + usableWidth * displayProgress;
          final double? ghostCenterX = widget.ghostProgress == null
              ? null
              : lineLeft + usableWidth * widget.ghostProgress!.clamp(0.0, 1.0);
          final double? delta = widget.deltaToBest;
          final bool hasDelta = delta != null;
          final Color deltaColor = !hasDelta
              ? AppTheme.textMuted
              : (delta <= 0 ? const Color(0xFF00D97E) : AppTheme.accentRed);
          final String deltaText = !hasDelta
              ? '--'
              : '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(3)}';

          return GestureDetector(
            behavior: HitTestBehavior.opaque,

            //tap to move
            onTapDown: (details) {
              final p = _dxToProgress(
                details.localPosition.dx,
                totalWidth,
                horizontalInset,
              );

              setState(() => _localProgress = p);
              widget.onProgressChanged?.call(p);
              _localProgress = null;
            },

            //drag to move
            onPanDown: (details) {
              final p = _dxToProgress(
                details.localPosition.dx,
                totalWidth,
                horizontalInset,
              );

              setState(() => _localProgress = p);
            },

            //update for dragging
            onPanUpdate: (details) {
              final p = _dxToProgress(
                details.localPosition.dx,
                totalWidth,
                horizontalInset,
              );

              setState(() => _localProgress = p);
            },

            //release dragging
            onPanEnd: (_) {
              if (_localProgress != null) {
                widget.onProgressChanged?.call(_localProgress!);
              }

              setState(() => _localProgress = null);
            },

            child: SizedBox(
              height: totalHeight,
              child: Stack(
                children: [
                  // background track
                  Positioned(
                    left: lineLeft,
                    right: horizontalInset,
                    top: lineY - (barHeight / 2),
                    child: Container(
                      height: barHeight,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2A2A),
                        borderRadius: BorderRadius.circular(barHeight / 2),
                      ),
                    ),
                  ),

                  // gradient progress fill
                  Positioned(
                    left: lineLeft,
                    top: lineY - (barHeight / 2),
                    child: Container(
                      width: usableWidth * displayProgress,
                      height: barHeight,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(barHeight / 2),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF440000), AppTheme.accentRed],
                        ),
                      ),
                    ),
                  ),

                  //add the lap markers
                  for (int i = 0; i < lapPositions.length - 1; i++)
                    Builder(
                      builder: (context) {
                        final pos = lapPositions[i];
                        final px = lineLeft + pos * usableWidth;
                        final showLabel = _shouldShowLapLabel(
                          i,
                          lapPositions.length,
                          totalWidth,
                        );

                        //find label width (min 3 chars so lap 20+ don't get clipped)
                        final lapNumber = i + 1;
                        final labelText = "$lapNumber";
                        final estimatedCharWidth = widget.lapFontSize * 0.6;
                        final labelWidth =
                            (labelText.length * estimatedCharWidth)
                                .clamp(estimatedCharWidth * 3, double.infinity)
                                .toDouble();

                        //clamp to screen and center label
                        double labelLeft = px - (labelWidth / 2);
                        labelLeft = labelLeft
                            .clamp(0.0, totalWidth - labelWidth)
                            .toDouble();

                        return Stack(
                          children: [
                            // lap number label
                            if (showLabel)
                              Positioned(
                                left: labelLeft,
                                top: totalHeight * 0.05,
                                width: labelWidth,
                                child: Text(
                                  labelText,
                                  textAlign: TextAlign.center,
                                  style: AppTheme.inter(
                                    fontSize:
                                        widget.lapFontSize *
                                        (widget.compact ? 0.86 : 1.0),
                                    color: AppTheme.textMuted,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.visible,
                                ),
                              ),

                            // tick mark (rounded to match widget style)
                            Positioned(
                              left: px - (totalWidth * widget.lapTickWidth / 2),
                              top:
                                  lineY -
                                  (totalHeight * widget.lapTickHeight / 2),
                              child: Container(
                                width: totalWidth * widget.lapTickWidth,
                                height: totalHeight * widget.lapTickHeight,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF555555),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                  // finish marker (rounded)
                  if (lapPositions.isNotEmpty)
                    Positioned(
                      left: lineLeft + lapPositions.last * usableWidth - 1.5,
                      top: lineY - (totalHeight * 0.04),
                      child: Container(
                        width: 3,
                        height: totalHeight * 0.08,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                  // glowing progress dot on the line
                  Positioned(
                    left: carCenterX - 6,
                    top: lineY - 6,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.accentRed,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.accentRed.withAlpha(120),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (ghostCenterX != null)
                    Positioned(
                      left: ghostCenterX - 5,
                      top: lineY - 5,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF00D2FF),
                          border: Border.all(
                            color: const Color(0xFFB6F3FF),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00D2FF).withAlpha(120),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                  Positioned(
                    right: 6,
                    top: 0,
                    child: Text(
                      deltaText,
                      style: AppTheme.orbitron(
                        fontSize: 10,
                        color: deltaColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

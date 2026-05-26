import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'homepage_track_background.dart';

class FastF1BrowserBackdrop extends StatelessWidget {
  const FastF1BrowserBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF06070B), Color(0xFF10111F), Color(0xFF190909)],
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool isWide = constraints.maxWidth >= 920;
            final double trackWidth =
                constraints.maxWidth * (isWide ? 0.66 : 1.08);
            final double trackHeight =
                constraints.maxHeight * (isWide ? 0.72 : 0.44);

            return Stack(
              children: [
                const Positioned.fill(
                  child: CustomPaint(painter: _FastF1GridPainter()),
                ),
                Positioned(
                  top: isWide ? -132 : -104,
                  right: isWide ? -72 : -120,
                  child: _BackdropGlow(
                    size: isWide ? 390 : 300,
                    color: AppTheme.accentRed,
                    opacity: isWide ? 0.22 : 0.18,
                  ),
                ),
                Positioned(
                  bottom: isWide ? -152 : -108,
                  left: isWide ? -80 : -130,
                  child: _BackdropGlow(
                    size: isWide ? 430 : 320,
                    color: AppTheme.accentCyan,
                    opacity: isWide ? 0.16 : 0.12,
                  ),
                ),
                Positioned(
                  right: isWide ? -42 : -64,
                  top: isWide ? 88 : 126,
                  child: Opacity(
                    opacity: isWide ? 0.74 : 0.42,
                    child: ShaderMask(
                      shaderCallback: (bounds) {
                        return const LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Colors.transparent,
                            Colors.white,
                            Colors.white,
                            Colors.transparent,
                          ],
                          stops: [0.0, 0.16, 0.84, 1.0],
                        ).createShader(bounds);
                      },
                      blendMode: BlendMode.dstIn,
                      child: SizedBox(
                        width: trackWidth,
                        height: trackHeight,
                        child: const HomepageTrackBackground(opacity: 1),
                      ),
                    ),
                  ),
                ),
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x00000000),
                          Color(0x6606070B),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BackdropGlow extends StatelessWidget {
  const _BackdropGlow({
    required this.size,
    required this.color,
    required this.opacity,
  });

  final double size;
  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: opacity),
            color.withValues(alpha: opacity * 0.28),
            Colors.transparent,
          ],
          stops: const [0.0, 0.42, 1.0],
        ),
      ),
    );
  }
}

class _FastF1GridPainter extends CustomPainter {
  const _FastF1GridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint majorPaint = Paint()
      ..color = const Color(0x14FFFFFF)
      ..strokeWidth = 1;
    final Paint minorPaint = Paint()
      ..color = const Color(0x0BFFFFFF)
      ..strokeWidth = 1;

    const double majorGap = 56;
    const double minorGap = 28;

    for (double x = 0; x <= size.width; x += minorGap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), minorPaint);
    }
    for (double y = 0; y <= size.height; y += minorGap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), minorPaint);
    }
    for (double x = 0; x <= size.width; x += majorGap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), majorPaint);
    }
    for (double y = 0; y <= size.height; y += majorGap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), majorPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

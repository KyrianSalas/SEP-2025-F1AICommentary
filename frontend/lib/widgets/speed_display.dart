import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SpeedGraph extends StatefulWidget {
  final double currentTime;
  final double currentSpeed;
  final double bufferSeconds;
  final double minSpeed;
  final double maxSpeed;
  final Color backgroundColour;

  const SpeedGraph({
    super.key,
    required this.currentTime,
    required this.currentSpeed,
    this.bufferSeconds = 10.0,
    this.minSpeed = 0.0,
    this.maxSpeed = 200.0,
    this.backgroundColour = Colors.white,
  });

  @override
  State<SpeedGraph> createState() => _SpeedGraphState();
}

class _SpeedGraphState extends State<SpeedGraph> {
  final List<SpeedPoint> _speedData = [];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  //send update
  @override
  void didUpdateWidget(SpeedGraph oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentTime > oldWidget.currentTime) {
      _updateSpeedData();
    }

    // clear if travelled backwards in time
    if (widget.currentTime < oldWidget.currentTime) {
      _speedData.clear();
    }
  }

  void _initializeData() {
    _speedData.clear();
  }

  void _updateSpeedData() {
    //add next speed point
    double newSpeed = widget.currentSpeed;
    _speedData.add(SpeedPoint(widget.currentTime, newSpeed));

    //add cut off for old data
    double cutoffTime = widget.currentTime - widget.bufferSeconds;
    _speedData.removeWhere((point) => point.time < cutoffTime);

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: AppTheme.glassCard(),
      clipBehavior: Clip.antiAlias,
      child: _speedData.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.accentCyan),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxHeight < 88 || constraints.maxWidth < 110;
                if (compact) {
                  return Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '${widget.currentSpeed.toInt()} km/h',
                        style: AppTheme.orbitron(
                          fontSize: 18,
                          color: AppTheme.accentCyan,
                        ),
                      ),
                    ),
                  );
                }

                final widthScale = (constraints.maxWidth / 200).clamp(0.2, 1.0);
                final fontSize1 = (10 * widthScale).clamp(7.0, 10.0);
                final fontSize2 = (constraints.maxHeight * 0.2 * widthScale)
                    .clamp(14.0, 48.0);
                final fontSize3 = (10 * widthScale).clamp(7.0, 10.0);
                return Stack(
                  children: [
                    // the chart fills the entire card
                    Positioned.fill(
                      child: CustomPaint(
                        painter: SpeedGraphPainter(
                          speedData: _speedData,
                          minSpeed: widget.minSpeed,
                          maxSpeed: widget.maxSpeed,
                          bufferSeconds: widget.bufferSeconds,
                          currentTime: widget.currentTime,
                        ),
                      ),
                    ),

                    // top-left label
                    Positioned(
                      top: 10,
                      left: 12,
                      child: Text(
                        'SPEED',
                        style: AppTheme.inter(
                          fontSize: fontSize1,
                          color: AppTheme.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    // big current speed readout top-right
                    Positioned(
                      top: 16,
                      right: 12,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            widget.currentSpeed.toInt().toString(),
                            style: AppTheme.orbitron(
                              fontSize: fontSize2,
                              color: AppTheme.accentCyan,
                            ),
                          ),
                          Text(
                            'km/h',
                            style: AppTheme.inter(
                              fontSize: fontSize3,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

class SpeedPoint {
  final double time;
  final double speed;

  SpeedPoint(this.time, this.speed);
}

class SpeedGraphPainter extends CustomPainter {
  final List<SpeedPoint> speedData;
  final double minSpeed;
  final double maxSpeed;
  final double bufferSeconds;
  final double currentTime;

  SpeedGraphPainter({
    required this.speedData,
    required this.minSpeed,
    required this.maxSpeed,
    required this.bufferSeconds,
    required this.currentTime,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (speedData.isEmpty) return;

    // subtle dark grid lines
    final gridPaint = Paint()
      ..color = const Color(0xFF2A2A2A)
      ..strokeWidth = 0.5;

    const int numLines = 4;
    for (int i = 1; i < numLines; i++) {
      final y = size.height * (i / numLines);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // build the line path
    final minTime = currentTime - bufferSeconds;
    final linePath = Path();
    bool firstPoint = true;
    double lastX = 0;
    double lastY = size.height;

    for (var point in speedData) {
      if (point.time < minTime) continue;

      final x = ((point.time - minTime) / bufferSeconds) * size.width;
      final normalised = ((point.speed - minSpeed) / (maxSpeed - minSpeed))
          .clamp(0.0, 1.0);
      final y = size.height - (normalised * size.height);

      if (firstPoint) {
        linePath.moveTo(x, y);
        firstPoint = false;
      } else {
        linePath.lineTo(x, y);
      }
      lastX = x;
      lastY = y;
    }

    // gradient area fill under the line
    final areaPath = Path.from(linePath)
      ..lineTo(lastX, size.height)
      ..lineTo(
        speedData.first.time < minTime
            ? 0
            : ((speedData.first.time - minTime) / bufferSeconds) * size.width,
        size.height,
      )
      ..close();

    final areaGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        AppTheme.accentCyan.withAlpha(60),
        AppTheme.accentCyan.withAlpha(5),
      ],
    );

    final areaPaint = Paint()
      ..shader = areaGradient.createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      );
    canvas.drawPath(areaPath, areaPaint);

    // glow behind the line
    final glowPaint = Paint()
      ..color = AppTheme.accentCyan.withAlpha(40)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawPath(linePath, glowPaint);

    // the main line
    final linePaint = Paint()
      ..color = AppTheme.accentCyan
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(linePath, linePaint);

    // bright dot at the latest point
    final dotPaint = Paint()..color = AppTheme.accentCyan;
    canvas.drawCircle(Offset(lastX, lastY), 3, dotPaint);
    final dotGlow = Paint()
      ..color = AppTheme.accentCyan.withAlpha(60)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(Offset(lastX, lastY), 6, dotGlow);
  }

  @override
  bool shouldRepaint(SpeedGraphPainter oldDelegate) => true;
}

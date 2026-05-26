import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';
import 'car_on_map.dart';
import 'driver_telemetry_struct.dart';
import 'multi_cars_on_map.dart';

class MapDisplay extends StatelessWidget {
  final List<Map<String, dynamic>> coordinates;
  final List<List<Map<String, dynamic>>> coordinatesGroup;
  final Color dotColor;
  final double dotSize;
  final Color backgroundColor;
  final double padding;
  final double finishSize;
  final Color finishColour;
  final Map<String, dynamic>? carPosition;
  final Map<String, dynamic>? carLastPosition;
  final String? carAssetPath;
  final double carSize;
  final Map<String, dynamic> startPosition;
  final Map<String, dynamic> startPosition2;
  final List<Map<String, double>> heatmapPoints;
  final double heatmapMin;
  final double heatmapMax;
  final List<DriverTelemetry> allDrivers;
  final String selectedDriverCode;

  const MapDisplay({
    super.key,
    this.coordinates = const [],
    this.coordinatesGroup = const [],
    this.dotColor = Colors.black,
    this.dotSize = 8.0,
    this.backgroundColor = Colors.white,
    this.padding = 20.0,
    this.finishSize = 50.0,
    required this.finishColour,
    this.carPosition,
    this.carLastPosition,
    this.carAssetPath,
    this.carSize = 30.0,
    required this.startPosition,
    required this.startPosition2,
    this.heatmapPoints = const [],
    this.heatmapMin = 0.0,
    this.heatmapMax = 350.0,
    this.allDrivers = const [],
    this.selectedDriverCode = '',
  });

  @override
  Widget build(BuildContext context) {
    final bounds = _computeHeatmapBounds();
    final effectiveHeatmapMin = bounds.$1;
    final effectiveHeatmapMax = bounds.$2;

    return Container(
      decoration: AppTheme.glassCard(),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          double minX = double.infinity;
          double maxX = double.negativeInfinity;
          double minY = double.infinity;
          double maxY = double.negativeInfinity;

          for (var coord in coordinates) {
            double x = coord['X'].toDouble();
            double y = coord['Y'].toDouble();
            minX = math.min(minX, x);
            maxX = math.max(maxX, x);
            minY = math.min(minY, y);
            maxY = math.max(maxY, y);
          }

          double dataWidth = maxX - minX;
          double dataHeight = maxY - minY;
          double availableWidth = constraints.maxWidth - (2 * padding);
          double availableHeight = constraints.maxHeight - (2 * padding);
          double scaleX = availableWidth / dataWidth;
          double scaleY = availableHeight / dataHeight;
          double scale = math.min(scaleX, scaleY);
          double mapScale = (math.min(scaleX, scaleY) * 2.0).clamp(0.4, 1.0);
          double offsetX = padding + (availableWidth - (dataWidth * scale)) / 2;
          double offsetY =
              padding + (availableHeight - (dataHeight * scale)) / 2;

          return Stack(
            children: [
              RepaintBoundary(
                child: CustomPaint(
                  size: Size(constraints.maxWidth, constraints.maxHeight),
                  painter: MapPainter(
                    coordinates: coordinates,
                    dotColor: dotColor,
                    dotSize: dotSize * mapScale,
                    padding: padding,
                    finishSize: finishSize * mapScale,
                    finishColour: finishColour,
                    heatmapPoints: heatmapPoints,
                    heatmapMin: effectiveHeatmapMin,
                    heatmapMax: effectiveHeatmapMax,
                  ),
                ),
              ),

              if (allDrivers.isNotEmpty)
                MultiCarsOnMap(
                  drivers: allDrivers,
                  selectedDriverCode: selectedDriverCode,
                  minX: minX,
                  minY: minY,
                  scale: scale,
                  offsetX: offsetX,
                  offsetY: offsetY,
                  containerHeight: constraints.maxHeight,
                  containerWidth: constraints.maxWidth,
                  carSize: carSize,
                  startPosition: startPosition,
                  startPosition2: startPosition2,
                )
              else if (carPosition != null)
                CarOnMap(
                  carPosition: carPosition!,
                  carLastPosition: carLastPosition!,
                  minX: minX,
                  minY: minY,
                  scale: scale,
                  offsetX: offsetX,
                  offsetY: offsetY,
                  containerHeight: constraints.maxHeight,
                  containerWidth: constraints.maxWidth,
                  carAssetPath: carAssetPath!,
                  carSize: carSize,
                  startPosition: startPosition,
                  startPosition2: startPosition2,
                ),

              if (heatmapPoints.isNotEmpty)
                Positioned(
                  top: 10,
                  right: 10,
                  child: _HeatmapLegend(
                    minValue: effectiveHeatmapMin,
                    maxValue: effectiveHeatmapMax,
                    containerWidth: constraints.maxWidth,
                    containerHeight: constraints.maxHeight,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  (double, double) _computeHeatmapBounds() {
    final metrics = <double>[];
    for (final point in heatmapPoints) {
      final value = point['metric'];
      if (value != null && value.isFinite) {
        metrics.add(value);
      }
    }

    if (metrics.length < 10) {
      final minValue = heatmapMin;
      final maxValue = heatmapMax > heatmapMin ? heatmapMax : heatmapMin + 1;
      return (minValue, maxValue);
    }

    metrics.sort();
    final p10 =
        metrics[(metrics.length * 0.10).floor().clamp(0, metrics.length - 1)];
    final p90 =
        metrics[(metrics.length * 0.90).floor().clamp(0, metrics.length - 1)];

    var minValue = p10;
    var maxValue = p90;

    if (maxValue <= minValue) {
      minValue = metrics.first;
      maxValue = metrics.last;
    }
    if (maxValue <= minValue) {
      maxValue = minValue + 1;
    }

    return (minValue, maxValue);
  }
}

class _HeatmapLegend extends StatelessWidget {
  final double minValue;
  final double maxValue;
  final double containerWidth;
  final double containerHeight;

  const _HeatmapLegend({
    required this.minValue,
    required this.maxValue,
    required this.containerWidth,
    required this.containerHeight,
  });

  @override
  Widget build(BuildContext context) {
    final widthScale = (containerWidth / 400).clamp(0.6, 1.0);
    final heightScale = (containerHeight / 300).clamp(0.6, 1.0);
    final scale = math.min(widthScale, heightScale);
    final fontSize = (10 * scale).clamp(7.0, 10.0);
    final changingSize = (9 * scale).clamp(6.0, 9.0);
    final barWidth = (92 * scale).clamp(60.0, 92.0);
    final barHeight = (7 * scale).clamp(5.0, 7.0);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8 * scale, vertical: 6 * scale),
      decoration: BoxDecoration(
        color: const Color(0xAA111122),
        borderRadius: BorderRadius.circular(8 * scale),
        border: Border.all(color: const Color(0x44FFFFFF)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Speed',
            style: TextStyle(
              color: const Color(0xFFEEEEEE),
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4 * scale),
          Container(
            width: barWidth,
            height: barHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF2F6BFF),
                  Color(0xFF00D2FF),
                  Color(0xFF00D97E),
                  Color(0xFFFFD400),
                  Color(0xFFFF3A2E),
                ],
              ),
            ),
          ),
          SizedBox(height: 3 * scale),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                minValue.toStringAsFixed(0),
                style: TextStyle(
                  color: const Color(0xFF8A8A8A),
                  fontSize: changingSize,
                ),
              ),
              SizedBox(width: 38 * scale),
              Text(
                '${maxValue.toStringAsFixed(0)} km/h',
                style: TextStyle(
                  color: const Color(0xFF8A8A8A),
                  fontSize: changingSize,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class MapPainter extends CustomPainter {
  final List<Map<String, dynamic>> coordinates;
  final Color dotColor;
  final double dotSize;
  final double padding;
  final double finishSize;
  final Color finishColour;
  final List<Map<String, double>> heatmapPoints;
  final double heatmapMin;
  final double heatmapMax;

  MapPainter({
    required this.coordinates,
    required this.dotColor,
    required this.dotSize,
    required this.padding,
    required this.finishSize,
    required this.finishColour,
    required this.heatmapPoints,
    required this.heatmapMin,
    required this.heatmapMax,
  });

  @override
  void paint(Canvas canvas, Size size) {
    double minX = double.infinity;
    double maxX = double.negativeInfinity;
    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    for (var coord in coordinates) {
      double x = coord['X'].toDouble();
      double y = coord['Y'].toDouble();
      minX = math.min(minX, x);
      maxX = math.max(maxX, x);
      minY = math.min(minY, y);
      maxY = math.max(maxY, y);
    }

    double dataWidth = maxX - minX;
    double dataHeight = maxY - minY;
    double availableWidth = size.width - (2 * padding);
    double availableHeight = size.height - (2 * padding);
    double scaleX = availableWidth / dataWidth;
    double scaleY = availableHeight / dataHeight;
    double scale = math.min(scaleX, scaleY);
    double offsetX = padding + (availableWidth - (dataWidth * scale)) / 2;
    double offsetY = padding + (availableHeight - (dataHeight * scale)) / 2;

    final path = Path();
    var lastCoord = coordinates.last;
    double lastAdjX = offsetX + (lastCoord['X'].toDouble() - minX) * scale;
    double lastAdjY =
        size.height - (offsetY + (lastCoord['Y'].toDouble() - minY) * scale);
    path.moveTo(lastAdjX, lastAdjY);

    for (var coord in coordinates) {
      double screenX = offsetX + (coord['X'].toDouble() - minX) * scale;
      double screenY =
          size.height - (offsetY + (coord['Y'].toDouble() - minY) * scale);
      path.lineTo(screenX, screenY);
    }

    final glowPaint = Paint()
      ..color = const Color(0xFF444466).withAlpha(50)
      ..style = PaintingStyle.stroke
      ..strokeWidth = dotSize + 6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawPath(path, glowPaint);

    final trackPaint = Paint()
      ..color = const Color(0xFF555577)
      ..style = PaintingStyle.stroke
      ..strokeWidth = dotSize
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, trackPaint);

    if (heatmapPoints.length > 1) {
      final heatGlowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = dotSize * 0.95
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

      final linePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = dotSize * 0.62
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      Offset toScreen(double x, double y) {
        return Offset(
          offsetX + (x - minX) * scale,
          size.height - (offsetY + (y - minY) * scale),
        );
      }

      for (int i = 1; i < heatmapPoints.length; i++) {
        final prev = heatmapPoints[i - 1];
        final curr = heatmapPoints[i];
        final prevX = prev['X'];
        final prevY = prev['Y'];
        final currX = curr['X'];
        final currY = curr['Y'];
        final metric = curr['metric'] ?? heatmapMin;

        if (prevX == null || prevY == null || currX == null || currY == null) {
          continue;
        }

        final color = _metricToColor(metric);
        heatGlowPaint.color = color.withAlpha(70);
        linePaint.color = color;

        final p0 = toScreen(prevX, prevY);
        final p1 = toScreen(currX, currY);
        canvas.drawLine(p0, p1, heatGlowPaint);
        canvas.drawLine(p0, p1, linePaint);
      }
    }

    var firstCoord = coordinates.first;
    double firstX = offsetX + (firstCoord['X'].toDouble() - minX) * scale;
    double firstY =
        size.height - (offsetY + (firstCoord['Y'].toDouble() - minY) * scale);
    Offset firstPoint = Offset(firstX, firstY);

    double dx = firstPoint.dx - lastAdjX;
    double dy = firstPoint.dy - lastAdjY;
    double perpDx = -dy;
    double perpDy = dx;
    double perpLength = math.sqrt(perpDx * perpDx + perpDy * perpDy);
    if (perpLength > 0) {
      perpDx = perpDx / perpLength * finishSize / 2;
      perpDy = perpDy / perpLength * finishSize / 2;
    }

    const int numSquares = 8;
    final startPt = Offset(firstPoint.dx - perpDx, firstPoint.dy - perpDy);
    final endPt = Offset(firstPoint.dx + perpDx, firstPoint.dy + perpDy);
    final segDx = (endPt.dx - startPt.dx) / numSquares;
    final segDy = (endPt.dy - startPt.dy) / numSquares;
    const squareWidth = 3.0;

    for (int i = 0; i < numSquares; i++) {
      final color = i % 2 == 0 ? Colors.white : Colors.black;
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = squareWidth;
      canvas.drawLine(
        Offset(startPt.dx + segDx * i, startPt.dy + segDy * i),
        Offset(startPt.dx + segDx * (i + 1), startPt.dy + segDy * (i + 1)),
        paint,
      );
    }
  }

  Color _metricToColor(double value) {
    if (heatmapMax <= heatmapMin) return const Color(0xFF00D2FF);
    final t = ((value - heatmapMin) / (heatmapMax - heatmapMin)).clamp(0.0, 1.0);
    if (t < 0.25) {
      return Color.lerp(const Color(0xFF2F6BFF), const Color(0xFF00D2FF), t / 0.25)!;
    }
    if (t < 0.5) {
      return Color.lerp(const Color(0xFF00D2FF), const Color(0xFF00D97E), (t - 0.25) / 0.25)!;
    }
    if (t < 0.75) {
      return Color.lerp(const Color(0xFF00D97E), const Color(0xFFFFD400), (t - 0.5) / 0.25)!;
    }
    return Color.lerp(const Color(0xFFFFD400), const Color(0xFFFF3A2E), (t - 0.75) / 0.25)!;
  }

  @override
  bool shouldRepaint(MapPainter oldDelegate) {
    return oldDelegate.coordinates != coordinates ||
        oldDelegate.heatmapPoints.length != heatmapPoints.length ||
        oldDelegate.heatmapMin != heatmapMin ||
        oldDelegate.heatmapMax != heatmapMax;
  }
}
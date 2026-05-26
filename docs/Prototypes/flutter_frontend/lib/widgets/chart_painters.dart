// lib/widgets/chart_painters.dart
import 'package:flutter/material.dart';
import 'dart:ui' as ui;

/// Draws a single line chart for a list of [data] points.
class TelemetryChartPainter extends CustomPainter {
  final List<double> data;
  final Color lineColor;

  TelemetryChartPainter({required this.data, required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..strokeWidth = 1;

    // Draw horizontal grid lines
    for (int i = 0; i < 5; i++) {
      final y = (size.height / 4) * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (data.isEmpty) return; // Don't draw if no data

    // Find min and max values in the data
    double minVal = data.first;
    double maxVal = data.first;
    for (var val in data) {
      if (val < minVal) minVal = val;
      if (val > maxVal) maxVal = val;
    }

    // Handle the case where all values are the same
    if (maxVal == minVal) maxVal += 1;

    // Apply a 10% vertical padding for visual comfort
    final double range = maxVal - minVal;
    final double paddedMin = (minVal - (range * 0.1)).floorToDouble();
    final double paddedMax = (maxVal + (range * 0.1)).ceilToDouble();
    final double effectiveRange = paddedMax - paddedMin;

    if (effectiveRange == 0) return; // Avoid division by zero

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path = Path();
    
    // Calculate X-step
    // Use data.length - 1 to ensure the line touches the right edge
    final double xStep = data.length > 1 ? size.width / (data.length - 1) : size.width;

    for (int i = 0; i < data.length; i++) {
      final x = xStep * i;

      // Normalize value (0.0 to 1.0)
      final double normalizedY = (data[i] - paddedMin) / effectiveRange;
      // Invert Y-axis (canvas 0 is top, we want 0 at bottom)
      final y = size.height - (normalizedY * size.height);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, linePaint);

    // Draw gradient fill below line
    final fillPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, 0),
        Offset(0, size.height),
        [lineColor.withOpacity(0.3), lineColor.withOpacity(0.0)],
      )
      ..style = PaintingStyle.fill;

    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant TelemetryChartPainter oldDelegate) {
    // Repaint only if the data has actually changed
    return oldDelegate.data != data;
  }
}

/// Draws multiple line charts from a map of [dataMap].
class TelemetryMultiChartPainter extends CustomPainter {
  final Map<String, List<double>> dataMap;
  final Map<String, Color> colors;

  TelemetryMultiChartPainter({required this.dataMap, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    // Draw grid lines
    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..strokeWidth = 1;
    for (int i = 0; i < 5; i++) {
      final y = (size.height / 4) * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (dataMap.isEmpty) return;

    // Find global min and max across ALL datasets
    double globalMin = double.maxFinite;
    double globalMax = double.minPositive;
    int maxPoints = 0;

    for (var entry in dataMap.entries) {
      if (entry.value.isEmpty) continue;
      if (entry.value.length > maxPoints) maxPoints = entry.value.length;
      for (var val in entry.value) {
        if (val < globalMin) globalMin = val;
        if (val > globalMax) globalMax = val;
      }
    }

    if (globalMin == double.maxFinite) return; // All lists were empty
    if (maxPoints == 0) return; // No data points

    // Apply padding
    if (globalMax == globalMin) globalMax += 1;
    final double range = globalMax - globalMin;
    final double paddedMin = (globalMin - (range * 0.1)).floorToDouble();
    final double paddedMax = (globalMax + (range * 0.1)).ceilToDouble();
    final double effectiveRange = paddedMax - paddedMin;

    if (effectiveRange == 0) return;

    // Draw each line
    for (var entry in dataMap.entries) {
      final key = entry.key;
      final data = entry.value;
      final color = colors[key] ?? Colors.grey;

      if (data.isEmpty) continue;

      final paint = Paint()
        ..color = color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      final path = Path();
      
      final double xStep = data.length > 1 ? size.width / (data.length - 1) : size.width;

      for (int i = 0; i < data.length; i++) {
        final x = xStep * i;

        final double normalizedY = (data[i] - paddedMin) / effectiveRange;
        final y = size.height - (normalizedY * size.height);

        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant TelemetryMultiChartPainter oldDelegate) {
    // Repaint if the data map has changed
    return oldDelegate.dataMap != dataMap;
  }
}
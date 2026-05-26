import 'package:flutter/material.dart';

/// Static telemetry chart widget - displays UI design only, no real data
class TelemetryChartStatic extends StatelessWidget {
  final String title;
  final String currentValue;
  final Color lineColor;
  final String unit;

  const TelemetryChartStatic({
    Key? key,
    required this.title,
    required this.currentValue,
    required this.lineColor,
    required this.unit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: lineColor.withValues(alpha: 0.3), width: 2),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: lineColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '$currentValue $unit',
                style: TextStyle(
                  color: lineColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _buildMockChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildMockChart() {
    return CustomPaint(
      painter: MockChartPainter(lineColor: lineColor),
      child: Container(),
    );
  }
}

/// Multi-value static chart widget - displays UI design only
class MultiValueChartStatic extends StatelessWidget {
  final String title;
  final Map<String, String> values;
  final Map<String, Color> colors;
  final String unit;

  const MultiValueChartStatic({
    Key? key,
    required this.title,
    required this.values,
    required this.colors,
    required this.unit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3), width: 2),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.orange,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            children: values.entries.map((entry) {
              final color = colors[entry.key] ?? Colors.grey;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${entry.key}: ${entry.value}$unit',
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: CustomPaint(
              painter: MockMultiChartPainter(colors: colors.values.toList()),
              child: Container(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter to draw a mock chart line
class MockChartPainter extends CustomPainter {
  final Color lineColor;

  MockChartPainter({required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path = Path();
    
    // Create a wavy line pattern to simulate telemetry data
    final points = 50;
    for (int i = 0; i < points; i++) {
      final x = (size.width / points) * i;
      final y = size.height / 2 + 
               (size.height / 4) * (0.5 - (i % 10) / 10.0) +
               (size.height / 6) * (0.5 - (i % 5) / 5.0);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    // Draw gradient fill below line
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          lineColor.withValues(alpha: 0.3),
          lineColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);

    // Draw grid lines
    final gridPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.2)
      ..strokeWidth = 1;

    for (int i = 0; i < 5; i++) {
      final y = (size.height / 4) * i;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter for multi-line mock chart
class MockMultiChartPainter extends CustomPainter {
  final List<Color> colors;

  MockMultiChartPainter({required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final points = 50;

    for (int colorIndex = 0; colorIndex < colors.length; colorIndex++) {
      final paint = Paint()
        ..color = colors[colorIndex]
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      final path = Path();
      final offset = colorIndex * 0.1;

      for (int i = 0; i < points; i++) {
        final x = (size.width / points) * i;
        final y = size.height / 2 + 
                 (size.height / 4) * (0.5 - (i % 10) / 10.0) +
                 (size.height / 8) * (0.5 - (i % 7) / 7.0) +
                 offset * size.height / 4;
        
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }

      canvas.drawPath(path, paint);
    }

    // Draw grid lines
    final gridPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.2)
      ..strokeWidth = 1;

    for (int i = 0; i < 5; i++) {
      final y = (size.height / 4) * i;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


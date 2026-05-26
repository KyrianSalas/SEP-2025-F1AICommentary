// lib/widgets/telemetry_chart.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../playback_service.dart';
import 'chart_painters.dart'; // <-- CHANGED: Import new painters

class TelemetryChart extends StatelessWidget {
  final String title;
  final String dataKey;
  final Color lineColor;
  final String unit;

  const TelemetryChart({
    Key? key,
    required this.title,
    required this.dataKey,
    required this.lineColor,
    required this.unit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<PlaybackService>(
      builder: (context, playbackService, child) {
        // Get the latest value for display
        final value = playbackService.latestTelemetry[dataKey];
        String formattedValue;
        if (value == null) {
          formattedValue = '---';
        } else if (value is double) {
          formattedValue = value.toStringAsFixed(1);
        } else {
          formattedValue = value.toString();
        }

        // --- NEW: Extract the data history for the chart ---
        final List<double> chartData =
            playbackService.telemetryHistory.map((point) {
          final val = point[dataKey];
          if (val is num) {
            return val.toDouble();
          }
          return 0.0; // Default if null or wrong type
        }).toList();
        // --- END NEW ---

        return Container(
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: lineColor.withOpacity(0.3), width: 2),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                // ... (Header Row with title and formattedValue - no change)
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
                    '$formattedValue $unit', // This is still the latest value
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
                // --- CHANGED: Use the new painter and pass data ---
                child: CustomPaint(
                  painter: TelemetryChartPainter(
                    data: chartData,
                    lineColor: lineColor,
                  ),
                  child: Container(),
                ),
                // --- END CHANGED ---
              ),
            ],
          ),
        );
      },
    );
  }
}
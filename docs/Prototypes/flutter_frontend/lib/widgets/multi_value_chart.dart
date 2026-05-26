// lib/widgets/multi_value_chart.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../playback_service.dart';
import 'chart_painters.dart'; // <-- CHANGED: Import new painters

class MultiValueChart extends StatelessWidget {
  final String title;
  final List<String> dataKeys;
  final Map<String, Color> colors;
  final String unit;

  const MultiValueChart({
    Key? key,
    required this.title,
    required this.dataKeys,
    required this.colors,
    required this.unit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<PlaybackService>(
      builder: (context, playbackService, child) {
        // --- NEW: Extract data history for all keys ---
        final Map<String, List<double>> chartDataMap = {};
        for (String key in dataKeys) {
          chartDataMap[key] =
              playbackService.telemetryHistory.map((point) {
            final val = point[key];
            if (val is num) {
              return val.toDouble();
            }
            return 0.0;
          }).toList();
        }
        // --- END NEW ---

        return Container(
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.withOpacity(0.3), width: 2),
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
                // This part (showing latest values) is unchanged
                children: dataKeys.map((key) {
                  final color = colors[key] ?? Colors.grey;
                  final value = playbackService.latestTelemetry[key]; // Latest val

                  String formattedValue;
                  if (value == null) {
                    formattedValue = '---';
                  } else if (value is double) {
                    formattedValue = value.toStringAsFixed(1);
                  } else {
                    formattedValue = value.toString();
                  }

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
                        '$key: $formattedValue$unit',
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
                // --- CHANGED: Use new painter and pass data map ---
                child: CustomPaint(
                  painter: TelemetryMultiChartPainter(
                    dataMap: chartDataMap,
                    colors: colors,
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
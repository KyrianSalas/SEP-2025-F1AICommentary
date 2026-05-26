// lib/screens/telemetry_screen.dart
import 'package:flutter/material.dart';
import '../widgets/playback_controls.dart';
import '../widgets/telemetry_chart.dart';
import '../widgets/multi_value_chart.dart';

class TelemetryScreen extends StatelessWidget {
  const TelemetryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('F1 Live Telemetry'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 1. The Playback Controls
            const PlaybackControls(),
            const SizedBox(height: 16),

            // 2. The Charts
            Expanded(
              child: GridView.count(
                crossAxisCount: 2, // Adjust as needed
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2, // Adjust aspect ratio
                children: [
                  // Pass a 'dataKey' to tell the chart what to display
                  TelemetryChart(
                    title: 'Speed',
                    dataKey: 'Ground Speed (km/h)', // This MUST match your JSON key
                    unit: 'KPH',
                    lineColor: Colors.cyan,
                  ),
                  TelemetryChart(
                    title: 'RPM',
                    dataKey: 'Engine RPM (rpm)', // This MUST match your JSON key
                    unit: '',
                    lineColor: Colors.red,
                  ),
                  TelemetryChart(
                    title: 'Throttle',
                    dataKey: 'Throttle Pos (%)', // This MUST match your JSON key
                    unit: '%',
                    lineColor: Colors.green,
                  ),
                  TelemetryChart(
                    title: 'Brake',
                    dataKey: 'Brake', // This MUST match your JSON key
                    unit: '%',
                    lineColor: Colors.orange,
                  ),

                  // Example for the multi-value chart
                  MultiValueChart(
                    title: 'Tyre Temps (FL/FR)',
                    // These keys MUST match your JSON
                    dataKeys: const ['TyreTempFL', 'TyreTempFR'],
                    unit: '°C',
                    colors: {
                      'TyreTempFL': Colors.blue,
                      'TyreTempFR': Colors.green,
                    },
                  ),
                  MultiValueChart(
                    title: 'Tyre Temps (RL/RR)',
                    // These keys MUST match your JSON
                    dataKeys: const ['TyreTempRL', 'TyreTempRR'],
                    unit: '°C',
                    colors: {
                      'TyreTempRL': Colors.yellow,
      'TyreTempRR': Colors.purple,
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
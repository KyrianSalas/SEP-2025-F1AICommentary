import 'package:flutter/material.dart';
import '../widgets/telemetry_chart_static.dart';
import '../widgets/playback_controls_static.dart';

/// Static version of telemetry screen - UI design only, no backend connection
class TelemetryScreenStatic extends StatelessWidget {
  const TelemetryScreenStatic({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'F1',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 24,
                  letterSpacing: -1,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'TELEMETRY REPLAY - UI DESIGN',
              style: TextStyle(
                fontWeight: FontWeight.w300,
                fontSize: 20,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Playback Controls
            const PlaybackControlsStatic(),
            const SizedBox(height: 16),
            
            // Current Values Display
            _buildCurrentValuesCard(),
            const SizedBox(height: 16),
            
            // Telemetry Graphs Grid
            LayoutBuilder(
              builder: (context, constraints) {
                final isWideScreen = constraints.maxWidth > 1200;
                return isWideScreen
                    ? _buildWideScreenLayout()
                    : _buildNarrowScreenLayout();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentValuesCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CURRENT VALUES',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 24,
            runSpacing: 16,
            children: [
              _buildValueDisplay('GEAR', '5', Colors.white),
              _buildValueDisplay('SPEED', '245 km/h', Colors.cyan),
              _buildValueDisplay('RPM', '7850', Colors.red),
              _buildValueDisplay('THROTTLE', '95%', Colors.green),
              _buildValueDisplay('BRAKE', '0%', Colors.orange),
              _buildValueDisplay('FUEL', '28.5 L', Colors.yellow),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildValueDisplay(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildWideScreenLayout() {
    return Column(
      children: [
        // Row 1: RPM and Speed
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 250,
                child: TelemetryChartStatic(
                  title: 'ENGINE RPM',
                  currentValue: '7850',
                  lineColor: Colors.red,
                  unit: 'rpm',
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SizedBox(
                height: 250,
                child: TelemetryChartStatic(
                  title: 'SPEED',
                  currentValue: '245',
                  lineColor: Colors.cyan,
                  unit: 'km/h',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Row 2: Throttle and Brake
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 250,
                child: TelemetryChartStatic(
                  title: 'THROTTLE',
                  currentValue: '95.0',
                  lineColor: Colors.green,
                  unit: '%',
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SizedBox(
                height: 250,
                child: TelemetryChartStatic(
                  title: 'BRAKE',
                  currentValue: '0.0',
                  lineColor: Colors.orange,
                  unit: '%',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Row 3: Brake Temperatures
        SizedBox(
          height: 250,
          child: MultiValueChartStatic(
            title: 'BRAKE TEMPERATURES',
            values: {
              'FL': '145',
              'FR': '142',
              'RL': '138',
              'RR': '140',
            },
            colors: {
              'FL': Colors.red,
              'FR': Colors.orange,
              'RL': Colors.yellow,
              'RR': Colors.purple,
            },
            unit: '°C',
          ),
        ),
        const SizedBox(height: 16),
        
        // Row 4: Fuel Level
        SizedBox(
          height: 250,
          child: TelemetryChartStatic(
            title: 'FUEL LEVEL',
            currentValue: '28.5',
            lineColor: Colors.yellow,
            unit: 'L',
          ),
        ),
      ],
    );
  }

  Widget _buildNarrowScreenLayout() {
    return Column(
      children: [
        // RPM
        SizedBox(
          height: 250,
          child: TelemetryChartStatic(
            title: 'ENGINE RPM',
            currentValue: '7850',
            lineColor: Colors.red,
            unit: 'rpm',
          ),
        ),
        const SizedBox(height: 16),
        
        // Speed
        SizedBox(
          height: 250,
          child: TelemetryChartStatic(
            title: 'SPEED',
            currentValue: '245',
            lineColor: Colors.cyan,
            unit: 'km/h',
          ),
        ),
        const SizedBox(height: 16),
        
        // Throttle
        SizedBox(
          height: 250,
          child: TelemetryChartStatic(
            title: 'THROTTLE',
            currentValue: '95.0',
            lineColor: Colors.green,
            unit: '%',
          ),
        ),
        const SizedBox(height: 16),
        
        // Brake
        SizedBox(
          height: 250,
          child: TelemetryChartStatic(
            title: 'BRAKE',
            currentValue: '0.0',
            lineColor: Colors.orange,
            unit: '%',
          ),
        ),
        const SizedBox(height: 16),
        
        // Brake Temperatures
        SizedBox(
          height: 250,
          child: MultiValueChartStatic(
            title: 'BRAKE TEMPERATURES',
            values: {
              'FL': '145',
              'FR': '142',
              'RL': '138',
              'RR': '140',
            },
            colors: {
              'FL': Colors.red,
              'FR': Colors.orange,
              'RL': Colors.yellow,
              'RR': Colors.purple,
            },
            unit: '°C',
          ),
        ),
        const SizedBox(height: 16),
        
        // Fuel Level
        SizedBox(
          height: 250,
          child: TelemetryChartStatic(
            title: 'FUEL LEVEL',
            currentValue: '28.5',
            lineColor: Colors.yellow,
            unit: 'L',
          ),
        ),
      ],
    );
  }
}


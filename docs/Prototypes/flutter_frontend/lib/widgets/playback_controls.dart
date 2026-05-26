// lib/widgets/playback_controls.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../playback_service.dart';

class PlaybackControls extends StatelessWidget {
  const PlaybackControls({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Consumer rebuilds this widget when the service changes
    return Consumer<PlaybackService>(
      builder: (context, playbackService, child) {
        // Now we use the service's state to build the UI
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.withOpacity(0.3), width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Connection Status (now dynamic)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: playbackService.isConnected
                          ? Colors.green
                          : Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    playbackService.isConnected ? 'Connected' : 'Disconnected',
                    style: TextStyle(
                      color: playbackService.isConnected
                          ? Colors.green
                          : Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Playback Buttons (now functional)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildControlButton(
                    icon: Icons.replay,
                    color: Colors.orange,
                    tooltip: 'Reset',
                    onPressed: () => playbackService.sendCommand('reset'),
                  ),
                  const SizedBox(width: 20),
                  _buildControlButton(
                    icon: Icons.play_arrow,
                    color: Colors.red,
                    tooltip: 'Play',
                    isLarge: true,
                    onPressed: () => playbackService.sendCommand('play'),
                  ),
                  const SizedBox(width: 20),
                  _buildControlButton(
                    icon: Icons.stop,
                    color: Colors.grey,
                    tooltip: 'Pause', // Changed tooltip
                    onPressed: () => playbackService.sendCommand('pause'),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Speed Control (now functional)
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'PLAYBACK SPEED',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        '${playbackService.selectedSpeed.toStringAsFixed(1)}x',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: Colors.red,
                      inactiveTrackColor: Colors.grey[800],
                      thumbColor: Colors.red,
                      overlayColor: Colors.red.withOpacity(0.2),
                      trackHeight: 4,
                    ),
                    child: Slider(
                      value: playbackService.selectedSpeed,
                      min: 0.25,
                      max: 4.0,
                      divisions: 15,
                      onChanged: (newSpeed) {
                        playbackService.setSpeed(newSpeed);
                        playbackService.sendCommand('change_speed');
                      },
                    ),
                  ),
                  // Speed presets
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildSpeedButton(playbackService, 0.5),
                      _buildSpeedButton(playbackService, 1.0),
                      _buildSpeedButton(playbackService, 2.0),
                      _buildSpeedButton(playbackService, 4.0),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onPressed,
    bool isLarge = false,
  }) {
    final size = isLarge ? 70.0 : 50.0;
    final iconSize = isLarge ? 40.0 : 28.0;

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(size / 2),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.2),
            border: Border.all(color: color, width: 2),
          ),
          child: Icon(
            icon,
            color: color,
            size: iconSize,
          ),
        ),
      ),
    );
  }

  Widget _buildSpeedButton(PlaybackService service, double speed) {
    final isSelected = service.selectedSpeed == speed;
    return GestureDetector(
      onTap: () => service.setSpeed(speed),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.red : Colors.grey[850],
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? Colors.red : Colors.grey[700]!,
            width: 1,
          ),
        ),
        child: Text(
          '${speed}x',
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[400],
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
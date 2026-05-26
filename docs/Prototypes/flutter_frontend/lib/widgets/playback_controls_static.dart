// lib/playback_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class PlaybackService with ChangeNotifier {
  final String _serverUrl = "ws://127.0.0.1:8000/ws";
  WebSocketChannel? _channel;

  // --- NEW: Telemetry History ---
  final int _historyLength = 100; // Store 100 data points
  List<Map<String, dynamic>> _telemetryHistory = [];
  // --- END NEW ---

  bool _isConnected = false;
  double _selectedSpeed = 1.0;
  Map<String, dynamic> _latestTelemetry = {};

  // Public getters
  bool get isConnected => _isConnected;
  double get selectedSpeed => _selectedSpeed;
  Map<String, dynamic> get latestTelemetry => _latestTelemetry;

  // --- NEW: Getter for the history ---
  List<Map<String, dynamic>> get telemetryHistory => _telemetryHistory;
  // --- END NEW ---

  void connect() {
    if (_isConnected) return;
    try {
      _channel = WebSocketChannel.connect(Uri.parse(_serverUrl));
      _isConnected = true;
      notifyListeners();

      _channel!.stream.listen(
        (message) {
          _latestTelemetry = jsonDecode(message) as Map<String, dynamic>;

          // --- NEW: Add to history and trim ---
          _telemetryHistory.add(_latestTelemetry);
          if (_telemetryHistory.length > _historyLength) {
            _telemetryHistory.removeAt(0); // Remove the oldest point
          }
          // --- END NEW ---

          notifyListeners(); // Tell UI to update with new data
        },
        onDone: () {
          _isConnected = false;
          _latestTelemetry = {};
          _telemetryHistory.clear(); // --- NEW ---
          notifyListeners();
        },
        onError: (error) {
          print("WebSocket Error: $error");
          _isConnected = false;
          _latestTelemetry = {};
          _telemetryHistory.clear(); // --- NEW ---
          notifyListeners();
        },
      );
    } catch (e) {
      print("Error connecting to WebSocket: $e");
    }
  }

  void sendCommand(String action) {
    if (_channel != null && _isConnected) {
      // --- NEW: Clear history on reset ---
      if (action == 'reset') {
        _telemetryHistory.clear();
        notifyListeners();
      }
      // --- END NEW ---

      Map<String, dynamic> command = {
        'action': action,
        'playback_speed': _selectedSpeed,
      };
      _channel!.sink.add(jsonEncode(command));
    }
  }

  void setSpeed(double speed) {
    _selectedSpeed = speed;
    notifyListeners();
  }

  void disconnect() {
    _channel?.sink.close();
    _isConnected = false;
    _telemetryHistory.clear(); // --- NEW ---
    notifyListeners();
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
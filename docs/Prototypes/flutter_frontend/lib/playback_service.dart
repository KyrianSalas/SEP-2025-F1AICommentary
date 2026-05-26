// lib/playback_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class PlaybackService with ChangeNotifier {
  final String _serverUrl = "ws://0.0.0.0:8000/api/ws";
  WebSocketChannel? _channel;

  // --- Data History (from previous step) ---
  final int _historyLength = 100;
  List<Map<String, dynamic>> _telemetryHistory = [];
  
  // --- Private State ---
  bool _isConnected = false;
  double _selectedSpeed = 1.0;
  Map<String, dynamic> _latestTelemetry = {};

  // --- NEW: Seek Bar State ---
  double _playbackProgress = 0.0; // Current progress from 0.0 to 1.0
  bool _isUserSeeking = false;    // True if user is dragging the slider
  // --- END NEW ---

  // --- Public Getters ---
  bool get isConnected => _isConnected;
  double get selectedSpeed => _selectedSpeed;
  Map<String, dynamic> get latestTelemetry => _latestTelemetry;
  List<Map<String, dynamic>> get telemetryHistory => _telemetryHistory;

  // --- NEW: Getter for seek bar ---
  double get playbackProgress => _playbackProgress;
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

          // --- NEW: Update progress if user is not seeking ---
          // We assume the backend sends a 'progress': 0.xx key
          if (_latestTelemetry.containsKey('progress') && !_isUserSeeking) {
            _playbackProgress = (_latestTelemetry['progress'] as num).toDouble();
          }
          // --- END NEW ---

          // Add to history
          _telemetryHistory.add(_latestTelemetry);
          if (_telemetryHistory.length > _historyLength) {
            _telemetryHistory.removeAt(0);
          }
          notifyListeners();
        },
        onDone: () {
          _isConnected = false;
          _latestTelemetry = {};
          _telemetryHistory.clear();
          _playbackProgress = 0.0; // --- NEW ---
          _isUserSeeking = false;  // --- NEW ---
          notifyListeners();
        },
        onError: (error) {
          print("WebSocket Error: $error");
          _isConnected = false;
          _latestTelemetry = {};
          _telemetryHistory.clear();
          _playbackProgress = 0.0; // --- NEW ---
          _isUserSeeking = false;  // --- NEW ---
          notifyListeners();
        },
      );
    } catch (e) {
      print("Error connecting to WebSocket: $e");
    }
  }

  void sendCommand(String action) {
    if (_channel != null && _isConnected) {
      if (action == 'reset') {
        _telemetryHistory.clear();
        _playbackProgress = 0.0; // --- NEW ---
        _isUserSeeking = false;  // --- NEW ---
        notifyListeners();
      }

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

  // --- NEW: Methods for Seek Bar ---
  
  /// User has started dragging the seek bar.
  void onSeekStart() {
    _isUserSeeking = true;
  }

  /// User is dragging the seek bar.
  void onSeek(double progress) {
    if (!_isUserSeeking) _isUserSeeking = true;
    _playbackProgress = progress;
    notifyListeners(); // Update the UI to show the dragged position
  }

  /// User has finished dragging the seek bar.
  void onSeekEnd(double progress) {
    _isUserSeeking = false;
    _playbackProgress = progress;
    
    // Send the final seek command to the backend
    if (_channel != null && _isConnected) {
      Map<String, dynamic> command = {
        'action': 'seek',
        'progress': progress, // Send the new progress (0.0 to 1.0)
      };
      _channel!.sink.add(jsonEncode(command));
    }
    notifyListeners();
  }
  // --- END NEW ---

  void disconnect() {
    _channel?.sink.close();
    _isConnected = false;
    _telemetryHistory.clear();
    _playbackProgress = 0.0; // --- NEW ---
    _isUserSeeking = false;  // --- NEW ---
    notifyListeners();
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
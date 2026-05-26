// lib/main.dart (Copied, needs dependencies to work)

import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: PlaybackScreen(),
    );
  }
}

class PlaybackScreen extends StatefulWidget {
  const PlaybackScreen({super.key});

  @override
  State<PlaybackScreen> createState() => _PlaybackScreenState();
}

class _PlaybackScreenState extends State<PlaybackScreen> {
  final String serverUrl = "ws://0.0.0.0:8000/api/ws"; // Make sure this path is correct
  WebSocketChannel? _channel;
  final List<String> _events = [];
  bool _isConnected = false;

  // --- ADDED THIS STATE VARIABLE FOR SPEED ---
  double _selectedSpeed = 1.0;

  // --- ADDED THIS LIST FOR THE BUTTONS ---
  final List<ButtonSegment<double>> speedSegments = [
    const ButtonSegment(value: 0.5, label: Text('1/2x')),
    const ButtonSegment(value: 1.0, label: Text('1x')),
    const ButtonSegment(value: 2.0, label: Text('2x')),
  ];

  @override
  void initState() {
    super.initState();
    _connect();
  }

  void _connect() {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(serverUrl));
      setState(() {
        _isConnected = true;
        _events.add('Connection established...');
      });

      _channel!.stream.listen((message) {
        final decodedMessage = jsonDecode(message);
        setState(() {
          _events.add(decodedMessage.toString());
        });
      }, onDone: () {
        setState(() {
          _isConnected = false;
          _events.add('Connection closed.');
        });
      }, onError: (error) {
        setState(() {
          _isConnected = false;
          _events.add('Error: $error');
        });
      });
    } catch (e) {
      print("Error connecting to WebSocket: $e");
    }
  }

  void _sendCommand(String action) {
    if (_channel != null && _isConnected) {
      Map<String, dynamic> command = {
        'action': action,
        'playback_speed': _selectedSpeed,
      };

      final jsonCommand = jsonEncode(command);
      _channel!.sink.add(jsonCommand);
    }
    print("Sent command: $action with speed $_selectedSpeed");
  }

  @override
  void dispose() {
    _channel?.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Playback Control'),
        backgroundColor: _isConnected ? Colors.green : Colors.red,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // --- ADDED THIS WIDGET ---
            SegmentedButton<double>(
              segments: speedSegments,
              selected: {_selectedSpeed}, // This must be a Set
              onSelectionChanged: (Set<double> newSelection) {
                setState(() {
                  // The Set will only contain one value
                  _selectedSpeed = newSelection.first;
                });
              },
            ),
            const SizedBox(height: 16), // Added some spacing
            // -------------------------
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Play'),
                  onPressed: () => _sendCommand('play'),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.pause),
                  label: const Text('Pause'),
                  onPressed: () => _sendCommand('pause'),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset'),
                  onPressed: () => _sendCommand('reset'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8.0),
                color: Colors.grey[200],
                child: ListView.builder(
                  itemCount: _events.length,
                  itemBuilder: (context, index) {
                    return Text(_events[index]);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
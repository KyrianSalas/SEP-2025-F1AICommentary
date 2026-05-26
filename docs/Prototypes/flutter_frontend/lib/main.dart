// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'playback_service.dart';
import 'screens/telemetry_screen.dart';

void main() {
  runApp(
    // Wrap your app with the provider
    ChangeNotifierProvider(
      // Create the service and immediately tell it to connect.
      create: (context) => PlaybackService()..connect(),
      // The child is your main app widget
      child: const F1TelemetryApp(),
    ),
  );
}

class F1TelemetryApp extends StatelessWidget {
  const F1TelemetryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'F1 Telemetry UI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.red,
        scaffoldBackgroundColor: const Color(0xFF0D0D0D),
        colorScheme: ColorScheme.dark(
          primary: Colors.red,
          secondary: Colors.red.shade700,
          background: const Color(0xFF0D0D0D),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          elevation: 0,
        ),
        fontFamily: 'Roboto', // Make sure you've added this font to pubspec.yaml
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontSize: 72,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          titleLarge: TextStyle(
            fontSize: 30,
            fontStyle: FontStyle.italic,
            color: Colors.white,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            color: Colors.white70,
          ),
        ),
      ),
      home: const TelemetryScreen(), // Changed from static
    );
  }
}
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'theme/app_theme.dart';
import 'pages/home_page.dart';
import 'pages/csv_library_page.dart';
import 'pages/csv_ui_page.dart';
import 'pages/fastf1_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
    await windowManager.ensureInitialized();
    windowManager.waitUntilReadyToShow(
      const WindowOptions(minimumSize: Size(600, 400)),
    );
  }
  runApp(const MyApp());
}

final GoRouter _router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomePageLanding()),
    GoRoute(
      path: '/csv',
      builder: (context, state) => const CsvLibraryPage(),
    ),
    GoRoute(
      path: '/csv/playback',
      builder: (context, state) {
        final csvFile = state.uri.queryParameters['csv'];
        return CsvUiPage(source: 'csv', csvFilename: csvFile);
      },
    ),
    GoRoute(path: '/fastf1', builder: (context, state) => const FastF1Page()),
    GoRoute(
      path: '/playback',
      builder: (context, state) {
        final source = state.uri.queryParameters['source'] ?? 'csv';
        final year = state.uri.queryParameters['year'];
        final location = state.uri.queryParameters['location'];
        return CsvUiPage(
          source: source,
          year: year != null ? int.tryParse(year) : null,
          location: location,
        );
      },
    ),
    // Legacy redirect — keeps deep-links from older builds working
    GoRoute(
      path: '/fastf1/playback',
      redirect: (context, state) {
        final year = state.uri.queryParameters['year'] ?? '';
        final location = state.uri.queryParameters['location'] ?? '';
        return '/playback?source=fastf1&year=${Uri.encodeComponent(year)}&location=${Uri.encodeComponent(location)}';
      },
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'F1 Telemetry Dashboard',
      theme: AppTheme.darkTheme,
      routerConfig: _router,
    );
  }
}

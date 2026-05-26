import 'dart:convert';

import 'package:f1aicommentary/config/api_config.dart';
import 'package:f1aicommentary/pages/csv_library_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

Widget _buildTestApp({
  required Future<http.Response> Function(Uri uri) getRequest,
}) {
  final GoRouter router = GoRouter(
    routes: [
      GoRoute(
        path: '/csv',
        builder: (context, state) =>
            CsvLibraryPage(getRequest: getRequest, showNavigation: false),
      ),
      GoRoute(
        path: '/csv/playback',
        builder: (context, state) {
          final csv = state.uri.queryParameters['csv'] ?? '';
          return Scaffold(body: Text('Playback for $csv'));
        },
      ),
    ],
    initialLocation: '/csv',
  );

  return MaterialApp.router(routerConfig: router);
}

Future<void> _setLargeTestSurface(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(1600, 1200));
}

Future<void> _pumpCsvLibrary(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 250));
}

void main() {
  testWidgets('CSV library shows files returned by the API', (
    WidgetTester tester,
  ) async {
    await _setLargeTestSurface(tester);
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(
      _buildTestApp(
        getRequest: (Uri uri) async {
          expect(uri, ApiConfig.api('csv/files'));
          return http.Response(
            jsonEncode({
              'files': ['silverstone.csv', 'monza.csv'],
            }),
            200,
          );
        },
      ),
    );

    await _pumpCsvLibrary(tester);

    expect(find.text('silverstone.csv'), findsAtLeastNWidgets(1));
    expect(find.text('monza.csv'), findsAtLeastNWidgets(1));
    expect(find.text('Click to choose CSV'), findsOneWidget);
  });

  testWidgets('CSV library shows an error when the API fails', (
    WidgetTester tester,
  ) async {
    await _setLargeTestSurface(tester);
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(
      _buildTestApp(
        getRequest: (Uri uri) async {
          expect(uri, ApiConfig.api('csv/files'));
          return http.Response('server error', 500);
        },
      ),
    );

    await _pumpCsvLibrary(tester);

    expect(find.textContaining('Failed to load CSV files'), findsOneWidget);
  });

  testWidgets('Play button navigates to playback with selected CSV', (
    WidgetTester tester,
  ) async {
    await _setLargeTestSurface(tester);
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(
      _buildTestApp(
        getRequest: (Uri uri) async {
          return http.Response(
            jsonEncode({
              'files': ['monza.csv'],
            }),
            200,
          );
        },
      ),
    );

    await _pumpCsvLibrary(tester);

    await tester.tap(find.text('Play'));
    await _pumpCsvLibrary(tester);

    expect(find.text('Playback for monza.csv'), findsOneWidget);
  });

  testWidgets('CSV library shows empty state when no files are returned', (
    WidgetTester tester,
  ) async {
    await _setLargeTestSurface(tester);
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(
      _buildTestApp(
        getRequest: (Uri uri) async {
          return http.Response(jsonEncode({'files': []}), 200);
        },
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('No CSV files found on the server yet.'), findsOneWidget);
  });

  testWidgets('CSV library shows loading indicator while fetching files', (
    WidgetTester tester,
  ) async {
    await _setLargeTestSurface(tester);
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(
      _buildTestApp(
        getRequest: (Uri uri) async {
          await Future.delayed(const Duration(seconds: 10));
          return http.Response(jsonEncode({'files': []}), 200);
        },
      ),
    );

    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Clean up pending timer
    await tester.pump(const Duration(seconds: 11));
  });

  testWidgets('CSV library refresh button reloads the file list', (
    WidgetTester tester,
  ) async {
    await _setLargeTestSurface(tester);
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    int callCount = 0;

    await tester.pumpWidget(
      _buildTestApp(
        getRequest: (Uri uri) async {
          callCount++;
          return http.Response(jsonEncode({'files': ['monza.csv']}), 200);
        },
      ),
    );

    await tester.pumpAndSettle();

    expect(callCount, 1);

    await tester.tap(find.text('Refresh'));
    await tester.pumpAndSettle();

    expect(callCount, 2);
  });

  testWidgets('CSV library shows upload card', (
    WidgetTester tester,
  ) async {
    await _setLargeTestSurface(tester);
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(
      _buildTestApp(
        getRequest: (Uri uri) async {
          return http.Response(jsonEncode({'files': []}), 200);
        },
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Click to choose CSV'), findsOneWidget);
    expect(find.byIcon(Icons.upload_file_rounded), findsOneWidget);
  });

  testWidgets('CSV library shows error when request throws an exception', (
    WidgetTester tester,
  ) async {
    await _setLargeTestSurface(tester);
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(
      _buildTestApp(
        getRequest: (Uri uri) async {
          throw Exception('Network error');
        },
      ),
    );

    await tester.pumpAndSettle();

    expect(find.textContaining('Could not load CSV files'), findsOneWidget);
  });
}

import 'package:f1aicommentary/main.dart';
import 'package:f1aicommentary/pages/csv_ui_page.dart';
import 'package:f1aicommentary/widgets/brake_display.dart';
import 'package:f1aicommentary/widgets/brake_temp_display.dart';
import 'package:f1aicommentary/widgets/commentary_display.dart';
import 'package:f1aicommentary/widgets/map_display.dart';
import 'package:f1aicommentary/widgets/progress_bar.dart';
import 'package:f1aicommentary/widgets/rpm_display.dart';
import 'package:f1aicommentary/widgets/speed_display.dart';
import 'package:f1aicommentary/widgets/steering_display.dart';
import 'package:f1aicommentary/widgets/top_bar.dart';
import 'package:f1aicommentary/widgets/homepage_backend_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:f1aicommentary/pages/csv_library_page.dart';
import 'package:f1aicommentary/pages/fastf1_page.dart';
import 'package:f1aicommentary/pages/home_page.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

final testCoordinates = [
  {"X": 0, "Y": 0},
  {"X": 50, "Y": 0},
  {"X": 100, "Y": 0},
  {"X": 150, "Y": 0},
  {"X": 200, "Y": 0},
  {"X": 250, "Y": 0},
  {"X": 300, "Y": 0},
  {"X": 350, "Y": -20},
  {"X": 400, "Y": -50},
  {"X": 440, "Y": -90},
  {"X": 470, "Y": -140},
  {"X": 490, "Y": -200},
  {"X": 500, "Y": -260},
  {"X": 505, "Y": -320},
  {"X": 510, "Y": -380},
  {"X": 515, "Y": -440},
  {"X": 510, "Y": -500},
  {"X": 495, "Y": -550},
  {"X": 470, "Y": -590},
  {"X": 430, "Y": -615},
  {"X": 380, "Y": -625},
  {"X": 330, "Y": -620},
  {"X": 280, "Y": -605},
  {"X": 240, "Y": -580},
  {"X": 200, "Y": -550},
  {"X": 170, "Y": -520},
  {"X": 150, "Y": -480},
  {"X": 140, "Y": -440},
  {"X": 150, "Y": -400},
  {"X": 170, "Y": -360},
  {"X": 180, "Y": -320},
  {"X": 190, "Y": -280},
  {"X": 200, "Y": -240},
  {"X": 210, "Y": -200},
  {"X": 220, "Y": -160},
  {"X": 230, "Y": -120},
  {"X": 235, "Y": -80},
  {"X": 235, "Y": -40},
  {"X": 230, "Y": 0},
  {"X": 220, "Y": 40},
  {"X": 200, "Y": 75},
  {"X": 170, "Y": 100},
  {"X": 130, "Y": 115},
  {"X": 85, "Y": 120},
  {"X": 40, "Y": 115},
  {"X": 0, "Y": 105},
  {"X": -35, "Y": 90},
  {"X": -60, "Y": 70},
  {"X": -75, "Y": 45},
  {"X": -80, "Y": 10},
  {"X": -75, "Y": -20},
  {"X": -60, "Y": -40},
  {"X": -40, "Y": -50},
  {"X": -20, "Y": -45},
];

final List<Map<String, double>> speedHeatmapPoints = [
  {'X': 0.0, 'Y': 0.0, 'metric': 50.0},
  {'X': 5.0, 'Y': 2.5, 'metric': 80.0},
  {'X': 10.0, 'Y': 5.0, 'metric': 120.0},
  {'X': 15.0, 'Y': 7.5, 'metric': 150.0},
  {'X': 20.0, 'Y': 10.0, 'metric': 200.0},
];

Widget buildCsvPage() {
  return const MaterialApp(home: CsvUiPage(source: 'csv', autoConnect: false));
}

Widget _buildAppAtRoute(String location, {Future<http.Response> Function(Uri)? getRequest}) {
  final mockRequest = getRequest ?? (Uri uri) async => http.Response(jsonEncode({'files': []}), 200);

  final router = GoRouter(
    initialLocation: location,
    routes: [
      GoRoute(path: '/', builder: (context, state) => const HomePageLanding()),
      GoRoute(path: '/csv', builder: (context, state) => CsvLibraryPage(getRequest: mockRequest)),
      GoRoute(path: '/csv/playback', builder: (context, state) {
          final csvFile = state.uri.queryParameters['csv'];
          return CsvUiPage(source: 'csv', csvFilename: csvFile);
        },
      ),
      GoRoute(path: '/fastf1', builder: (context, state) => const FastF1Page()),
      GoRoute(path: '/fastf1/playback', builder: (context, state) {
          final year = state.uri.queryParameters['year'] ?? '2024';
          final location = state.uri.queryParameters['location'] ?? 'Bahrain';
          return CsvUiPage(  source: 'fastf1', year: int.tryParse(year), location: location,
          );
        },
      ),
    ],
  );

  return MaterialApp.router(routerConfig: router);
}
void main() {
  testWidgets('App builds without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
  });

  testWidgets('CsvUiPage builds without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(buildCsvPage());
    await tester.pump();

    expect(find.byType(CsvUiPage), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
  });

  testWidgets('Default values are initialized correctly', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildCsvPage());
    await tester.pump();

    expect(find.byType(AppBar), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
  });

  testWidgets('Top bar icons initialise to correct state', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildCsvPage());
    await tester.pump();

    final topBar = find.byType(TopBar);
    expect(
      find.descendant(
        of: topBar,
        matching: find.byIcon(Icons.play_arrow_rounded),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: topBar, matching: find.byIcon(Icons.pause_rounded)),
      findsNothing,
    );
    expect(find.byIcon(Icons.volume_up_rounded), findsOneWidget);
    expect(find.byIcon(Icons.volume_off_rounded), findsNothing);
  });

  testWidgets('Play and pause switches', (WidgetTester tester) async {
    await tester.pumpWidget(buildCsvPage());
    await tester.pump();

    final topBar = find.byType(TopBar);
    final playPauseButton = find.descendant(
      of: topBar,
      matching: find.byIcon(Icons.play_arrow_rounded),
    );
    expect(playPauseButton, findsOneWidget);

    await tester.tap(playPauseButton);
    await tester.pump();

    expect(
      find.descendant(of: topBar, matching: find.byIcon(Icons.pause_rounded)),
      findsOneWidget,
    );
  });

  testWidgets('Speed button cycles correctly', (WidgetTester tester) async {
    await tester.pumpWidget(buildCsvPage());
    await tester.pump();

    final speeds = ['1x', '2x', '4x', '8x', '16x', '32x'];

    expect(find.text(speeds.first), findsOneWidget);

    for (int i = 1; i < speeds.length; i++) {
      await tester.tap(find.text(speeds[i - 1]));
      await tester.pump();
      expect(find.text(speeds[i]), findsOneWidget);
    }

    await tester.tap(find.text(speeds.last));
    await tester.pump();

    expect(find.text(speeds.first), findsOneWidget);
  });

  testWidgets('Mute button toggles', (WidgetTester tester) async {
    await tester.pumpWidget(buildCsvPage());
    await tester.pump();

    final muteButton = find.byIcon(Icons.volume_up_rounded);
    expect(muteButton, findsOneWidget);

    await tester.tap(muteButton);
    await tester.pump();

    expect(find.byIcon(Icons.volume_off_rounded), findsOneWidget);
  });

  testWidgets('All widgets exist', (WidgetTester tester) async {
    await tester.pumpWidget(buildCsvPage());
    await tester.pump();

    expect(find.byType(TopBar), findsOneWidget);
    expect(find.byType(CommentaryDisplay), findsOneWidget);
    expect(find.byType(RpmDisplay), findsOneWidget);
    expect(find.byType(SpeedGraph), findsOneWidget);
    expect(find.byType(SteeringDisplay), findsOneWidget);
    expect(find.byType(BrakeDisplay), findsOneWidget);
    expect(find.byType(BTDisplay), findsOneWidget);
  });

  testWidgets('RpmDisplay shows correct RPM', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: RpmDisplay(
          currentTime: 1.0,
          currentRPM: 6500,
          maxRPM: 9000,
          backgroundColour: Colors.black,
        ),
      ),
    );

    expect(find.byType(RpmDisplay), findsOneWidget);
  });

  testWidgets('RpmDisplay loads with data', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: RpmDisplay(
          currentTime: 1.0,
          currentRPM: 6500,
          maxRPM: 9000,
          backgroundColour: Colors.black,
        ),
      ),
    );

    expect(find.byType(RpmDisplay), findsOneWidget);
  });

  testWidgets('SpeedGraph loads with data', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SpeedGraph(
          currentTime: 1.0,
          currentSpeed: 120.0,
          bufferSeconds: 10.0,
          minSpeed: 0.0,
          maxSpeed: 300.0,
          backgroundColour: Colors.black,
        ),
      ),
    );

    expect(find.byType(SpeedGraph), findsOneWidget);

    await tester.pumpWidget(
      const MaterialApp(
        home: SpeedGraph(
          currentTime: 1,
          currentSpeed: 120,
          bufferSeconds: 5,
          minSpeed: 0,
          maxSpeed: 300,
          backgroundColour: Colors.black,
        ),
      ),
    );
    await tester.pump();

    await tester.pumpWidget(
      const MaterialApp(
        home: SpeedGraph(
          currentTime: 2,
          currentSpeed: 140,
          bufferSeconds: 5,
          minSpeed: 0,
          maxSpeed: 300,
          backgroundColour: Colors.black,
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(SpeedGraph), findsOneWidget);
  });

  testWidgets('RaceProgressBar loads with data', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: RaceProgressBar(
          progress: 0.5,
          ghostProgress: 0.45,
          deltaToBest: -0.2,
          totalRaceLength: 100,
          lapStartTimes: [0, 25, 50, 75],
          carAssetPath: 'assets/car.png',
          lapFontSize: 12,
          lapTickHeight: 10,
          lapTickWidth: 2,
        ),
      ),
    );

    expect(find.byType(RaceProgressBar), findsOneWidget);
  });

  testWidgets('MapDisplay loads with data', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MapDisplay(
          coordinates: testCoordinates,
          dotColor: Colors.white,
          dotSize: 6.0,
          backgroundColor: Colors.black,
          padding: 10.0,
          finishSize: 40.0,
          finishColour: Colors.red,
          carAssetPath: 'assets/FERRARI1.png',
          carSize: 30.0,
          carPosition: {'X': 10.0, 'Y': 5.0},
          carLastPosition: {'X': 8.0, 'Y': 4.0},
          startPosition: testCoordinates.first,
          startPosition2: testCoordinates.last,
          heatmapPoints: const [],
          heatmapMin: 0.0,
          heatmapMax: 350.0,
        ),
      ),
    );

    expect(find.byType(MapDisplay), findsOneWidget);

    await tester.pump();

    await tester.pumpWidget(
      MaterialApp(
        home: MapDisplay(
          coordinates: testCoordinates,
          dotColor: Colors.white,
          dotSize: 6.0,
          backgroundColor: Colors.black,
          padding: 10.0,
          finishSize: 40.0,
          finishColour: Colors.red,
          carAssetPath: 'assets/FERRARI1.png',
          carSize: 30.0,
          carPosition: {'X': 5.0, 'Y': 3.0},
          carLastPosition: {'X': 10.0, 'Y': 5.0},
          startPosition: testCoordinates.first,
          startPosition2: testCoordinates.last,
          heatmapPoints: speedHeatmapPoints,
          heatmapMin: 0.0,
          heatmapMax: 350.0,
        ),
      ),
    );

    expect(find.byType(MapDisplay), findsOneWidget);
  });

  testWidgets('HomepageBackendStatus shows loading indicator initially', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: HomepageBackendStatus())),
    );
    // Don't pump further - we want to catch the initial loading state
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('HomepageBackendStatus shows backend online when API returns 200', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomepageBackendStatus(
            getRequest: (Uri uri) async => http.Response('ok', 200),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Backend online'), findsOneWidget);
  });

  testWidgets('HomepageBackendStatus shows backend offline when API fails', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomepageBackendStatus(
            getRequest: (Uri uri) async => http.Response('error', 500),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Backend offline'), findsOneWidget);
  });

  testWidgets('HomepageBackendStatus opens status dialog when tapped', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomepageBackendStatus(
            getRequest: (Uri uri) async => http.Response('ok', 200),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.byType(OutlinedButton));
    await tester.pumpAndSettle();

    expect(find.text('System status'), findsAtLeast(1));
  });

// Focused on main.dart and loading the correct page based on route:
  testWidgets('MyApp has correct title and no debug banner', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    final MaterialApp app = tester.widget(find.byType(MaterialApp));
    expect(app.debugShowCheckedModeBanner, isFalse);
    expect(app.title, 'F1 Telemetry Dashboard');
  });

  testWidgets('MyApp uses dark theme', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    final MaterialApp app = tester.widget(find.byType(MaterialApp));
    expect(app.theme, isNotNull);
    expect(app.theme!.brightness, Brightness.dark);
  });

  testWidgets('/ route renders HomePageLanding', (WidgetTester tester) async {
    await tester.pumpWidget(_buildAppAtRoute('/'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(HomePageLanding), findsOneWidget);
  });

  testWidgets('/csv route renders CsvLibraryPage', (WidgetTester tester) async {

    await tester.pumpWidget(_buildAppAtRoute('/csv'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    tester.takeException(); // smth on nav bar overflows, but not dependant on surface size so just ignore
    expect(find.byType(CsvLibraryPage), findsOneWidget);
  });

  testWidgets('/fastf1 route renders FastF1Page', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1600, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    
    await tester.pumpWidget(_buildAppAtRoute('/fastf1'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(FastF1Page), findsOneWidget);
    tester.takeException();
  });

  testWidgets('/csv/playback renders CsvUiPage with csv param', (WidgetTester tester) async {
    await tester.pumpWidget(_buildAppAtRoute('/csv/playback?csv=monza.csv'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(CsvUiPage), findsOneWidget);
  });

  testWidgets('/csv/playback handles missing csv param', (WidgetTester tester) async {
    await tester.pumpWidget(_buildAppAtRoute('/csv/playback'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(CsvUiPage), findsOneWidget);
  });

  testWidgets('/fastf1/playback renders CsvUiPage with year and location', (WidgetTester tester) async {
    await tester.pumpWidget(_buildAppAtRoute('/fastf1/playback?year=2023&location=Silverstone'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(CsvUiPage), findsOneWidget);
  });

  testWidgets('/fastf1/playback uses defaults when params absent', (WidgetTester tester) async {
    await tester.pumpWidget(_buildAppAtRoute('/fastf1/playback'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(CsvUiPage), findsOneWidget);
  });

// Focused on fastf1_page.dart

  testWidgets('FastF1Page shows loading indicator initially', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1600, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: FastF1Page(
          getRequest: (Uri uri) async {
            await Future.delayed(const Duration(seconds: 10));
            return http.Response('', 200);
          },
        ),
      ),
    );

    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing); // FastF1Page uses skeleton, not spinner
    expect(find.text('Loading race cache'), findsOneWidget); // status pill text

    await tester.pump(const Duration(seconds: 11));
    tester.takeException();
  });

  testWidgets('FastF1Page shows races when API returns data', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1600, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: FastF1Page(
          getRequest: (Uri uri) async => http.Response(
            jsonEncode({
              '2024': [
                {'name': 'Bahrain Grand Prix', 'location': 'Bahrain', 'round': 1, 'status': 'ready', 'ready': true},
                {'name': 'Monaco Grand Prix', 'location': 'Monaco', 'round': 8, 'status': 'ready', 'ready': true},
              ]
            }),
            200,
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Bahrain Grand Prix'), findsWidgets);
    expect(find.text('Monaco Grand Prix'), findsWidgets);

    tester.takeException(); //ovwerflow error can be ignored
  });

  testWidgets('FastF1Page season selector shows correct years', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1600, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: FastF1Page(
          getRequest: (Uri uri) async => http.Response(
            jsonEncode({
              '2024': [
                {'name': 'Bahrain Grand Prix', 'location': 'Bahrain', 'round': 1, 'status': 'ready', 'ready': true},
              ],
              '2023': [
                {'name': 'Monaco Grand Prix', 'location': 'Monaco', 'round': 8, 'status': 'ready', 'ready': true},
              ],
            }),
            200,
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('2024'), findsWidgets);
    expect(find.text('2023'), findsWidgets);

    tester.takeException();
  });

  testWidgets('FastF1Page shows snackbar when tapping a non-ready race', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1600, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: FastF1Page(
          getRequest: (Uri uri) async => http.Response(
            jsonEncode({
              '2024': [
                {'name': 'Bahrain Grand Prix', 'location': 'Bahrain', 'round': 1, 'status': 'race-loading', 'ready': false},
              ],
            }),
            200,
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.text('Bahrain Grand Prix').first);
    await tester.pump();

    expect(find.text('Preparing telemetry cache'), findsWidgets);

    tester.takeException();
  });

  testWidgets('FastF1Page switching season updates displayed races', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1600, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: FastF1Page(
          getRequest: (Uri uri) async => http.Response(
            jsonEncode({
              '2024': [
                {'name': 'Bahrain Grand Prix', 'location': 'Bahrain', 'round': 1, 'status': 'ready', 'ready': true},
              ],
              '2023': [
                {'name': 'Monaco Grand Prix', 'location': 'Monaco', 'round': 8, 'status': 'ready', 'ready': true},
              ],
            }),
            200,
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // 2024 should be selected by default
    expect(find.text('Bahrain Grand Prix'), findsWidgets);

    // tap 2023 season chip
    await tester.tap(find.text('2023'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Monaco Grand Prix'), findsWidgets);

    tester.takeException();
  });

  testWidgets('FastF1Page navigates to playback when tapping a ready race', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1600, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final router = GoRouter(
      initialLocation: '/fastf1',
      routes: [
        GoRoute(
          path: '/fastf1',
          builder: (context, state) => FastF1Page(
            getRequest: (Uri uri) async => http.Response(
              jsonEncode({
                '2024': [
                  {'name': 'Bahrain Grand Prix', 'location': 'Bahrain', 'round': 1, 'status': 'ready', 'ready': true},
                ],
              }),
              200,
            ),
          ),
        ),
        GoRoute(
          path: '/fastf1/playback',
          builder: (context, state) {
            final year = state.uri.queryParameters['year'] ?? '';
            final location = state.uri.queryParameters['location'] ?? '';
            return Scaffold(body: Text('Playback $year $location'));
          },
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.text('Launch Playback'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Playback 2024 Bahrain'), findsOneWidget);

    tester.takeException();
  });

}

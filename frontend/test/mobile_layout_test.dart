import 'package:f1aicommentary/pages/home_page.dart';
import 'package:f1aicommentary/theme/app_theme.dart';
import 'package:f1aicommentary/widgets/brake_display1.dart';
import 'package:f1aicommentary/widgets/commentary_display.dart';
import 'package:f1aicommentary/widgets/driver_telemetry_struct.dart';
import 'package:f1aicommentary/widgets/grid_layout2.dart';
import 'package:f1aicommentary/widgets/leaderboard.dart';
import 'package:f1aicommentary/widgets/top_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _setPhoneSurface(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(375, 667));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

DriverTelemetry _driver({
  required String code,
  required String team,
  required int gap,
  double rpm = 11200,
  double speed = 212,
  int gear = 4,
}) {
  return DriverTelemetry(
    driverCode: code,
    teamName: team,
    date: DateTime(2024),
    sessionTime: 12,
    lapTime: 91,
    rpm: rpm,
    speed: speed,
    gear: gear,
    throttle: 78,
    brake: true,
    brakePressure: 92,
    drs: 0,
    x: 1,
    y: 1,
    z: 0,
    distance: 100,
    relativeDistance: 0.2,
    driverAhead: '',
    distanceToDriverAhead: gap.toDouble(),
    status: 'OnTrack',
    source: 'fastf1',
  );
}

void main() {
  testWidgets('landing page fits a phone viewport', (tester) async {
    await _setPhoneSurface(tester);

    await tester.pumpWidget(const MaterialApp(home: HomePageLanding()));
    await tester.pump();

    expect(find.text('CSV Telemetry'), findsOneWidget);
    expect(find.text('FastF1 Races'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact playback top bar keeps controls visible', (
    tester,
  ) async {
    await _setPhoneSurface(tester);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          appBar: TopBar(
            raceName: 'British Grand Prix',
            currentTime: 42.1,
            paused: true,
            isMuted: false,
            selectedLap: 'Lap 1',
            lapOptions: const ['Lap 1', 'Lap 2'],
            speedIndex: 0,
            onPlayPauseToggle: () {},
            onMuteToggle: () {},
            onLapChanged: (_) {},
            onSpeedToggle: () {},
            currentRoute: '/fastf1',
            compact: true,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    expect(find.byIcon(Icons.volume_up_rounded), findsOneWidget);
    expect(find.text('Lap 1'), findsOneWidget);
    expect(find.text('1x'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('FastF1 playback layout stacks cleanly on phones', (
    tester,
  ) async {
    await _setPhoneSurface(tester);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: GridLayout2(
            topWidget: const CommentaryDisplay(
              commentary: 'Back on track and building speed.',
              backgroundColor: Colors.black,
            ),
            mainWidget: Leaderboard(
              columnWidths: const [200.0, 300.0, 200.0, 160.0],
              rowHeights: List.filled(3, 60.0),
              selectedDriver: 'ALO',
              drivers: [
                _driver(code: 'SAI', team: 'Ferrari', gap: 2),
                _driver(code: 'ALO', team: 'Aston Martin', gap: 19),
                _driver(code: 'NOR', team: 'McLaren', gap: 31),
              ],
              onDriverSelected: (_) {},
            ),
            rightWidget: Container(
              decoration: AppTheme.glassCard(),
              alignment: Alignment.center,
              child: const Text('Track map'),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(SingleChildScrollView), findsWidgets);
    expect(find.byType(CommentaryDisplay), findsOneWidget);
    expect(find.byType(Leaderboard), findsOneWidget);
    expect(find.text('Gap'), findsOneWidget);
    await tester.ensureVisible(find.text('Track map'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Track map'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact brake display does not overflow', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 207,
              height: 132,
              child: BrakeDisplay1(
                currentTime: 12,
                brake: true,
                brakePressure: 0,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('BRAKE'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

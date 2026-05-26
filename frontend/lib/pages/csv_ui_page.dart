// ignore_for_file: avoid_print
import 'package:f1aicommentary/widgets/leaderboard.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:mp_audio_stream/mp_audio_stream.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'dart:async'
    show StreamSubscription, Completer, TimeoutException, unawaited;
import '../config/api_config.dart';
import '../theme/app_theme.dart';
import '../widgets/progress_bar.dart';
import '../widgets/rpm_display.dart';
import '../widgets/grid_layout.dart';
import '../widgets/grid_layout2.dart';
import '../widgets/steering_display.dart';
import '../widgets/speed_display.dart';
import '../widgets/brake_display.dart';
import '../widgets/brake_temp_display.dart';
import '../widgets/fuel_level_display.dart';
import '../widgets/top_bar.dart';
import '../widgets/map_display.dart';
import '../widgets/commentary_display.dart';
import '../widgets/driver_telemetry_struct.dart';
//_sendCommand('reset');

final dynamic _sharedAudioStream = getAudioStream();

class Lap {
  final int number;
  final double time;
  Lap(this.number, this.time);
}

class CsvUiPage extends StatefulWidget {
  final String source;
  final int? year;
  final String? location;
  final String? csvFilename;
  final bool autoConnect;

  const CsvUiPage({
    super.key,
    required this.source,
    this.year,
    this.location,
    this.csvFilename,
    this.autoConnect = true,
  });

  @override
  State<CsvUiPage> createState() => _CsvUiPageState();
}

class _CsvUiPageState extends State<CsvUiPage> {
  static bool _globalAudioInitialized = false;
  static Future<void>? _globalAudioInitFuture;

  Uri get telemetryWsUri => ApiConfig.ws('telemetry');
  Uri get commentaryWsUri => ApiConfig.ws('commentary');

  Uri get sessionApiUri {
    final Map<String, String> queryParameters = <String, String>{
      'source': widget.source,
    };

    if (widget.source == 'fastf1' &&
        widget.year != null &&
        widget.location != null) {
      queryParameters['year'] = widget.year.toString();
      queryParameters['location'] = widget.location!;
    } else if (widget.source == 'csv' &&
        widget.csvFilename != null &&
        widget.csvFilename!.isNotEmpty) {
      queryParameters['csv_filename'] = widget.csvFilename!;
    }

    return ApiConfig.api('session').replace(queryParameters: queryParameters);
  }

  String? sessionId;
  WebSocketChannel? _channel;
  WebSocketChannel? _commentaryChannel;
  StreamSubscription<dynamic>? _telemetrySubscription;
  StreamSubscription<dynamic>? _commentarySubscription;
  final List<Map<String, dynamic>> _events = [];
  Map<String, dynamic> initalValues = {};
  bool _isConnected = false;

  //real time data fields
  double _currentRPM = 0.0;
  double _currentSpeed = 0.0;
  double _currentAngle = 0.0;
  double _brakePos = 0.0;
  double _currentTime = 0.0;
  double bTBL = 0.0;
  double bTBR = 0.0;
  double bTFL = 0.0;
  double bTFR = 0.0;
  double _fuelLevel = 0.0;
  bool paused = true;
  double x = 0.0;
  double y = 0.0;
  Map<String, dynamic> carLastPos = {'X': 0.0, 'Y': 0.0};
  List<Map<String, dynamic>> trackCoordinates = [];
  final List<Map<String, double>> speedHeatmapPoints = [];
  bool hasStart = false;
  String currentCommentary = '';
  List<DriverTelemetry> _driverTelemetry = [];
  String _selectedDriver = '';

  final dynamic _audioStream = _sharedAudioStream;
  final List<Float32List> _audioQueue = [];
  bool _isPlayingQueue = false;
  bool _audioInitialized = _globalAudioInitialized;
  bool _audioReadyForPlayback = false;
  bool _isDisposing = false;

  bool get _canUpdateUi => mounted && !_isDisposing;

  double counter = 0;
  int totalRaceLength = 0;
  bool playbackForward = false;
  String raceName = "Placeholder Race Name";
  List<String> lapOptions = [];
  List<String> drivers = [];
  Map<String, String> _driverTeamsByCode = {};
  double airTemp = 0.0;
  double trackTemp = 0.0;
  bool rain = false;
  String selectedLap = "";
  int totalLaps = 0;
  double maxFuel = 0.0;
  double maxSpeed = 0.0;
  int maxRPM = 0;
  List<int> lapStartTimes = [];
  int speedIndex = 0;
  bool commentaryMuted = false;
  static const int _trackBins = 120;
  int _activeLapIndex = -1;
  List<double?> _currentLapProfile = List<double?>.filled(_trackBins, null);
  List<double> _bestLapProfile = [];
  double? _bestLapDuration;
  double? _deltaToBestLap;
  double? _ghostProgress;
  //colour for background of widgets
  Color graphBackgrounds = const Color.fromARGB(255, 183, 118, 118);
  //colour for top and bottom bars
  Color backColour2 = const Color.fromARGB(255, 141, 30, 22);
  //colour for small details
  Color accentColour = const Color.fromARGB(210, 230, 186, 99);

  List<Lap> laps = [];

  @override
  void initState() {
    super.initState();
    _audioInitialized = _globalAudioInitialized;

    _setupAudio();
    setLapOptions(6);
    if (widget.autoConnect) {
      _initSessionAndConnect();
    }
  }

  @override
  void dispose() {
    _isDisposing = true;
    _telemetrySubscription?.cancel();
    _commentarySubscription?.cancel();
    _telemetrySubscription = null;
    _commentarySubscription = null;
    _channel?.sink.close();
    _commentaryChannel?.sink.close();
    _audioQueue.clear();
    _isPlayingQueue = false;
    _audioReadyForPlayback = false;
    super.dispose();
  }

  double _asDouble(dynamic value, {double fallback = 0.0}) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is bool) {
      return value ? 100.0 : 0.0;
    }
    if (value is String) {
      return double.tryParse(value) ?? fallback;
    }
    return fallback;
  }

  int _asInt(dynamic value, {int fallback = 0}) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value) ?? fallback;
    }
    return fallback;
  }

  bool _asBool(dynamic value, {bool fallback = false}) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
        return true;
      }
      if (normalized == 'false' || normalized == '0' || normalized == 'no') {
        return false;
      }
    }
    return fallback;
  }

  List<DriverTelemetry> _buildDriverTelemetryList(List<dynamic>? rawDrivers) {
    if (rawDrivers == null || rawDrivers.isEmpty) {
      return [];
    }

    final telemetryWithPosition = rawDrivers.whereType<Map>().map((rawDriver) {
      final driver = Map<String, dynamic>.from(rawDriver);
      return (
        position: _asInt(driver['race_position']),
        telemetry: DriverTelemetry(
          driverCode:
              (driver['driver_code'] ??
                      driver['driverCode'] ??
                      driver['Driver'] ??
                      driver['DriverCode'] ??
                      'N/A')
                  .toString(),
          teamName:
              (driver['team_name'] ??
                      driver['TeamName'] ??
                      _driverTeamsByCode[(driver['driver_code'] ??
                              driver['driverCode'] ??
                              driver['Driver'] ??
                              driver['DriverCode'] ??
                              'N/A')
                          .toString()])
                  ?.toString(),
          date:
              DateTime.tryParse(driver['Date']?.toString() ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0),
          sessionTime: _asDouble(
            driver['Time (s)'] ?? driver['Time_s'] ?? driver['Time'],
          ),
          lapTime: _asDouble(driver['Lap Time'] ?? driver['LapTime']),
          rpm: _asDouble(
            driver['Engine RPM (rpm)'] ?? driver['RPM'] ?? driver['rpm'],
          ),
          speed: _asDouble(
            driver['Ground Speed (km/h)'] ??
                driver['Speed'] ??
                driver['SpeedI1'],
          ),
          gear: _asInt(driver['Gear'] ?? driver['nGear']),
          throttle: _asDouble(driver['Throttle Pos (%)'] ?? driver['Throttle']),
          brake: _asDouble(driver['Brake Pos (%)'] ?? driver['Brake']) > 0,
          brakePressure: _asDouble(driver['Brake Pos (%)'] ?? driver['Brake']),
          drs: _asInt(driver['DRS'] ?? driver['drs'] ?? driver['Drs']),
          x: _asDouble(driver['X']),
          y: _asDouble(driver['Y']),
          z: _asDouble(driver['Z']),
          distance: _asDouble(driver['Distance']),
          relativeDistance: _asDouble(driver['RelativeDistance']),
          driverAhead:
              (driver['DriverAhead'] ?? driver['driver_ahead'] ?? 'N/A')
                  .toString(),
          distanceToDriverAhead: _asDouble(
            driver['DistanceToDriverAhead'] ?? driver['distanceToDriverAhead'],
          ),
          status: (driver['Status'] ?? driver['status'] ?? 'N/A').toString(),
          source: (driver['source'] ?? widget.source).toString(),
        ),
      );
    }).toList();

    telemetryWithPosition.sort((left, right) {
      final leftPosition = left.position == 0 ? 9999 : left.position;
      final rightPosition = right.position == 0 ? 9999 : right.position;
      if (leftPosition != rightPosition) {
        return leftPosition.compareTo(rightPosition);
      }
      return left.telemetry.driverCode.compareTo(right.telemetry.driverCode);
    });

    return telemetryWithPosition.map((entry) => entry.telemetry).toList();
  }

  Map<String, String> _parseDriverTeams(dynamic rawMetadata) {
    final parsed = <String, String>{};
    if (rawMetadata is! Map) {
      return parsed;
    }

    rawMetadata.forEach((key, value) {
      final driverCode = key.toString().trim();
      if (driverCode.isEmpty || value is! Map) {
        return;
      }

      final teamName = value['team_name']?.toString().trim() ?? '';
      if (teamName.isNotEmpty) {
        parsed[driverCode] = teamName;
      }
    });
    return parsed;
  }

  dynamic _firstValue(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      if (source.containsKey(key) && source[key] != null) {
        return source[key];
      }
    }
    return null;
  }

  List<int> _parseLapIndexes(dynamic raw) {
    try {
      if (raw is String && raw.isNotEmpty) {
        return List<int>.from(jsonDecode(raw));
      }
      if (raw is List) {
        return raw.map((e) => _asInt(e)).toList();
      }
    } catch (_) {
      // Fallback below
    }
    return [0];
  }

  Future<void> _setupAudio() async {
    await _ensureAudioInitialized();
  }

  Future<void> _ensureAudioInitialized() async {
    if (_globalAudioInitialized) {
      _audioInitialized = true;
      return;
    }

    if (_globalAudioInitFuture != null) {
      await _globalAudioInitFuture;
      _audioInitialized = _globalAudioInitialized;
      return;
    }

    final completer = Completer<void>();
    _globalAudioInitFuture = completer.future;

    try {
      final dynamic initResult = _audioStream.init(
        sampleRate: 24000,
        channels: 1,
      );
      if (initResult is Future) {
        await initResult;
      }
      _globalAudioInitialized = true;
      _audioInitialized = true;
      debugPrint("Audio Stream Initialised");
    } catch (e) {
      _globalAudioInitialized = false;
      _audioInitialized = false;
      debugPrint("Audio Init Error: $e");
    } finally {
      completer.complete();
      _globalAudioInitFuture = null;
    }
  }

  Future<void> _initSessionAndConnect() async {
    try {
      final response = await http
          .get(sessionApiUri)
          .timeout(const Duration(seconds: 20));

      if (!_canUpdateUi) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final id = data['session_id'] ?? data['sessionId'] ?? data['id'];
        if (id == null) {
          debugPrint('Session response missing ID: ${response.body}');
          return;
        }
        _audioReadyForPlayback = false;
        _audioQueue.clear();
        setState(() => sessionId = id.toString());
        _connect();
      } else {
        debugPrint(
          'Failed to get session ID: ${response.statusCode} ${response.body}',
        );
      }
    } on TimeoutException {
      debugPrint('Session request timed out for $sessionApiUri');
    } catch (e) {
      debugPrint('Error fetching session ID: $e');
    }
  }

  void _signalAudioFinished() {
    if (_channel != null && _isConnected) {
      try {
        _channel!.sink.add(jsonEncode({"action": "playback_finished"}));
      } catch (e) {
        debugPrint('Playback finished signal skipped: $e');
      }
    }
    if (!_canUpdateUi) {
      return;
    }
    setState(() {
      currentCommentary = '';
    });
  }

  void _handleIncomingAudio(String encodedAudio) {
    if (encodedAudio.isEmpty) return;
    if (!_audioInitialized) {
      unawaited(_ensureAudioInitialized());
    }

    final audioBytes = base64Decode(encodedAudio);
    final sampleCount = audioBytes.lengthInBytes ~/ 2;

    if (sampleCount > 0) {
      final int16Data = audioBytes.buffer.asInt16List(
        audioBytes.offsetInBytes,
        sampleCount,
      );
      final float32Data = Float32List(int16Data.length);
      for (int i = 0; i < int16Data.length; i++) {
        float32Data[i] = int16Data[i] / 32768.0;
      }

      _audioQueue.add(float32Data);

      if (!_isPlayingQueue && _audioQueue.length >= 3) {
        unawaited(_processAudioQueue());
      }
    }
  }

  Future<void> _processAudioQueue() async {
    if (_isPlayingQueue) return;
    _isPlayingQueue = true;

    while (_audioQueue.isNotEmpty) {
      if (!_canUpdateUi) {
        _isPlayingQueue = false;
        return;
      }

      if (!_audioReadyForPlayback || commentaryMuted || paused) {
        await Future.delayed(const Duration(milliseconds: 20));
        continue;
      }

      final chunk = _audioQueue.removeAt(0);
      await _ensureAudioInitialized();

      if (_audioInitialized) {
        try {
          _audioStream.push(chunk);
        } catch (e) {
          _globalAudioInitialized = false;
          _audioInitialized = false;
          _audioReadyForPlayback = false;
          debugPrint('Audio push error: $e');
        }
      }

      // Calculate how long this chunk takes to play (at 24khz)
      final durationMs = (chunk.length / 24000.0 * 1000).toInt();

      await Future.delayed(
        Duration(milliseconds: durationMs > 50 ? durationMs - 50 : durationMs),
      );
    }

    _isPlayingQueue = false;
    _signalAudioFinished();
  }

  Future<void> _resumeAudioStream() async {
    await _ensureAudioInitialized();
    if (!_audioInitialized) {
      _audioReadyForPlayback = false;
      return;
    }
    try {
      final dynamic resumeResult = _audioStream.resume();
      if (resumeResult is Future) {
        await resumeResult;
      }
      _audioReadyForPlayback = true;
    } catch (e) {
      _globalAudioInitialized = false;
      _audioInitialized = false;
      _audioReadyForPlayback = false;
      debugPrint('Audio resume error: $e');
    }
  }

  void _connect() {
    if (sessionId == null) {
      print('Session ID not set, cannot connect WebSocket.');
      return;
    }
    final wsUrl = telemetryWsUri.replace(
      queryParameters: {'session_id': sessionId!},
    );
    final comUrl = commentaryWsUri.replace(
      queryParameters: {'session_id': sessionId!},
    );
    try {
      _channel = WebSocketChannel.connect(wsUrl);
      _commentaryChannel = WebSocketChannel.connect(comUrl);
      _telemetrySubscription?.cancel();
      _commentarySubscription?.cancel();
      if (!_canUpdateUi) {
        return;
      }
      setState(() {
        _isConnected = true;
      });
      _commentarySubscription = _commentaryChannel!.stream.listen((message) {
        if (!_canUpdateUi) {
          return;
        }
        final decoded = jsonDecode(message);

        if (decoded['type'] == 'commentary_delta') {
          final String newSnippet = decoded['text'] as String;

          setState(() {
            String updatedText = currentCommentary + newSnippet;
            int sentenceCount = RegExp(r'[.!?]').allMatches(updatedText).length;

            if (sentenceCount > 8) {
              currentCommentary = newSnippet.trimLeft();
            } else {
              currentCommentary = updatedText;
            }
          });
        } else if (decoded['type'] == 'audio_delta') {
          _handleIncomingAudio(decoded['audio'] as String? ?? '');
        }
      }, onError: (err) => print("Commentary Error: $err"));

      _telemetrySubscription = _channel!.stream.listen(
        (message) {
          if (!_canUpdateUi) {
            return;
          }
          //print(message);
          final Map<String, dynamic> decoded = jsonDecode(message);
          //print(decoded);
          //use below for checking available keys
          //print("keys: ${decoded.keys.toList()}");
          //print("X value: ${decoded['Car coord X (m)']}, Y value: ${decoded['Y']}");

          try {
            String? type = decoded['type']?.toString();
            if (type == 'commentary') {
              setState(() {
                currentCommentary = decoded['text'] as String? ?? '';
              });
            } else if (type == 'initial_setup' && !hasStart) {
              //print("INITIAL HERE");
              //the inital message data checker
              setState(() {
                trackCoordinates =
                    (decoded['track_map'] as List?)
                        ?.map((coord) => coord as Map<String, dynamic>)
                        .toList() ??
                    [];
                initalValues = (decoded['session_info']) ?? {};
                raceName = initalValues['event'] as String? ?? raceName;
                lapStartTimes = _parseLapIndexes(initalValues['LapIndexes']);
                if (lapStartTimes.isEmpty) {
                  lapStartTimes = [0];
                }

                final int rawTotalLaps = _asInt(initalValues['TotalLapCount']);
                final int lapsFromIndexes = lapStartTimes.length;
                if (rawTotalLaps > 0 && lapsFromIndexes > 0) {
                  totalLaps = max(rawTotalLaps, lapsFromIndexes);
                } else if (rawTotalLaps > 0) {
                  totalLaps = rawTotalLaps;
                } else {
                  totalLaps = lapsFromIndexes > 0 ? lapsFromIndexes : 1;
                }

                totalRaceLength = _asInt(
                  initalValues['RaceIndexLength'] ?? decoded['total_points'],
                  fallback: 0,
                );
                drivers = List<String>.from(initalValues['drivers'] ?? []);
                rain = _asBool(initalValues['rainfall']);
                trackTemp = initalValues['track_temp'];
                trackTemp = initalValues['air_temp'];
                totalRaceLength = initalValues['RaceIndexLength'];
                maxFuel = _asDouble(initalValues['Max Fuel']);
                maxSpeed = _asDouble(initalValues['MaxSpeed']);
                maxRPM = _asInt(initalValues['Max RPM']);
                _driverTeamsByCode = _parseDriverTeams(
                  initalValues['driver_metadata'],
                );
                _driverTelemetry = [];
                _selectedDriver = '';
                speedHeatmapPoints.clear();
                _activeLapIndex = -1;
                _currentLapProfile = List<double?>.filled(_trackBins, null);
                _bestLapProfile = [];
                _bestLapDuration = null;
                _deltaToBestLap = null;
                _ghostProgress = null;
                setLapOptions(totalLaps);
                hasStart = true;
              });
            } else {
              setState(() {
                _events.add(decoded);
                _driverTelemetry = _buildDriverTelemetryList(
                  decoded['drivers'] as List?,
                );
                final Map<String, dynamic> driver0 =
                    (decoded['drivers'] as List).isNotEmpty
                    ? Map<String, dynamic>.from(decoded['drivers'][0] as Map)
                    : <String, dynamic>{};

                _currentRPM = _asDouble(
                  _firstValue(driver0, ['Engine RPM (rpm)', 'RPM']),
                  fallback: _currentRPM,
                );
                _currentSpeed = _asDouble(
                  _firstValue(driver0, [
                    'Ground Speed (km/h)',
                    'Speed',
                    'SpeedI1',
                  ]),
                  fallback: _currentSpeed,
                );
                _currentAngle = _asDouble(
                  _firstValue(driver0, ['Steering Angle (deg)']),
                  fallback: _currentAngle,
                );
                _brakePos = _asDouble(
                  _firstValue(driver0, ['Brake Pos (%)', 'Brake']),
                  fallback: _brakePos,
                );
                bTBL = _asDouble(driver0['Brake Temp RL (C)'], fallback: bTBL);
                bTBR = _asDouble(driver0['Brake Temp RR (C)'], fallback: bTBR);
                bTFL = _asDouble(driver0['Brake Temp FL (C)'], fallback: bTFL);
                bTFR = _asDouble(driver0['Brake Temp FR (C)'], fallback: bTFR);
                _fuelLevel = _asDouble(
                  driver0['Fuel Level (l)'],
                  fallback: _fuelLevel,
                );

                //must update previous position before grabbing current location
                carLastPos = {'X': x, 'Y': y};

                x = _asDouble(driver0['X'], fallback: x);
                y = _asDouble(driver0['Y'], fallback: y);
                speedHeatmapPoints.add({
                  'X': x,
                  'Y': y,
                  'metric': _currentSpeed,
                });
                if (speedHeatmapPoints.length > 3000) {
                  speedHeatmapPoints.removeAt(0);
                }
                final int backendIndex = _asInt(decoded['index'], fallback: -1);
                if (backendIndex >= 0) {
                  counter = backendIndex.toDouble();
                } else {
                  counter += 1;
                }
                _currentTime = counter / 20.0;
                if (_driverTelemetry.length <= 1) {
                  _updateLapCoaching();
                } else {
                  _deltaToBestLap = null;
                  _ghostProgress = null;
                }
              });
            }
          } catch (e) {
            debugPrint('Error processing message: $e');
          }
        },
        onDone: () {
          debugPrint("WebSocket closed");
          if (!_canUpdateUi) {
            return;
          }
          setState(() {
            _isConnected = false;
          });
        },
        onError: (error) {
          debugPrint("WebSocket Error: $error");
          if (!_canUpdateUi) {
            return;
          }
          setState(() {
            _isConnected = false;
          });
        },
      );
    } catch (e) {
      debugPrint("Error connecting to WebSocket: $e");
    }
  }

  void _sendCommand(String action, {Map<String, dynamic>? extraFields}) {
    int selectedSpeed = pow(2, speedIndex).toInt();

    if (_channel != null && _isConnected) {
      Map<String, dynamic> command = {
        'action': action,
        'playback_speed': selectedSpeed,
      };
      if (extraFields != null && extraFields.isNotEmpty) {
        command.addAll(extraFields);
      }

      if (action == 'seek') {
        speedHeatmapPoints.clear();
      }

      final jsonCommand = jsonEncode(command);
      _channel!.sink.add(jsonCommand);
      print("Sent command: $jsonCommand");
    } else {
      //print("Not connected, cannot send: $action");
    }
  }

  void setLapOptions(int totalLaps) {
    lapOptions = List.generate(totalLaps, (index) => "Lap ${index + 1}");
    if (lapOptions.isNotEmpty) {
      selectedLap = lapOptions[0];
    }
    laps = List.generate(totalLaps, (i) => Lap(i + 1, 48 * i.toDouble()));
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  void _updateLapCoaching() {
    if (totalRaceLength <= 0 || lapStartTimes.length < 2) {
      _deltaToBestLap = null;
      _ghostProgress = null;
      return;
    }

    final raceIndex = counter.round().clamp(0, totalRaceLength - 1);
    final lapIndex = _lapIndexForRaceIndex(raceIndex);
    final lapStart = lapStartTimes[lapIndex];

    if (_activeLapIndex == -1) {
      _activeLapIndex = lapIndex;
      _currentLapProfile = List<double?>.filled(_trackBins, null);
    } else if (lapIndex != _activeLapIndex) {
      _finalizeLap(_activeLapIndex);
      _activeLapIndex = lapIndex;
      _currentLapProfile = List<double?>.filled(_trackBins, null);
    }

    final lapElapsedSeconds = (raceIndex - lapStart) / 20.0;
    final trackProgress = _computeTrackProgress(x, y);
    final bin = (trackProgress * (_trackBins - 1)).round().clamp(
      0,
      _trackBins - 1,
    );
    _currentLapProfile[bin] ??= lapElapsedSeconds;

    if (_bestLapProfile.isNotEmpty) {
      final bestElapsed = _bestLapProfile[bin];
      _deltaToBestLap = lapElapsedSeconds - bestElapsed;
      final ghostRaceIndex = lapStart + (bestElapsed * 20.0);
      _ghostProgress = (ghostRaceIndex / totalRaceLength).clamp(0.0, 1.0);
    } else {
      _deltaToBestLap = null;
      _ghostProgress = null;
    }
  }

  int _lapIndexForRaceIndex(int raceIndex) {
    for (int i = lapStartTimes.length - 1; i >= 0; i--) {
      if (raceIndex >= lapStartTimes[i]) {
        return i;
      }
    }
    return 0;
  }

  double _computeTrackProgress(double carX, double carY) {
    if (trackCoordinates.isEmpty) return 0.0;
    int nearestIndex = 0;
    double nearestDist = double.infinity;
    for (int i = 0; i < trackCoordinates.length; i++) {
      final point = trackCoordinates[i];
      final px = point['X']?.toDouble() ?? 0.0;
      final py = point['Y']?.toDouble() ?? 0.0;
      final dx = carX - px;
      final dy = carY - py;
      final dist = dx * dx + dy * dy;
      if (dist < nearestDist) {
        nearestDist = dist;
        nearestIndex = i;
      }
    }
    if (trackCoordinates.length <= 1) return 0.0;
    return nearestIndex / (trackCoordinates.length - 1);
  }

  void _finalizeLap(int lapIndex) {
    if (lapIndex < 0 || lapIndex >= lapStartTimes.length) return;
    final lapStart = lapStartTimes[lapIndex];
    final lapEnd = lapIndex + 1 < lapStartTimes.length
        ? lapStartTimes[lapIndex + 1]
        : totalRaceLength;
    if (lapEnd <= lapStart) return;

    final lapDuration = (lapEnd - lapStart) / 20.0;
    if (_bestLapDuration != null && lapDuration >= _bestLapDuration!) {
      return;
    }

    final profile = List<double>.filled(_trackBins, lapDuration);
    double lastKnown = 0.0;
    for (int i = 0; i < _trackBins; i++) {
      final v = _currentLapProfile[i];
      if (v != null) {
        lastKnown = v;
      }
      profile[i] = lastKnown.clamp(0.0, lapDuration);
    }
    for (int i = _trackBins - 2; i >= 0; i--) {
      if (_currentLapProfile[i] == null) {
        profile[i] = profile[i + 1].clamp(0.0, lapDuration);
      }
    }

    _bestLapDuration = lapDuration;
    _bestLapProfile = profile;
  }

  void _togglePlayback() {
    if (paused) {
      unawaited(_resumeAudioStream());
      commentaryMuted = false;
    } else if (!paused) {
      _audioReadyForPlayback = false;
      _audioQueue.clear();
      commentaryMuted = true;
    }
    setState(() {
      paused = !paused;
    });
    _sendCommand(paused ? 'pause' : 'play');
  }

  Widget _buildPlaybackStartPrompt() {
    return Container(
      decoration: AppTheme.glassCard(),
      child: Center(
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: _togglePlayback,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppTheme.accentCyan.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.accentCyan.withValues(alpha: 0.45),
                    ),
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: AppTheme.accentCyan,
                    size: 42,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Press play to begin',
                  textAlign: TextAlign.center,
                  style: AppTheme.orbitron(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Use either play button to start the data visualisation.',
                  textAlign: TextAlign.center,
                  style: AppTheme.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool compactPlaybackChrome = MediaQuery.sizeOf(context).width < 640;

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: TopBar(
        raceName: initalValues['event'] as String? ?? raceName,
        currentTime: _currentTime,
        paused: paused,
        isMuted: commentaryMuted,
        selectedLap: selectedLap,
        lapOptions: lapOptions,
        speedIndex: speedIndex,
        onMuteToggle: () {
          setState(() {
            commentaryMuted = !commentaryMuted;
          });
        },
        onPlayPauseToggle: _togglePlayback,
        onLapChanged: (String? newValue) {
          setState(() {
            selectedLap = newValue!;
          });

          int? lapNumber = newValue != null
              ? int.tryParse(newValue.replaceAll(RegExp(r'\D'), ''))
              : null;

          if (lapNumber == null ||
              lapNumber < 1 ||
              lapNumber > lapStartTimes.length) {
            return;
          }

          _sendCommand(
            'seek',
            extraFields: {'index': lapStartTimes[lapNumber - 1]},
          );
        },
        onSpeedToggle: () {
          setState(() {
            speedIndex = (speedIndex + 1) % 6;
          });
          _sendCommand("change_speed");
        },
        currentRoute: widget.source == 'fastf1' ? '/fastf1' : '/csv',
        compact: compactPlaybackChrome,
      ),
      body: widget.source == 'fastf1'
          ? GridLayout2(
              topWidget: CommentaryDisplay(
                commentary: currentCommentary,
                backgroundColor: graphBackgrounds,
              ),
              mainWidget: Leaderboard(
                columnWidths: [200.0, 300.0, 200.0, 160.0],
                rowHeights: List.filled(_driverTelemetry.length, 60.0),
                drivers: _driverTelemetry,
                selectedDriver: _selectedDriver,
                onStartPlayback: _togglePlayback,
                onDriverSelected: (driverCode) {
                  setState(() {
                    _selectedDriver = _selectedDriver == driverCode
                        ? ''
                        : driverCode;
                  });
                },
              ),
              rightWidget: trackCoordinates.isEmpty
                  ? _buildPlaybackStartPrompt()
                  : MapDisplay(
                      coordinates: trackCoordinates,
                      dotSize: 6.0,
                      finishSize: 40.0,
                      finishColour: AppTheme.accentRed,
                      carAssetPath: 'assets/FERRARI1.png',
                      carSize: 30.0,
                      carPosition: {'X': x, 'Y': y},
                      carLastPosition: carLastPos,
                      startPosition: trackCoordinates[0],
                      startPosition2:
                          trackCoordinates[trackCoordinates.length - 1],
                      heatmapPoints: speedHeatmapPoints,
                      heatmapMin: 0.0,
                      heatmapMax: maxSpeed > 0 ? maxSpeed : 350.0,
                      allDrivers: _driverTelemetry,
                      selectedDriverCode: _selectedDriver,
                    ),
            )
          : GridLayout(
              topWidget: CommentaryDisplay(
                commentary: currentCommentary,
                backgroundColor: graphBackgrounds,
              ),
              heroWidgets: [
                RpmDisplay(
                  currentTime: _currentTime,
                  currentRPM: _currentRPM,
                  maxRPM: maxRPM.toDouble(),
                  backgroundColour: graphBackgrounds,
                ),
                SpeedGraph(
                  currentTime: _currentTime,
                  currentSpeed: _currentSpeed,
                  bufferSeconds: 10.0,
                  minSpeed: 0.0,
                  maxSpeed: maxSpeed,
                  backgroundColour: graphBackgrounds,
                ),
              ],
              secondaryWidgets: [
                SteeringDisplay(
                  currentTime: _currentTime,
                  currentAngle: _currentAngle,
                  backgroundColour: graphBackgrounds,
                ),
                BrakeDisplay(
                  brakePos: _brakePos,
                  currentTime: _currentTime,
                  backgroundColour: graphBackgrounds,
                ),
                BTDisplay(
                  currentTime: _currentTime,
                  bTFR: bTFR,
                  bTFL: bTFL,
                  bTBL: bTBL,
                  bTBR: bTBR,
                  sBRPM: _currentSpeed * 30.0,
                  pause: paused,
                  backgroundColour: graphBackgrounds,
                ),
                FuelLevelGraph(
                  currentTime: _currentTime,
                  currentFuel: _fuelLevel,
                  bufferSeconds: 30.0,
                  minFuel: 0.0,
                  maxFuel: maxFuel,
                  backgroundColour: graphBackgrounds,
                ),
              ],
              rightWidget: trackCoordinates.isEmpty
                  ? _buildPlaybackStartPrompt()
                  : MapDisplay(
                      coordinates: trackCoordinates,
                      dotSize: 6.0,
                      finishSize: 40.0,
                      finishColour: AppTheme.accentRed,
                      carAssetPath: 'assets/FERRARI1.png',
                      carSize: 30.0,
                      carPosition: {'X': x, 'Y': y},
                      carLastPosition: carLastPos,
                      startPosition: trackCoordinates[0],
                      startPosition2:
                          trackCoordinates[trackCoordinates.length - 1],
                      heatmapPoints: speedHeatmapPoints,
                      heatmapMin: 0.0,
                      heatmapMax: maxSpeed > 0 ? maxSpeed : 350.0,
                      allDrivers: _driverTelemetry,
                      selectedDriverCode: _selectedDriver,
                    ),
            ),

      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          height: compactPlaybackChrome ? 82 : 92,
          decoration: const BoxDecoration(
            color: Color(0xFF111122),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: compactPlaybackChrome ? 8 : 10,
            vertical: compactPlaybackChrome ? 6 : 8,
          ),
          child: lapStartTimes.isEmpty
              ? const SizedBox.expand()
              : RaceProgressBar(
                  progress: totalRaceLength > 0 ? counter / totalRaceLength : 0,
                  ghostProgress: _driverTelemetry.length > 1
                      ? null
                      : _ghostProgress,
                  deltaToBest: _driverTelemetry.length > 1
                      ? null
                      : _deltaToBestLap,
                  totalRaceLength: totalRaceLength,
                  lapStartTimes: lapStartTimes,
                  lapFontSize: compactPlaybackChrome ? 9.0 : 10.0,
                  lapTickHeight: 0.04,
                  lapTickWidth: compactPlaybackChrome ? 0.003 : 0.004,
                  compact: compactPlaybackChrome,
                  carAssetPath: 'assets/pilot.png',
                  onProgressChanged: (newPosition) {
                    _sendCommand(
                      'seek',
                      extraFields: {
                        'index': (newPosition * totalRaceLength).round(),
                      },
                    );
                    setState(() {});
                  },
                ),
        ),
      ),
    );
  }
}

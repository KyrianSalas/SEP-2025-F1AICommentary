import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../theme/app_theme.dart';
import '../widgets/fastf1_browser_backdrop.dart';
import '../widgets/section_nav_bar.dart';

class FastF1Page extends StatefulWidget {
  const FastF1Page({super.key, this.getRequest});

  final Future<http.Response> Function(Uri uri)? getRequest;

  @override
  State<FastF1Page> createState() => _FastF1PageState();
}

class _FastF1PageState extends State<FastF1Page> {
  Map<String, dynamic> racesByYear = {};
  bool isLoading = true;
  String? loadError;
  String? selectedYear;
  _RaceEvent? selectedRace;
  Timer? _raceRefreshTimer;

  @override
  void initState() {
    super.initState();
    _fetchRaces();
  }

  @override
  void dispose() {
    _raceRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchRaces({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() {
        isLoading = true;
        loadError = null;
      });
    }

    try {
      final getRequest = widget.getRequest ?? http.get;
      final response = await getRequest(ApiConfig.api('races'));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final bool hasLoadingRaces = _hasLoadingRaces(decoded);
        _syncRacePolling(hasLoadingRaces);
        if (!mounted) return;
        setState(() {
          racesByYear = decoded;
          selectedYear = _resolveSelectedYear(decoded);
          selectedRace = _resolveSelectedRace(decoded);
          isLoading = false;
          loadError = null;
        });
      } else {
        if (!mounted) return;
        setState(() {
          isLoading = false;
          loadError = 'Race cache returned ${response.statusCode}.';
        });
      }
    } catch (e) {
      debugPrint('Error fetching races: $e');
      if (!mounted) return;
      setState(() {
        isLoading = false;
        loadError = 'Could not load the FastF1 race cache.';
      });
    }
  }

  bool _hasLoadingRaces(Map<String, dynamic> payload) {
    for (final dynamic yearRaces in payload.values) {
      if (yearRaces is! List) continue;
      for (final dynamic race in yearRaces) {
        if (race is! Map) continue;
        final raceData = Map<String, dynamic>.from(race);
        final status = (raceData['status'] ?? 'race-loading').toString();
        if (raceData['ready'] != true && status != 'ready') return true;
      }
    }
    return false;
  }

  void _syncRacePolling(bool shouldPoll) {
    if (shouldPoll) {
      _raceRefreshTimer ??= Timer.periodic(
        const Duration(seconds: 10),
        (_) => _fetchRaces(silent: true),
      );
      return;
    }
    _raceRefreshTimer?.cancel();
    _raceRefreshTimer = null;
  }

  List<String> get _seasonYears {
    final years = racesByYear.keys.toList();
    years.sort(_compareYearsDescending);
    return years;
  }

  String? get _activeYear {
    if (selectedYear != null && racesByYear.containsKey(selectedYear)) {
      return selectedYear;
    }
    final years = _seasonYears;
    return years.isEmpty ? null : years.first;
  }

  int get _activeEventCount {
    final year = _activeYear;
    if (year == null) {
      return 0;
    }
    final races = racesByYear[year];
    return races is List ? races.length : 0;
  }

  List<_RaceEvent> get _activeRaces {
    final year = _activeYear;
    if (year == null) {
      return <_RaceEvent>[];
    }
    final races = racesByYear[year];
    if (races is! List) {
      return <_RaceEvent>[];
    }
    return races
        .whereType<Map>()
        .map((race) => _RaceEvent.fromMap(year, race))
        .toList();
  }

  _RaceEvent? get _selectedActiveRace {
    final race = selectedRace;
    if (race != null && race.year == _activeYear) {
      return race;
    }
    final races = _activeRaces;
    return races.isEmpty ? null : races.first;
  }

  _RaceEvent? _firstRaceForYear(String year) {
    final races = racesByYear[year];
    if (races is! List) {
      return null;
    }
    for (final race in races.whereType<Map>()) {
      return _RaceEvent.fromMap(year, race);
    }
    return null;
  }

  void _launchRace(_RaceEvent race) {
    if (!race.isReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preparing telemetry cache')),
      );
      return;
    }
    final location = Uri.encodeComponent(race.location);
    context.go('/fastf1/playback?year=${race.year}&location=$location');
  }

  String? _resolveSelectedYear(Map<String, dynamic> payload) {
    if (selectedYear != null && payload.containsKey(selectedYear)) {
      return selectedYear;
    }
    final years = payload.keys.toList();
    years.sort(_compareYearsDescending);
    return years.isEmpty ? null : years.first;
  }

  _RaceEvent? _resolveSelectedRace(Map<String, dynamic> payload) {
    if (selectedRace != null) {
      final currentYearRaces = payload[selectedRace!.year];
      if (currentYearRaces is List) {
        for (final race in currentYearRaces.whereType<Map>()) {
          final event = _RaceEvent.fromMap(selectedRace!.year, race);
          if (event.location == selectedRace!.location) {
            return event;
          }
        }
      }
    }

    final year = _resolveSelectedYear(payload);
    final races = year == null ? null : payload[year];
    if (races is List && races.isNotEmpty) {
      for (final race in races.whereType<Map>()) {
        return _RaceEvent.fromMap(year!, race);
      }
    }
    return null;
  }

  int _compareYearsDescending(String a, String b) {
    final int? yearA = int.tryParse(a);
    final int? yearB = int.tryParse(b);
    if (yearA != null && yearB != null) {
      return yearB.compareTo(yearA);
    }
    return b.compareTo(a);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 12,
        leadingWidth: 120,
        leading: const Padding(
          padding: EdgeInsets.only(left: 16, top: 10, bottom: 10),
          child: Align(
            alignment: Alignment.centerLeft,
            child: SectionNavBar(currentRoute: '/fastf1'),
          ),
        ),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: FastF1BrowserBackdrop()),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final bool isWide = constraints.maxWidth >= 980;
                final selectedRace = _selectedActiveRace;
                final bottomPadding = !isWide && selectedRace != null
                    ? 104.0
                    : 32.0;

                return Stack(
                  children: [
                    ListView(
                      padding: EdgeInsets.fromLTRB(20, 28, 20, bottomPadding),
                      children: [
                        _FastF1CommandBar(
                          seasonLabel: _activeYear == null
                              ? 'Season loading'
                              : '${_activeYear!} season',
                          eventCount: _activeEventCount,
                          isLoading: isLoading,
                          isPolling: _raceRefreshTimer != null,
                        ),
                        const SizedBox(height: 18),
                        _SeasonSelector(
                          years: _seasonYears,
                          selectedYear: _activeYear,
                          onSelected: (year) {
                            setState(() {
                              selectedYear = year;
                              this.selectedRace = _firstRaceForYear(year);
                            });
                          },
                        ),
                        const SizedBox(height: 18),
                        if (isLoading && _activeRaces.isEmpty)
                          const _RaceSkeletonGrid()
                        else if (loadError != null && _activeRaces.isEmpty)
                          _RaceErrorPanel(
                            message: loadError!,
                            onRetry: () => _fetchRaces(),
                          )
                        else if (_activeRaces.isEmpty)
                          const _RaceEmptyPanel()
                        else if (isWide)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _RaceGrid(
                                  races: _activeRaces,
                                  selectedRace: selectedRace,
                                  onSelected: (race) {
                                    setState(() {
                                      this.selectedRace = race;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 18),
                              SizedBox(
                                width: 360,
                                child: _RacePreviewPanel(
                                  race: selectedRace,
                                  onLaunch: selectedRace == null
                                      ? null
                                      : () => _launchRace(selectedRace),
                                ),
                              ),
                            ],
                          )
                        else
                          _RaceGrid(
                            races: _activeRaces,
                            selectedRace: selectedRace,
                            onSelected: (race) {
                              setState(() {
                                this.selectedRace = race;
                              });
                            },
                          ),
                      ],
                    ),
                    if (!isWide && selectedRace != null)
                      Positioned(
                        left: 20,
                        right: 20,
                        bottom: 16,
                        child: _MobileLaunchBar(
                          race: selectedRace,
                          onLaunch: () => _launchRace(selectedRace),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

enum _RaceStatusState { ready, preparing, unavailable }

class _RaceEvent {
  const _RaceEvent({
    required this.year,
    required this.name,
    required this.location,
    required this.round,
    required this.status,
  });

  factory _RaceEvent.fromMap(String year, Map<dynamic, dynamic> race) {
    final rawStatus = (race['status'] ?? 'race-loading').toString();
    final isReady = race['ready'] == true || rawStatus == 'ready';
    return _RaceEvent(
      year: year,
      name: race['name']?.toString() ?? 'Unknown Race',
      location: race['location']?.toString() ?? 'Unknown Location',
      round: int.tryParse(race['round']?.toString() ?? '') ?? 0,
      status: _statusFromPayload(rawStatus, isReady),
    );
  }

  final String year;
  final String name;
  final String location;
  final int round;
  final _RaceStatusState status;

  bool get isReady => status == _RaceStatusState.ready;

  Color get statusAccent {
    switch (status) {
      case _RaceStatusState.ready:
        return const Color(0xFF39FF97);
      case _RaceStatusState.preparing:
        return const Color(0xFFFFB347);
      case _RaceStatusState.unavailable:
        return AppTheme.accentRed;
    }
  }

  String get statusLabel {
    switch (status) {
      case _RaceStatusState.ready:
        return 'Ready';
      case _RaceStatusState.preparing:
        return 'Preparing';
      case _RaceStatusState.unavailable:
        return 'Unavailable';
    }
  }

  String get roundLabel {
    return round <= 0 ? 'R--' : 'R${round.toString().padLeft(2, '0')}';
  }

  static _RaceStatusState _statusFromPayload(String status, bool isReady) {
    if (isReady) {
      return _RaceStatusState.ready;
    }
    if (status == 'error' || status == 'unavailable') {
      return _RaceStatusState.unavailable;
    }
    return _RaceStatusState.preparing;
  }
}

class _RaceSkeletonGrid extends StatelessWidget {
  const _RaceSkeletonGrid();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final int columns = width >= 1060 ? 3 : (width >= 680 ? 2 : 1);
        const double gap = 16;
        final double cardWidth = (width - (gap * (columns - 1))) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: List.generate(3, (index) {
            return SizedBox(width: cardWidth, child: const _RaceSkeletonCard());
          }),
        );
      },
    );
  }
}

class _RaceSkeletonCard extends StatelessWidget {
  const _RaceSkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 218,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xAA151823),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _SkeletonBlock(width: 44, height: 14),
              const Spacer(),
              _SkeletonBlock(width: 82, height: 26, radius: 999),
            ],
          ),
          const SizedBox(height: 24),
          const _SkeletonBlock(width: 210, height: 22),
          const SizedBox(height: 12),
          const _SkeletonBlock(width: 142, height: 14),
          const Spacer(),
          const _SkeletonBlock(width: double.infinity, height: 42),
        ],
      ),
    );
  }
}

class _SkeletonBlock extends StatelessWidget {
  const _SkeletonBlock({
    required this.width,
    required this.height,
    this.radius = 10,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0x22FFFFFF),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class _RaceErrorPanel extends StatelessWidget {
  const _RaceErrorPanel({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.glassCard(borderRadius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Race cache unavailable',
            style: AppTheme.orbitron(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppTheme.accentRed,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            style: AppTheme.inter(fontSize: 14, color: const Color(0xFFD4D8E4)),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(
              'Retry',
              style: AppTheme.inter(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.accentRed,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RaceEmptyPanel extends StatelessWidget {
  const _RaceEmptyPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.glassCard(borderRadius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'No races loaded',
            style: AppTheme.orbitron(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Text(
            'This season is available, but the race cache has not returned any events yet.',
            style: AppTheme.inter(fontSize: 14, color: const Color(0xFFD4D8E4)),
          ),
        ],
      ),
    );
  }
}

class _RacePreviewPanel extends StatelessWidget {
  const _RacePreviewPanel({required this.race, required this.onLaunch});

  final _RaceEvent? race;
  final VoidCallback? onLaunch;

  @override
  Widget build(BuildContext context) {
    final race = this.race;
    if (race == null) {
      return Container(
        padding: const EdgeInsets.all(22),
        decoration: AppTheme.glassCard(borderRadius: 24),
        child: Text('Select a race', style: AppTheme.orbitron(fontSize: 20)),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.glassCard(borderRadius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                race.roundLabel,
                style: AppTheme.orbitron(
                  fontSize: 13,
                  color: race.statusAccent,
                ),
              ),
              const Spacer(),
              _RaceStatusBadge(race: race),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            race.name,
            style: AppTheme.orbitron(fontSize: 28, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          _PreviewFact(label: 'Location', value: race.location),
          _PreviewFact(label: 'Season', value: race.year),
          _PreviewFact(label: 'Session', value: 'Race'),
          _PreviewFact(label: 'Status', value: race.statusLabel),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: race.isReady ? onLaunch : null,
              icon: const Icon(Icons.play_arrow_rounded, size: 20),
              label: Text(
                race.isReady ? 'Launch Playback' : 'Preparing telemetry',
                style: AppTheme.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: race.isReady ? Colors.black : AppTheme.textMuted,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: race.statusAccent,
                disabledBackgroundColor: const Color(0x332A2E3A),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewFact extends StatelessWidget {
  const _PreviewFact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTheme.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.textMuted,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTheme.inter(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileLaunchBar extends StatelessWidget {
  const _MobileLaunchBar({required this.race, required this.onLaunch});

  final _RaceEvent race;
  final VoidCallback onLaunch;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xF00D1017),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: race.statusAccent.withValues(alpha: 0.46)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.36),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  race.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.orbitron(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${race.roundLabel} - Race',
                  style: AppTheme.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton(
            onPressed: race.isReady ? onLaunch : null,
            style: FilledButton.styleFrom(
              backgroundColor: race.statusAccent,
              foregroundColor: Colors.black,
              disabledBackgroundColor: const Color(0x332A2E3A),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              race.isReady ? 'Launch' : 'Preparing',
              style: AppTheme.inter(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: race.isReady ? Colors.black : AppTheme.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RaceGrid extends StatelessWidget {
  const _RaceGrid({
    required this.races,
    required this.selectedRace,
    required this.onSelected,
  });

  final List<_RaceEvent> races;
  final _RaceEvent? selectedRace;
  final ValueChanged<_RaceEvent> onSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final int columns = width >= 1060 ? 3 : (width >= 680 ? 2 : 1);
        const double gap = 16;
        final double cardWidth = (width - (gap * (columns - 1))) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: races.map((race) {
            final isSelected =
                selectedRace?.year == race.year &&
                selectedRace?.location == race.location;
            return SizedBox(
              width: cardWidth,
              child: _RaceCard(
                race: race,
                isSelected: isSelected,
                onSelected: () => onSelected(race),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _RaceCard extends StatefulWidget {
  const _RaceCard({
    required this.race,
    required this.isSelected,
    required this.onSelected,
  });

  final _RaceEvent race;
  final bool isSelected;
  final VoidCallback onSelected;

  @override
  State<_RaceCard> createState() => _RaceCardState();
}

class _RaceCardState extends State<_RaceCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isInteractive = widget.race.isReady;
    final isHighlighted = widget.isSelected || (_isHovered && isInteractive);
    final accent = widget.race.statusAccent;

    return MouseRegion(
      cursor: isInteractive
          ? SystemMouseCursors.click
          : SystemMouseCursors.forbidden,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isInteractive
              ? widget.onSelected
              : () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Preparing telemetry cache')),
                  );
                },
          borderRadius: BorderRadius.circular(22),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            height: 224,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isHighlighted
                    ? accent.withValues(alpha: 0.82)
                    : AppTheme.cardBorder,
                width: isHighlighted ? 1.4 : 1,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xE6171925),
                  accent.withValues(alpha: isHighlighted ? 0.18 : 0.08),
                  const Color(0xD10B0D13),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: isHighlighted ? 0.28 : 0.08),
                  blurRadius: isHighlighted ? 30 : 12,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Opacity(
              opacity: isInteractive ? 1 : 0.72,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        widget.race.roundLabel,
                        style: AppTheme.orbitron(fontSize: 13, color: accent),
                      ),
                      const Spacer(),
                      _RaceStatusBadge(race: widget.race),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    widget.race.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.orbitron(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.race.location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFD4D8E4),
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    height: 44,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: _TelemetryPulsePainter(
                        accent: accent,
                        muted: !isInteractive,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RaceStatusBadge extends StatelessWidget {
  const _RaceStatusBadge({required this.race});

  final _RaceEvent race;

  @override
  Widget build(BuildContext context) {
    final accent = race.statusAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.34)),
      ),
      child: Text(
        race.statusLabel,
        style: AppTheme.inter(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: accent,
        ),
      ),
    );
  }
}

class _TelemetryPulsePainter extends CustomPainter {
  const _TelemetryPulsePainter({required this.accent, required this.muted});

  final Color accent;
  final bool muted;

  @override
  void paint(Canvas canvas, Size size) {
    final basePaint = Paint()
      ..color = Colors.white.withValues(alpha: muted ? 0.08 : 0.12)
      ..strokeWidth = 1;
    final linePaint = Paint()
      ..color = accent.withValues(alpha: muted ? 0.28 : 0.78)
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (double x = 0; x <= size.width; x += 14) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), basePaint);
    }

    final path = Path();
    for (int i = 0; i <= 8; i++) {
      final x = size.width * (i / 8);
      final wave = i.isEven ? 0.34 : 0.72;
      final y = size.height * wave;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _TelemetryPulsePainter oldDelegate) {
    return oldDelegate.accent != accent || oldDelegate.muted != muted;
  }
}

class _SeasonSelector extends StatelessWidget {
  const _SeasonSelector({
    required this.years,
    required this.selectedYear,
    required this.onSelected,
  });

  final List<String> years;
  final String? selectedYear;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.glassCard(borderRadius: 22),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: years.isEmpty
              ? const [_SeasonPlaceholder()]
              : years.map((year) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: _SeasonChip(
                      year: year,
                      isSelected: year == selectedYear,
                      onTap: () => onSelected(year),
                    ),
                  );
                }).toList(),
        ),
      ),
    );
  }
}

class _SeasonPlaceholder extends StatelessWidget {
  const _SeasonPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0x33111122),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Text(
        'Loading seasons',
        style: AppTheme.inter(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppTheme.textMuted,
        ),
      ),
    );
  }
}

class _SeasonChip extends StatelessWidget {
  const _SeasonChip({
    required this.year,
    required this.isSelected,
    required this.onTap,
  });

  final String year;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = isSelected ? AppTheme.accentRed : AppTheme.accentCyan;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: isSelected ? 0.18 : 0.08),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: accent.withValues(alpha: isSelected ? 0.78 : 0.28),
              width: isSelected ? 1.4 : 1,
            ),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: accent.withValues(alpha: 0.22),
                  blurRadius: 22,
                  offset: const Offset(0, 8),
                ),
            ],
          ),
          child: Text(
            year,
            style: AppTheme.orbitron(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _FastF1CommandBar extends StatelessWidget {
  const _FastF1CommandBar({
    required this.seasonLabel,
    required this.eventCount,
    required this.isLoading,
    required this.isPolling,
  });

  final String seasonLabel;
  final int eventCount;
  final bool isLoading;
  final bool isPolling;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isWide = constraints.maxWidth >= 760;
        final statusLabel = isLoading
            ? 'Loading race cache'
            : (isPolling ? 'Preparing telemetry cache' : 'Cache ready');

        final pills = [
          _CommandStatusPill(label: seasonLabel, accent: AppTheme.accentRed),
          _CommandStatusPill(
            label: '$eventCount events loaded',
            accent: AppTheme.accentCyan,
          ),
          _CommandStatusPill(
            label: statusLabel,
            accent: const Color(0xFFFFB347),
          ),
        ];

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: AppTheme.glassCard(borderRadius: 24),
          child: isWide
              ? Row(
                  children: [
                    const SectionNavBar(currentRoute: '/fastf1'),
                    const SizedBox(width: 20),
                    Text(
                      'FastF1 Race Browser',
                      style: AppTheme.orbitron(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    Wrap(spacing: 10, runSpacing: 10, children: pills),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const SectionNavBar(currentRoute: '/fastf1'),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            'FastF1 Race Browser',
                            style: AppTheme.orbitron(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Wrap(spacing: 10, runSpacing: 10, children: pills),
                  ],
                ),
        );
      },
    );
  }
}

class _CommandStatusPill extends StatelessWidget {
  const _CommandStatusPill({required this.label, required this.accent});

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.34)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTheme.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}


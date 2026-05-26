import 'package:f1aicommentary/widgets/rpm_display.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'driver_telemetry_struct.dart';
import 'expanded_layout.dart';
import 'speed_display.dart';
import 'throttle_display.dart';
import 'drs_display.dart';
import 'gear_display.dart';
import 'brake_display1.dart';
import 'driver_team_data.dart';

class Leaderboard extends StatefulWidget {
  final Color backgroundColour;
  final List<double> columnWidths;
  final List<double> rowHeights;
  final List<DriverTelemetry> drivers;
  final String selectedDriver;
  final ValueChanged<String> onDriverSelected;
  final VoidCallback? onStartPlayback;

  Leaderboard({
    super.key,
    this.backgroundColour = Colors.white,
    required this.columnWidths,
    required this.rowHeights,
    this.selectedDriver = '',
    required this.onDriverSelected,
    this.onStartPlayback,
    List<DriverTelemetry>? drivers,
  }) : drivers =
           drivers ??
           [
             DriverTelemetry(
               driverCode: 'N/A',
               teamName: 'N/A',
               date: DateTime.fromMillisecondsSinceEpoch(0),
               sessionTime: 0,
               lapTime: 0,
               rpm: 0,
               speed: 0,
               gear: 0,
               throttle: 0,
               brake: false,
               brakePressure: 0,
               drs: 0,
               x: 0,
               y: 0,
               z: 0,
               distance: 0,
               relativeDistance: 0,
               driverAhead: 'N/A',
               distanceToDriverAhead: 0,
               status: 'N/A',
               source: 'N/A',
             ),
             DriverTelemetry(
               driverCode: 'N/A',
               teamName: 'N/A',
               date: DateTime.fromMillisecondsSinceEpoch(0),
               sessionTime: 0,
               lapTime: 0,
               rpm: 0,
               speed: 0,
               gear: 0,
               throttle: 0,
               brake: false,
               brakePressure: 0,
               drs: 0,
               x: 0,
               y: 0,
               z: 0,
               distance: 0,
               relativeDistance: 0,
               driverAhead: 'N/A',
               distanceToDriverAhead: 0,
               status: 'N/A',
               source: 'N/A',
             ),
           ];

  @override
  State<Leaderboard> createState() => _LeaderboardState();
}

class _LeaderboardState extends State<Leaderboard> {
  @override
  void initState() {
    super.initState();
  }

  BorderRadius _cellBorderRadius({
    required int colIndex,
    required int columnCount,
    required bool isExpanded,
    double radius = 11.0,
  }) {
    if (isExpanded) {
      return BorderRadius.circular(radius);
    }

    final isFirst = colIndex == 0;
    final isLast = colIndex == columnCount - 1;
    return BorderRadius.only(
      topLeft: isFirst ? Radius.circular(radius) : Radius.zero,
      bottomLeft: isFirst ? Radius.circular(radius) : Radius.zero,
      topRight: isLast ? Radius.circular(radius) : Radius.zero,
      bottomRight: isLast ? Radius.circular(radius) : Radius.zero,
    );
  }

  Color _rowTileColor(DriverTelemetry driver, {required bool isSelected}) {
    final teamColor = getTeamColor(
      driver.driverCode,
      reportedTeam: driver.teamName,
    );
    final darkenAmount = isSelected ? 0.18 : 0.32;
    return Color.lerp(teamColor, Colors.black, darkenAmount) ?? teamColor;
  }

  Color _rowTextColor(Color backgroundColor) {
    return backgroundColor.computeLuminance() > 0.45
        ? Colors.black87
        : AppTheme.textPrimary;
  }

  String _teamLabel(DriverTelemetry driver, {required bool isCompact}) {
    final team =
        getTeam(driver.driverCode, reportedTeam: driver.teamName) ?? 'N/A';
    if (!isCompact) {
      return team;
    }

    const compactNames = {
      'Alfa Romeo': 'Alfa',
      'AlphaTauri': 'AT',
      'Aston Martin': 'Aston',
      'Ferrari': 'Ferrari',
      'Haas F1 Team': 'Haas',
      'McLaren': 'McLaren',
      'Mercedes': 'Merc',
      'Red Bull Racing': 'Red Bull',
      'Williams': 'Williams',
    };

    return compactNames[team] ?? team;
  }

  Widget _buildCompactCell({
    required int colIndex,
    required int rowIndex,
    required DriverTelemetry rowDriver,
    required Color rowTextColor,
    required bool useDarkText,
    required bool isCompact,
  }) {
    if (colIndex == 0) {
      return Text(
        (rowIndex + 1).toString(),
        style: AppTheme.orbitron(
          fontSize: isCompact ? 12.5 : 14,
          fontWeight: FontWeight.w700,
          color: rowTextColor,
        ),
      );
    }

    if (colIndex == 1) {
      final carAsset = getCarAsset(
        rowDriver.driverCode,
        reportedTeam: rowDriver.teamName,
      );
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              carAsset,
              width: isCompact ? 22 : 24,
              height: isCompact ? 13 : 14,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Image.asset(
                defaultCarAsset,
                width: isCompact ? 22 : 24,
                height: isCompact ? 13 : 14,
                fit: BoxFit.contain,
              ),
            ),
            SizedBox(width: isCompact ? 4 : 6),
            Flexible(
              child: Text(
                rowDriver.driverCode,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.orbitron(
                  fontSize: isCompact ? 12 : 13,
                  fontWeight: FontWeight.w700,
                  color: rowTextColor,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (colIndex == 2) {
      final team = _teamLabel(rowDriver, isCompact: isCompact);
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 8 : 10,
          vertical: isCompact ? 4 : 5,
        ),
        decoration: BoxDecoration(
          color: useDarkText
              ? Colors.black.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          team,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTheme.inter(
            fontSize: isCompact ? 10.5 : 11.5,
            fontWeight: FontWeight.w600,
            color: rowTextColor,
          ),
        ),
      );
    }

    if (colIndex == 3) {
      final gap = rowDriver.distanceToDriverAhead.round();
      return Text(
        gap > 0 ? gap.toString() : '--',
        style: AppTheme.orbitron(
          fontSize: isCompact ? 11.5 : 12,
          fontWeight: FontWeight.w700,
          color: rowTextColor,
        ),
      );
    }

    return Text(
      'N/A',
      style: AppTheme.inter(fontSize: 12, color: rowTextColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: AppTheme.glassCard(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final assignedWidth = widget.columnWidths.reduce((a, b) => a + b);
          final scale = constraints.maxWidth / assignedWidth;
          final bool isCompact = constraints.maxWidth < 520;
          final maxRPM = 15000.0;
          final headerHeight = isCompact
              ? 32.0
              : widget.rowHeights.isNotEmpty
              ? widget.rowHeights[0] * scale
              : 60.0 * scale;
          final totalColumns = widget.columnWidths.length;
          final headerTitles = isCompact
              ? const ['Pos', 'Driver', 'Team', 'Gap']
              : const [
                  'Position',
                  'Driver',
                  'Team',
                  'Distance to car ahead (m)',
                ];
          final headerFontSizes = isCompact
              ? const [11.0, 11.0, 11.0, 10.5]
              : const [13.0, 13.0, 13.0, 10.5];
          final selectedIndex = widget.drivers.indexWhere(
            (driver) => driver.driverCode == widget.selectedDriver,
          );
          final orderedRows = <MapEntry<int, DriverTelemetry>>[];

          if (selectedIndex >= 0) {
            orderedRows.add(
              MapEntry(selectedIndex, widget.drivers[selectedIndex]),
            );
          }

          for (var i = 0; i < widget.drivers.length; i++) {
            if (i == selectedIndex) {
              continue;
            }
            orderedRows.add(MapEntry(i, widget.drivers[i]));
          }

          if (widget.drivers.isEmpty) {
            return Center(
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: widget.onStartPlayback,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 18,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
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
                          size: 38,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Press play to begin',
                        textAlign: TextAlign.center,
                        style: AppTheme.orbitron(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
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
            );
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: List.generate(totalColumns, (colIndex) {
                      final borderRadius = _cellBorderRadius(
                        colIndex: colIndex,
                        columnCount: totalColumns,
                        isExpanded: false,
                        radius: isCompact ? 8 : 11,
                      );
                      return Container(
                        width: widget.columnWidths[colIndex] * scale,
                        height: headerHeight,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppTheme.cardBg.withValues(alpha: 0.93),
                              Colors.black.withValues(alpha: 0.88),
                            ],
                          ),
                          borderRadius: borderRadius,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.16),
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              headerTitles[colIndex],
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.orbitron(
                                fontSize: headerFontSizes[colIndex],
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                ...List.generate(orderedRows.length, (index) {
                  final row = orderedRows[index];
                  final rowIndex = row.key;
                  final rowDriver = row.value;
                  final rowDriverCode = rowDriver.driverCode;
                  final isExpanded = widget.selectedDriver == rowDriverCode;
                  final rowColor = _rowTileColor(
                    rowDriver,
                    isSelected: isExpanded,
                  );
                  final useDarkText = rowColor.computeLuminance() > 0.45;
                  final rowTextColor = _rowTextColor(rowColor);
                  final rowBaseHeight = isCompact
                      ? 33.0
                      : (widget.rowHeights.length > rowIndex
                                ? widget.rowHeights[rowIndex]
                                : 60.0) *
                            scale;
                  final widthMultiplier = isExpanded
                      ? (widget.columnWidths.reduce((a, b) => a + b) /
                            widget.columnWidths[0])
                      : 1.0;

                  return Padding(
                    padding: EdgeInsets.only(bottom: isCompact ? 4 : 6),
                    child: Row(
                      children: List.generate(widget.columnWidths.length, (
                        colIndex,
                      ) {
                        if (isExpanded && colIndex > 0) {
                          return const SizedBox.shrink();
                        }

                        final borderRadius = _cellBorderRadius(
                          colIndex: colIndex,
                          columnCount: totalColumns,
                          isExpanded: isExpanded,
                          radius: isCompact ? 9 : 11,
                        );
                        final startColor =
                            Color.lerp(rowColor, Colors.white, 0.07) ??
                            rowColor;
                        final endColor =
                            Color.lerp(rowColor, Colors.black, 0.22) ??
                            rowColor;

                        return GestureDetector(
                          onTap: () {
                            widget.onDriverSelected(rowDriverCode);
                          },
                          child: Container(
                            width:
                                widget.columnWidths[colIndex] *
                                scale *
                                (colIndex == 0 ? widthMultiplier : 1.0),
                            height: isExpanded ? null : rowBaseHeight,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [startColor, endColor],
                              ),
                              borderRadius: borderRadius,
                              border: Border.all(
                                color: isExpanded
                                    ? Colors.white.withValues(alpha: 0.55)
                                    : Colors.white.withValues(alpha: 0.12),
                                width: isExpanded ? 1.3 : 0.8,
                              ),
                              boxShadow: isExpanded
                                  ? [
                                      BoxShadow(
                                        color: rowColor.withValues(alpha: 0.35),
                                        blurRadius: 12,
                                        spreadRadius: 1,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: ClipRRect(
                              borderRadius: borderRadius,
                              child: (colIndex == 0 && isExpanded)
                                  ? ExpandedLayout(
                                      position: rowIndex,
                                      driver: rowDriver,
                                      columnWidths: widget.columnWidths,
                                      scale: scale,
                                      compact: isCompact,
                                      rowColor: rowColor,
                                      textColor: rowTextColor,
                                      gridWidgets: [
                                        RpmDisplay(
                                          currentTime: rowDriver.sessionTime,
                                          currentRPM: rowDriver.rpm,
                                          maxRPM: maxRPM,
                                        ),
                                        SpeedGraph(
                                          currentTime: rowDriver.sessionTime,
                                          currentSpeed: rowDriver.speed,
                                          maxSpeed: 390.0,
                                        ),
                                        DrsDisplay(
                                          currentTime: rowDriver.sessionTime,
                                          drsState: rowDriver.drs,
                                        ),
                                        ThrottleDisplay(
                                          currentTime: rowDriver.sessionTime,
                                          throttle: rowDriver.throttle,
                                        ),
                                        GearDisplay(
                                          currentTime: rowDriver.sessionTime,
                                          gear: rowDriver.gear,
                                        ),
                                        BrakeDisplay1(
                                          currentTime: rowDriver.sessionTime,
                                          brake: rowDriver.brake,
                                          brakePressure:
                                              rowDriver.brakePressure,
                                        ),
                                      ],
                                    )
                                  : Center(
                                      child: _buildCompactCell(
                                        colIndex: colIndex,
                                        rowIndex: rowIndex,
                                        rowDriver: rowDriver,
                                        rowTextColor: rowTextColor,
                                        useDarkText: useDarkText,
                                        isCompact: isCompact,
                                      ),
                                    ),
                            ),
                          ),
                        );
                      }),
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}

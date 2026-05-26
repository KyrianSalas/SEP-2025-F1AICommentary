import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';
import 'driver_telemetry_struct.dart';
import 'driver_team_data.dart';

class ExpandedLayout extends StatelessWidget {
  final DriverTelemetry driver;
  final List<double> columnWidths;
  final double scale;
  final int position;
  final Color rowColor;
  final Color textColor;
  final List<Widget> gridWidgets;
  final bool compact;

  const ExpandedLayout({
    super.key,
    required this.driver,
    required this.columnWidths,
    required this.scale,
    required this.position,
    required this.rowColor,
    required this.textColor,
    required this.gridWidgets,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    // Total width = sum of all column widths * scale
    final totalWidth = columnWidths.reduce((a, b) => a + b) * scale;
    final useCompact = compact || totalWidth < 520;
    final summaryHeight = useCompact ? 54.0 : 60.0;
    final crossAxisCount = useCompact ? 2 : 3;
    final spacing = useCompact ? 6.0 : 4.0;
    final padding = useCompact ? 6.0 : 4.0;
    final childAspectRatio = useCompact ? 1.35 : 1.4;
    final cellWidth =
        (totalWidth - padding * 2 - spacing * (crossAxisCount - 1)) /
        crossAxisCount;
    final cellHeight = cellWidth / childAspectRatio;
    final rowCount = (math.min(gridWidgets.length, 6) / crossAxisCount).ceil();
    final gridHeight =
        cellHeight * rowCount + spacing * (rowCount - 1) + padding * 2;
    final gridBackgroundColor =
        Color.lerp(rowColor, Colors.black, 0.35) ?? rowColor;
    final chartTileColor =
        Color.lerp(rowColor, Colors.black, 0.55) ?? Colors.grey.shade900;

    return SizedBox(
      height: summaryHeight + gridHeight,
      child: Column(
        children: [
          SizedBox(
            height: summaryHeight,
            child: Row(
              children: List.generate(
                columnWidths.length,
                (colIndex) => Expanded(
                  child: Container(
                    decoration: BoxDecoration(color: rowColor),
                    padding: EdgeInsets.symmetric(
                      horizontal: useCompact ? 6 : 8,
                      vertical: 6,
                    ),
                    child: Center(
                      child: Text(
                        _getValue(colIndex),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.inter(
                          fontSize: useCompact ? 11 : 12,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            height: gridHeight,
            child: Container(
              color: gridBackgroundColor,
              padding: EdgeInsets.all(padding),
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: math.min(gridWidgets.length, 6),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: spacing,
                  mainAxisSpacing: spacing,
                  childAspectRatio: childAspectRatio,
                ),
                itemBuilder: (context, index) {
                  return Container(
                    decoration: BoxDecoration(
                      color: chartTileColor,
                      borderRadius: BorderRadius.circular(useCompact ? 8 : 4),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.10),
                      ),
                    ),
                    child: ClipRect(
                      child: Padding(
                        padding: EdgeInsets.all(useCompact ? 3 : 2),
                        child: gridWidgets[index],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getValue(int colIndex) {
    if (colIndex == 0) return (position + 1).toString();
    if (colIndex == 1) return driver.driverCode;
    if (colIndex == 2) {
      return getTeam(driver.driverCode, reportedTeam: driver.teamName) ?? 'N/A';
    }
    if (colIndex == 3) return driver.distanceToDriverAhead.round().toString();
    return 'N/A';
  }
}

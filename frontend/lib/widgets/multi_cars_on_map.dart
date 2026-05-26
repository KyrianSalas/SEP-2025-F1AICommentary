import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'driver_telemetry_struct.dart';
import 'driver_team_data.dart';

class MultiCarsOnMap extends StatefulWidget {
  final List<DriverTelemetry> drivers;
  final String selectedDriverCode;
  final double minX;
  final double minY;
  final double scale;
  final double offsetX;
  final double offsetY;
  final double containerHeight;
  final double containerWidth;
  final double carSize;
  final Map<String, dynamic> startPosition;
  final Map<String, dynamic> startPosition2;

  const MultiCarsOnMap({
    super.key,
    required this.drivers,
    required this.selectedDriverCode,
    required this.minX,
    required this.minY,
    required this.scale,
    required this.offsetX,
    required this.offsetY,
    required this.containerHeight,
    required this.containerWidth,
    required this.carSize,
    required this.startPosition,
    required this.startPosition2,
  });

  @override
  State<MultiCarsOnMap> createState() => _MultiCarsOnMapState();
}

class _MultiCarsOnMapState extends State<MultiCarsOnMap> {
  Map<String, Offset> _previousWorldPositions = <String, Offset>{};

  @override
  void didUpdateWidget(covariant MultiCarsOnMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final updated = <String, Offset>{};
    for (final driver in oldWidget.drivers) {
      updated[driver.driverCode] = Offset(driver.x, driver.y);
    }
    _previousWorldPositions = updated;
  }

  @override
  Widget build(BuildContext context) {
    final widthScale = (widget.containerWidth / 400).clamp(0.3, 1.0);
    final heightScale = (widget.containerHeight / 300).clamp(0.3, 1.0);
    final sizeScale = math.min(widthScale, heightScale) * widget.carSize;
    final carWidth = sizeScale * 1.5;
    final carHeight = sizeScale;

    return Stack(
      children: widget.drivers.map((driver) {
        final code = driver.driverCode;
        final selected = code == widget.selectedDriverCode;
        final assetPath = getCarAsset(code, reportedTeam: driver.teamName);

        final hasPosition =
            !(driver.x == 0.0 && driver.y == 0.0) &&
            driver.x.isFinite &&
            driver.y.isFinite;

        final worldX = hasPosition
            ? driver.x
            : (widget.startPosition['X'] as num?)?.toDouble() ?? 0.0;
        final worldY = hasPosition
            ? driver.y
            : (widget.startPosition['Y'] as num?)?.toDouble() ?? 0.0;

        final fallbackPrevX =
            (widget.startPosition2['X'] as num?)?.toDouble() ?? worldX;
        final fallbackPrevY =
            (widget.startPosition2['Y'] as num?)?.toDouble() ?? worldY;
        final prev = _previousWorldPositions[code] ??
            Offset(fallbackPrevX, fallbackPrevY);

        final carScreenX =
            widget.offsetX + (worldX - widget.minX) * widget.scale;
        final carScreenY = widget.containerHeight -
            (widget.offsetY + (worldY - widget.minY) * widget.scale);

        final lastCarScreenX =
            widget.offsetX + (prev.dx - widget.minX) * widget.scale;
        final lastCarScreenY = widget.containerHeight -
            (widget.offsetY + (prev.dy - widget.minY) * widget.scale);

        final dx = carScreenX - lastCarScreenX;
        final dy = carScreenY - lastCarScreenY;
        final carAngle = math.atan2(dy, dx) + math.pi;

        return Positioned(
          left: carScreenX - (carWidth / 2),
          top: carScreenY - (carHeight / 2),
          child: SizedBox(
            width: carWidth,
            height: carHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Center(
                  child: Transform.rotate(
                    angle: carAngle,
                    child: Image.asset(
                      assetPath,
                      width: carWidth,
                      height: carHeight,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          Image.asset(
                        defaultCarAsset,
                        width: carWidth,
                        height: carHeight,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: -10,
                  left: 0,
                  right: 0,
                  child: Text(
                    code,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: selected ? Colors.yellow : Colors.white,
                      fontSize: (carHeight * 0.28).clamp(7.0, 11.0),
                      fontWeight: FontWeight.w700,
                      shadows: const [
                        Shadow(color: Colors.black, blurRadius: 3),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

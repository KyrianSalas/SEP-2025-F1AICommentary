import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;

class CarOnMap extends StatefulWidget {
  final Map<String, dynamic> carPosition;
  final Map<String, dynamic> carLastPosition;
  final double minX;
  final double minY;
  final double scale;
  final double offsetX;
  final double offsetY;
  final double containerHeight;
  final String carAssetPath;
  final double carSize;
  final Map<String, dynamic> startPosition;
  final Map<String, dynamic> startPosition2;
  final double containerWidth;

  const CarOnMap({
    super.key,
    required this.carPosition,
    required this.carLastPosition,
    required this.minX,
    required this.minY,
    required this.scale,
    required this.offsetX,
    required this.offsetY,
    required this.containerHeight,
    required this.carAssetPath,
    required this.startPosition,
    required this.startPosition2,
    this.carSize = 30.0,
    required this.containerWidth,
  });

  @override
  State<CarOnMap> createState() => _CarOnMapState();
}

class _CarOnMapState extends State<CarOnMap> {
  ui.Image? carImage;
  final List<Offset> _trail = [];
  static const int _maxTrailLength = 15;
  ImageStream? _imageStream;
  ImageStreamListener? _imageStreamListener;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final imageProvider = AssetImage(widget.carAssetPath);
    _imageStream = imageProvider.resolve(const ImageConfiguration());
    _imageStreamListener = ImageStreamListener((imageInfo, synchronousCall) {
      if (!mounted) {
        return;
      }
      setState(() {
        carImage = imageInfo.image;
      });
    });
    _imageStream!.addListener(_imageStreamListener!);
  }

  @override
  void dispose() {
    if (_imageStream != null && _imageStreamListener != null) {
      _imageStream!.removeListener(_imageStreamListener!);
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(CarOnMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    // track screen position for trail
    if (widget.carPosition != oldWidget.carPosition) {
      double carX = widget.carPosition['X'].toDouble();
      double carY = widget.carPosition['Y'].toDouble();
      if (carX != 0.0 || carY != 0.0) {
        double screenX = widget.offsetX + (carX - widget.minX) * widget.scale;
        double screenY =
            widget.containerHeight -
            (widget.offsetY + (carY - widget.minY) * widget.scale);
        _trail.add(Offset(screenX, screenY));
        if (_trail.length > _maxTrailLength) {
          _trail.removeAt(0);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // add scaling
    final widthScale = (widget.containerWidth / 400).clamp(0.3, 1.0);
    final heightScale = (widget.containerHeight / 300).clamp(0.3, 1.0);
    final sizeScale = math.min(widthScale, heightScale) * widget.carSize;
    return CustomPaint(
      painter: CarPainter(
        carPosition: widget.carPosition,
        carLastPosition: widget.carLastPosition,
        minX: widget.minX,
        minY: widget.minY,
        scale: widget.scale,
        offsetX: widget.offsetX,
        offsetY: widget.offsetY,
        containerHeight: widget.containerHeight,
        containerWidth: widget.containerWidth,
        carImage: carImage,
        carSize: sizeScale,
        startPosition: widget.startPosition,
        startPosition2: widget.startPosition2,
        trail: List.from(_trail),
      ),
    );
  }
}

class CarPainter extends CustomPainter {
  final Map<String, dynamic> carPosition;
  final Map<String, dynamic> carLastPosition;
  final double minX;
  final double minY;
  final double scale;
  final double offsetX;
  final double offsetY;
  final double containerHeight;
  final double containerWidth;
  final ui.Image? carImage;
  final double carSize;
  final Map<String, dynamic> startPosition;
  final Map<String, dynamic> startPosition2;

  final List<Offset> trail;

  CarPainter({
    required this.carPosition,
    required this.carLastPosition,
    required this.minX,
    required this.minY,
    required this.scale,
    required this.offsetX,
    required this.offsetY,
    required this.containerHeight,
    required this.containerWidth,
    required this.carImage,
    required this.carSize,
    required this.startPosition,
    required this.startPosition2,
    required this.trail,
  });

  @override
  void paint(Canvas canvas, Size size) {
    double carX;
    double carY;
    double lastCarX;
    double lastCarY;

    if (carPosition['X'].toDouble() == 0.0 &&
        carPosition['Y'].toDouble() == 0.0) {
      carX = startPosition['X'].toDouble();
      carY = startPosition['Y'].toDouble();
      lastCarX = startPosition2['X'].toDouble();
      lastCarY = startPosition2['Y'].toDouble();
    } else {
      carX = carPosition['X'].toDouble();
      carY = carPosition['Y'].toDouble();
      lastCarX = carLastPosition['X'].toDouble();
      lastCarY = carLastPosition['Y'].toDouble();
    }

    double carScreenX = offsetX + (carX - minX) * scale;
    double carScreenY = containerHeight - (offsetY + (carY - minY) * scale);
    double lastCarScreenX = offsetX + (lastCarX - minX) * scale;
    double lastCarScreenY =
        containerHeight - (offsetY + (lastCarY - minY) * scale);

    double dx = carScreenX - lastCarScreenX;
    double dy = carScreenY - lastCarScreenY;
    double carAngle = math.atan2(dy, dx) + math.pi;

    // draw fading trail behind the car
    for (int i = 0; i < trail.length; i++) {
      final fraction = i / trail.length;
      final alpha = (fraction * 120).toInt();
      final radius = 2.0 + fraction * 2.0;
      final trailPaint = Paint()
        ..color = const Color(0xFFE10600).withAlpha(alpha);
      canvas.drawCircle(trail[i], radius, trailPaint);
    }

    if (carImage != null) {
      final imageWidth = carImage!.width.toDouble();
      final imageHeight = carImage!.height.toDouble();
      final aspectRatio = imageWidth / imageHeight;

      double drawWidth = carSize;
      double drawHeight = carSize;
      if (aspectRatio >= 1.0) {
        drawHeight = carSize / aspectRatio;
      } else {
        drawWidth = carSize * aspectRatio;
      }

      canvas.save();
      canvas.translate(carScreenX, carScreenY);
      canvas.rotate(carAngle);
      canvas.drawImageRect(
        carImage!,
        Rect.fromLTWH(0, 0, imageWidth, imageHeight),
        Rect.fromCenter(
          center: Offset.zero,
          width: drawWidth,
          height: drawHeight,
        ),
        Paint(),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(CarPainter oldDelegate) {
    return oldDelegate.carPosition != carPosition ||
        oldDelegate.carImage != carImage;
  }
}

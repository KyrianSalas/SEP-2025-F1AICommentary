import 'package:flutter/material.dart';
import 'dart:math';

class BrakeTempSpin extends StatefulWidget {
  final double size;
  final Color circleColor;
  final double sBrpm;
  final bool pause;

  const BrakeTempSpin({
    super.key,
    required this.size,
    required this.circleColor,
    this.sBrpm = 0.0,
    required this.pause,
  });

  @override
  State<BrakeTempSpin> createState() => _BrakeTempSpinState();
}

class _BrakeTempSpinState extends State<BrakeTempSpin>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();

    _rotationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: _calculateDuration(widget.sBrpm)),
    );

    if (widget.sBrpm > 0 && !widget.pause) {
      _rotationController.repeat();
    }
  }

  @override
  void didUpdateWidget(BrakeTempSpin oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.sBrpm != oldWidget.sBrpm) {
      _rotationController.duration = Duration(
        milliseconds: _calculateDuration(widget.sBrpm),
      );
    }

    //stop spin if paused
    if (widget.pause || widget.sBrpm == 0) {
      _rotationController.stop();
    } else {
      _rotationController.repeat();
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  int _calculateDuration(double rpm) {
    if (rpm <= 0) return 600000;
    return (60000 / rpm).round();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          //brake pad color with glow
          Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.circleColor,
              boxShadow: [
                BoxShadow(
                  color: widget.circleColor.withAlpha(80),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),

          //inside tire asset
          SizedBox(
            width: widget.size,
            height: widget.size,
            child: Image.asset(
              'assets/inside_of_tire.png',
              fit: BoxFit.contain,
            ),
          ),

          //spinning wheel
          AnimatedBuilder(
            animation: _rotationController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotationController.value * 2 * pi,
                child: child,
              );
            },
            child: SizedBox(
              width: widget.size,
              height: widget.size,
              child: Image.asset('assets/tire.png', fit: BoxFit.contain),
            ),
          ),
        ],
      ),
    );
  }
}

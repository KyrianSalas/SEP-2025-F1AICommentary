import 'package:flutter/material.dart';

class GridLayout2 extends StatelessWidget {
  final Widget topWidget;
  final Widget mainWidget;
  final Widget rightWidget;

  const GridLayout2({
    super.key,
    required this.topWidget,
    required this.mainWidget,
    required this.rightWidget,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isCompact = constraints.maxWidth < 720;

        if (isCompact) {
          final double padding = constraints.maxWidth < 420 ? 10 : 12;
          final double commentaryHeight = constraints.maxWidth < 420 ? 92 : 80;
          final double leaderboardHeight =
              (constraints.maxHeight - commentaryHeight - 32)
                  .clamp(520.0, 720.0)
                  .toDouble();
          final double mapHeight = constraints.maxWidth < 420 ? 240 : 280;

          return SingleChildScrollView(
            padding: EdgeInsets.all(padding),
            child: Column(
              children: [
                SizedBox(height: commentaryHeight, child: topWidget),
                const SizedBox(height: 10),
                SizedBox(height: leaderboardHeight, child: mainWidget),
                const SizedBox(height: 10),
                SizedBox(height: mapHeight, child: rightWidget),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              SizedBox(height: 72, child: topWidget),
              const SizedBox(height: 12),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(flex: 2, child: mainWidget),
                    const SizedBox(width: 12),
                    Expanded(flex: 1, child: rightWidget),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

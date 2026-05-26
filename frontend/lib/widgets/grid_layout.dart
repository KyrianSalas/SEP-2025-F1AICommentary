import 'package:flutter/material.dart';

class GridLayout extends StatelessWidget {
  final Widget topWidget;
  final List<Widget> heroWidgets;
  final List<Widget> secondaryWidgets;
  final Widget rightWidget;

  const GridLayout({
    super.key,
    required this.topWidget,
    required this.heroWidgets,
    required this.secondaryWidgets,
    required this.rightWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          // commentary banner across the top
          SizedBox(height: 72, child: topWidget),
          const SizedBox(height: 12),

          // main content area
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // left column: hero row + secondary row
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      // hero row – RPM and Speed get the most space
                      Expanded(
                        flex: 3,
                        child: Row(
                          children: [
                            Expanded(
                              child: heroWidgets.isNotEmpty
                                  ? heroWidgets[0]
                                  : const SizedBox(),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: heroWidgets.length > 1
                                  ? heroWidgets[1]
                                  : const SizedBox(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // secondary row – four smaller widgets
                      Expanded(
                        flex: 2,
                        child: Row(children: _buildSecondaryRow()),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // right column: map spans full height
                Expanded(flex: 1, child: rightWidget),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSecondaryRow() {
    final List<Widget> row = [];
    for (int i = 0; i < secondaryWidgets.length; i++) {
      if (i > 0) row.add(const SizedBox(width: 12));
      row.add(Expanded(child: secondaryWidgets[i]));
    }
    return row;
  }
}

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CommentaryDisplay extends StatelessWidget {
  final String commentary;
  final Color backgroundColor;
  final Color borderColor;

  const CommentaryDisplay({
    super.key,
    required this.commentary,
    this.backgroundColor = const Color.fromARGB(255, 183, 118, 118),
    this.borderColor = Colors.cyan,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceGlass,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder, width: 1),
      ),
      child: Row(
        children: [
          // left accent bar
          Container(
            width: 3,
            decoration: BoxDecoration(
              color: AppTheme.accentCyan,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),

          // mic icon
          const Icon(Icons.mic, color: AppTheme.accentCyan, size: 14),
          const SizedBox(width: 6),

          // label
          Text(
            'AI',
            style: AppTheme.orbitron(fontSize: 10, color: AppTheme.accentCyan),
          ),
          const SizedBox(width: 10),

          // scrolling commentary text
          Expanded(
            child: SingleChildScrollView(
              reverse: true,
              scrollDirection: Axis.vertical,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  commentary.isEmpty ? 'Waiting for commentary...' : commentary,
                  style: AppTheme.inter(
                    fontSize: 12,
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w400,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
    );
  }
}

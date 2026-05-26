import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class SourceModeCard extends StatefulWidget {
  const SourceModeCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.eyebrow,
    required this.bullets,
    required this.onPressed,
  });

  final String title;
  final String subtitle;
  final Color accent;
  final String eyebrow;
  final List<String> bullets;
  final VoidCallback onPressed;

  @override
  State<SourceModeCard> createState() => _SourceModeCardState();
}

class _SourceModeCardState extends State<SourceModeCard> {
  bool _isHovered = false;
  bool _isPressed = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final bool isActive = _isHovered || _isPressed || _isFocused;

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isCompact = constraints.maxWidth < 430;
        final double radius = isCompact ? 22 : 28;
        final double padding = isCompact ? 18 : 24;
        final double titleSize = isCompact ? 23 : 28;
        final double subtitleSize = isCompact ? 13 : 15;
        final double bulletSize = isCompact ? 12.5 : 14;

        return FocusableActionDetector(
          onShowFocusHighlight: (value) => setState(() => _isFocused = value),
          mouseCursor: SystemMouseCursors.click,
          child: MouseRegion(
            onEnter: (_) => setState(() => _isHovered = true),
            onExit: (_) => setState(() {
              _isHovered = false;
              _isPressed = false;
            }),
            child: GestureDetector(
              onTapDown: (_) => setState(() => _isPressed = true),
              onTapCancel: () => setState(() => _isPressed = false),
              onTapUp: (_) => setState(() => _isPressed = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                transform: Matrix4.identity()
                  ..translateByDouble(
                    0.0,
                    _isPressed ? 0.0 : (isActive ? -4.0 : 0.0),
                    0.0,
                    1.0,
                  )
                  ..scaleByDouble(
                    _isPressed ? 0.99 : 1.0,
                    _isPressed ? 0.99 : 1.0,
                    1.0,
                    1.0,
                  ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(radius),
                    onTap: widget.onPressed,
                    child: Ink(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(radius),
                        border: Border.all(
                          color: isActive
                              ? widget.accent.withValues(alpha: 0.82)
                              : AppTheme.cardBorder,
                          width: isActive ? 1.4 : 1.0,
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xE6181A22),
                            widget.accent.withValues(
                              alpha: isActive ? 0.16 : 0.10,
                            ),
                            const Color(0xD10F1118),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: widget.accent.withValues(
                              alpha: isActive ? 0.28 : 0.08,
                            ),
                            blurRadius: isActive ? 34 : 14,
                            spreadRadius: isActive ? 1 : 0,
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(padding),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isCompact ? 9 : 10,
                                    vertical: isCompact ? 5 : 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: widget.accent.withValues(
                                      alpha: 0.14,
                                    ),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    widget.eyebrow,
                                    style: AppTheme.orbitron(
                                      fontSize: isCompact ? 10 : 11,
                                      color: widget.accent,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                AnimatedRotation(
                                  duration: const Duration(milliseconds: 180),
                                  turns: isActive ? 0.0 : -0.03,
                                  child: Icon(
                                    Icons.north_east,
                                    color: widget.accent,
                                    size: isCompact ? 18 : 20,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: isCompact ? 16 : 20),
                            Text(
                              widget.title,
                              style: AppTheme.orbitron(
                                fontSize: titleSize,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: isCompact ? 10 : 12),
                            Text(
                              widget.subtitle,
                              style: AppTheme.inter(
                                fontSize: subtitleSize,
                                color: const Color(0xFFD6D9E3),
                              ).copyWith(height: 1.34),
                            ),
                            SizedBox(height: isCompact ? 14 : 18),
                            ...widget.bullets.map(
                              (bullet) => Padding(
                                padding: EdgeInsets.only(
                                  bottom: isCompact ? 8 : 10,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Container(
                                        width: 7,
                                        height: 7,
                                        decoration: BoxDecoration(
                                          color: widget.accent,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        bullet,
                                        style: AppTheme.inter(
                                          fontSize: bulletSize,
                                          color: AppTheme.textPrimary,
                                        ).copyWith(height: 1.28),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: isCompact ? 8 : 10),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: FilledButton.icon(
                                onPressed: widget.onPressed,
                                style: FilledButton.styleFrom(
                                  backgroundColor: widget.accent,
                                  foregroundColor: Colors.black,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isCompact ? 16 : 18,
                                    vertical: isCompact ? 12 : 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                icon: const Icon(Icons.arrow_forward, size: 18),
                                label: Text(
                                  'Enter mode',
                                  style: AppTheme.inter(
                                    fontSize: isCompact ? 13 : 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

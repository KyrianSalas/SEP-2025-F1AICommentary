import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';

class SectionNavBar extends StatelessWidget implements PreferredSizeWidget {
  const SectionNavBar({super.key, required this.currentRoute});

  final String currentRoute;

  @override
  Size get preferredSize => const Size.fromHeight(40);

  @override
  Widget build(BuildContext context) {
    return _NavChip(
      label: 'Home',
      route: '/',
      isActive: currentRoute == '/',
    );
  }
}

class _NavChip extends StatelessWidget {
  const _NavChip({
    required this.label,
    required this.route,
    required this.isActive,
  });

  final String label;
  final String route;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return _HoverNavChip(label: label, route: route, isActive: isActive);
  }
}

class _HoverNavChip extends StatefulWidget {
  const _HoverNavChip({
    required this.label,
    required this.route,
    required this.isActive,
  });

  final String label;
  final String route;
  final bool isActive;

  @override
  State<_HoverNavChip> createState() => _HoverNavChipState();
}

class _HoverNavChipState extends State<_HoverNavChip> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bool highlighted = widget.isActive || _isHovered;
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.isActive ? null : () => context.go(widget.route),
          borderRadius: BorderRadius.circular(999),
          hoverColor: Colors.transparent,
          splashColor: AppTheme.accentRed.withValues(alpha: 0.14),
          highlightColor: Colors.transparent,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: highlighted
                    ? [
                        AppTheme.accentRed.withValues(alpha: 0.34),
                        AppTheme.accentRed.withValues(alpha: 0.16),
                      ]
                    : [
                        const Color(0xFF23253A),
                        const Color(0xFF17192A),
                      ],
              ),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: highlighted ? AppTheme.accentRed : const Color(0x66FFFFFF),
              ),
              boxShadow: [
                BoxShadow(
                  color: highlighted
                      ? AppTheme.accentRed.withValues(alpha: 0.26)
                      : Colors.black.withValues(alpha: 0.22),
                  blurRadius: highlighted ? 18 : 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSlide(
                  duration: const Duration(milliseconds: 180),
                  offset: _isHovered
                      ? const Offset(-0.08, 0)
                      : Offset.zero,
                  child: Icon(
                    Icons.arrow_back_rounded,
                    size: 14,
                    color: highlighted
                        ? AppTheme.textPrimary
                        : AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  widget.label,
                  style: AppTheme.orbitron(
                    fontSize: 11,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

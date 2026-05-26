import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'section_nav_bar.dart';

class TopBar extends StatelessWidget implements PreferredSizeWidget {
  const TopBar({
    super.key,
    this.raceName = 'Placeholder',
    required this.currentTime,
    required this.paused,
    required this.isMuted,
    required this.selectedLap,
    required this.lapOptions,
    required this.speedIndex,
    required this.onPlayPauseToggle,
    required this.onMuteToggle,
    required this.onLapChanged,
    required this.onSpeedToggle,
    required this.currentRoute,
    this.compact = false,
  });

  final String raceName;
  final double currentTime;
  final bool paused;
  final bool isMuted;
  final String selectedLap;
  final List<String> lapOptions;
  final int speedIndex;
  final VoidCallback onPlayPauseToggle;
  final VoidCallback onMuteToggle;
  final Function(String?) onLapChanged;
  final VoidCallback onSpeedToggle;
  final String currentRoute;
  final bool compact;

  String get _speedLabel => '${pow(2, speedIndex).toInt()}x';

  @override
  Size get preferredSize =>
      Size.fromHeight((compact ? 104.0 : kToolbarHeight) + 1.0);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = (constraints.maxWidth / 900).clamp(0.72, 1.0);
        final iconSize = 24 * scale;
        final playSize = 28 * scale;
        final titleSize = 14 * scale;
        final liveSize = 10 * scale;
        final timeSize = 22 * scale;
        final speedSize = 13 * scale;

        if (compact) {
          return AppBar(
            toolbarHeight: 104,
            automaticallyImplyLeading: false,
            backgroundColor: const Color(0xFF111122),
            elevation: 0,
            titleSpacing: 0,
            title: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Column(
                children: [
                  Row(
                    children: [
                      SectionNavBar(currentRoute: currentRoute),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          raceName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.orbitron(
                            fontSize: 12,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.accentRed,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        currentTime.toStringAsFixed(1),
                        style: AppTheme.orbitron(
                          fontSize: 15,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _CompactControlButton(
                        onPressed: onMuteToggle,
                        tooltip: isMuted
                            ? 'Unmute commentary'
                            : 'Mute commentary',
                        child: Icon(
                          isMuted
                              ? Icons.volume_off_rounded
                              : Icons.volume_up_rounded,
                          color: isMuted
                              ? AppTheme.accentRed
                              : AppTheme.textPrimary,
                          size: 21,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _CompactControlButton(
                        onPressed: onPlayPauseToggle,
                        tooltip: paused ? 'Play' : 'Pause',
                        child: Icon(
                          paused
                              ? Icons.play_arrow_rounded
                              : Icons.pause_rounded,
                          color: AppTheme.textPrimary,
                          size: 25,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SizedBox(
                          height: 44,
                          child: _LapSelector(
                            selectedLap: selectedLap,
                            lapOptions: lapOptions,
                            onLapChanged: onLapChanged,
                            compact: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 44,
                        child: _SpeedButton(
                          label: _speedLabel,
                          onTap: onSpeedToggle,
                          fontSize: 12,
                          horizontalPadding: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(
                height: 1,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      AppTheme.accentRed,
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return AppBar(
          toolbarHeight: kToolbarHeight,
          backgroundColor: const Color(0xFF111122),
          elevation: 0,
          titleSpacing: 12,
          leadingWidth: 126,
          leading: Padding(
            padding: const EdgeInsets.only(left: 16, top: 10, bottom: 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SectionNavBar(currentRoute: currentRoute),
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      Text(
                        raceName,
                        style: AppTheme.orbitron(
                          fontSize: titleSize,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.accentRed,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.accentRed,
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'LIVE',
                        style: AppTheme.orbitron(
                          fontSize: liveSize,
                          color: AppTheme.accentRed,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                currentTime.toStringAsFixed(1),
                style: AppTheme.orbitron(
                  fontSize: timeSize,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              onPressed: onMuteToggle,
              icon: Icon(
                isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                color: isMuted ? AppTheme.accentRed : AppTheme.textPrimary,
                size: iconSize,
              ),
              tooltip: isMuted ? 'Unmute commentary' : 'Mute commentary',
              style: IconButton.styleFrom(
                backgroundColor: AppTheme.cardBg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: AppTheme.cardBorder),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: onPlayPauseToggle,
              icon: Icon(
                paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                color: AppTheme.textPrimary,
                size: playSize,
              ),
              style: IconButton.styleFrom(
                backgroundColor: AppTheme.cardBg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: AppTheme.cardBorder),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _LapSelector(
              selectedLap: selectedLap,
              lapOptions: lapOptions,
              onLapChanged: onLapChanged,
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _SpeedButton(
                label: _speedLabel,
                onTap: onSpeedToggle,
                fontSize: speedSize,
              ),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(
              height: 1,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    AppTheme.accentRed,
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LapSelector extends StatelessWidget {
  const _LapSelector({
    required this.selectedLap,
    required this.lapOptions,
    required this.onLapChanged,
    this.compact = false,
  });

  final String selectedLap;
  final List<String> lapOptions;
  final ValueChanged<String?> onLapChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedLap.isNotEmpty ? selectedLap : null,
          isDense: compact,
          isExpanded: compact,
          dropdownColor: AppTheme.cardBg,
          style: AppTheme.inter(
            fontSize: compact ? 12 : 13,
            color: AppTheme.textPrimary,
          ),
          iconEnabledColor: AppTheme.textMuted,
          onChanged: onLapChanged,
          items: lapOptions.map<DropdownMenuItem<String>>((String lap) {
            return DropdownMenuItem<String>(
              value: lap,
              child: Text(lap, overflow: TextOverflow.ellipsis, maxLines: 1),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _CompactControlButton extends StatelessWidget {
  const _CompactControlButton({
    required this.onPressed,
    required this.child,
    required this.tooltip,
  });

  final VoidCallback onPressed;
  final Widget child;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: IconButton(
        onPressed: onPressed,
        tooltip: tooltip,
        icon: child,
        style: IconButton.styleFrom(
          backgroundColor: AppTheme.cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: AppTheme.cardBorder),
          ),
        ),
      ),
    );
  }
}

class _SpeedButton extends StatelessWidget {
  const _SpeedButton({
    required this.label,
    required this.onTap,
    required this.fontSize,
    this.horizontalPadding = 14,
  });

  final String label;
  final VoidCallback onTap;
  final double fontSize;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppTheme.cardBorder),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 8,
            ),
            child: Text(
              label,
              style: AppTheme.orbitron(
                fontSize: fontSize,
                color: AppTheme.accentCyan,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

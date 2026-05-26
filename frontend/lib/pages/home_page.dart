import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';
import '../widgets/homepage_backend_status.dart';
import '../widgets/homepage_track_background.dart';
import '../widgets/homepage_telemetry_hud.dart';
import '../widgets/source_mode_card.dart';

class HomePageLanding extends StatelessWidget {
  const HomePageLanding({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF07070B), Color(0xFF111122), Color(0xFF180B0B)],
          ),
        ),
        child: Stack(
          children: [
            const _LandingBackdrop(),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final bool isWide = constraints.maxWidth >= 980;
                  final bool isPhone = constraints.maxWidth < 600;
                  final double footerRevealGap = isWide
                      ? constraints.maxHeight * 0.22
                      : (isPhone ? 24 : constraints.maxHeight * 0.12);
                  final EdgeInsets contentPadding = EdgeInsets.symmetric(
                    horizontal: isWide ? 48 : (isPhone ? 16 : 20),
                    vertical: isWide ? 36 : (isPhone ? 14 : 20),
                  );
                  return Stack(
                    children: [
                      SingleChildScrollView(
                        padding: contentPadding.copyWith(
                          bottom: isWide ? 36 : 28,
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight + footerRevealGap,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _EntranceReveal(
                                delay: const Duration(milliseconds: 40),
                                child: _TopLabel(
                                  isWide: isWide,
                                  isPhone: isPhone,
                                ),
                              ),
                              SizedBox(
                                height: isWide ? 36 : (isPhone ? 20 : 24),
                              ),
                              if (isWide)
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Expanded(
                                      flex: 12,
                                      child: _EntranceReveal(
                                        delay: Duration(milliseconds: 120),
                                        child: _HeroCopy(isWide: true),
                                      ),
                                    ),
                                    const SizedBox(width: 28),
                                    Expanded(
                                      flex: 11,
                                      child: _EntranceReveal(
                                        delay: const Duration(
                                          milliseconds: 220,
                                        ),
                                        child: _ModeGrid(isWide: true),
                                      ),
                                    ),
                                  ],
                                )
                              else ...[
                                const _EntranceReveal(
                                  delay: Duration(milliseconds: 120),
                                  child: _HeroCopy(isWide: false),
                                ),
                                SizedBox(height: isPhone ? 22 : 28),
                                _EntranceReveal(
                                  delay: const Duration(milliseconds: 220),
                                  child: _ModeGrid(isWide: isWide),
                                ),
                              ],
                              SizedBox(height: footerRevealGap),
                              const _EntranceReveal(
                                delay: Duration(milliseconds: 320),
                                child: _BottomStrip(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopLabel extends StatelessWidget {
  const _TopLabel({required this.isWide, required this.isPhone});

  final bool isWide;
  final bool isPhone;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0x33111122),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppTheme.accentRed,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'F1 AI COMMENTARY',
                style: AppTheme.orbitron(
                  fontSize: isWide ? 12 : 11,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
        if (isPhone) const SizedBox(width: 10) else const Spacer(),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isWide ? 250 : 154),
          child: Align(
            alignment: Alignment.topRight,
            child: HomepageBackendStatus(compact: !isWide),
          ),
        ),
      ],
    );
  }
}

class _HeroCopy extends StatelessWidget {
  const _HeroCopy({required this.isWide});

  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final double titleSize = isWide ? 44 : 34;
    final double bodySize = isWide ? 17 : 15;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose your race feed and launch straight into playback.',
          style: AppTheme.orbitron(
            fontSize: titleSize,
            fontWeight: FontWeight.w800,
          ).copyWith(height: isWide ? 1.16 : 1.12),
        ),
        SizedBox(height: isWide ? 20 : 14),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Text(
            'Start with simulator CSV telemetry for controlled local sessions, '
            'or open the FastF1 race browser for real-world event data.',
            style: AppTheme.inter(
              fontSize: bodySize,
              fontWeight: FontWeight.w400,
              color: const Color(0xFFD0D3DD),
            ).copyWith(height: 1.38),
          ),
        ),
        SizedBox(height: isWide ? 28 : 18),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: const [
            _InfoPill(label: 'Two data modes', accent: AppTheme.accentRed),
            _InfoPill(
              label: 'Playback-first workflow',
              accent: Color(0xFFFFB347),
            ),
          ],
        ),
        if (isWide) ...[
          const SizedBox(height: 22),
          const Opacity(
            opacity: 0.8,
            child: Align(
              alignment: Alignment.centerLeft,
              child: HomepageTelemetryHud(),
            ),
          ),
        ],
      ],
    );
  }
}

class _ModeGrid extends StatelessWidget {
  const _ModeGrid({required this.isWide});

  final bool isWide;

  @override
  Widget build(BuildContext context) {
    if (isWide) {
      return Column(
        children: [
          SourceModeCard(
            title: 'CSV Telemetry',
            subtitle:
                'Replay imported simulator telemetry with a faster local path.',
            accent: AppTheme.accentCyan,
            eyebrow: 'LOCAL DATA',
            bullets: [
              'Best for parsed simulator sessions',
              'Predictable local workflow',
              'Ideal for repeat playback and review',
            ],
            onPressed: () => context.go('/csv'),
          ),
          const SizedBox(height: 18),
          SourceModeCard(
            title: 'FastF1 Races',
            subtitle:
                'Browse real sessions and move into a richer event selection flow.',
            accent: AppTheme.accentRed,
            eyebrow: 'HISTORICAL RACE DATA',
            bullets: [
              'Best for official event exploration',
              'Session choice before playback',
              'Built for race-driven storytelling',
            ],
            onPressed: () => context.go('/fastf1'),
          ),
        ],
      );
    }

    return Column(
      children: [
        SourceModeCard(
          title: 'CSV Telemetry',
          subtitle:
              'Replay imported simulator telemetry with a faster local path.',
          accent: AppTheme.accentCyan,
          eyebrow: 'LOCAL DATA',
          bullets: [
            'Best for parsed simulator sessions',
            'Predictable local workflow',
            'Ideal for repeat playback and review',
          ],
          onPressed: () => context.go('/csv'),
        ),
        const SizedBox(height: 16),
        SourceModeCard(
          title: 'FastF1 Races',
          subtitle:
              'Browse real sessions and move into a richer event selection flow.',
          accent: AppTheme.accentRed,
          eyebrow: 'HISTORICAL RACE DATA',
          bullets: [
            'Best for official event exploration',
            'Session choice before playback',
            'Built for race-driven storytelling',
          ],
          onPressed: () => context.go('/fastf1'),
        ),
      ],
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.label, required this.accent});

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: AppTheme.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }
}

class _BottomStrip extends StatelessWidget {
  const _BottomStrip();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0x55101018),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Wrap(
        spacing: 18,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            'Choose a data source to continue.',
            style: AppTheme.inter(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          Text(
            'CSV is faster for local replay.',
            style: AppTheme.inter(fontSize: 14, color: AppTheme.textMuted),
          ),
          Text(
            'FastF1 is better for real event browsing.',
            style: AppTheme.inter(fontSize: 14, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }
}

class _LandingBackdrop extends StatelessWidget {
  const _LandingBackdrop();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool isWide = constraints.maxWidth >= 980;
          final double trackWidth = isWide
              ? constraints.maxWidth * 0.62
              : constraints.maxWidth * 0.92;
          final double trackHeight = isWide
              ? constraints.maxHeight * 0.74
              : constraints.maxHeight * 0.32;

          return Stack(
            children: [
              Positioned(
                top: -120,
                right: -80,
                child: Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppTheme.accentRed.withValues(alpha: 0.24),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -120,
                left: -80,
                child: Container(
                  width: 360,
                  height: 360,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppTheme.accentCyan.withValues(alpha: 0.18),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned.fill(child: CustomPaint(painter: _GridPainter())),
              Positioned(
                right: isWide ? -36 : -72,
                top: isWide ? 78 : 146,
                child: Opacity(
                  opacity: isWide ? 0.92 : 0.48,
                  child: ShaderMask(
                    shaderCallback: (bounds) {
                      return const LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.transparent,
                          Colors.white,
                          Colors.white,
                          Colors.transparent,
                        ],
                        stops: [0.0, 0.18, 0.82, 1.0],
                      ).createShader(bounds);
                    },
                    blendMode: BlendMode.dstIn,
                    child: SizedBox(
                      width: trackWidth,
                      height: trackHeight,
                      child: const HomepageTrackBackground(opacity: 1),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _EntranceReveal extends StatelessWidget {
  const _EntranceReveal({required this.child, required this.delay});

  final Widget child;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, value, currentChild) {
        final double delayedValue = Curves.easeOutCubic.transform(
          ((value * 700 - delay.inMilliseconds) / 420).clamp(0.0, 1.0),
        );

        return Opacity(
          opacity: delayedValue,
          child: Transform.translate(
            offset: Offset(0, 24 * (1 - delayedValue)),
            child: currentChild,
          ),
        );
      },
      child: child,
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = const Color(0x16FFFFFF)
      ..strokeWidth = 1;

    const double gap = 44;
    for (double x = 0; x < size.width; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

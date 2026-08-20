import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_colors.dart';
import '../models/club.dart';
import 'entity_image.dart';

/// Full-screen celebration shown once when opening an OFFICIAL case:
/// "OFFICIAL" pops center screen, then the player card slides from the
/// origin club to the destination club. See SPEC.md §22 アニメーション — OFFICIAL.
class OfficialRevealOverlay extends StatefulWidget {
  const OfficialRevealOverlay({
    super.key,
    required this.playerName,
    required this.fromClub,
    required this.toClub,
    required this.onFinished,
  });

  final String playerName;
  final Club fromClub;
  final Club toClub;
  final VoidCallback onFinished;

  @override
  State<OfficialRevealOverlay> createState() => _OfficialRevealOverlayState();
}

class _OfficialRevealOverlayState extends State<OfficialRevealOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..forward();

    HapticFeedback.heavyImpact();
    _dismissTimer = Timer(const Duration(milliseconds: 3000), () {
      if (mounted) widget.onFinished();
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _skip() {
    _dismissTimer?.cancel();
    widget.onFinished();
  }

  @override
  Widget build(BuildContext context) {
    final officialPop = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.32, curve: Curves.elasticOut),
    );
    final officialFadeIn = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.16, curve: Curves.easeOut),
    );
    final officialFadeOut = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.38, 0.5, curve: Curves.easeIn),
    );
    final transferReveal = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.42, 0.8, curve: Curves.easeOutCubic),
    );
    final overlayExit = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.92, 1.0, curve: Curves.easeIn),
    );

    return GestureDetector(
      onTap: _skip,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final officialOpacity = (officialFadeIn.value *
                  (1 - officialFadeOut.value))
              .clamp(0.0, 1.0);
          final revealT = transferReveal.value.clamp(0.0, 1.0);

          return Opacity(
            opacity: 1 - overlayExit.value.clamp(0.0, 1.0),
            child: Container(
              color: AppColors.background.withValues(alpha: 0.94),
              width: double.infinity,
              height: double.infinity,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Opacity(
                      opacity: officialOpacity,
                      child: Transform.scale(
                        scale: 0.3 + officialPop.value * 0.9,
                        child: const Text(
                          'OFFICIAL',
                          style: TextStyle(
                            fontSize: 44,
                            fontWeight: FontWeight.w900,
                            color: AppColors.official,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 28 * revealT),
                    Opacity(
                      opacity: revealT,
                      child: Transform.translate(
                        offset: Offset(0, (1 - revealT) * 18),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Transform.translate(
                                  offset: Offset((1 - revealT) * -70, 0),
                                  child: _ClubChip(club: widget.fromClub),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: Icon(
                                    Icons.arrow_forward,
                                    color: AppColors.official,
                                    size: 20 + revealT * 6,
                                  ),
                                ),
                                Transform.translate(
                                  offset: Offset((1 - revealT) * 70, 0),
                                  child: _ClubChip(
                                    club: widget.toClub,
                                    highlighted: true,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Text(
                              'WELCOME TO ${widget.toClub.name.toUpperCase()}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.playerName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Opacity(
                      opacity: revealT,
                      child: const Text(
                        'タップしてスキップ',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ClubChip extends StatelessWidget {
  const _ClubChip({required this.club, this.highlighted = false});

  final Club club;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClubCrest(club: club, size: 56, circular: true),
        const SizedBox(height: 6),
        Text(
          club.name,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

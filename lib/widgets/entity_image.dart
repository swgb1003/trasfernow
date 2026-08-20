import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../models/club.dart';
import '../models/transfer_case.dart';

/// Player photo with a deterministic flag fallback. See SPEC.md §6, §24.
class PlayerAvatar extends StatelessWidget {
  const PlayerAvatar({super.key, required this.transferCase, this.radius = 24});

  final TransferCase transferCase;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final fallback = Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(transferCase.fromClub.primaryColorValue),
                Color(transferCase.toClub.primaryColorValue),
              ],
            ),
          ),
        ),
        Image.asset(
          'assets/images/player_placeholder.png',
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
          filterQuality: FilterQuality.medium,
        ),
        Positioned(
          right: radius * 0.06,
          bottom: radius * 0.04,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.92),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.7),
                width: 0.8,
              ),
              boxShadow: const [
                BoxShadow(color: Colors.black38, blurRadius: 3),
              ],
            ),
            child: SizedBox.square(
              dimension: radius * 0.72,
              child: Center(
                child: Text(
                  transferCase.playerCountryFlag,
                  style: TextStyle(fontSize: radius * 0.39),
                ),
              ),
            ),
          ),
        ),
      ],
    );

    return Semantics(
      image: true,
      label: '${transferCase.playerName}の選手画像',
      child: Container(
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.cardBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: _OptionalNetworkImage(
          url: transferCase.playerImageUrl,
          fallback: fallback,
        ),
      ),
    );
  }
}

/// Club crest that switches from a branded local monogram to a remote asset
/// when [Club.crestUrl] becomes available. See SPEC.md §17, §24.
class ClubCrest extends StatelessWidget {
  const ClubCrest({
    super.key,
    required this.club,
    this.size = 44,
    this.circular = false,
  });

  final Club club;
  final double size;
  final bool circular;

  @override
  Widget build(BuildContext context) {
    final borderRadius =
        circular
            ? BorderRadius.circular(size / 2)
            : BorderRadius.only(
              topLeft: Radius.circular(size * 0.28),
              topRight: Radius.circular(size * 0.28),
              bottomLeft: Radius.circular(size * 0.46),
              bottomRight: Radius.circular(size * 0.46),
            );
    final fallback = _ClubMonogram(club: club, size: size);

    return Semantics(
      image: true,
      label: '${club.name}のクラブエンブレム',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
          boxShadow: [
            BoxShadow(
              color: Color(club.primaryColorValue).withValues(alpha: 0.18),
              blurRadius: 10,
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: _OptionalNetworkImage(
          url: club.crestUrl,
          fit: BoxFit.contain,
          padding: EdgeInsets.all(size * 0.1),
          fallback: fallback,
        ),
      ),
    );
  }
}

class _ClubMonogram extends StatelessWidget {
  const _ClubMonogram({required this.club, required this.size});

  final Club club;
  final double size;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(club.primaryColorValue),
            Color(club.secondaryColorValue),
          ],
        ),
      ),
      child: CustomPaint(
        painter: _CrestPatternPainter(),
        child: Stack(
          fit: StackFit.expand,
          alignment: Alignment.center,
          children: [
            Positioned(
              top: size * 0.08,
              left: 0,
              right: 0,
              child: Icon(
                Icons.star_rounded,
                size: size * 0.15,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
            Center(
              child: Text(
                club.shortCode,
                maxLines: 1,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size * 0.22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: size * 0.008,
                  shadows: const [Shadow(color: Colors.black54, blurRadius: 3)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CrestPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint =
        Paint()
          ..color = Colors.white.withValues(alpha: 0.16)
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.width * 0.035;
    final ringPaint =
        Paint()
          ..color = Colors.white.withValues(alpha: 0.2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.width * 0.025;

    canvas.drawCircle(size.center(Offset.zero), size.width * 0.32, ringPaint);
    canvas.drawLine(
      Offset(-size.width * 0.08, size.height * 0.72),
      Offset(size.width * 0.46, size.height * 0.18),
      linePaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.54, size.height * 0.82),
      Offset(size.width * 1.08, size.height * 0.28),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CrestPatternPainter oldDelegate) => false;
}

class _OptionalNetworkImage extends StatelessWidget {
  const _OptionalNetworkImage({
    required this.url,
    required this.fallback,
    this.fit = BoxFit.cover,
    this.padding = EdgeInsets.zero,
  });

  final String? url;
  final Widget fallback;
  final BoxFit fit;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = url?.trim();
    if (resolvedUrl == null || resolvedUrl.isEmpty) return fallback;

    return ColoredBox(
      color: AppColors.surface,
      child: Padding(
        padding: padding,
        child: Image.network(
          resolvedUrl,
          fit: fit,
          filterQuality: FilterQuality.medium,
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded || frame != null) return child;
            return Stack(
              fit: StackFit.expand,
              children: [
                fallback,
                const Center(
                  child: SizedBox.square(
                    dimension: 14,
                    child: CircularProgressIndicator(strokeWidth: 1.5),
                  ),
                ),
              ],
            );
          },
          errorBuilder: (_, __, ___) => fallback,
        ),
      ),
    );
  }
}

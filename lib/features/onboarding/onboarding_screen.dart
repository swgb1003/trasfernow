import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../data/favorites_provider.dart';
import '../../data/club_catalog.dart';
import '../../data/onboarding_preferences.dart';
import '../../models/club.dart';
import '../../widgets/entity_image.dart';

/// First-launch flow: splash → league → club. See SPEC.md §20 (screens 01-03).
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  late final PageController _pageController;
  late final AnimationController _marketStreamController;
  late final Timer _splashTimer;
  final _clubSearchController = TextEditingController();

  int _page = 0;
  String? _selectedLeague;
  String? _selectedClub;
  String _clubQuery = '';
  bool _isCompleting = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _marketStreamController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5200),
    )..repeat();
    _splashTimer = Timer(const Duration(milliseconds: 2400), _showLeaguePage);
  }

  @override
  void dispose() {
    _splashTimer.cancel();
    _pageController.dispose();
    _marketStreamController.dispose();
    _clubSearchController.dispose();
    super.dispose();
  }

  Future<void> _goToPage(int page) async {
    if (!mounted || !_pageController.hasClients || _page == page) return;
    setState(() => _page = page);
    await _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 620),
      curve: Curves.easeInOutCubic,
    );
  }

  void _showLeaguePage() {
    _marketStreamController.stop();
    _goToPage(1);
  }

  void _showClubPage() {
    if (_selectedLeague == null) return;
    setState(() {
      _selectedClub = null;
      _clubQuery = '';
      _clubSearchController.clear();
    });
    _goToPage(2);
  }

  Future<void> _finish() async {
    final league = _selectedLeague;
    final club = _selectedClub;
    if (league == null || club == null || _isCompleting) return;

    setState(() => _isCompleting = true);
    ref.read(favoritesProvider.notifier).addClub(club);
    await ref
        .read(onboardingPreferencesProvider)
        .complete(league: league, club: club);
    if (mounted) context.go('/live');
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _MarketBackdrop(),
          PageView(
            key: const ValueKey('onboarding-pages'),
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _SplashPage(
                streamAnimation: _marketStreamController,
                reduceMotion: reduceMotion,
              ),
              _LeaguePage(
                selectedLeague: _selectedLeague,
                onSelected:
                    (league) => setState(() => _selectedLeague = league),
                onContinue: _showClubPage,
              ),
              _ClubPage(
                league: _selectedLeague ?? _leagues.first.name,
                selectedClub: _selectedClub,
                queryController: _clubSearchController,
                query: _clubQuery,
                isCompleting: _isCompleting,
                onBack: () => _goToPage(1),
                onQueryChanged:
                    (value) => setState(() => _clubQuery = value.trim()),
                onSelected: (club) => setState(() => _selectedClub = club),
                onComplete: _finish,
              ),
            ],
          ),
          if (_page > 0)
            Positioned(
              top: MediaQuery.paddingOf(context).top + 12,
              right: 18,
              child: _StepIndicator(current: _page),
            ),
        ],
      ),
    );
  }
}

class _SplashPage extends StatelessWidget {
  const _SplashPage({
    required this.streamAnimation,
    required this.reduceMotion,
  });

  final Animation<double> streamAnimation;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: const ValueKey('onboarding-splash'),
      label: 'TRANSFER NOW スプラッシュ',
      child: Stack(
        fit: StackFit.expand,
        children: [
          Opacity(
            opacity: reduceMotion ? 0.18 : 0.34,
            child: AnimatedBuilder(
              animation: streamAnimation,
              builder:
                  (context, _) => _TransferCardStream(
                    progress: reduceMotion ? 0.2 : streamAnimation.value,
                  ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                radius: 0.92,
                colors: [
                  AppColors.background.withValues(alpha: 0.35),
                  AppColors.background.withValues(alpha: 0.88),
                ],
              ),
            ),
          ),
          Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.86, end: 1),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutBack,
              builder:
                  (context, scale, child) => Transform.scale(
                    scale: reduceMotion ? 1 : scale,
                    child: child,
                  ),
              child: const _HeroLogo(),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.paddingOf(context).bottom + 26,
            child: const Column(
              children: [
                Text(
                  'POWERED BY DATA. DRIVEN BY PASSION.',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.7,
                  ),
                ),
                SizedBox(height: 9),
                _LoadingRail(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroLogo extends StatelessWidget {
  const _HeroLogo();

  @override
  Widget build(BuildContext context) {
    final width = math.min(MediaQuery.sizeOf(context).width - 52, 360.0);
    return SizedBox(
      width: width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF79E9FF).withValues(alpha: 0.6),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentCyanStrong.withValues(alpha: 0.25),
                  blurRadius: 24,
                  spreadRadius: 3,
                ),
              ],
            ),
            child: const CustomPaint(painter: _GlobePainter()),
          ),
          const SizedBox(height: 24),
          const _TransferNowLogo(),
          const SizedBox(height: 10),
          const Text(
            'LIVE THE MARKET.',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              letterSpacing: 3.6,
            ),
          ),
          const SizedBox(height: 22),
          Container(
            width: 132,
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppColors.accentCyan.withValues(alpha: 0.9),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TransferNowLogo extends StatelessWidget {
  const _TransferNowLogo({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 18.0 : 37.0;
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'TRANSFER ',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: size,
              height: 1,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              letterSpacing: compact ? -0.3 : -1.4,
            ),
          ),
          Text(
            'NOW',
            style: TextStyle(
              color: AppColors.accentLime,
              fontSize: size,
              height: 1,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              letterSpacing: compact ? -0.3 : -1.4,
              shadows: [
                Shadow(
                  color: AppColors.accentLimeGlow.withValues(alpha: 0.45),
                  blurRadius: compact ? 6 : 14,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaguePage extends StatelessWidget {
  const _LeaguePage({
    required this.selectedLeague,
    required this.onSelected,
    required this.onContinue,
  });

  final String? selectedLeague;
  final ValueChanged<String> onSelected;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            const SizedBox(width: 168, child: _TransferNowLogo(compact: true)),
            const Spacer(),
            const _Eyebrow(text: 'PERSONALIZE YOUR FEED'),
            const SizedBox(height: 12),
            const Text(
              '好きなリーグを\n選択してください',
              style: TextStyle(
                fontSize: 29,
                height: 1.22,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.8,
              ),
            ),
            const SizedBox(height: 9),
            const Text(
              '選んだリーグの移籍情報を優先してお届けします。',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 22),
            Flexible(
              flex: 8,
              child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: _leagues.length,
                separatorBuilder: (_, __) => const SizedBox(height: 9),
                itemBuilder: (context, index) {
                  final league = _leagues[index];
                  return _LeagueChoiceCard(
                    league: league,
                    selected: selectedLeague == league.name,
                    onTap: () => onSelected(league.name),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            _PrimaryActionButton(
              key: const ValueKey('league-continue'),
              label: 'クラブを選ぶ',
              enabled: selectedLeague != null,
              onPressed: onContinue,
            ),
          ],
        ),
      ),
    );
  }
}

class _ClubPage extends StatelessWidget {
  const _ClubPage({
    required this.league,
    required this.selectedClub,
    required this.queryController,
    required this.query,
    required this.isCompleting,
    required this.onBack,
    required this.onQueryChanged,
    required this.onSelected,
    required this.onComplete,
  });

  final String league;
  final String? selectedClub;
  final TextEditingController queryController;
  final String query;
  final bool isCompleting;
  final VoidCallback onBack;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<String> onSelected;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    final allClubs = ClubCatalog.byLeague(league);
    final normalized = query.toLowerCase();
    final clubs =
        allClubs
            .where((club) => club.name.toLowerCase().contains(normalized))
            .toList();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  key: const ValueKey('club-back'),
                  tooltip: 'リーグ選択に戻る',
                  onPressed: onBack,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.surface.withValues(alpha: 0.85),
                    side: const BorderSide(color: AppColors.cardBorder),
                  ),
                  icon: const Icon(Icons.arrow_back_rounded, size: 20),
                ),
                const SizedBox(width: 10),
                const SizedBox(
                  width: 150,
                  child: _TransferNowLogo(compact: true),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Eyebrow(text: 'BUILD YOUR WATCHLIST'),
                      SizedBox(height: 8),
                      Text(
                        'お気に入りクラブを選択',
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.6,
                        ),
                      ),
                    ],
                  ),
                ),
                _LeagueMonogram(name: league),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '$league · 1クラブを登録',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              key: const ValueKey('club-search'),
              controller: queryController,
              onChanged: onQueryChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'クラブ名を検索',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon:
                    query.isEmpty
                        ? null
                        : IconButton(
                          tooltip: '検索をクリア',
                          onPressed: () {
                            queryController.clear();
                            onQueryChanged('');
                          },
                          icon: const Icon(Icons.close_rounded, size: 18),
                        ),
              ),
            ),
            const SizedBox(height: 15),
            Expanded(
              child:
                  clubs.isEmpty
                      ? const _NoClubResults()
                      : GridView.builder(
                        key: const ValueKey('club-grid'),
                        padding: const EdgeInsets.only(bottom: 8),
                        itemCount: clubs.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 10,
                              childAspectRatio: 1.7,
                            ),
                        itemBuilder: (context, index) {
                          final club = clubs[index];
                          return _ClubChoiceCard(
                            club: club,
                            selected: club.name == selectedClub,
                            onTap: () => onSelected(club.name),
                          );
                        },
                      ),
            ),
            const SizedBox(height: 10),
            _PrimaryActionButton(
              key: const ValueKey('onboarding-complete'),
              label: isCompleting ? '設定を保存中...' : 'TRANSFER NOWを始める',
              enabled: selectedClub != null && !isCompleting,
              onPressed: onComplete,
              icon: isCompleting ? null : Icons.arrow_forward_rounded,
            ),
          ],
        ),
      ),
    );
  }
}

class _LeagueChoiceCard extends StatelessWidget {
  const _LeagueChoiceCard({
    required this.league,
    required this.selected,
    required this.onTap,
  });

  final _LeagueOption league;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color:
              selected
                  ? league.color.withValues(alpha: 0.12)
                  : AppColors.card.withValues(alpha: 0.78),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                selected
                    ? league.color.withValues(alpha: 0.9)
                    : AppColors.cardBorder,
            width: selected ? 1.4 : 1,
          ),
          boxShadow:
              selected
                  ? [
                    BoxShadow(
                      color: league.color.withValues(alpha: 0.14),
                      blurRadius: 18,
                    ),
                  ]
                  : const [],
        ),
        child: InkWell(
          key: ValueKey('league-${league.name}'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              children: [
                _LeagueBadge(league: league),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        league.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        league.country,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child:
                      selected
                          ? Icon(
                            Icons.check_circle_rounded,
                            key: const ValueKey('selected'),
                            color: league.color,
                            size: 24,
                          )
                          : const Icon(
                            Icons.chevron_right_rounded,
                            key: ValueKey('unselected'),
                            color: AppColors.textMuted,
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

class _ClubChoiceCard extends StatelessWidget {
  const _ClubChoiceCard({
    required this.club,
    required this.selected,
    required this.onTap,
  });

  final Club club;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color:
              selected
                  ? Color(club.primaryColorValue).withValues(alpha: 0.16)
                  : AppColors.card.withValues(alpha: 0.8),
          border: Border.all(
            color: selected ? AppColors.accentCyan : AppColors.cardBorder,
            width: selected ? 1.5 : 1,
          ),
          boxShadow:
              selected
                  ? [
                    BoxShadow(
                      color: AppColors.accentCyanStrong.withValues(alpha: 0.14),
                      blurRadius: 16,
                    ),
                  ]
                  : const [],
        ),
        child: InkWell(
          key: ValueKey('club-${club.name}'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                ClubCrest(club: club, size: 42),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    club.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.15,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                    ),
                  ),
                ),
                if (selected)
                  const Icon(
                    Icons.check_rounded,
                    color: AppColors.accentCyan,
                    size: 19,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  const _PrimaryActionButton({
    super.key,
    required this.label,
    required this.enabled,
    required this.onPressed,
    this.icon = Icons.arrow_forward_rounded,
  });

  final String label;
  final bool enabled;
  final VoidCallback onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow:
              enabled
                  ? [
                    BoxShadow(
                      color: AppColors.accentLimeGlow.withValues(alpha: 0.18),
                      blurRadius: 22,
                    ),
                  ]
                  : const [],
        ),
        child: FilledButton(
          onPressed: enabled ? onPressed : null,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.accentLime,
            disabledBackgroundColor: AppColors.card,
            foregroundColor: const Color(0xFF081005),
            disabledForegroundColor: AppColors.textMuted,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color:
                    enabled ? AppColors.accentLimeBorder : AppColors.cardBorder,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.2,
                ),
              ),
              if (icon != null) ...[
                const SizedBox(width: 9),
                Icon(icon, size: 19),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.current});

  final int current;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '0$current',
              style: const TextStyle(color: AppColors.accentLime),
            ),
            const TextSpan(
              text: ' / 02',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ],
        ),
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 18, height: 2, color: AppColors.accentCyan),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            color: AppColors.accentCyan,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.4,
          ),
        ),
      ],
    );
  }
}

class _LeagueBadge extends StatelessWidget {
  const _LeagueBadge({required this.league});

  final _LeagueOption league;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: league.color.withValues(alpha: 0.14),
        border: Border.all(color: league.color.withValues(alpha: 0.55)),
      ),
      child: Text(
        league.code,
        style: TextStyle(
          color: league.color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.3,
        ),
      ),
    );
  }
}

class _LeagueMonogram extends StatelessWidget {
  const _LeagueMonogram({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final league = _leagues.firstWhere((item) => item.name == name);
    return _LeagueBadge(league: league);
  }
}

class _NoClubResults extends StatelessWidget {
  const _NoClubResults();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, color: AppColors.textMuted, size: 36),
          SizedBox(height: 8),
          Text(
            '該当するクラブがありません',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _LoadingRail extends StatelessWidget {
  const _LoadingRail();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      height: 2,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        gradient: const LinearGradient(
          colors: [AppColors.accentCyan, AppColors.accentLime],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentCyan.withValues(alpha: 0.6),
            blurRadius: 7,
          ),
        ],
      ),
    );
  }
}

class _TransferCardStream extends StatelessWidget {
  const _TransferCardStream({required this.progress});

  final double progress;

  static const _cards = [
    ('Garnacho', 'MAN UTD  →  CHELSEA', '76%', AppColors.breaking),
    ('Osimhen', 'NAPOLI  →  ARSENAL', '48%', AppColors.negotiation),
    ('Isak', 'NEWCASTLE  →  LIVERPOOL', '100%', AppColors.official),
    ('Olise', 'CRYSTAL PALACE  →  BAYERN', '34%', AppColors.rumour),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final travel = constraints.maxHeight + 150;
        return ClipRect(
          child: Stack(
            children: [
              for (var column = 0; column < 2; column++)
                for (var i = 0; i < 5; i++)
                  Positioned(
                    left: column == 0 ? -32 : constraints.maxWidth * 0.52,
                    top:
                        ((progress * travel * (column == 0 ? 1 : -1) +
                                i * 142 +
                                column * 71) %
                            travel) -
                        110,
                    width: constraints.maxWidth * 0.62,
                    child: Transform.rotate(
                      angle: column == 0 ? -0.035 : 0.035,
                      child: _GhostTransferCard(data: _cards[(i + column) % 4]),
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }
}

class _GhostTransferCard extends StatelessWidget {
  const _GhostTransferCard({required this.data});

  final (String, String, String, Color) data;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 92,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: data.$4.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(color: data.$4.withValues(alpha: 0.12), blurRadius: 16),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: data.$4.withValues(alpha: 0.16),
            child: const Icon(Icons.person, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.$1,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  data.$2,
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  style: const TextStyle(
                    fontSize: 8,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Text(
            data.$3,
            style: TextStyle(
              color: data.$4,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _MarketBackdrop extends StatelessWidget {
  const _MarketBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.background,
        gradient: RadialGradient(
          center: Alignment(0.7, -0.75),
          radius: 1.15,
          colors: [AppColors.backgroundGlow, AppColors.background],
        ),
      ),
      child: CustomPaint(painter: const _GridPainter()),
    );
  }
}

class _GridPainter extends CustomPainter {
  const _GridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = const Color(0xFF4ACDE8).withValues(alpha: 0.045)
          ..strokeWidth = 0.7;
    const gap = 34.0;
    for (var x = 0.0; x < size.width; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) => false;
}

class _GlobePainter extends CustomPainter {
  const _GlobePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide * 0.34;
    final paint =
        Paint()
          ..color = AppColors.accentCyan.withValues(alpha: 0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;
    canvas.drawCircle(center, radius, paint);
    canvas.drawOval(
      Rect.fromCenter(center: center, width: radius, height: radius * 2),
      paint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: center, width: radius * 2, height: radius * 0.72),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx - radius, center.dy),
      Offset(center.dx + radius, center.dy),
      paint,
    );
    final nodePaint =
        Paint()
          ..color = AppColors.accentLime
          ..style = PaintingStyle.fill;
    canvas.drawCircle(
      center + Offset(radius * 0.58, -radius * 0.36),
      2.2,
      nodePaint,
    );
    canvas.drawCircle(
      center + Offset(-radius * 0.5, radius * 0.3),
      2.2,
      nodePaint,
    );
  }

  @override
  bool shouldRepaint(_GlobePainter oldDelegate) => false;
}

class _LeagueOption {
  const _LeagueOption(this.name, this.country, this.code, this.color);

  final String name;
  final String country;
  final String code;
  final Color color;
}

const _leagues = [
  _LeagueOption('Premier League', 'ENGLAND', 'PL', Color(0xFFC66BFF)),
  _LeagueOption('LaLiga', 'SPAIN', 'LL', Color(0xFFFF5F6D)),
  _LeagueOption('Serie A', 'ITALY', 'SA', Color(0xFF58A6FF)),
  _LeagueOption('Bundesliga', 'GERMANY', 'BL', Color(0xFFFF5454)),
  _LeagueOption('Ligue 1', 'FRANCE', 'L1', AppColors.accentCyan),
];

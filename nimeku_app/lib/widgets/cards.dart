import 'package:flutter/material.dart';

import '../models/anime.dart';
import '../services/favorites_store.dart';
import '../theme.dart';
import 'common.dart';

/// Kartu poster vertikal: gambar 2:3 + judul maks 2 baris + meta.
/// [heroPrefix] membedakan sumber Hero tiap tab agar tag selalu unik.
class PosterCard extends StatelessWidget {
  const PosterCard({
    super.key,
    required this.anime,
    this.onTap,
    this.width,
    this.heroPrefix = '',
  });

  final Anime anime;
  final VoidCallback? onTap;
  final double? width;
  final String heroPrefix;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Hero(
            tag: '$heroPrefix${anime.id}',
            child: AspectRatio(
              aspectRatio: 2 / 3,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(NimekuRadii.card),
                  boxShadow: NimekuTheme.cardShadow,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(NimekuRadii.card),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CoverImage(anime: anime),
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.45),
                              ],
                              stops: const [0.55, 1],
                            ),
                          ),
                        ),
                      ),
                      if (anime.rating > 0)
                        Positioned(
                          left: 8,
                          top: 8,
                          child: RatingBadge(rating: anime.rating),
                        ),
                      const Positioned.fill(
                        child: Center(
                          child: Icon(
                            Icons.play_circle_fill_rounded,
                            size: 40,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            anime.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: NimekuType.body.copyWith(
              fontWeight: FontWeight.w600,
              color: isDark
                  ? NimekuColors.textPrimary
                  : NimekuColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            anime.metaShort,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: NimekuType.caption.copyWith(
              color: isDark
                  ? NimekuColors.textSecondary
                  : NimekuColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return card;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(NimekuRadii.card),
      child: card,
    );
  }
}

/// Kartu horizontal "Lanjutkan Menonton" — lebar tetap 280.
/// Thumbnail landscape 16:9 di atas, judul + progres di bawah.
class ContinueCard extends StatelessWidget {
  const ContinueCard({
    super.key,
    required this.anime,
    this.onTap,
    this.heroPrefix = '',
  });

  final Anime anime;
  final VoidCallback? onTap;
  final String heroPrefix;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final percent = (anime.progress * 100).round();
    final caption = anime.progress > 0
        ? 'E${anime.currentEpisode} • $percent%'
        : 'E${anime.currentEpisode} • Mulai';
    return Container(
      width: 280,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(NimekuRadii.card),
        boxShadow: NimekuTheme.cardShadow,
        color: isDark ? NimekuColors.surface : NimekuColors.lightSurface,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(NimekuRadii.card),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Hero(
              tag: '$heroPrefix${anime.id}',
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(NimekuRadii.card),
                ),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CoverImage(anime: anime),
                      Center(
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withValues(alpha: 0.45),
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            size: 28,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: SizedBox(
                          height: 4,
                          child: LinearProgressIndicator(
                            value: anime.progress.clamp(0.0, 1.0),
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.25),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              NimekuColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    anime.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: NimekuType.body.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? NimekuColors.textPrimary
                          : NimekuColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    caption,
                    style: NimekuType.caption.copyWith(
                      color: isDark
                          ? NimekuColors.textSecondary
                          : NimekuColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Satu halaman banner sorotan: banner jaringan + lapisan gelap bawah,
/// tombol "Tonton" putih solid dan "Daftar Saya" outline putih.
class SpotlightPage extends StatelessWidget {
  const SpotlightPage({
    super.key,
    required this.anime,
    required this.onWatch,
    required this.onToggleList,
    required this.inList,
  });

  final Anime anime;
  final VoidCallback onWatch;
  final VoidCallback onToggleList;
  final bool inList;

  @override
  Widget build(BuildContext context) {
    final bannerUrl = anime.bannerUrl;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(NimekuRadii.banner),
        boxShadow: [
          BoxShadow(
            color: NimekuColors.primary.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
        color: const Color(0xFF1D1E2E),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(NimekuRadii.banner),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (bannerUrl != null && bannerUrl.isNotEmpty)
              Image.network(
                bannerUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(decoration: hueGradient(anime));
                },
              )
            else
              Container(decoration: hueGradient(anime)),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: NimekuColors.bannerShade,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(NimekuSpacing.page),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(NimekuRadii.chip),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.local_fire_department_rounded,
                          size: 14,
                          color: NimekuColors.rating,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          anime.badge.isEmpty ? 'Sorotan' : anime.badge,
                          style: NimekuType.caption.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  FractionallySizedBox(
                    widthFactor: 0.85,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      anime.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: NimekuType.bannerTitle.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    anime.metaLine,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: NimekuType.bannerInfo.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: onWatch,
                          icon: const Icon(
                            Icons.play_arrow_rounded,
                            size: 20,
                          ),
                          label: const Text('Tonton'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF14141C),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                NimekuRadii.button,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: PressScale(
                          child: OutlinedButton.icon(
                            onPressed: onToggleList,
                            icon: Icon(
                              inList
                                  ? Icons.check_rounded
                                  : Icons.add_rounded,
                              size: 20,
                            ),
                            label: Text(
                              inList ? 'Di Daftar' : 'Daftar Saya',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Carousel banner unggulan: PageView 0.92 + titik indikator.
class SpotlightCarousel extends StatefulWidget {
  const SpotlightCarousel({
    super.key,
    required this.items,
    required this.onOpenDetail,
  });

  final List<Anime> items;
  final void Function(Anime) onOpenDetail;

  @override
  State<SpotlightCarousel> createState() => _SpotlightCarouselState();
}

class _SpotlightCarouselState extends State<SpotlightCarousel> {
  late final PageController _controller =
      PageController(viewportFraction: 0.92);
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Tinggi banner mengikuti skala font agar aman di font besar.
    final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final bannerH = (252.0 * scale).clamp(252.0, 330.0);
    return ListenableBuilder(
      listenable: FavoritesStore.instance,
      builder: (context, _) {
        final favorites = FavoritesStore.instance;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: bannerH,
              child: PageView.builder(
                controller: _controller,
                itemCount: widget.items.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  final anime = widget.items[i];
                  final inList = favorites.contains(anime.id);
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: SpotlightPage(
                      anime: anime,
                      inList: inList,
                      onWatch: () => widget.onOpenDetail(anime),
                      onToggleList: () => favorites.toggle(anime),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < widget.items.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _index ? 22 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: i == _index
                          ? NimekuColors.primary
                          : Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF3A3B52)
                              : const Color(0xFFC9CAD8),
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

import 'package:flutter/material.dart';

import '../models/anime.dart';
import '../theme.dart';
import 'cards.dart';

/// Lencana rating kuning amber. Disembunyikan bila belum ada rating.
class RatingBadge extends StatelessWidget {
  const RatingBadge({super.key, required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) {
    if (rating <= 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(NimekuRadii.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 14, color: NimekuColors.rating),
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: NimekuType.caption.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Kepala bagian: judul 18 bold + aksi "Lihat Semua".
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.onSeeAll});

  final String title;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: NimekuType.sectionTitle.copyWith(
              color: isDark
                  ? NimekuColors.textPrimary
                  : NimekuColors.lightTextPrimary,
            ),
          ),
        ),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            style: TextButton.styleFrom(
              foregroundColor: NimekuColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: const Text('Lihat Semua'),
          ),
      ],
    );
  }
}

/// Pembungkus animasi skala saat ditekan (untuk tombol favorit).
/// Hanya menganimasikan; logika tap milik tombol di dalamnya.
class PressScale extends StatefulWidget {
  const PressScale({super.key, required this.child});

  final Widget child;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 120),
    value: 1,
  );
  late final Animation<double> _scale = Tween<double>(begin: 1, end: 0.88)
      .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _controller.animateTo(0),
      onPointerUp: (_) => _controller.animateTo(1),
      onPointerCancel: (_) => _controller.animateTo(1),
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}

/// Gradien cadangan bermotif rona anime (dipakai saat gambar dimuat/gagal).
BoxDecoration hueGradient(Anime anime) {
  final base = HSVColor.fromAHSV(1, anime.hue % 360, 0.62, 0.38).toColor();
  final deep = HSVColor.fromAHSV(1, anime.hue % 360, 0.7, 0.16).toColor();
  return BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [base, deep],
    ),
  );
}

/// Gambar poster/banner dari jaringan dengan placeholder gradien.
/// Anti-crash offline: [errorBuilder] selalu menampilkan gradien.
class CoverImage extends StatelessWidget {
  const CoverImage({super.key, required this.anime});

  final Anime anime;

  @override
  Widget build(BuildContext context) {
    final url = anime.posterUrl;
    if (url == null || url.isEmpty) {
      return Container(
        decoration: hueGradient(anime),
        alignment: Alignment.center,
        child: _InitialLetter(anime: anime, size: 56),
      );
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      // Placeholder statis (tanpa animasi tak berujung) + gradien cadangan.
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(decoration: hueGradient(anime));
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          decoration: hueGradient(anime),
          alignment: Alignment.center,
          child: const Icon(
            Icons.broken_image_rounded,
            size: 32,
            color: Colors.white54,
          ),
        );
      },
    );
  }
}

class _InitialLetter extends StatelessWidget {
  const _InitialLetter({required this.anime, required this.size});

  final Anime anime;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Text(
      anime.title.characters.first,
      style: TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w800,
        color: Colors.white,
        height: 1,
      ),
    );
  }
}

/// Grid poster responsif: jumlah kolom & tinggi sel dihitung dari lebar
/// layar agar poster 2:3 + judul 2 baris + meta tidak pernah overflow,
/// dari HP 320px sampai desktop lebar.
class SliverAnimeGrid extends StatelessWidget {
  const SliverAnimeGrid({
    super.key,
    required this.items,
    required this.onTap,
    this.heroPrefix = '',
  });

  final List<Anime> items;
  final void Function(Anime) onTap;

  /// Prefix Hero agar tag unik per tab (IndexedStack me-mount semua tab).
  final String heroPrefix;

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final cross = constraints.crossAxisExtent;
        final cols = ((cross -
                    NimekuSpacing.page * 2 +
                    NimekuSpacing.cardGap) /
                120)
            .round()
            .clamp(2, 6);
        final cellW = (cross -
                NimekuSpacing.page * 2 -
                (cols - 1) * NimekuSpacing.cardGap) /
            cols;
        // Poster 2:3 + teks (18 tetap + 59 mengikuti skala font) + napas.
        final tScale = MediaQuery.textScalerOf(context).scale(14) / 14;
        final extent = cellW * 1.5 + 18 + 59 * tScale;
        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            NimekuSpacing.page,
            12,
            NimekuSpacing.page,
            NimekuSpacing.section,
          ),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
              mainAxisSpacing: NimekuSpacing.cardGap,
              crossAxisSpacing: NimekuSpacing.cardGap,
              mainAxisExtent: extent,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, i) => PosterCard(
                anime: items[i],
                heroPrefix: heroPrefix,
                onTap: () => onTap(items[i]),
              ),
              childCount: items.length,
            ),
          ),
        );
      },
    );
  }
}

/// Status kosong yang ramah (untuk Daftar Saya & hasil cari).
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark
                    ? NimekuColors.surfaceHigh
                    : NimekuColors.lightSurfaceHigh,
              ),
              child: Icon(
                icon,
                size: 40,
                color: NimekuColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: NimekuType.sectionTitle.copyWith(
                color: isDark
                    ? NimekuColors.textPrimary
                    : NimekuColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: NimekuType.body.copyWith(
                color: isDark
                    ? NimekuColors.textSecondary
                    : NimekuColors.lightTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Keadaan gagal: pesan ramah + tombol "Coba lagi" (anti-crash offline).
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark
                    ? NimekuColors.surfaceHigh
                    : NimekuColors.lightSurfaceHigh,
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                size: 40,
                color: NimekuColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Gagal memuat',
              style: NimekuType.sectionTitle.copyWith(
                color: isDark
                    ? NimekuColors.textPrimary
                    : NimekuColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: NimekuType.body.copyWith(
                color: isDark
                    ? NimekuColors.textSecondary
                    : NimekuColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: const Text('Coba lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kotak skeleton statis (tanpa animasi tak berujung agar aman di test).
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.radius = NimekuRadii.card,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        color: isDark
            ? NimekuColors.surfaceHigh
            : NimekuColors.lightSurfaceHigh,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/anime.dart';
import '../services/anilist_service.dart';
import '../services/consumet/consumet_client.dart';
import '../services/consumet/streaming_config.dart';
import '../services/favorites_store.dart';
import '../services/history_store.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Detail anime: header langsung tampil dari data kartu (Hero),
/// area konten punya tiga keadaan: loading skeleton, error + retry,
/// dan sukses (sinopsis, episode, tombol).
class DetailScreen extends StatefulWidget {
  const DetailScreen({
    super.key,
    required this.anime,
    required this.heroTag,
  });

  /// Data awal dari kartu (judul + poster untuk Hero).
  final Anime anime;

  /// Tag Hero yang cocok dengan kartu sumber (unik per tab).
  final String heroTag;

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  bool _loading = true;
  String? _error;
  Anime? _data;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await aniListService.fetchDetail(widget.anime.id);
      if (!mounted) return;
      setState(() {
        _data = data;
        _loading = false;
      });
    } on AniListException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Terjadi galat tak terduga. Coba lagi.';
        _loading = false;
      });
    }
  }

  /// Alur "Mulai Nonton": selalu catat riwayat. Bila sumber streaming
  /// milik pengguna terkonfigurasi, coba resolve episode pertama via
  /// kerangka Consumet; bila tidak, tampilkan dialog belum tersedia.
  /// Tidak ada pemutar video — hasilnya selalu dialog, tanpa crash.
  Future<void> _startWatching() async {
    final anime = _data ?? widget.anime;
    await HistoryStore.instance.touch(anime);
    if (!mounted) return;
    final cfg = StreamingConfig.instance;
    if (!cfg.isConfigured) {
      _showPlayerDialog('Pemutar belum tersedia.');
      return;
    }
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 16),
            Expanded(child: Text('Memuat sumber…')),
          ],
        ),
      ),
    );
    try {
      final client = ConsumetClient();
      final info = await client.fetchInfo(
        baseUrl: cfg.baseUrl,
        provider: cfg.provider,
        anilistId: anime.id,
      );
      if (info.episodes.isEmpty) {
        throw ConsumetException('Tidak ada episode di instans.');
      }
      final watch = await client.fetchSources(
        baseUrl: cfg.baseUrl,
        provider: cfg.provider,
        episodeId: info.episodes.first.id,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      final qualities =
          watch.sources.map((s) => s.quality ?? 'auto').join(', ');
      _showPlayerDialog(
        'Ditemukan ${watch.sources.length} sumber ($qualities). '
        'Pemutar belum tersedia.',
      );
    } on ConsumetException catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      _showPlayerDialog(e.message);
    } catch (_) {
      if (!mounted) return;
      Navigator.of(context).pop();
      _showPlayerDialog('Gagal memuat sumber. Coba lagi.');
    }
  }

  /// Membuka tautan resmi di aplikasi browser (platform streaming legal).
  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || (!uri.isScheme('http') && !uri.isScheme('https'))) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tautan tidak valid.')),
      );
      return;
    }
    bool ok = false;
    try {
      ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      ok = false;
    }
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak dapat membuka tautan.')),
      );
    }
  }

  void _showPlayerDialog(String message) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NimekuRadii.card),
        ),
        title: const Text('Segera hadir'),
        content: Text(message),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? NimekuColors.textPrimary : NimekuColors.lightTextPrimary;
    final textSecondary =
        isDark ? NimekuColors.textSecondary : NimekuColors.lightTextSecondary;
    final initial = widget.anime;
    final data = _data;
    final base = HSVColor.fromAHSV(1, initial.hue % 360, 0.62, 0.38).toColor();
    final deep = HSVColor.fromAHSV(1, initial.hue % 360, 0.7, 0.16).toColor();
    final bannerUrl = data?.bannerUrl ?? initial.bannerUrl;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            leading: Padding(
              padding: const EdgeInsets.all(4),
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Kembali',
                icon: const Icon(Icons.arrow_back_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withValues(alpha: 0.45),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            actions: [
              ListenableBuilder(
                listenable: FavoritesStore.instance,
                builder: (context, _) {
                  final inList =
                      FavoritesStore.instance.contains(initial.id);
                  return Padding(
                    padding: const EdgeInsets.all(4),
                    child: PressScale(
                      child: IconButton(
                        onPressed: () => FavoritesStore.instance
                            .toggle(data ?? initial),
                        tooltip: inList
                            ? 'Hapus dari Daftar Saya'
                            : 'Tambah ke Daftar Saya',
                        icon: Icon(
                          inList
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_border_rounded,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor:
                              Colors.black.withValues(alpha: 0.45),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: widget.heroTag,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [base, deep],
                    ),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (bannerUrl != null && bannerUrl.isNotEmpty)
                        Image.network(
                          bannerUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const SizedBox.shrink();
                          },
                        ),
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                (isDark
                                        ? NimekuColors.background
                                        : NimekuColors.lightBackground)
                                    .withValues(alpha: 0.95),
                              ],
                              stops: const [0.4, 1],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: NimekuSpacing.page,
                        right: NimekuSpacing.page,
                        bottom: 16,
                        child: Row(
                          children: [
                            RatingBadge(
                              rating: data?.rating ?? initial.rating,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                (data ?? initial).metaLine,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: NimekuType.caption.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_loading)
            const _DetailSkeleton()
          else if (_error != null)
            SliverFillRemaining(
              hasScrollBody: false,
              child: ErrorView(message: _error!, onRetry: _fetch),
            )
          else ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(NimekuSpacing.page),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (data ?? initial).title,
                      style: NimekuType.screenTitle.copyWith(
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final genre in (data ?? initial).genres)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? NimekuColors.surfaceHigh
                                  : NimekuColors.lightSurfaceHigh,
                              borderRadius: BorderRadius.circular(
                                NimekuRadii.chip,
                              ),
                            ),
                            child: Text(
                              genre,
                              style: NimekuType.caption.copyWith(
                                color: textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _startWatching,
                        icon: const Icon(
                          Icons.play_arrow_rounded,
                          size: 20,
                        ),
                        label: const Text('Mulai Nonton'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF14141C),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              NimekuRadii.button,
                            ),
                          ),
                        ),
                      ),
                    ),
                    _LegalSection(
                      streams: (data ?? initial).streamingEpisodes,
                      links: (data ?? initial).externalLinks,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      onOpen: _openUrl,
                    ),
                    const SizedBox(height: NimekuSpacing.section),
                    Text(
                      'Sinopsis',
                      style: NimekuType.sectionTitle.copyWith(
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      (data ?? initial).synopsis.isEmpty
                          ? 'Sinopsis belum tersedia.'
                          : (data ?? initial).synopsis,
                      style: NimekuType.body.copyWith(color: textSecondary),
                    ),
                    const SizedBox(height: NimekuSpacing.section),
                    Text(
                      'Daftar Episode',
                      style: NimekuType.sectionTitle.copyWith(
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if ((data?.episodes ?? initial.episodes) <= 0)
                      Text(
                        'Jumlah episode belum tersedia.',
                        style: NimekuType.body.copyWith(
                          color: textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if ((data?.episodes ?? initial.episodes) > 0)
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final ep = i + 1;
                    final total = data?.episodes ?? initial.episodes;
                    return Padding(
                      padding: EdgeInsets.fromLTRB(
                        NimekuSpacing.page,
                        0,
                        NimekuSpacing.page,
                        i == total - 1 ? NimekuSpacing.section : 8,
                      ),
                      child: Card(
                        child: ListTile(
                          minVerticalPadding: 12,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(NimekuRadii.card),
                          ),
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: NimekuColors.buttonGradient,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '$ep',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          title: Text(
                            'Episode $ep',
                            style: NimekuType.body.copyWith(
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            '± 24 menit',
                            style: NimekuType.caption.copyWith(
                              color: textSecondary,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.play_circle_outline_rounded,
                            color: NimekuColors.primary,
                          ),
                          onTap: _startWatching,
                        ),
                      ),
                    );
                  },
                  childCount: data?.episodes ?? initial.episodes,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// Seksi tautan resmi: "Tonton Legal di" (streamingEpisodes AniList)
/// + chip situs resmi (externalLinks). Disembunyikan bila kosong.
class _LegalSection extends StatelessWidget {
  const _LegalSection({
    required this.streams,
    required this.links,
    required this.textPrimary,
    required this.textSecondary,
    required this.onOpen,
  });

  final List<StreamingEpisode> streams;
  final List<ExternalLink> links;
  final Color textPrimary;
  final Color textSecondary;
  final void Function(String url) onOpen;

  @override
  Widget build(BuildContext context) {
    if (streams.isEmpty && links.isEmpty) {
      return const SizedBox.shrink();
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: NimekuSpacing.section),
        if (streams.isNotEmpty) ...[
          Text(
            'Tonton Legal di',
            style: NimekuType.sectionTitle.copyWith(color: textPrimary),
          ),
          const SizedBox(height: 8),
          for (final s in streams.take(6))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                child: ListTile(
                  minVerticalPadding: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(NimekuRadii.card),
                  ),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 64,
                      height: 36,
                      child: (s.thumbnail == null || s.thumbnail!.isEmpty)
                          ? Container(
                              color: isDark
                                  ? NimekuColors.surfaceHigh
                                  : NimekuColors.lightSurfaceHigh,
                              child: const Icon(
                                Icons.play_arrow_rounded,
                                color: NimekuColors.primary,
                              ),
                            )
                          : Image.network(
                              s.thumbnail!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: isDark
                                      ? NimekuColors.surfaceHigh
                                      : NimekuColors.lightSurfaceHigh,
                                  child: const Icon(
                                    Icons.play_arrow_rounded,
                                    color: NimekuColors.primary,
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                  title: Text(
                    s.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: NimekuType.body.copyWith(
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    s.site ?? 'Platform resmi',
                    style:
                        NimekuType.caption.copyWith(color: textSecondary),
                  ),
                  trailing: const Icon(
                    Icons.open_in_new_rounded,
                    color: NimekuColors.primary,
                  ),
                  onTap: () => onOpen(s.url),
                ),
              ),
            ),
        ],
        if (links.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'Situs Resmi',
            style: NimekuType.sectionTitle.copyWith(
              color: textPrimary,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final l in links.take(6))
                OutlinedButton.icon(
                  onPressed: () => onOpen(l.url),
                  icon: const Icon(Icons.language_rounded, size: 18),
                  label: Text(l.site ?? 'Situs resmi'),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Skeleton statis area konten detail.
class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return const SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.all(NimekuSpacing.page),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBox(width: 240, height: 28, radius: 6),
            SizedBox(height: 12),
            SkeletonBox(width: double.infinity, height: 48, radius: 14),
            SizedBox(height: 24),
            SkeletonBox(width: 140, height: 20, radius: 6),
            SizedBox(height: 8),
            SkeletonBox(width: double.infinity, height: 60, radius: 8),
            SizedBox(height: 24),
            SkeletonBox(width: 160, height: 20, radius: 6),
            SizedBox(height: 8),
            SkeletonBox(width: double.infinity, height: 64, radius: 16),
            SizedBox(height: 8),
            SkeletonBox(width: double.infinity, height: 64, radius: 16),
          ],
        ),
      ),
    );
  }
}

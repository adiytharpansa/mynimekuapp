import 'package:flutter/material.dart';

import '../models/anime.dart';
import '../services/anilist_service.dart';
import '../services/history_store.dart';
import '../theme.dart';
import '../widgets/cards.dart';
import '../widgets/common.dart';
import 'detail_screen.dart';

/// Beranda: header, carousel sorotan (trending), riwayat menonton,
/// grid trending, row sedang tayang, grid rilis terbaru.
/// Tiga keadaan: loading skeleton, error + "Coba lagi", sukses.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.onOpenSearch,
    required this.onOpenProfile,
  });

  final VoidCallback onOpenSearch;
  final VoidCallback onOpenProfile;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _loading = true;
  String? _error;
  List<Anime> _trending = [];
  List<Anime> _airing = [];
  List<Anime> _latest = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        aniListService.fetchTrending(perPage: 12),
        aniListService.fetchAiring(perPage: 10),
        aniListService.fetchLatest(perPage: 12),
      ]);
      if (!mounted) return;
      setState(() {
        _trending = results[0];
        _airing = results[1];
        _latest = results[2];
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

  void _openDetail(BuildContext context, Anime anime, String heroTag) {
    HistoryStore.instance.touch(anime);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DetailScreen(anime: anime, heroTag: heroTag),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    // Tinggi daftar mengikuti skala font agar kartu tak terpotong.
    final listH = (244.0 * tScale).clamp(244.0, 320.0);
    final rowH = (300.0 * tScale).clamp(300.0, 380.0);
    final textPrimary =
        isDark ? NimekuColors.textPrimary : NimekuColors.lightTextPrimary;
    final textSecondary =
        isDark ? NimekuColors.textSecondary : NimekuColors.lightTextSecondary;
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                NimekuSpacing.page,
                8,
                8,
                0,
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: NimekuColors.buttonGradient,
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'NIMEKU',
                      style: NimekuType.sectionTitle.copyWith(
                        color: textPrimary,
                        fontSize: 17,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: widget.onOpenSearch,
                    tooltip: 'Cari anime',
                    icon: Icon(
                      Icons.search_rounded,
                      color: textSecondary,
                    ),
                  ),
                  InkWell(
                    onTap: widget.onOpenProfile,
                    borderRadius: BorderRadius.circular(24),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: NimekuColors.buttonGradient,
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'W',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                NimekuSpacing.page,
                8,
                NimekuSpacing.page,
                0,
              ),
              child: Text(
                'Mau nonton apa hari ini?',
                style: NimekuType.body.copyWith(color: textSecondary),
              ),
            ),
          ),
          if (_loading)
            const _HomeSkeleton()
          else if (_error != null)
            SliverFillRemaining(
              hasScrollBody: false,
              child: ErrorView(message: _error!, onRetry: _load),
            )
          else ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 16),
                child: SpotlightCarousel(
                  items: _trending.take(3).toList(),
                  onOpenDetail: (anime) => _openDetail(
                    context,
                    anime,
                    'banner-${anime.id}',
                  ),
                ),
              ),
            ),
            ListenableBuilder(
              listenable: HistoryStore.instance,
              builder: (context, _) {
                final history = HistoryStore.instance.entries;
                if (history.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: SizedBox.shrink(),
                  );
                }
                return _ContinueSection(
                  history: history,
                  listH: listH,
                  onTap: (entry) => _openDetail(
                    context,
                    entry.toAnime(),
                    'c-${entry.id}',
                  ),
                );
              },
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  NimekuSpacing.page,
                  NimekuSpacing.section,
                  NimekuSpacing.page,
                  0,
                ),
                child: const SectionHeader(title: 'Trending Minggu Ini'),
              ),
            ),
            SliverAnimeGrid(
              items: _trending,
              onTap: (anime) => _openDetail(
                context,
                anime,
                'poster-${anime.id}',
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  NimekuSpacing.page,
                  0,
                  NimekuSpacing.page,
                  0,
                ),
                child: const SectionHeader(title: 'Sedang Tayang'),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: rowH,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: NimekuSpacing.page,
                    vertical: 8,
                  ),
                  itemCount: _airing.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: NimekuSpacing.cardGap),
                  itemBuilder: (context, i) => PosterCard(
                    anime: _airing[i],
                    width: 130,
                    heroPrefix: 'a-',
                    onTap: () => _openDetail(
                      context,
                      _airing[i],
                      'a-${_airing[i].id}',
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  NimekuSpacing.page,
                  NimekuSpacing.section,
                  NimekuSpacing.page,
                  0,
                ),
                child: const SectionHeader(title: 'Baru Rilis'),
              ),
            ),
            SliverAnimeGrid(
              items: _latest,
              heroPrefix: 'r-',
              onTap: (anime) => _openDetail(
                context,
                anime,
                'r-${anime.id}',
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Bagian riwayat menonton (disembunyikan bila kosong).
class _ContinueSection extends StatelessWidget {
  const _ContinueSection({
    required this.history,
    required this.listH,
    required this.onTap,
  });

  final List<HistoryEntry> history;
  final double listH;
  final void Function(HistoryEntry) onTap;

  @override
  Widget build(BuildContext context) {
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              NimekuSpacing.page,
              NimekuSpacing.section,
              NimekuSpacing.page,
              0,
            ),
            child: const SectionHeader(title: 'Lanjutkan Menonton'),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: listH,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: NimekuSpacing.page,
                vertical: 8,
              ),
              itemCount: history.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(width: NimekuSpacing.cardGap),
              itemBuilder: (context, i) => ContinueCard(
                anime: history[i].toAnime(),
                heroPrefix: 'c-',
                onTap: () => onTap(history[i]),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Skeleton statis untuk keadaan loading Beranda.
class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context) {
    return SliverMainAxisGroup(
      slivers: [
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              NimekuSpacing.page,
              16,
              NimekuSpacing.page,
              0,
            ),
            child: SkeletonBox(
              width: double.infinity,
              height: 252,
              radius: NimekuRadii.banner,
            ),
          ),
        ),
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              NimekuSpacing.page,
              NimekuSpacing.section,
              NimekuSpacing.page,
              12,
            ),
            child: SkeletonBox(width: 180, height: 20, radius: 6),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 244,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: NimekuSpacing.page,
              ),
              itemCount: 3,
              separatorBuilder: (_, _) =>
                  const SizedBox(width: NimekuSpacing.cardGap),
              itemBuilder: (context, _) => const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 280, height: 150),
                  SizedBox(height: 8),
                  SkeletonBox(width: 200, height: 14, radius: 4),
                  SizedBox(height: 6),
                  SkeletonBox(width: 120, height: 12, radius: 4),
                ],
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            NimekuSpacing.page,
            NimekuSpacing.section,
            NimekuSpacing.page,
            NimekuSpacing.section,
          ),
          sliver: SliverGrid(
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: NimekuSpacing.cardGap,
              crossAxisSpacing: NimekuSpacing.cardGap,
              mainAxisExtent: 230,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, _) => const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(
                    width: double.infinity,
                    height: 150,
                  ),
                  SizedBox(height: 8),
                  SkeletonBox(width: 90, height: 12, radius: 4),
                ],
              ),
              childCount: 6,
            ),
          ),
        ),
      ],
    );
  }
}

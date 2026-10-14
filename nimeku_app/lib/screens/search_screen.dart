import 'dart:async';

import 'package:flutter/material.dart';

import '../models/anime.dart';
import '../services/anilist_service.dart';
import '../services/history_store.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'detail_screen.dart';

/// Pencarian: kolom cari (debounce 500 ms) + jelajah genre + hasil grid.
/// Tiga keadaan: loading skeleton, error + "Coba lagi", sukses.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  String _query = '';
  bool _loading = false;
  String? _error;
  List<Anime> _results = [];

  static const recentGenres = [
    'Action',
    'Fantasy',
    'Drama',
    'Comedy',
    'Isekai',
    'Mystery',
  ];

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    // Debounce 500 ms agar tidak memanggil API setiap ketikan.
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() => _query = value);
      _search(value);
    });
  }

  Future<void> _search(String value) async {
    final q = value.trim();
    if (q.isEmpty) {
      setState(() {
        _loading = false;
        _error = null;
        _results = [];
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await aniListService.searchAnime(q);
      if (!mounted) return;
      // Abaikan hasil basi bila query sudah berubah selama fetch.
      if (_controller.text.trim() != q) return;
      setState(() {
        _results = results;
        _loading = false;
      });
    } on AniListException catch (e) {
      if (!mounted) return;
      if (_controller.text.trim() != q) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      if (_controller.text.trim() != q) return;
      setState(() {
        _error = 'Terjadi galat tak terduga. Coba lagi.';
        _loading = false;
      });
    }
  }

  void _openDetail(Anime anime) {
    HistoryStore.instance.touch(anime);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DetailScreen(anime: anime, heroTag: 's-${anime.id}'),
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
    final showIdle = _query.trim().isEmpty;

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                NimekuSpacing.page,
                12,
                NimekuSpacing.page,
                0,
              ),
              child: Text(
                'Cari Anime',
                style: NimekuType.screenTitle.copyWith(color: textPrimary),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                NimekuSpacing.page,
                16,
                NimekuSpacing.page,
                0,
              ),
              child: TextField(
                controller: _controller,
                textInputAction: TextInputAction.search,
                onChanged: _onChanged,
                onSubmitted: (v) {
                  _debounce?.cancel();
                  setState(() => _query = v);
                  _search(v);
                },
                style: NimekuType.body.copyWith(color: textPrimary),
                decoration: InputDecoration(
                  hintText: 'Judul atau genre, mis. “Action”…',
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: textSecondary,
                  ),
                  suffixIcon: _controller.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _debounce?.cancel();
                            _controller.clear();
                            setState(() {
                              _query = '';
                              _results = [];
                              _error = null;
                              _loading = false;
                            });
                          },
                          tooltip: 'Hapus',
                          icon: const Icon(Icons.close_rounded),
                        ),
                ),
              ),
            ),
          ),
          if (showIdle) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  NimekuSpacing.page,
                  NimekuSpacing.section,
                  NimekuSpacing.page,
                  0,
                ),
                child: Text(
                  'Jelajahi Genre',
                  style: NimekuType.sectionTitle.copyWith(color: textPrimary),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  NimekuSpacing.page,
                  12,
                  NimekuSpacing.page,
                  0,
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final genre in recentGenres)
                      ActionChip(
                        label: Text(genre),
                        onPressed: () {
                          _debounce?.cancel();
                          _controller.text = genre;
                          setState(() => _query = genre);
                          _search(genre);
                        },
                      ),
                  ],
                ),
              ),
            ),
            const SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                icon: Icons.search_rounded,
                title: 'Mau cari apa?',
                subtitle: 'Ketik judul anime atau pilih genre di atas.',
              ),
            ),
          ] else if (_loading) ...[
            const _SearchSkeleton(),
          ] else if (_error != null) ...[
            SliverFillRemaining(
              hasScrollBody: false,
              child: ErrorView(
                message: _error!,
                onRetry: () => _search(_controller.text),
              ),
            ),
          ] else if (_results.isEmpty) ...[
            const SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                icon: Icons.search_off_rounded,
                title: 'Tidak ditemukan',
                subtitle: 'Coba kata kunci lain, misalnya “Fantasy”.',
              ),
            ),
          ] else ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  NimekuSpacing.page,
                  16,
                  NimekuSpacing.page,
                  0,
                ),
                child: Text(
                  '${_results.length} hasil untuk “$_query”',
                  style: NimekuType.caption.copyWith(color: textSecondary),
                ),
              ),
            ),
            SliverAnimeGrid(
              items: _results,
              heroPrefix: 's-',
              onTap: _openDetail,
            ),
          ],
        ],
      ),
    );
  }
}

/// Skeleton statis hasil pencarian.
class _SearchSkeleton extends StatelessWidget {
  const _SearchSkeleton();

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        NimekuSpacing.page,
        16,
        NimekuSpacing.page,
        NimekuSpacing.section,
      ),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: NimekuSpacing.cardGap,
          crossAxisSpacing: NimekuSpacing.cardGap,
          mainAxisExtent: 230,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, _) => const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBox(width: double.infinity, height: 150),
              SizedBox(height: 8),
              SkeletonBox(width: 90, height: 12, radius: 4),
            ],
          ),
          childCount: 6,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../services/favorites_store.dart';
import '../services/history_store.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'detail_screen.dart';

/// Daftar Saya: favorit permanen dari shared_preferences.
class ListScreen extends StatelessWidget {
  const ListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? NimekuColors.textPrimary : NimekuColors.lightTextPrimary;
    return SafeArea(
      child: ListenableBuilder(
        listenable: FavoritesStore.instance,
        builder: (context, _) {
          if (!FavoritesStore.instance.ready) {
            return const CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: SkeletonBox(
                      width: 200,
                      height: 200,
                      radius: 24,
                    ),
                  ),
                ),
              ],
            );
          }
          final saved = FavoritesStore.instance.items;
          return CustomScrollView(
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
                    'Daftar Saya',
                    style: NimekuType.screenTitle.copyWith(color: textPrimary),
                  ),
                ),
              ),
              if (saved.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                    icon: Icons.bookmark_border_rounded,
                    title: 'Belum ada simpanan',
                    subtitle:
                        'Ketuk ikon bookmark pada halaman detail untuk menyimpan anime favoritmu di sini.',
                  ),
                )
              else
                SliverAnimeGrid(
                  items: [for (final s in saved) s.toAnime()],
                  heroPrefix: 'l-',
                  onTap: (anime) {
                    HistoryStore.instance.touch(anime);
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => DetailScreen(
                          anime: anime,
                          heroTag: 'l-${anime.id}',
                        ),
                      ),
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}

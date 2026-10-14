import 'package:flutter/material.dart';

/// Membersihkan sinopsis AniList yang mengandung tag HTML.
/// `<br>` menjadi baris baru, tag lain dibuang, entitas umum didekode.
String cleanSynopsis(String? html) {
  if (html == null || html.trim().isEmpty) {
    return 'Sinopsis belum tersedia.';
  }
  var s = html.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
  s = s.replaceAll(RegExp(r'<[^>]*>'), '');
  const entities = {
    '&amp;': '&',
    '&lt;': '<',
    '&gt;': '>',
    '&quot;': '"',
    '&#039;': "'",
    '&#39;': "'",
    '&nbsp;': ' ',
    '&mdash;': '—',
    '&ndash;': '–',
  };
  entities.forEach((k, v) => s = s.replaceAll(k, v));
  s = s.replaceAll(RegExp(r'[ \t]+'), ' ');
  s = s.replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
  return s.isEmpty ? 'Sinopsis belum tersedia.' : s;
}

/// Model anime untuk tampilan. Dibangun dari JSON AniList
/// atau dari simpanan lokal (favorit / riwayat).
@immutable
class Anime {
  const Anime({
    required this.id,
    required this.title,
    this.genres = const [],
    this.rating = 0,
    this.year = 0,
    this.episodes = 0,
    this.synopsis = '',
    this.hue = 250,
    this.progress = 0,
    this.currentEpisode = 0,
    this.badge = '',
    this.posterUrl,
    this.bannerUrl,
    this.streamingEpisodes = const [],
    this.externalLinks = const [],
  });

  final int id;
  final String title;
  final List<String> genres;
  final double rating;
  final int year;
  final int episodes;
  final String synopsis;

  /// Rona (0-360) untuk seni gradien cadangan saat gambar gagal dimuat.
  final double hue;

  /// Progress tontonan 0..1 (dipakai kartu "Lanjutkan").
  final double progress;
  final int currentEpisode;
  final String badge;
  final String? posterUrl;
  final String? bannerUrl;

  /// Tautan tonton legal (hanya dari query detail).
  final List<StreamingEpisode> streamingEpisodes;

  /// Tautan situs resmi (hanya dari query detail).
  final List<ExternalLink> externalLinks;

  /// Judul tampil: english, fallback romaji (aturan tampilan).
  static String displayTitle(Map<String, dynamic>? titleMap) {
    final eng = (titleMap?['english'] as String?)?.trim();
    if (eng != null && eng.isNotEmpty) return eng;
    final rom = (titleMap?['romaji'] as String?)?.trim();
    if (rom != null && rom.isNotEmpty) return rom;
    return 'Tanpa judul';
  }

  factory Anime.fromMediaJson(Map<String, dynamic> json) {
    final cover = (json['coverImage'] as Map?) ?? {};
    final startDate = (json['startDate'] as Map?) ?? {};
    var year = (json['seasonYear'] as num?)?.toInt() ?? 0;
    if (year == 0) year = (startDate['year'] as num?)?.toInt() ?? 0;
    final id = (json['id'] as num).toInt();
    final streams = (json['streamingEpisodes'] as List?) ?? [];
    final links = (json['externalLinks'] as List?) ?? [];
    return Anime(
      id: id,
      title: displayTitle((json['title'] as Map?)?.cast<String, dynamic>()),
      genres: ((json['genres'] as List?) ?? [])
          .map((e) => e.toString())
          .toList(),
      rating: ((json['averageScore'] as num?) ?? 0) / 10,
      year: year,
      episodes: (json['episodes'] as num?)?.toInt() ?? 0,
      synopsis: cleanSynopsis(json['description'] as String?),
      hue: (id * 47) % 360,
      posterUrl: (cover['extraLarge'] ?? cover['large']) as String?,
      bannerUrl: json['bannerImage'] as String?,
      streamingEpisodes: streams
          .whereType<Map>()
          .map((e) => StreamingEpisode.fromJson(e.cast<String, dynamic>()))
          .where((e) => e.url.isNotEmpty)
          .toList(),
      externalLinks: links
          .whereType<Map>()
          .map((e) => ExternalLink.fromJson(e.cast<String, dynamic>()))
          .where((e) => e.url.isNotEmpty)
          .toList(),
    );
  }

  String get metaLine {
    final parts = <String>[
      year > 0 ? '$year' : '–',
      episodes > 0 ? '$episodes Episode' : 'Episode ?',
      if (genres.isNotEmpty) genres.first,
    ];
    return parts.join(' • ');
  }

  /// Varian ringkas untuk ruang sempit (kartu poster grid).
  String get metaShort {
    final y = year > 0 ? '$year' : '–';
    return genres.isNotEmpty ? '$y • ${genres.first}' : y;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'genres': genres,
        'rating': rating,
        'year': year,
        'episodes': episodes,
        'hue': hue,
        'episode': currentEpisode,
        'progress': progress,
        'posterUrl': posterUrl,
        'bannerUrl': bannerUrl,
      };

  factory Anime.fromJson(Map<String, dynamic> json) => Anime(
        id: (json['id'] as num).toInt(),
        title: (json['title'] as String?) ?? 'Tanpa judul',
        genres: ((json['genres'] as List?) ?? [])
            .map((e) => e.toString())
            .toList(),
        rating: ((json['rating'] as num?) ?? 0).toDouble(),
        year: (json['year'] as num?)?.toInt() ?? 0,
        episodes: (json['episodes'] as num?)?.toInt() ?? 0,
        hue: ((json['hue'] as num?) ?? 250).toDouble(),
        currentEpisode: (json['episode'] as num?)?.toInt() ?? 0,
        progress: ((json['progress'] as num?) ?? 0).toDouble(),
        posterUrl: json['posterUrl'] as String?,
        bannerUrl: json['bannerUrl'] as String?,
      );
}

/// Satu tautan tonton legal dari AniList (`streamingEpisodes`).
@immutable
class StreamingEpisode {
  const StreamingEpisode({
    required this.title,
    required this.url,
    this.thumbnail,
    this.site,
  });

  final String title;
  final String url;
  final String? thumbnail;
  final String? site;

  factory StreamingEpisode.fromJson(Map<String, dynamic> json) {
    return StreamingEpisode(
      title: (json['title'] as String?)?.trim().isNotEmpty == true
          ? (json['title'] as String).trim()
          : 'Tonton',
      url: (json['url'] as String? ?? '').trim(),
      thumbnail: json['thumbnail'] as String?,
      site: (json['site'] as String?)?.trim(),
    );
  }
}

/// Satu tautan eksternal resmi (`externalLinks`: situs resmi, dsb).
@immutable
class ExternalLink {
  const ExternalLink({required this.url, this.site});

  final String url;
  final String? site;

  factory ExternalLink.fromJson(Map<String, dynamic> json) {
    return ExternalLink(
      url: (json['url'] as String? ?? '').trim(),
      site: (json['site'] as String?)?.trim(),
    );
  }
}

/// Satu entri favorit permanen (id + judul + poster).
@immutable
class FavoriteItem {
  const FavoriteItem({
    required this.id,
    required this.title,
    this.posterUrl,
    required this.savedAt,
  });

  final int id;
  final String title;
  final String? posterUrl;
  final int savedAt;

  Anime toAnime() => Anime(
        id: id,
        title: title,
        posterUrl: posterUrl,
        hue: (id * 47) % 360,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'posterUrl': posterUrl,
        'savedAt': savedAt,
      };

  factory FavoriteItem.fromJson(Map<String, dynamic> json) => FavoriteItem(
        id: (json['id'] as num).toInt(),
        title: (json['title'] as String?) ?? 'Tanpa judul',
        posterUrl: json['posterUrl'] as String?,
        savedAt: (json['savedAt'] as num?)?.toInt() ?? 0,
      );
}

/// Satu entri riwayat "Lanjutkan Menonton".
@immutable
class HistoryEntry {
  const HistoryEntry({
    required this.id,
    required this.title,
    this.posterUrl,
    this.episode = 1,
    this.progress = 0,
    required this.updatedAt,
  });

  final int id;
  final String title;
  final String? posterUrl;
  final int episode;
  final double progress;
  final int updatedAt;

  Anime toAnime() => Anime(
        id: id,
        title: title,
        posterUrl: posterUrl,
        hue: (id * 47) % 360,
        currentEpisode: episode,
        progress: progress,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'posterUrl': posterUrl,
        'episode': episode,
        'progress': progress,
        'updatedAt': updatedAt,
      };

  factory HistoryEntry.fromJson(Map<String, dynamic> json) => HistoryEntry(
        id: (json['id'] as num).toInt(),
        title: (json['title'] as String?) ?? 'Tanpa judul',
        posterUrl: json['posterUrl'] as String?,
        episode: (json['episode'] as num?)?.toInt() ?? 1,
        progress: ((json['progress'] as num?) ?? 0).toDouble(),
        updatedAt: (json['updatedAt'] as num?)?.toInt() ?? 0,
      );
}

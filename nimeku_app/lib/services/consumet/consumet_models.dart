// Kerangka klien untuk API yang kompatibel Consumet (self-hosted).
//
// Prinsip: framework ini TIDAK membundel endpoint / provider apa pun.
// Pengguna wajib mengisi URL instans miliknya sendiri di Pengaturan;
// selama kosong, seluruh fitur streaming NONAKTIF dan aplikasi
// berperilaku persis seperti sebelumnya (dialog "Pemutar belum tersedia").
//
// Bentuk respons yang didukung (defensif: field tak dikenal diabaikan):
//   GET {base}/meta/anilist/search/{q}?provider={p}
//     -> { "results": [{ "id", "title", "image", ... }] }
//   GET {base}/meta/anilist/info/{id}?provider={p}
//     -> { "id", "title", "image", "description",
//          "episodes": [{ "id", "number", "title", "image" }] }
//   GET {base}/meta/anilist/watch/{episodeId}?provider={p}
//     -> { "sources": [{ "url", "quality", "isM3U8" }],
//          "subtitles": [{ "url", "lang" }] }

/// Satu hasil pencarian Consumet.
class ConsumetSearchResult {
  const ConsumetSearchResult({
    required this.id,
    required this.title,
    this.image,
  });

  final String id;
  final String title;
  final String? image;

  /// `title` Consumet bisa string polos atau map {english, romaji}.
  static String parseTitle(dynamic raw) {
    if (raw is String && raw.trim().isNotEmpty) return raw.trim();
    if (raw is Map) {
      final eng = (raw['english'] as String?)?.trim();
      if (eng != null && eng.isNotEmpty) return eng;
      final rom = (raw['romaji'] as String?)?.trim();
      if (rom != null && rom.isNotEmpty) return rom;
    }
    return 'Tanpa judul';
  }

  factory ConsumetSearchResult.fromJson(Map<String, dynamic> json) {
    return ConsumetSearchResult(
      id: (json['id']?.toString() ?? '').trim(),
      title: parseTitle(json['title']),
      image: json['image'] as String?,
    );
  }
}

/// Satu episode menurut Consumet (`id`-nya dipakai untuk watch).
class ConsumetEpisode {
  const ConsumetEpisode({
    required this.id,
    required this.number,
    this.title,
    this.image,
  });

  final String id;
  final double number;
  final String? title;
  final String? image;

  factory ConsumetEpisode.fromJson(Map<String, dynamic> json) {
    return ConsumetEpisode(
      id: (json['id']?.toString() ?? '').trim(),
      number: ((json['number'] as num?) ?? 0).toDouble(),
      title: (json['title'] as String?)?.trim(),
      image: json['image'] as String?,
    );
  }
}

/// Satu sumber video (biasanya HLS .m3u8 + beberapa kualitas).
class ConsumetVideoSource {
  const ConsumetVideoSource({
    required this.url,
    this.quality,
    this.isM3U8 = false,
  });

  final String url;
  final String? quality;
  final bool isM3U8;

  factory ConsumetVideoSource.fromJson(Map<String, dynamic> json) {
    return ConsumetVideoSource(
      url: (json['url'] as String? ?? '').trim(),
      quality: json['quality'] as String?,
      isM3U8: (json['isM3U8'] as bool?) ?? false,
    );
  }
}

/// Satu trek subtitle.
class ConsumetSubtitle {
  const ConsumetSubtitle({required this.url, this.lang});

  final String url;
  final String? lang;

  factory ConsumetSubtitle.fromJson(Map<String, dynamic> json) {
    return ConsumetSubtitle(
      url: (json['url'] as String? ?? '').trim(),
      lang: json['lang'] as String?,
    );
  }
}

/// Hasil info anime: metadata + daftar episode.
class ConsumetAnimeInfo {
  const ConsumetAnimeInfo({
    required this.id,
    required this.title,
    this.image,
    this.description = '',
    this.episodes = const [],
  });

  final String id;
  final String title;
  final String? image;
  final String description;
  final List<ConsumetEpisode> episodes;

  factory ConsumetAnimeInfo.fromJson(Map<String, dynamic> json) {
    final eps = (json['episodes'] as List?) ?? [];
    return ConsumetAnimeInfo(
      id: (json['id']?.toString() ?? '').trim(),
      title: ConsumetSearchResult.parseTitle(json['title']),
      image: json['image'] as String?,
      description: (json['description'] as String?) ?? '',
      episodes: eps
          .whereType<Map>()
          .map((e) => ConsumetEpisode.fromJson(e.cast<String, dynamic>()))
          .where((e) => e.id.isNotEmpty)
          .toList(),
    );
  }
}

/// Hasil watch: daftar sumber video + subtitle.
class ConsumetWatchResult {
  const ConsumetWatchResult({
    this.sources = const [],
    this.subtitles = const [],
  });

  final List<ConsumetVideoSource> sources;
  final List<ConsumetSubtitle> subtitles;

  factory ConsumetWatchResult.fromJson(Map<String, dynamic> json) {
    final src = (json['sources'] as List?) ?? [];
    final sub = (json['subtitles'] as List?) ?? [];
    return ConsumetWatchResult(
      sources: src
          .whereType<Map>()
          .map((e) => ConsumetVideoSource.fromJson(e.cast<String, dynamic>()))
          .where((e) => e.url.isNotEmpty)
          .toList(),
      subtitles: sub
          .whereType<Map>()
          .map((e) => ConsumetSubtitle.fromJson(e.cast<String, dynamic>()))
          .where((e) => e.url.isNotEmpty)
          .toList(),
    );
  }
}

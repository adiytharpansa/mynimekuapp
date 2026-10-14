import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/anime.dart';

/// Galat jaringan/API yang pesannya aman ditampilkan ke pengguna.
class AniListException implements Exception {
  AniListException(this.message);

  final String message;

  @override
  String toString() => 'AniListException: $message';
}

class _CacheEntry {
  _CacheEntry(this.data, this.at);

  final Map<String, dynamic> data;
  final DateTime at;
}

/// Klien AniList GraphQL (POST, tanpa API key) dengan cache memori.
/// Semua galat jaringan diubah menjadi [AniListException] agar UI
/// tidak pernah crash saat offline.
class AniListService {
  AniListService({http.Client? client, this.timeout = const Duration(seconds: 12)})
      : _client = client ?? http.Client();

  static const String endpoint = 'https://graphql.anilist.co';
  static const Duration listTtl = Duration(minutes: 10);
  static const Duration detailTtl = Duration(minutes: 30);

  final http.Client _client;
  final Duration timeout;
  final Map<String, _CacheEntry> _cache = {};

  static const _mediaFields = '''
    id
    title { romaji english }
    description
    genres
    averageScore
    episodes
    seasonYear
    startDate { year }
    coverImage { extraLarge large }
    bannerImage
    streamingEpisodes { title thumbnail url site }
    externalLinks { url site }
  ''';

  Future<Map<String, dynamic>> _post(
    String cacheKey,
    String query,
    Map<String, dynamic> variables,
    Duration ttl,
  ) async {
    final now = DateTime.now();
    final hit = _cache[cacheKey];
    if (hit != null && now.difference(hit.at) < ttl) {
      return hit.data;
    }
    http.Response res;
    try {
      res = await _client
          .post(
            Uri.parse(endpoint),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'query': query, 'variables': variables}),
          )
          .timeout(timeout);
    } on SocketException {
      throw AniListException(
        'Tidak ada koneksi internet. Periksa jaringan lalu coba lagi.',
      );
    } on TimeoutException {
      throw AniListException(
        'Permintaan ke AniList habis. Coba lagi.',
      );
    } on http.ClientException catch (e) {
      throw AniListException('Jaringan bermasalah (${e.message}). Coba lagi.');
    }
    if (res.statusCode == 429) {
      throw AniListException(
        'Terlalu banyak permintaan. Tunggu sebentar lalu coba lagi.',
      );
    }
    if (res.statusCode != 200) {
      throw AniListException(
        'Server AniList menjawab ${res.statusCode}. Coba lagi.',
      );
    }
    Map<String, dynamic> body;
    try {
      body = jsonDecode(res.body) as Map<String, dynamic>;
    } on FormatException {
      throw AniListException('Respons server tidak valid. Coba lagi.');
    }
    final errors = body['errors'];
    if (errors is List && errors.isNotEmpty) {
      final first = errors.first;
      final msg = first is Map
          ? (first['message']?.toString() ?? 'Query tidak valid.')
          : 'Query tidak valid.';
      throw AniListException(msg);
    }
    _cache[cacheKey] = _CacheEntry(body, now);
    return body;
  }

  List<Anime> _parsePage(Map<String, dynamic> body) {
    try {
      final data = body['data'] as Map<String, dynamic>?;
      final page = data?['Page'] as Map<String, dynamic>?;
      final media = (page?['media'] as List?) ?? [];
      return media
          .whereType<Map>()
          .map((e) => Anime.fromMediaJson(e.cast<String, dynamic>()))
          .toList();
    } catch (_) {
      throw AniListException('Respons server tak terduga. Coba lagi.');
    }
  }

  Future<List<Anime>> _pageQuery(
    String cacheKey,
    String query,
    Map<String, dynamic> variables,
    Duration ttl,
  ) async {
    final body = await _post(cacheKey, query, variables, ttl);
    return _parsePage(body);
  }

  /// Trending minggu ini.
  Future<List<Anime>> fetchTrending({int page = 1, int perPage = 12}) {
    return _pageQuery(
      'trending:$page:$perPage',
      'query (\$page: Int, \$perPage: Int) { Page(page: \$page, perPage: \$perPage) { media(type: ANIME, sort: TRENDING_DESC) { $_mediaFields } } }',
      {'page': page, 'perPage': perPage},
      listTtl,
    );
  }

  /// Sedang tayang (status RELEASING).
  Future<List<Anime>> fetchAiring({int page = 1, int perPage = 10}) {
    return _pageQuery(
      'airing:$page:$perPage',
      'query (\$page: Int, \$perPage: Int) { Page(page: \$page, perPage: \$perPage) { media(type: ANIME, status: RELEASING, sort: POPULARITY_DESC) { $_mediaFields } } }',
      {'page': page, 'perPage': perPage},
      listTtl,
    );
  }

  /// Rilis terbaru.
  Future<List<Anime>> fetchLatest({int page = 1, int perPage = 12}) {
    return _pageQuery(
      'latest:$page:$perPage',
      'query (\$page: Int, \$perPage: Int) { Page(page: \$page, perPage: \$perPage) { media(type: ANIME, sort: START_DATE_DESC) { $_mediaFields } } }',
      {'page': page, 'perPage': perPage},
      listTtl,
    );
  }

  /// Pencarian judul (hasil di-cache per kata kunci).
  Future<List<Anime>> searchAnime(String query, {int perPage = 18}) {
    final q = query.trim();
    return _pageQuery(
      'search:${q.toLowerCase()}:$perPage',
      'query (\$search: String, \$perPage: Int) { Page(perPage: \$perPage) { media(type: ANIME, search: \$search, sort: SEARCH_MATCH) { $_mediaFields } } }',
      {'search': q, 'perPage': perPage},
      listTtl,
    );
  }

  /// Detail satu anime.
  Future<Anime> fetchDetail(int id) async {
    final body = await _post(
      'detail:$id',
      'query (\$id: Int) { Media(id: \$id, type: ANIME) { $_mediaFields } }',
      {'id': id},
      detailTtl,
    );
    try {
      final data = body['data'] as Map<String, dynamic>?;
      final media = data?['Media'] as Map?;
      if (media == null) throw AniListException('Anime tidak ditemukan.');
      return Anime.fromMediaJson(media.cast<String, dynamic>());
    } on AniListException {
      rethrow;
    } catch (_) {
      throw AniListException('Respons server tak terduga. Coba lagi.');
    }
  }

  /// Membersihkan cache memori (dipakai dari Profil).
  void clearCache() => _cache.clear();
}

/// Instans global yang dipakai layar-layar. Di test diganti dengan
/// `AniListService(client: MockClient(...))`.
AniListService aniListService = AniListService();

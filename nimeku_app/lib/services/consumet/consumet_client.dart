import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'consumet_models.dart';

/// Galat klien streaming yang pesannya aman ditampilkan ke pengguna.
class ConsumetException implements Exception {
  ConsumetException(this.message);

  final String message;

  @override
  String toString() => 'ConsumetException: $message';
}

/// Klien HTTP untuk API yang kompatibel Consumet.
///
/// [baseUrl] dan [provider] selalu berasal dari konfigurasi pengguna
/// ([StreamingConfig]) — tidak ada nilai bawaan yang mengarah ke
/// layanan pihak ketiga mana pun.
class ConsumetClient {
  ConsumetClient({
    http.Client? client,
    this.timeout = const Duration(seconds: 12),
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final Duration timeout;

  Uri _uri(String baseUrl, String path, String provider) {
    final base = baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    if (base.isEmpty) {
      throw ConsumetException('URL instans streaming belum diisi.');
    }
    if (provider.trim().isEmpty) {
      throw ConsumetException('Provider streaming belum diisi.');
    }
    final uri = Uri.parse('$base$path');
    if (!uri.hasScheme || !uri.hasAuthority) {
      throw ConsumetException('URL instans tidak valid.');
    }
    return uri.replace(queryParameters: {'provider': provider.trim()});
  }

  Future<Map<String, dynamic>> _get(Uri uri) async {
    http.Response res;
    try {
      res = await _client
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(timeout);
    } on SocketException {
      throw ConsumetException(
        'Tidak dapat mencapai instans streaming. Periksa jaringan/URL.',
      );
    } on TimeoutException {
      throw ConsumetException('Instans streaming tidak menjawab. Coba lagi.');
    } on http.ClientException catch (e) {
      throw ConsumetException('Jaringan bermasalah (${e.message}).');
    } on FormatException {
      // Termasuk Uri.parse yang gagal.
      throw ConsumetException('URL instans tidak valid.');
    }
    if (res.statusCode != 200) {
      throw ConsumetException(
        'Instans menjawab ${res.statusCode}. Periksa URL/provider.',
      );
    }
    try {
      return jsonDecode(res.body) as Map<String, dynamic>;
    } on FormatException {
      throw ConsumetException('Respons instans tidak valid.');
    }
  }

  /// Cari anime di instans: GET /meta/anilist/search/{query}.
  Future<List<ConsumetSearchResult>> searchAnime({
    required String baseUrl,
    required String provider,
    required String query,
  }) async {
    final q = query.trim();
    if (q.isEmpty) return const [];
    final uri = _uri(
      baseUrl,
      '/meta/anilist/search/${Uri.encodeComponent(q)}',
      provider,
    );
    final body = await _get(uri);
    final results = (body['results'] as List?) ?? [];
    return results
        .whereType<Map>()
        .map((e) => ConsumetSearchResult.fromJson(e.cast<String, dynamic>()))
        .where((e) => e.id.isNotEmpty)
        .toList();
  }

  /// Info + daftar episode: GET /meta/anilist/info/{anilistId}.
  Future<ConsumetAnimeInfo> fetchInfo({
    required String baseUrl,
    required String provider,
    required int anilistId,
  }) async {
    final uri = _uri(baseUrl, '/meta/anilist/info/$anilistId', provider);
    final body = await _get(uri);
    final info = ConsumetAnimeInfo.fromJson(body);
    if (info.id.isEmpty) {
      throw ConsumetException('Anime tidak ditemukan di instans.');
    }
    return info;
  }

  /// Sumber tonton episode: GET /meta/anilist/watch/{episodeId}.
  Future<ConsumetWatchResult> fetchSources({
    required String baseUrl,
    required String provider,
    required String episodeId,
  }) async {
    if (episodeId.trim().isEmpty) {
      throw ConsumetException('ID episode tidak valid.');
    }
    final uri = _uri(
      baseUrl,
      '/meta/anilist/watch/${Uri.encodeComponent(episodeId.trim())}',
      provider,
    );
    final body = await _get(uri);
    final result = ConsumetWatchResult.fromJson(body);
    if (result.sources.isEmpty) {
      throw ConsumetException('Tidak ada sumber video untuk episode ini.');
    }
    return result;
  }
}

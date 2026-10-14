import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nimeku_app/main.dart';
import 'package:nimeku_app/models/anime.dart';
import 'package:nimeku_app/screens/detail_screen.dart';
import 'package:nimeku_app/services/anilist_service.dart';
import 'package:nimeku_app/services/consumet/consumet_client.dart';
import 'package:nimeku_app/services/consumet/consumet_models.dart';
import 'package:nimeku_app/services/consumet/streaming_config.dart';

Map<String, dynamic> cannedMedia(int id, String english) => {
      'id': id,
      'title': {'romaji': 'Romaji $id', 'english': english},
      'description':
          'Petualangan <b>seru</b> melintasi dunia.<br>Musim kedua.',
      'genres': ['Action', 'Fantasy'],
      'averageScore': 87,
      'episodes': 24,
      'seasonYear': 2023,
      'startDate': {'year': 2023},
      'coverImage': {
        'extraLarge': 'https://example.com/poster$id.jpg',
        'large': 'https://example.com/poster$id.jpg',
      },
      'bannerImage': 'https://example.com/banner$id.jpg',
      'streamingEpisodes': [
        {
          'title': 'Episode 1',
          'thumbnail': 'https://example.com/t1.jpg',
          'url': 'https://legal.example/watch/1',
          'site': 'Contoh Legal',
        },
      ],
      'externalLinks': [
        {'url': 'https://legal.example/official', 'site': 'Situs Resmi'},
      ],
    };

MockClient successClient() {
  return MockClient((http.Request request) async {
    final body = jsonDecode(request.body) as Map<String, dynamic>;
    final query = (body['query'] as String?) ?? '';
    if (query.contains('Media(')) {
      final vars = (body['variables'] as Map?) ?? {};
      final id = ((vars['id'] as num?) ?? 1).toInt();
      return http.Response(
        jsonEncode({
          'data': {'Media': cannedMedia(id, 'Canned Detail $id')}
        }),
        200,
      );
    }
    return http.Response(
      jsonEncode({
        'data': {
          'Page': {
            'media': [
              cannedMedia(101, 'Canned Anime Satu'),
              cannedMedia(102, 'Canned Anime Dua'),
              cannedMedia(103, 'Canned Anime Tiga'),
              cannedMedia(104, 'Canned Anime Empat'),
            ],
          }
        }
      }),
      200,
    );
  });
}

MockClient offlineClient() {
  return MockClient((_) async {
    throw const SocketException('no network');
  });
}

Future<void> pumpHome(WidgetTester tester) async {
  await tester.pumpWidget(const NimekuApp());
  await tester.pump(const Duration(milliseconds: 1700));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  setUp(() {
    aniListService = AniListService(client: successClient());
  });

  testWidgets('Splash lalu Beranda menampilkan data AniList',
      (WidgetTester tester) async {
    await pumpHome(tester);

    expect(find.text('NIMEKU'), findsOneWidget);
    expect(find.text('Mau nonton apa hari ini?'), findsOneWidget);
    // Data asli dari mock (bukan dummy).
    expect(find.text('Canned Anime Satu'), findsWidgets);
    await tester.dragUntilVisible(
      find.text('Trending Minggu Ini'),
      find.byType(CustomScrollView).first,
      const Offset(0, -300),
    );
    await tester.dragUntilVisible(
      find.text('Sedang Tayang'),
      find.byType(CustomScrollView).first,
      const Offset(0, -300),
    );
    expect(find.text('Sedang Tayang'), findsOneWidget);
    await tester.dragUntilVisible(
      find.text('Baru Rilis'),
      find.byType(CustomScrollView).first,
      const Offset(0, -300),
    );
    expect(find.text('Baru Rilis'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Offline menampilkan error + tombol Coba lagi tanpa crash',
      (WidgetTester tester) async {
    aniListService = AniListService(client: offlineClient());
    await pumpHome(tester);

    expect(find.text('Gagal memuat'), findsOneWidget);
    expect(find.text('Coba lagi'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Tidak overflow di layar 360px dengan font besar',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360 * 3, 740 * 3);
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });

    await pumpHome(tester);
    await tester.dragUntilVisible(
      find.text('Trending Minggu Ini'),
      find.byType(CustomScrollView).first,
      const Offset(0, -300),
    );
    expect(find.text('Mau nonton apa hari ini?'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('Sinopsis membersihkan tag HTML', () {
    expect(
      cleanSynopsis('A <b>berani</b>.<br>B baru.'),
      'A berani.\nB baru.',
    );
    expect(cleanSynopsis(null), 'Sinopsis belum tersedia.');
  });

  test('Judul memakai english, fallback romaji', () {
    expect(
      Anime.displayTitle({'english': 'Eng', 'romaji': 'Rom'}),
      'Eng',
    );
    expect(
      Anime.displayTitle({'english': '  ', 'romaji': 'Rom'}),
      'Rom',
    );
    expect(Anime.displayTitle(null), 'Tanpa judul');
  });

  test('Model Consumet mem-parsing respons defensif', () {
    final search = ConsumetSearchResult.fromJson({
      'id': 7,
      'title': {'english': ' ', 'romaji': 'Romaji Tujuh'},
      'image': 'https://example.com/i.jpg',
    });
    expect(search.id, '7');
    expect(search.title, 'Romaji Tujuh');

    final info = ConsumetAnimeInfo.fromJson({
      'id': 'abc',
      'title': 'Judul Polos',
      'episodes': [
        {'id': 'ep-1', 'number': 1, 'title': 'Awal'},
        {'id': '', 'number': 2},
      ],
    });
    expect(info.episodes.length, 1);
    expect(info.episodes.first.number, 1);

    final watch = ConsumetWatchResult.fromJson({
      'sources': [
        {'url': 'https://example.com/a.m3u8', 'quality': '720p'},
        {'url': '', 'quality': 'kosong dibuang'},
      ],
      'subtitles': [
        {'url': 'https://example.com/id.vtt', 'lang': 'Indonesia'},
      ],
    });
    expect(watch.sources.length, 1);
    expect(watch.sources.first.isM3U8, isFalse);
    expect(watch.subtitles.first.lang, 'Indonesia');
  });

  test('Klien Consumet sukses + offline tanpa crash', () async {
    final ok = ConsumetClient(
      client: MockClient((_) async {
        return http.Response(
          jsonEncode({
            'sources': [
              {'url': 'https://example.com/a.m3u8', 'quality': 'auto'}
            ],
            'subtitles': [],
          }),
          200,
        );
      }),
    );
    final result = await ok.fetchSources(
      baseUrl: 'https://instans.example',
      provider: 'contoh',
      episodeId: 'ep-1',
    );
    expect(result.sources.length, 1);

    final offline = ConsumetClient(client: offlineClient());
    expect(
      () => offline.fetchInfo(
        baseUrl: 'https://instans.example',
        provider: 'contoh',
        anilistId: 1,
      ),
      throwsA(isA<ConsumetException>()),
    );
  });

  test('Konfigurasi streaming default nonaktif', () async {    SharedPreferences.setMockInitialValues({});
    final cfg = StreamingConfig.instance;
    await cfg.init();
    expect(cfg.enabled, isFalse);
    expect(cfg.isConfigured, isFalse);
    await cfg.update(
      enabled: true,
      baseUrl: 'https://instans.example',
      provider: 'contoh',
    );
    expect(cfg.isConfigured, isTrue);
    await cfg.clear();
    expect(cfg.isConfigured, isFalse);
  });

  testWidgets('Detail menampilkan tautan tonton legal',
      (WidgetTester tester) async {
    final anime = Anime.fromMediaJson(cannedMedia(101, 'Canned Anime Satu'));
    await tester.pumpWidget(
      MaterialApp(
        home: DetailScreen(anime: anime, heroTag: 'debug-poster'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tonton Legal di'), findsOneWidget);
    expect(find.text('Contoh Legal'), findsOneWidget);
    expect(find.text('Situs Resmi'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Cari: ketik query, debounce, hasil tampil',
      (WidgetTester tester) async {
    await pumpHome(tester);
    await tester.tap(find.text('Cari'));
    await tester.pumpAndSettle();

    expect(find.text('Cari Anime'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'frieren');
    // Lewati debounce 500 ms + fetch mock.
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    expect(find.textContaining('hasil untuk'), findsOneWidget);
    expect(find.text('Canned Anime Satu'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Cari: query tak dikenal menampilkan status kosong',
      (WidgetTester tester) async {
    aniListService = AniListService(
      client: MockClient((_) async {
        return http.Response(
          jsonEncode({
            'data': {
              'Page': {'media': []}
            }
          }),
          200,
        );
      }),
    );
    await pumpHome(tester);
    await tester.tap(find.text('Cari'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'xyztidakada');
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    expect(find.text('Tidak ditemukan'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/anime.dart';

/// Favorit permanen (id + judul + poster) di shared_preferences.
/// State management: ChangeNotifier bawaan Flutter, tanpa paket tambahan.
class FavoritesStore extends ChangeNotifier {
  FavoritesStore._();

  static final FavoritesStore instance = FavoritesStore._();

  static const _prefsKey = 'nimeku_favorites_v1';

  final Map<int, FavoriteItem> _items = {};
  bool ready = false;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw != null && raw.isNotEmpty) {
        final list = jsonDecode(raw) as List;
        for (final e in list) {
          if (e is Map) {
            final item = FavoriteItem.fromJson(e.cast<String, dynamic>());
            _items[item.id] = item;
          }
        }
      }
    } catch (_) {
      // Penyimpanan korup/tak tersedia: mulai kosong, aplikasi tetap jalan.
      _items.clear();
    }
    ready = true;
    notifyListeners();
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _prefsKey,
        jsonEncode(_items.values.map((e) => e.toJson()).toList()),
      );
    } catch (_) {
      // Gagal simpan: abaikan, state memori tetap konsisten.
    }
  }

  bool contains(int id) => _items.containsKey(id);

  List<FavoriteItem> get items {
    final list = _items.values.toList()
      ..sort((a, b) => b.savedAt.compareTo(a.savedAt));
    return list;
  }

  Future<void> toggle(Anime anime) async {
    if (_items.containsKey(anime.id)) {
      _items.remove(anime.id);
    } else {
      _items[anime.id] = FavoriteItem(
        id: anime.id,
        title: anime.title,
        posterUrl: anime.posterUrl,
        savedAt: DateTime.now().millisecondsSinceEpoch,
      );
    }
    notifyListeners();
    await _save();
  }
}

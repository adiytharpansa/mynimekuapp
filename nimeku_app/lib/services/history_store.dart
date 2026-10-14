import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/anime.dart';

/// Riwayat "Lanjutkan Menonton" di shared_preferences (maks 20 terbaru).
class HistoryStore extends ChangeNotifier {
  HistoryStore._();

  static final HistoryStore instance = HistoryStore._();

  static const _prefsKey = 'nimeku_history_v1';
  static const _maxItems = 20;

  final Map<int, HistoryEntry> _items = {};
  bool ready = false;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw != null && raw.isNotEmpty) {
        final list = jsonDecode(raw) as List;
        for (final e in list) {
          if (e is Map) {
            final item = HistoryEntry.fromJson(e.cast<String, dynamic>());
            _items[item.id] = item;
          }
        }
      }
    } catch (_) {
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
      // Abaikan; state memori tetap konsisten.
    }
  }

  List<HistoryEntry> get entries {
    final list = _items.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  /// Catat anime sebagai "lanjutkan menonton" (episode default 1).
  /// Entri lama naik ke depan tanpa menimpa progres yang sudah ada.
  Future<void> touch(Anime anime, {int episode = 1}) async {
    final old = _items[anime.id];
    _items[anime.id] = HistoryEntry(
      id: anime.id,
      title: anime.title,
      posterUrl: anime.posterUrl,
      episode: old?.episode ?? episode,
      progress: old?.progress ?? 0,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    while (_items.length > _maxItems) {
      final oldest = entries.last;
      _items.remove(oldest.id);
    }
    notifyListeners();
    await _save();
  }
}

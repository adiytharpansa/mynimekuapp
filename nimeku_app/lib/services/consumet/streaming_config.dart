import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Konfigurasi sumber streaming milik pengguna (self-hosted).
///
/// Default: NONAKTIF dan kosong. Aplikasi tidak menghubungi server
/// streaming mana pun sampai pengguna eksplisit mengisi URL instans
/// + provider dan mengaktifkannya di Profil.
class StreamingConfig extends ChangeNotifier {
  StreamingConfig._();

  static final StreamingConfig instance = StreamingConfig._();

  static const _kEnabled = 'nimeku_stream_enabled_v1';
  static const _kBaseUrl = 'nimeku_stream_baseurl_v1';
  static const _kProvider = 'nimeku_stream_provider_v1';

  bool enabled = false;
  String baseUrl = '';
  String provider = '';
  bool ready = false;

  /// True hanya bila diaktifkan DAN URL + provider terisi.
  bool get isConfigured =>
      enabled && baseUrl.trim().isNotEmpty && provider.trim().isNotEmpty;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      enabled = prefs.getBool(_kEnabled) ?? false;
      baseUrl = prefs.getString(_kBaseUrl) ?? '';
      provider = prefs.getString(_kProvider) ?? '';
    } catch (_) {
      enabled = false;
      baseUrl = '';
      provider = '';
    }
    ready = true;
    notifyListeners();
  }

  Future<void> update({
    bool? enabled,
    String? baseUrl,
    String? provider,
  }) async {
    if (enabled != null) this.enabled = enabled;
    if (baseUrl != null) this.baseUrl = baseUrl.trim();
    if (provider != null) this.provider = provider.trim();
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kEnabled, this.enabled);
      await prefs.setString(_kBaseUrl, this.baseUrl);
      await prefs.setString(_kProvider, this.provider);
    } catch (_) {
      // Abaikan; state memori tetap konsisten.
    }
  }

  Future<void> clear() async {
    await update(enabled: false, baseUrl: '', provider: '');
  }
}

import 'package:flutter/material.dart';

import '../main.dart';
import '../services/anilist_service.dart';
import '../services/consumet/streaming_config.dart';
import '../theme.dart';

/// Profil: ringkasan pengguna, statistik, dan pengaturan tema.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? NimekuColors.textPrimary : NimekuColors.lightTextPrimary;
    final textSecondary =
        isDark ? NimekuColors.textSecondary : NimekuColors.lightTextSecondary;
    final cardColor = isDark ? NimekuColors.surface : NimekuColors.lightSurface;

    Widget stat(String value, String label) {
      return Expanded(
        child: Column(
          children: [
            Text(
              value,
              style: NimekuType.sectionTitle.copyWith(color: textPrimary),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: NimekuType.caption.copyWith(color: textSecondary),
            ),
          ],
        ),
      );
    }

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(NimekuSpacing.page),
        children: [
          Text(
            'Profil',
            style: NimekuType.screenTitle.copyWith(color: textPrimary),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(NimekuRadii.card),
              boxShadow: NimekuTheme.cardShadow,
            ),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: NimekuColors.buttonGradient,
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'W',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Wibu Sejati',
                        style: NimekuType.sectionTitle.copyWith(
                          color: textPrimary,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'wibu@nimeku.app',
                        style: NimekuType.caption.copyWith(
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(NimekuRadii.card),
              boxShadow: NimekuTheme.cardShadow,
            ),
            child: Row(
              children: [
                stat('128', 'Ditonton'),
                stat('24', 'Disimpan'),
                stat('36', 'Jam'),
              ],
            ),
          ),
          const SizedBox(height: NimekuSpacing.section),
          Text(
            'Pengaturan',
            style: NimekuType.sectionTitle.copyWith(color: textPrimary),
          ),
          const SizedBox(height: 8),
          Card(
            child: SwitchListTile(
              value: isDark,
              onChanged: (_) => toggleAppTheme(),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(NimekuRadii.card),
              ),
              secondary: Icon(
                isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                color: NimekuColors.rating,
              ),
              title: Text(
                'Mode gelap',
                style: NimekuType.body.copyWith(
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              subtitle: Text(
                isDark ? 'Sinematik, nyaman malam hari' : 'Terang dan rapi',
                style: NimekuType.caption.copyWith(color: textSecondary),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(NimekuRadii.card),
              ),
              leading: const Icon(
                Icons.cached_rounded,
                color: NimekuColors.primary,
              ),
              title: Text(
                'Hapus cache API',
                style: NimekuType.body.copyWith(
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              subtitle: Text(
                'Hapus data sementara AniList di memori',
                style: NimekuType.caption.copyWith(color: textSecondary),
              ),
              onTap: () {
                aniListService.clearCache();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cache API dihapus.')),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          const _StreamingCard(),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(NimekuRadii.card),
              ),
              leading: const Icon(
                Icons.info_outline_rounded,
                color: NimekuColors.primary,
              ),
              title: Text(
                'Tentang Nimeku',
                style: NimekuType.body.copyWith(
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              subtitle: Text(
                'Data oleh AniList • Versi 2.0.0',
                style: NimekuType.caption.copyWith(color: textSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Kartu pengaturan sumber streaming milik pengguna (self-hosted).
/// Default nonaktif: aplikasi tidak menghubungi server mana pun
/// sampai URL + provider diisi dan sakelar dinyalakan.
class _StreamingCard extends StatefulWidget {
  const _StreamingCard();

  @override
  State<_StreamingCard> createState() => _StreamingCardState();
}

class _StreamingCardState extends State<_StreamingCard> {
  late final TextEditingController _urlController;
  late final TextEditingController _providerController;

  @override
  void initState() {
    super.initState();
    final cfg = StreamingConfig.instance;
    _urlController = TextEditingController(text: cfg.baseUrl);
    _providerController = TextEditingController(text: cfg.provider);
  }

  @override
  void dispose() {
    _urlController.dispose();
    _providerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? NimekuColors.textPrimary : NimekuColors.lightTextPrimary;
    final textSecondary =
        isDark ? NimekuColors.textSecondary : NimekuColors.lightTextSecondary;
    return ListenableBuilder(
      listenable: StreamingConfig.instance,
      builder: (context, _) {
        final cfg = StreamingConfig.instance;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.dns_rounded,
                      color: NimekuColors.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Sumber streaming (opsional)',
                        style: NimekuType.body.copyWith(
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                    ),
                    Switch(
                      value: cfg.enabled,
                      onChanged: (v) => cfg.update(enabled: v),
                    ),
                  ],
                ),
                Text(
                  'Isi dengan URL instans kompatibel-Consumet milikmu '
                  'sendiri. Kosong = nonaktif.',
                  style:
                      NimekuType.caption.copyWith(color: textSecondary),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _urlController,
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.next,
                  onChanged: (v) => cfg.update(baseUrl: v),
                  style: NimekuType.body.copyWith(color: textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'https://instans-milikmu.example',
                    labelText: 'URL instans',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _providerController,
                  textInputAction: TextInputAction.done,
                  onChanged: (v) => cfg.update(provider: v),
                  style: NimekuType.body.copyWith(color: textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'nama-provider',
                    labelText: 'Provider',
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

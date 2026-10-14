import 'package:flutter/material.dart';

import 'screens/splash_screen.dart';
import 'services/consumet/streaming_config.dart';
import 'services/favorites_store.dart';
import 'services/history_store.dart';
import 'theme.dart';

/// Satu-satunya state global tema: gelap sinematik atau terang rapi.
final ValueNotifier<ThemeMode> appThemeMode = ValueNotifier(ThemeMode.dark);

void toggleAppTheme() {
  appThemeMode.value =
      appThemeMode.value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Muat simpanan lokal sebelum UI pertama tampil (anti-crash bila gagal).
  await Future.wait([
    FavoritesStore.instance.init(),
    HistoryStore.instance.init(),
    StreamingConfig.instance.init(),
  ]);
  runApp(const NimekuApp());
}

/// Akar aplikasi Nimeku — tema dikendalikan oleh [appThemeMode].
class NimekuApp extends StatelessWidget {
  const NimekuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: appThemeMode,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'Nimeku',
          debugShowCheckedModeBanner: false,
          theme: NimekuTheme.light(),
          darkTheme: NimekuTheme.dark(),
          themeMode: mode,
          home: const SplashScreen(),
        );
      },
    );
  }
}

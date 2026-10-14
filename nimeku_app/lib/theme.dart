import 'package:flutter/material.dart';

/// Warna merek Nimeku.
abstract final class NimekuColors {
  // Latar & permukaan (mode gelap sinematik)
  static const background = Color(0xFF0E0F17);
  static const surface = Color(0xFF151622);
  static const surfaceHigh = Color(0xFF1D1E2E);

  // Aksen
  static const primary = Color(0xFF8B5CF6);
  static const secondary = Color(0xFFEC4899);
  static const rating = Color(0xFFFBBF24);

  // Teks di atas latar gelap (lolos WCAG AA)
  static const textPrimary = Color(0xFFF4F4F8);
  static const textSecondary = Color(0xFFB9BCCF);

  // Varian terang
  static const lightBackground = Color(0xFFF6F6FA);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceHigh = Color(0xFFEDEDF4);
  static const lightTextPrimary = Color(0xFF14141C);
  static const lightTextSecondary = Color(0xFF4E5165);

  /// Gradien merek untuk elemen penting (logo, avatar, angka episode).
  static const buttonGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [primary, secondary],
  );

  /// Lapisan bawah banner agar teks terbaca (transparan ke hitam 65%).
  static final bannerShade = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.65)],
    stops: const [0.3, 1],
  );
}

/// Radius sudut konsisten.
abstract final class NimekuRadii {
  static const card = 16.0;
  static const banner = 24.0;
  static const chip = 20.0;
  static const button = 14.0;
}

/// Spacing grid 4/8: margin halaman 20, jarak antar bagian 24.
abstract final class NimekuSpacing {
  static const page = 20.0;
  static const section = 24.0;
  static const cardGap = 12.0;
}

/// Skala tipografi.
abstract final class NimekuType {
  static const screenTitle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.25,
  );
  static const bannerTitle = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w800,
    height: 1.25,
  );
  static const sectionTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );
  static const body = TextStyle(fontSize: 14, height: 1.5);
  static const bannerInfo = TextStyle(fontSize: 13, height: 1.4);
  static const caption = TextStyle(fontSize: 12, height: 1.4);
}

abstract final class NimekuTheme {
  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: NimekuColors.primary,
      brightness: Brightness.dark,
    ).copyWith(
      primary: NimekuColors.primary,
      secondary: NimekuColors.secondary,
      tertiary: NimekuColors.rating,
      surface: NimekuColors.surface,
      surfaceContainerHighest: NimekuColors.surfaceHigh,
    );
    return _base(scheme, true);
  }

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: NimekuColors.primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: const Color(0xFF7C3AED),
      secondary: const Color(0xFFDB2777),
      tertiary: const Color(0xFFB45309),
      surface: NimekuColors.lightSurface,
      surfaceContainerHighest: NimekuColors.lightSurfaceHigh,
    );
    return _base(scheme, false);
  }

  static ThemeData _base(ColorScheme scheme, bool isDark) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor:
          isDark ? NimekuColors.background : NimekuColors.lightBackground,
      appBarTheme: AppBarTheme(
        backgroundColor:
            isDark ? NimekuColors.background : NimekuColors.lightBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: NimekuType.screenTitle.copyWith(
          color:
              isDark ? NimekuColors.textPrimary : NimekuColors.lightTextPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: isDark ? NimekuColors.surface : NimekuColors.lightSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NimekuRadii.card),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NimekuRadii.chip),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        labelStyle: NimekuType.caption.copyWith(fontWeight: FontWeight.w600),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(NimekuRadii.button),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(NimekuRadii.button),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor:
            isDark ? NimekuColors.surfaceHigh : NimekuColors.lightSurfaceHigh,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NimekuRadii.button),
          borderSide: BorderSide.none,
        ),
        hintStyle: NimekuType.body.copyWith(
          color: isDark
              ? NimekuColors.textSecondary
              : NimekuColors.lightTextSecondary,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor:
            isDark ? NimekuColors.surface : NimekuColors.lightSurface,
        indicatorColor: NimekuColors.primary.withValues(alpha: 0.18),
        labelTextStyle: WidgetStatePropertyAll(
          NimekuType.caption.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        linearMinHeight: 4,
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
    );
  }

  /// Bayangan lembut kartu (tanpa garis tepi tebal).
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.35),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ];
}

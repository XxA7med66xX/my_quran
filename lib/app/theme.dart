import 'package:flutter/material.dart';
import 'package:my_quran/app/models.dart';

const _seedColor = Color(0xFF0F766E);

({ThemeData theme, ThemeData? darkTheme}) buildThemes(
  AppTheme appTheme, {
  ThemeMode themeMode = ThemeMode.system,
  ColorScheme? deviceLightScheme,
  ColorScheme? deviceDarkScheme,
}) {
  return switch (appTheme) {
    AppTheme.myQuran => switch (themeMode) {
      ThemeMode.light => (theme: _buildMyQuranLight(), darkTheme: null),
      ThemeMode.dark => (theme: _buildMyQuranDark(), darkTheme: null),

      ThemeMode.system => (
        theme: _buildMyQuranLight(),
        darkTheme: _buildMyQuranDark(),
      ),
    },
    AppTheme.sepia => switch (themeMode) {
      ThemeMode.light => (theme: _buildSepiaLight(), darkTheme: null),
      ThemeMode.dark => (theme: _buildSepiaDark(), darkTheme: null),
      ThemeMode.system => (
        theme: _buildSepiaLight(),
        darkTheme: _buildSepiaDark(),
      ),
    },
    AppTheme.dynamic => switch (themeMode) {
      ThemeMode.light => (
        theme: _buildDynamicLight(deviceLightScheme),
        darkTheme: null,
      ),
      ThemeMode.dark => (
        theme: _buildDynamicDark(deviceDarkScheme),
        darkTheme: null,
      ),
      ThemeMode.system => (
        theme: _buildDynamicLight(deviceLightScheme),
        darkTheme: _buildDynamicDark(deviceDarkScheme),
      ),
    },
  };
}

ThemeData _buildMyQuranLight() {
  final colorScheme = ColorScheme.fromSeed(seedColor: _seedColor).copyWith(
    surface: const Color(0xFFFAFDFC),
    onSurface: const Color(0xFF0D1211),
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: colorScheme.surface,
  );
}

ThemeData _buildMyQuranDark() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: _seedColor,
    brightness: Brightness.dark,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: colorScheme.surface,
  );
}

ThemeData _buildDynamicLight(ColorScheme? deviceScheme) {
  final colorScheme =
      deviceScheme ?? ColorScheme.fromSeed(seedColor: Colors.blue);
  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: colorScheme.surface,
  );
}

ThemeData _buildDynamicDark(ColorScheme? deviceScheme) {
  final colorScheme =
      deviceScheme ??
      ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark);
  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: colorScheme.surface,
  );
}

const _sepiaSeed = Color(0xFF7A5A3A);

// Light sepia surfaces (paper-like)
const _sepiaLightSurface = Color(0xFFF7F0E6);
const _sepiaLightOnSurface = Color(0xFF1A1410);

// Dark sepia surfaces (warm dark)
const _sepiaDarkSurface = Color(0xFF17110D);
const _sepiaDarkOnSurface = Color(0xFFF2E7DA);

ThemeData _buildSepiaLight() {
  final base = ColorScheme.fromSeed(seedColor: _sepiaSeed);

  final colorScheme = base.copyWith(
    surface: _sepiaLightSurface,
    onSurface: _sepiaLightOnSurface,

    // These help many Material3 widgets look cohesive on sepia backgrounds
    surfaceContainerLowest: const Color(0xFFFBF6EF),
    surfaceContainerLow: const Color(0xFFF4EBDD),
    surfaceContainer: const Color(0xFFF1E7DA),
    surfaceContainerHigh: const Color(0xFFEADCCE),
    surfaceContainerHighest: const Color(0xFFE2D1C2),

    outline: const Color(0xFFB8A999),
    outlineVariant: const Color(0xFFD7C7B7),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: colorScheme.surface,
  );
}

ThemeData _buildSepiaDark() {
  final base = ColorScheme.fromSeed(
    seedColor: _sepiaSeed,
    brightness: Brightness.dark,
  );

  final colorScheme = base.copyWith(
    surface: _sepiaDarkSurface,
    onSurface: _sepiaDarkOnSurface,

    surfaceContainerLowest: const Color(0xFF120D0A),
    surfaceContainerLow: const Color(0xFF1B1410),
    surfaceContainer: const Color(0xFF211813),
    surfaceContainerHigh: const Color(0xFF2A1F19),
    surfaceContainerHighest: const Color(0xFF33261F),

    outline: const Color(0xFF7E6B5D),
    outlineVariant: const Color(0xFF5D4C41),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: colorScheme.surface,
  );
}

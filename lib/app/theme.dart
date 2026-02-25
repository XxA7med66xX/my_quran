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

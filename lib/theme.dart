import 'dart:convert';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';

class ThemeConfig {
  final String themeName;
  final Color obsidianBackground;
  final Color darkCardSurface;
  final Color acrylicNavigationHeader;
  final Color borderOutline;
  
  final Color accent;
  final Color onAccent;
  
  final Color accentSecondary;
  final Color onAccentSecondary;
  
  final Color textPrimary;
  final Color textSecondary;
  
  final Color warningYellow;
  final Color onWarningYellow;
  
  final Color dangerRed;
  final Color onDangerRed;
  
  final Color successGreen;
  final Color onSuccessGreen;

  const ThemeConfig({
    required this.themeName,
    required this.obsidianBackground,
    required this.darkCardSurface,
    required this.acrylicNavigationHeader,
    required this.borderOutline,
    required this.accent,
    required this.onAccent,
    required this.accentSecondary,
    required this.onAccentSecondary,
    required this.textPrimary,
    required this.textSecondary,
    required this.warningYellow,
    required this.onWarningYellow,
    required this.dangerRed,
    required this.onDangerRed,
    required this.successGreen,
    required this.onSuccessGreen,
  });

  static Color _parseHexColor(String hex, Color fallback) {
    try {
      final buffer = StringBuffer();
      if (hex.length == 6 || hex.length == 7) {
        buffer.write('ff');
        buffer.write(hex.replaceFirst('#', ''));
        return Color(int.parse(buffer.toString(), radix: 16));
      } else if (hex.length == 9) {
        buffer.write(hex.replaceFirst('#', ''));
        return Color(int.parse(buffer.toString(), radix: 16));
      }
    } catch (_) {}
    return fallback;
  }

  factory ThemeConfig.fromJson(Map<String, dynamic> json) {
    return ThemeConfig(
      themeName: json['themeName'] as String? ?? 'Metro Dark',
      obsidianBackground: _parseHexColor(json['obsidianBackground'] as String? ?? '', const Color(0xFF0F0F12)),
      darkCardSurface: _parseHexColor(json['darkCardSurface'] as String? ?? '', const Color(0xFF1A1D24)),
      acrylicNavigationHeader: _parseHexColor(json['acrylicNavigationHeader'] as String? ?? '', const Color(0xFF14161D)),
      borderOutline: _parseHexColor(json['borderOutline'] as String? ?? '', const Color(0xFF2A2E3D)),
      accent: _parseHexColor(json['accent'] as String? ?? '', const Color(0xFF0078D4)),
      onAccent: _parseHexColor(json['onAccent'] as String? ?? '', const Color(0xFFFFFFFF)),
      accentSecondary: _parseHexColor(json['accentSecondary'] as String? ?? '', const Color(0xFF3B82F6)),
      onAccentSecondary: _parseHexColor(json['onAccentSecondary'] as String? ?? '', const Color(0xFFFFFFFF)),
      textPrimary: _parseHexColor(json['textPrimary'] as String? ?? '', const Color(0xFFF8FAFC)),
      textSecondary: _parseHexColor(json['textSecondary'] as String? ?? '', const Color(0xFF94A3B8)),
      warningYellow: _parseHexColor(json['warningYellow'] as String? ?? '', const Color(0xFFF59E0B)),
      onWarningYellow: _parseHexColor(json['onWarningYellow'] as String? ?? '', const Color(0xFF000000)),
      dangerRed: _parseHexColor(json['dangerRed'] as String? ?? '', const Color(0xFFEF4444)),
      onDangerRed: _parseHexColor(json['onDangerRed'] as String? ?? '', const Color(0xFFFFFFFF)),
      successGreen: _parseHexColor(json['successGreen'] as String? ?? '', const Color(0xFF22C55E)),
      onSuccessGreen: _parseHexColor(json['onSuccessGreen'] as String? ?? '', const Color(0xFF000000)),
    );
  }

  static const ThemeConfig metroDark = ThemeConfig(
    themeName: 'Metro Dark',
    obsidianBackground: Color(0xFF0F0F12),
    darkCardSurface: Color(0xFF1A1D24),
    acrylicNavigationHeader: Color(0xFF14161D),
    borderOutline: Color(0xFF2A2E3D),
    accent: Color(0xFF0078D4),
    onAccent: Color(0xFFFFFFFF),
    accentSecondary: Color(0xFF3B82F6),
    onAccentSecondary: Color(0xFFFFFFFF),
    textPrimary: Color(0xFFF8FAFC),
    textSecondary: Color(0xFF94A3B8),
    warningYellow: Color(0xFFF59E0B),
    onWarningYellow: Color(0xFF000000),
    dangerRed: Color(0xFFEF4444),
    onDangerRed: Color(0xFFFFFFFF),
    successGreen: Color(0xFF22C55E),
    onSuccessGreen: Color(0xFF000000),
  );
}

class AppTheme {
  static ThemeConfig current = ThemeConfig.metroDark;

  static Color get obsidianBackground => current.obsidianBackground;
  static Color get darkCardSurface => current.darkCardSurface;
  static Color get acrylicNavigationHeader => current.acrylicNavigationHeader;
  static Color get borderOutline => current.borderOutline;
  
  static Color get pastelTeal => current.accent;
  static Color get onAccent => current.onAccent;
  static Color get pastelLavender => current.accentSecondary;
  static Color get onAccentSecondary => current.onAccentSecondary;
  static Color get pastelRose => current.accentSecondary;
  static Color get pastelGreen => current.successGreen;
  static Color get pastelYellow => current.warningYellow;
  static Color get onWarningYellow => current.onWarningYellow;
  static Color get pastelCoral => current.dangerRed;
  static Color get onDangerRed => current.onDangerRed;
  
  static Color get textPrimary => current.textPrimary;
  static Color get textSecondary => current.textSecondary;

  static Future<void> loadThemeFromAsset([String assetPath = 'assets/themes/metro_dark.json']) async {
    try {
      final jsonString = await rootBundle.loadString(assetPath);
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      current = ThemeConfig.fromJson(jsonMap);
    } catch (_) {
      current = ThemeConfig.metroDark;
    }
  }

  static FluentThemeData get darkTheme {
    return FluentThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: current.obsidianBackground,
      cardColor: current.darkCardSurface,
      accentColor: AccentColor.swatch({
        'normal': current.accent,
        'light': current.accent,
        'lighter': current.accentSecondary,
        'lightest': current.accentSecondary,
        'dark': current.accent,
        'darker': current.accent,
        'darkest': current.accent,
      }),
      navigationPaneTheme: NavigationPaneThemeData(
        backgroundColor: current.acrylicNavigationHeader,
        overlayBackgroundColor: current.obsidianBackground,
      ),
      typography: Typography.raw(
        body: TextStyle(color: current.textPrimary, fontSize: 13),
        caption: TextStyle(color: current.textSecondary, fontSize: 11),
        title: TextStyle(color: current.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
        subtitle: TextStyle(color: current.textPrimary, fontSize: 15, fontWeight: FontWeight.w600),
      ),
    );
  }
}

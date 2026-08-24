import 'package:fluent_ui/fluent_ui.dart';

class AppTheme {
  // Base High-Contrast Dark Surfaces
  static const Color obsidianBackground = Color(0xFF0B0D12);
  static const Color darkCardSurface = Color(0xFF12151E);
  static const Color acrylicNavigationHeader = Color(0xFF181B26);
  static const Color borderOutline = Color(0xFF242938);

  // High-Contrast Pastel Palette
  static const Color pastelTeal = Color(0xFF80E5D9);     // Primary accent / selection
  static const Color pastelLavender = Color(0xFFC4B5FD); // Secondary interactive buttons
  static const Color pastelRose = Color(0xFFF472B6);     // Feature highlights & badges
  static const Color pastelGreen = Color(0xFF86EFAC);    // Published status badge
  static const Color pastelYellow = Color(0xFFFDE047);   // Pre-release status badge
  static const Color pastelCoral = Color(0xFFFCA5A5);    // Draft status / warnings
  
  // Text Colors
  static const Color textPrimary = Color(0xFFF9FAFB);
  static const Color textSecondary = Color(0xFF94A3B8);

  static FluentThemeData get darkTheme {
    return FluentThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: obsidianBackground,
      cardColor: darkCardSurface,
      accentColor: AccentColor.swatch({
        'normal': pastelTeal,
        'light': pastelTeal,
        'lighter': pastelLavender,
        'lightest': pastelRose,
        'dark': pastelTeal,
        'darker': pastelTeal,
        'darkest': pastelTeal,
      }),
      navigationPaneTheme: const NavigationPaneThemeData(
        backgroundColor: acrylicNavigationHeader,
        overlayBackgroundColor: obsidianBackground,
      ),
      typography: const Typography.raw(
        body: TextStyle(color: textPrimary, fontSize: 13),
        caption: TextStyle(color: textSecondary, fontSize: 11),
        title: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
        subtitle: TextStyle(color: textPrimary, fontSize: 15, fontWeight: FontWeight.w600),
      ),
    );
  }
}

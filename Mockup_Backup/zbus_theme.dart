import 'package:flutter/material.dart';

class ZColors {
  static const bg = Color(0xFF11110F);
  static const surface = Color(0xFF1A1A17);
  static const surface2 = Color(0xFF20201C);
  static const ink = Color(0xFFF2ECDD);
  static const muted = Color(0xFFAAA89F);
  static const line = Color(0xFF45443D);
  static const accent = Color(0xFFD95645);
  static const success = Color(0xFFB6C7A0);
  static const warning = Color(0xFFE6BB75);
}

class ZTheme {
  static ThemeData get dark => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: ZColors.bg,
    colorScheme: const ColorScheme.dark(
      primary: ZColors.ink,
      secondary: ZColors.accent,
      surface: ZColors.surface,
      onSurface: ZColors.ink,
    ),
    fontFamily: 'ZBody',
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: ZColors.accent,
    ),
    splashFactory: NoSplash.splashFactory,
    dividerColor: ZColors.line,
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: ZColors.surface,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 17),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: ZColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: ZColors.ink),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: ZColors.accent),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.zero),
      hintStyle: TextStyle(color: ZColors.muted),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: ZColors.surface,
      shape: RoundedRectangleBorder(side: BorderSide(color: ZColors.line)),
    ),
  );
  static TextStyle display(double size, {Color color = ZColors.ink}) =>
      TextStyle(
        fontFamily: 'ZDisplay',
        fontSize: size,
        color: color,
        height: .91,
        letterSpacing: -.7,
        fontWeight: FontWeight.w900,
      );
  static TextStyle mono(
    double size, {
    Color color = ZColors.muted,
    FontWeight weight = FontWeight.w600,
  }) => TextStyle(
    fontFamily: 'ZMono',
    fontSize: size,
    color: color,
    letterSpacing: 1.1,
    fontWeight: weight,
    height: 1.4,
  );
}

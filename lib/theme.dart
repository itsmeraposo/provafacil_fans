import 'package:flutter/material.dart';

/// Paleta e tipografia derivadas do protótipo web do ProvaFácil FANS,
/// para manter a interface coerente entre as etapas do projeto.
class AppColors {
  static const paper = Color(0xFFF4F5F3);
  static const surface = Color(0xFFFFFFFF);
  static const ink = Color(0xFF1B1D22);
  static const inkMuted = Color(0xFF63666E);
  static const inkFaint = Color(0xFF9A9DA4);
  static const rule = Color(0xFFDFE1E4);
  static const accent = Color(0xFF1F3A93);
  static const accentSoft = Color(0xFFEDF0FA);
  static const moss = Color(0xFF3F6B4F);
  static const mossSoft = Color(0xFFEEF4EF);
  static const amber = Color(0xFF92600B);
  static const amberSoft = Color(0xFFFBF3E3);
  static const claret = Color(0xFF8C2F2B);
  static const claretSoft = Color(0xFFFBEEED);
}

/// Cor de identidade de cada perfil de acesso, usada em selos e avatares
/// para reforçar visualmente "quem está navegando" em cada tela.
Color corDoPerfil(String perfil) {
  switch (perfil) {
    case 'direcao':
      return AppColors.amber;
    case 'repografia':
      return AppColors.moss;
    default:
      return AppColors.accent;
  }
}

ThemeData buildAppTheme() {
  final base = ThemeData.light(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.paper,
    colorScheme: base.colorScheme.copyWith(
      primary: AppColors.accent,
      secondary: AppColors.moss,
      surface: AppColors.surface,
      error: AppColors.claret,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.ink,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: AppColors.ink,
        fontSize: 19,
        fontWeight: FontWeight.w600,
      ),
    ),
    drawerTheme: const DrawerThemeData(backgroundColor: AppColors.surface),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: AppColors.rule),
      ),
      margin: EdgeInsets.zero,
    ),
    dividerTheme: const DividerThemeData(color: AppColors.rule, space: 1),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.ink,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.ink,
        side: const BorderSide(color: AppColors.rule),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.accent),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.rule),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.rule),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.accent, width: 1.4),
      ),
      labelStyle: const TextStyle(color: AppColors.inkMuted, fontSize: 13),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: AppColors.paper,
      selectedColor: AppColors.accentSoft,
      labelStyle: const TextStyle(fontSize: 12.5, color: AppColors.ink),
      side: const BorderSide(color: AppColors.rule),
    ),
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    ),
  );
}

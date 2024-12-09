import 'package:flutter/material.dart';

class AppColors {
  // Colores base
  static const Color black = Colors.black;
  static const Color white = Colors.white;
  static const Color grey = Colors.black54;
  static const Color lightGrey = Colors.black12;
  static const Color redDark = Color(0xFF8C2F39); // Rojo oscuro
  static const Color beigeLight = Color(0xFFF1EFE7); // Fondo beige claro
  static const Color selectedIcon = Color.fromARGB(255, 189, 105, 105);

  // Control de tema
  static bool _isDarkMode = false;

  static void toggleTheme(bool isDarkMode) {
    _isDarkMode = isDarkMode;
  }

  // Colores dinámicos según el tema
  static Color get primary => _isDarkMode ? black : redDark;
  static Color get secondary => grey;
  static Color get tittle => white; // Título siempre blanco para contraste
  static Color get scaffoldBackground => _isDarkMode ? black : beigeLight;

  // Fondo de tarjeta siempre blanco
  static Color get cardBackground => white;

  // Texto principal dinámico (blanco en dark, negro en light)
  static Color get textPrimary => _isDarkMode ? white : black;
  static Color get textSecondary => grey;
  static Color get shadow => _isDarkMode ? lightGrey : Colors.black38;
  static Color get divider => _isDarkMode ? lightGrey : Colors.black38;
  static Color get iconSelected => selectedIcon;
  static Color get iconUnselected => _isDarkMode ? white : grey;

  // Colores para diálogos
  static Color get dialogBackground => _isDarkMode ? grey.withOpacity(0.9) : white;
  static Color get dialogText => _isDarkMode ? white : black;
  static Color get dialogTitleText => _isDarkMode ? white : black;
  static Color get dialogBodyText => _isDarkMode ? white : Colors.black87;
  static Color get dialogPrimaryButton =>
      _isDarkMode ? const Color(0xFFD32F2F) : const Color(0xFFB71C1C);
  static Color get dialogPrimaryButtonText => white;
  static Color get dialogSecondaryButton =>
      _isDarkMode ? const Color(0xFF9E9E9E) : const Color(0xFF757575);
  static Color get dialogSecondaryButtonText =>
      _isDarkMode ? const Color(0xFFDDDDDD) : const Color(0xFF4A4A4A);

  // Notificaciones
  static Color get notificationReadBackground =>
      _isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0);
  static Color get notificationUnreadBackground =>
      _isDarkMode ? const Color(0xFF383838) : white;
  static Color get notificationReadText =>
      _isDarkMode ? const Color(0xFFB0B0B0) : grey;
  static Color get notificationUnreadText => textPrimary;
  static Color get notificationTitleHighlight =>
      _isDarkMode ? const Color(0xFFFFD700) : redDark;

  // Colores fijos para el texto dentro de las tarjetas (siempre oscuros, para verse en el fondo blanco)
  static Color get cardTitleColor => black;
  static Color get cardAuthorColor => grey;

  // Crear ThemeData
  static ThemeData getThemeData(bool isDarkMode) {
    return ThemeData(
      primaryColor: primary,
      scaffoldBackgroundColor: scaffoldBackground,
      appBarTheme: AppBarTheme(
        backgroundColor: primary,
        foregroundColor: textPrimary,
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: textPrimary),
        bodyMedium: TextStyle(color: textSecondary),
      ),
      dividerColor: divider,
      cardColor: cardBackground,
    );
  }
}

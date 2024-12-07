import 'package:flutter/material.dart';

class AppColors {
  // Colores existentes
  static const Color black = Colors.black;
  static const Color white = Colors.white;
  static const Color grey = Colors.black54;
  static const Color lightGrey = Colors.black12;
  static const Color redDark = Color(0xFF8C2F39); // Rojo oscuro
  static const Color beigeLight = Color(0xFFF1EFE7); // Fondo beige claro
  static const Color selectedIcon = Color.fromARGB(255, 189, 105, 105); // Íconos seleccionados

  // Dinámica (tema actual)
  static bool _isDarkMode = false;

  static void toggleTheme(bool isDarkMode) {
    _isDarkMode = isDarkMode;
  }

  // Colores dinámicos
  static Color get primary => _isDarkMode ? black : redDark;
  static Color get secondary => grey;
  static Color get tittle => _isDarkMode ? beigeLight : beigeLight;
  static Color get scaffoldBackground => _isDarkMode ? black : beigeLight;
  static Color get cardBackground => white;
  static Color get textPrimary => _isDarkMode ? white : black;
  static Color get textSecondary => grey;
  static Color get shadow => _isDarkMode ? lightGrey : Colors.black38;
  static Color get divider => _isDarkMode ? lightGrey : Colors.black38;
  static Color get iconSelected => selectedIcon;
  static Color get iconUnselected => _isDarkMode ? white : grey;

  // Colores específicos para los diálogos
  static Color get dialogBackground => _isDarkMode ? grey.withOpacity(0.9) : white;
  static Color get dialogText => _isDarkMode ? white : black;

  // Colores específicos para notificaciones
  static Color get notificationReadBackground =>
      _isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0); // Fondo gris claro
  static Color get notificationUnreadBackground =>
      _isDarkMode ? const Color(0xFF383838) : white; // Blanco o gris oscuro
  static Color get notificationReadText =>
      _isDarkMode ? const Color(0xFFB0B0B0) : grey; // Texto gris claro en leídas
  static Color get notificationUnreadText => textPrimary; // Texto normal en no leídas
  static Color get notificationTitleHighlight =>
      _isDarkMode ? const Color(0xFFFFD700) : redDark; // Color de resaltado para el título

  // Crear ThemeData dinámicamente
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

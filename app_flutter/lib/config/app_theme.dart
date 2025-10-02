import 'package:flutter/material.dart';

/// Tema oscuro moderno con morado y detalles neón
/// Sistema de colores tecnológico e innovador
class AppTheme {
  // Colores de fondo
  static const Color backgroundDark = Color(0xFF0A0E27);
  static const Color backgroundCard = Color(0xFF151932);
  static const Color backgroundElevated = Color(0xFF1E293B);

  // Morado principal
  static const Color primaryPurple = Color(0xFF8B5CF6);
  static const Color primaryPurpleLight = Color(0xFFA78BFA);
  static const Color primaryPurpleDark = Color(0xFF6D28D9);

  // Colores neón
  static const Color neonPurple = Color(0xFFD8B4FE);
  static const Color neonCyan = Color(0xFF06B6D4);
  static const Color neonGreen = Color(0xFF10B981);
  static const Color neonPink = Color(0xFFEC4899);
  static const Color neonYellow = Color(0xFFFBBF24);
  static const Color neonOrange = Color(0xFFF97316);

  // Grises
  static const Color greyDark = Color(0xFF1E293B);
  static const Color greyMedium = Color(0xFF334155);
  static const Color greyLight = Color(0xFF475569);
  static const Color greyVeryLight = Color(0xFF64748B);

  // Texto
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textTertiary = Color(0xFF64748B);

  // Estados
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFFBBF24);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF06B6D4);

  // Gradientes
  static const LinearGradient purpleGradient = LinearGradient(
    colors: [primaryPurple, primaryPurpleLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient neonGradient = LinearGradient(
    colors: [neonPurple, neonCyan],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [backgroundDark, backgroundCard],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Sombras con glow neón
  static List<BoxShadow> neonShadow(Color color, {double blur = 20}) {
    return [
      BoxShadow(
        color: color.withOpacity(0.5),
        blurRadius: blur,
        spreadRadius: 0,
      ),
      BoxShadow(
        color: color.withOpacity(0.3),
        blurRadius: blur * 1.5,
        spreadRadius: 2,
      ),
    ];
  }

  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.3),
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
  ];

  // Border radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 24.0;

  // Spacing
  static const double spaceXSmall = 4.0;
  static const double spaceSmall = 8.0;
  static const double spaceMedium = 16.0;
  static const double spaceLarge = 12.0;
  static const double spaceXLarge = 32.0;

  // Typography
  static const TextStyle headingLarge = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    letterSpacing: -0.5,
  );

  static const TextStyle headingMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    letterSpacing: -0.3,
  );

  static const TextStyle headingSmall = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: textSecondary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: textTertiary,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: textTertiary,
    letterSpacing: 0.5,
  );

  // Decoración de contenedores
  static BoxDecoration cardDecoration = BoxDecoration(
    color: backgroundCard,
    borderRadius: BorderRadius.circular(radiusMedium),
    border: Border.all(color: greyMedium.withOpacity(0.3), width: 1),
    boxShadow: cardShadow,
  );

  static BoxDecoration glassDecoration = BoxDecoration(
    gradient: LinearGradient(
      colors: [
        backgroundCard.withOpacity(0.8),
        backgroundCard.withOpacity(0.6),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(radiusMedium),
    border: Border.all(color: primaryPurple.withOpacity(0.2), width: 1),
    boxShadow: [
      BoxShadow(
        color: primaryPurple.withOpacity(0.1),
        blurRadius: 20,
        spreadRadius: -5,
      ),
    ],
  );

  // Theme data
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryPurple,
      scaffoldBackgroundColor: backgroundDark,
      cardColor: backgroundCard,
      dividerColor: greyMedium.withOpacity(0.3),
      colorScheme: const ColorScheme.dark(
        primary: primaryPurple,
        secondary: neonCyan,
        surface: backgroundCard,
        background: backgroundDark,
        error: error,
        onPrimary: textPrimary,
        onSecondary: textPrimary,
        onSurface: textPrimary,
        onBackground: textPrimary,
        onError: textPrimary,
      ),
      textTheme: const TextTheme(
        displayLarge: headingLarge,
        displayMedium: headingMedium,
        displaySmall: headingSmall,
        bodyLarge: bodyLarge,
        bodyMedium: bodyMedium,
        bodySmall: bodySmall,
      ),
      cardTheme: CardThemeData(
        color: backgroundCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundDark,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: headingMedium,
        iconTheme: IconThemeData(color: textPrimary),
      ),
    );
  }
}

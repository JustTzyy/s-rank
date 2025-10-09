import 'package:flutter/material.dart';

class AppTheme {
  // Purple color scheme
  static const Color primaryPurple = Color(0xFF9C27B0);
  static const Color lightPurple = Color(0xFFE1BEE7);
  static const Color darkPurple = Color(0xFF7B1FA2);
  static const Color accentPurple = Color(0xFFBA68C8);
  static const Color lightPurpleBackground = Color(0xFFFCFBFF); // Very light lavender background
  
  // Light mode colors
  static const Color backgroundColor = Color(0xFFFFFFFF);
  static const Color surfaceColor = Color(0xFFF8F9FA);
  static const Color textPrimary = Color(0xFF2C2C2C);
  static const Color textSecondary = Color(0xFF6C6C6C);
  static const Color borderColor = Color(0xFFE0E0E0);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color errorColor = Color(0xFFE53935);
  
  // Dark mode colors
  static const Color darkBackgroundColor = Color(0xFF121212);
  static const Color darkSurfaceColor = Color(0xFF1E1E1E);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFB0B0B0);
  static const Color darkBorderColor = Color(0xFF333333);
  static const Color darkSuccessColor = Color(0xFF66BB6A);
  static const Color darkErrorColor = Color(0xFFEF5350);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppTheme.primaryPurple,
        brightness: Brightness.light,
        primary: AppTheme.primaryPurple,
        secondary: AppTheme.accentPurple,
        surface: AppTheme.surfaceColor,
        background: AppTheme.backgroundColor,
        error: AppTheme.errorColor,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppTheme.backgroundColor,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryPurple,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.textPrimary,
          side: const BorderSide(color: AppTheme.borderColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppTheme.backgroundColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryPurple, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.errorColor),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppTheme.textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: AppTheme.textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: AppTheme.textSecondary,
        ),
        labelLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppTheme.textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppTheme.primaryPurple,
        unselectedLabelColor: AppTheme.textSecondary,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: AppTheme.primaryPurple, width: 2),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppTheme.primaryPurple,
        brightness: Brightness.dark,
        primary: AppTheme.primaryPurple,
        secondary: AppTheme.accentPurple,
        surface: AppTheme.darkSurfaceColor,
        background: AppTheme.darkBackgroundColor,
        error: AppTheme.darkErrorColor,
      ),
      scaffoldBackgroundColor: AppTheme.darkBackgroundColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppTheme.darkBackgroundColor,
        foregroundColor: AppTheme.darkTextPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryPurple,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.darkTextPrimary,
          side: const BorderSide(color: AppTheme.darkBorderColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppTheme.primaryPurple,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppTheme.darkSurfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.darkBorderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.darkBorderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryPurple, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.darkErrorColor),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        hintStyle: const TextStyle(color: AppTheme.darkTextSecondary),
        labelStyle: const TextStyle(color: AppTheme.darkTextSecondary),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppTheme.darkTextPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: AppTheme.darkTextPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: AppTheme.darkTextPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: AppTheme.darkTextSecondary,
        ),
        labelLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppTheme.darkTextPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppTheme.darkSurfaceColor,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppTheme.darkSurfaceColor,
        titleTextStyle: const TextStyle(
          color: AppTheme.darkTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        contentTextStyle: const TextStyle(
          color: AppTheme.darkTextSecondary,
          fontSize: 16,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppTheme.darkSurfaceColor,
        contentTextStyle: const TextStyle(
          color: AppTheme.darkTextPrimary,
        ),
        actionTextColor: AppTheme.primaryPurple,
      ),
      listTileTheme: const ListTileThemeData(
        textColor: AppTheme.darkTextPrimary,
        iconColor: AppTheme.darkTextSecondary,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return AppTheme.primaryPurple;
          }
          return AppTheme.darkTextSecondary;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return AppTheme.primaryPurple.withOpacity(0.5);
          }
          return AppTheme.darkBorderColor;
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return AppTheme.primaryPurple;
          }
          return Colors.transparent;
        }),
        checkColor: MaterialStateProperty.all(Colors.white),
        side: const BorderSide(color: AppTheme.darkBorderColor),
      ),
      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return AppTheme.primaryPurple;
          }
          return AppTheme.darkTextSecondary;
        }),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppTheme.primaryPurple,
        inactiveTrackColor: AppTheme.darkBorderColor,
        thumbColor: AppTheme.primaryPurple,
        overlayColor: AppTheme.primaryPurple.withOpacity(0.2),
      ),
      dividerTheme: const DividerThemeData(
        color: AppTheme.darkBorderColor,
        thickness: 1,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppTheme.darkSurfaceColor,
        selectedItemColor: AppTheme.primaryPurple,
        unselectedItemColor: AppTheme.darkTextSecondary,
        type: BottomNavigationBarType.fixed,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppTheme.primaryPurple,
        unselectedLabelColor: AppTheme.darkTextSecondary,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: AppTheme.primaryPurple, width: 2),
        ),
      ),
    );
  }
}

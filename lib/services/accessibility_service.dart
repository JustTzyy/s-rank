import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccessibilityService extends ChangeNotifier {
  static AccessibilityService? _instance;
  
  factory AccessibilityService() {
    _instance ??= AccessibilityService._internal();
    return _instance!;
  }
  
  AccessibilityService._internal();

  // Accessibility Settings
  String _fontSize = 'Medium';
  bool _darkMode = false;
  bool _highContrast = false;
  bool _screenReader = false;

  // Getters
  String get fontSize => _fontSize;
  bool get darkMode => _darkMode;
  bool get highContrast => _highContrast;
  bool get screenReader => _screenReader;

  // Font size multipliers
  double get fontScale {
    switch (_fontSize) {
      case 'Small':
        return 0.85;
      case 'Large':
        return 1.2;
      case 'Medium':
      default:
        return 1.0;
    }
  }

  // Initialize service and load saved settings
  Future<void> initialize() async {
    await _loadSettings();
  }

  // Load settings from SharedPreferences
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _fontSize = prefs.getString('accessibility_font_size') ?? 'Medium';
      _darkMode = prefs.getBool('accessibility_dark_mode') ?? false;
      _highContrast = prefs.getBool('accessibility_high_contrast') ?? false;
      _screenReader = prefs.getBool('accessibility_screen_reader') ?? false;
      notifyListeners();
    } catch (e) {
      print('Error loading accessibility settings: $e');
    }
  }

  // Save settings to SharedPreferences
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('accessibility_font_size', _fontSize);
      await prefs.setBool('accessibility_dark_mode', _darkMode);
      await prefs.setBool('accessibility_high_contrast', _highContrast);
      await prefs.setBool('accessibility_screen_reader', _screenReader);
    } catch (e) {
      print('Error saving accessibility settings: $e');
    }
  }

  // Update font size
  Future<void> updateFontSize(String fontSize) async {
    _fontSize = fontSize;
    await _saveSettings();
    notifyListeners();
  }

  // Update dark mode
  Future<void> updateDarkMode(bool darkMode) async {
    _darkMode = darkMode;
    await _saveSettings();
    notifyListeners();
  }

  // Update high contrast
  Future<void> updateHighContrast(bool highContrast) async {
    _highContrast = highContrast;
    await _saveSettings();
    notifyListeners();
  }

  // Update screen reader
  Future<void> updateScreenReader(bool screenReader) async {
    _screenReader = screenReader;
    await _saveSettings();
    notifyListeners();
  }

  // Get theme data based on accessibility settings
  ThemeData getThemeData(BuildContext context) {
    final baseTheme = _darkMode ? ThemeData.dark() : ThemeData.light();
    
    return baseTheme.copyWith(
      textTheme: _getTextTheme(baseTheme.textTheme),
      colorScheme: _getColorScheme(baseTheme.colorScheme),
      appBarTheme: _getAppBarTheme(baseTheme.appBarTheme),
      cardTheme: _getCardTheme(baseTheme.cardTheme),
      elevatedButtonTheme: _getElevatedButtonTheme(baseTheme.elevatedButtonTheme),
      outlinedButtonTheme: _getOutlinedButtonTheme(baseTheme.outlinedButtonTheme),
      inputDecorationTheme: _getInputDecorationTheme(baseTheme.inputDecorationTheme),
    );
  }

  // Get text theme with font scaling
  TextTheme _getTextTheme(TextTheme baseTextTheme) {
    // If fontScale is 1.0, return the original theme to avoid assertion issues
    if (fontScale == 1.0) {
      return baseTextTheme;
    }
    
    // Create a new TextTheme with explicit font sizes to avoid null fontSize issues
    return TextTheme(
      displayLarge: _scaleTextStyle(baseTextTheme.displayLarge),
      displayMedium: _scaleTextStyle(baseTextTheme.displayMedium),
      displaySmall: _scaleTextStyle(baseTextTheme.displaySmall),
      headlineLarge: _scaleTextStyle(baseTextTheme.headlineLarge),
      headlineMedium: _scaleTextStyle(baseTextTheme.headlineMedium),
      headlineSmall: _scaleTextStyle(baseTextTheme.headlineSmall),
      titleLarge: _scaleTextStyle(baseTextTheme.titleLarge),
      titleMedium: _scaleTextStyle(baseTextTheme.titleMedium),
      titleSmall: _scaleTextStyle(baseTextTheme.titleSmall),
      bodyLarge: _scaleTextStyle(baseTextTheme.bodyLarge),
      bodyMedium: _scaleTextStyle(baseTextTheme.bodyMedium),
      bodySmall: _scaleTextStyle(baseTextTheme.bodySmall),
      labelLarge: _scaleTextStyle(baseTextTheme.labelLarge),
      labelMedium: _scaleTextStyle(baseTextTheme.labelMedium),
      labelSmall: _scaleTextStyle(baseTextTheme.labelSmall),
    );
  }

  // Helper method to safely scale a TextStyle
  TextStyle? _scaleTextStyle(TextStyle? style) {
    if (style == null) return null;
    
    final baseFontSize = style.fontSize ?? 14.0;
    return style.copyWith(
      fontSize: baseFontSize * fontScale,
    );
  }

  // Get color scheme with high contrast support
  ColorScheme _getColorScheme(ColorScheme baseColorScheme) {
    if (!_highContrast) return baseColorScheme;

    return baseColorScheme.copyWith(
      primary: _darkMode ? Colors.white : Colors.black,
      secondary: _darkMode ? Colors.grey[300] : Colors.grey[700],
      surface: _darkMode ? Colors.grey[900] : Colors.white,
      background: _darkMode ? Colors.black : Colors.grey[50],
      error: Colors.red[700],
      onPrimary: _darkMode ? Colors.black : Colors.white,
      onSecondary: _darkMode ? Colors.black : Colors.white,
      onSurface: _darkMode ? Colors.white : Colors.black,
      onBackground: _darkMode ? Colors.white : Colors.black,
      onError: Colors.white,
    );
  }

  // Get app bar theme
  AppBarTheme _getAppBarTheme(AppBarThemeData baseAppBarTheme) {
    return AppBarTheme(
      backgroundColor: _highContrast 
          ? (_darkMode ? Colors.black : Colors.white)
          : baseAppBarTheme.backgroundColor,
      foregroundColor: _highContrast 
          ? (_darkMode ? Colors.white : Colors.black)
          : baseAppBarTheme.foregroundColor,
    );
  }

  // Get card theme
  CardThemeData _getCardTheme(CardThemeData baseCardTheme) {
    return CardThemeData(
      color: _highContrast 
          ? (_darkMode ? Colors.grey[800] : Colors.grey[100])
          : baseCardTheme.color,
      elevation: _highContrast ? 8.0 : baseCardTheme.elevation,
    );
  }

  // Get elevated button theme
  ElevatedButtonThemeData _getElevatedButtonTheme(ElevatedButtonThemeData baseTheme) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _highContrast 
            ? (_darkMode ? Colors.white : Colors.black)
            : const Color(0xFF6B46C1), // AppTheme.primaryPurple
        foregroundColor: _highContrast 
            ? (_darkMode ? Colors.black : Colors.white)
            : Colors.white,
        elevation: _highContrast ? 4.0 : 2.0,
        textStyle: TextStyle(
          fontSize: (baseTheme.style?.textStyle?.resolve({})?.fontSize ?? 14) * fontScale,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // Get outlined button theme
  OutlinedButtonThemeData _getOutlinedButtonTheme(OutlinedButtonThemeData baseTheme) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _highContrast 
            ? (_darkMode ? Colors.white : Colors.black)
            : const Color(0xFF6B46C1), // AppTheme.primaryPurple
        side: BorderSide(
          color: _highContrast 
              ? (_darkMode ? Colors.white : Colors.black)
              : const Color(0xFF6B46C1),
          width: _highContrast ? 2.0 : 1.0,
        ),
        textStyle: TextStyle(
          fontSize: (baseTheme.style?.textStyle?.resolve({})?.fontSize ?? 14) * fontScale,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // Get input decoration theme
  InputDecorationTheme _getInputDecorationTheme(InputDecorationThemeData baseTheme) {
    return InputDecorationTheme(
      border: OutlineInputBorder(
        borderSide: BorderSide(
          color: _highContrast 
              ? (_darkMode ? Colors.white : Colors.black)
              : Colors.grey,
          width: _highContrast ? 2.0 : 1.0,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: _highContrast 
              ? (_darkMode ? Colors.white : Colors.black)
              : const Color(0xFF6B46C1),
          width: _highContrast ? 3.0 : 2.0,
        ),
      ),
    );
  }

  // Get semantic label for screen reader
  String? getSemanticLabel(String? originalLabel) {
    if (!_screenReader) return originalLabel;
    
    // Add more descriptive labels for screen readers
    if (originalLabel == null) return null;
    
    // You can add more specific semantic labels here
    return originalLabel;
  }

  // Get semantic hint for screen reader
  String? getSemanticHint(String? originalHint) {
    if (!_screenReader) return originalHint;
    
    // Add more descriptive hints for screen readers
    if (originalHint == null) return null;
    
    return originalHint;
  }

  // Apply accessibility to any widget
  Widget applyAccessibility(Widget child, {String? semanticLabel, String? semanticHint}) {
    if (!_screenReader) return child;
    
    return Semantics(
      label: getSemanticLabel(semanticLabel),
      hint: getSemanticHint(semanticHint),
      child: child,
    );
  }

  // Get accessible text style
  TextStyle getAccessibleTextStyle(TextStyle baseStyle) {
    final baseFontSize = baseStyle.fontSize ?? 14.0;
    return baseStyle.copyWith(
      fontSize: baseFontSize * fontScale,
    );
  }

  // Get accessible icon size
  double getAccessibleIconSize(double baseSize) {
    return baseSize * fontScale;
  }

  // Get accessible padding
  EdgeInsets getAccessiblePadding(EdgeInsetsGeometry basePadding) {
    final padding = basePadding as EdgeInsets;
    return EdgeInsets.only(
      left: padding.left * fontScale,
      top: padding.top * fontScale,
      right: padding.right * fontScale,
      bottom: padding.bottom * fontScale,
    );
  }

  // Get accessible spacing
  double getAccessibleSpacing(double baseSpacing) {
    return baseSpacing * fontScale;
  }
}

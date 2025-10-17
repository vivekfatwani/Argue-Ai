import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class ThemeProvider with ChangeNotifier {
  final StorageService _storageService;
  bool _isDarkMode = false;
  
  // Define light and dark themes
  static final ThemeData _lightTheme = ThemeData(
    primarySwatch: Colors.indigo,
    colorScheme: ColorScheme.light(
      primary: const Color(0xFF3F51B5),      // Indigo
      secondary: const Color(0xFF2196F3),    // Blue
      tertiary: const Color(0xFFFFC107),     // Amber for accents
      surface: Colors.white,
      background: Colors.white,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.black87,
      onBackground: Colors.black87,
    ),
    brightness: Brightness.light,
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF3F51B5),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF3F51B5),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
    ),
    textTheme: const TextTheme(
      headlineMedium: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF3F51B5)),
      titleLarge: TextStyle(fontWeight: FontWeight.bold),
    ),
  );
  
  static final ThemeData _darkTheme = ThemeData(
    primarySwatch: Colors.indigo,
    colorScheme: ColorScheme.dark(
      primary: const Color(0xFF3F51B5),      // Indigo
      secondary: const Color(0xFF2196F3),    // Blue
      tertiary: const Color(0xFFFFC107),     // Amber for accents
      surface: const Color(0xFF1F1F1F),
      background: const Color(0xFF121212),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.white,
      onBackground: Colors.white,
    ),
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF121212),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1A237E),  // Darker indigo
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF3F51B5),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: const Color(0xFF1F1F1F),
    ),
    textTheme: const TextTheme(
      headlineMedium: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF7986CB)),  // Lighter indigo
      titleLarge: TextStyle(fontWeight: FontWeight.bold),
    ),
  );
  
  ThemeProvider(this._storageService) {
    _loadThemePreference();
  }
  
  bool get isDarkMode => _isDarkMode;
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;
  ThemeData get currentTheme => _isDarkMode ? _darkTheme : _lightTheme;
  
  // Load theme preference from storage
  Future<void> _loadThemePreference() async {
    final preferences = await _storageService.getUserPreferences();
    _isDarkMode = preferences['darkMode'] ?? false;
    notifyListeners();
  }
  
  // Toggle between light and dark theme
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    
    final preferences = await _storageService.getUserPreferences();
    preferences['darkMode'] = _isDarkMode;
    await _storageService.saveUserPreferences(preferences);
    
    notifyListeners();
  }
  
  // Set specific theme mode
  Future<void> setDarkMode(bool isDark) async {
    _isDarkMode = isDark;
    
    final preferences = await _storageService.getUserPreferences();
    preferences['darkMode'] = _isDarkMode;
    await _storageService.saveUserPreferences(preferences);
    
    notifyListeners();
  }
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends ChangeNotifier {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  SharedPreferences? _prefs;

  // Settings keys
  static const String _keyNotificationsEnabled = 'notifications_enabled';
  static const String _keyFullBinAlerts = 'full_bin_alerts';
  static const String _keyDailySummary = 'daily_summary';
  static const String _keySoundEnabled = 'sound_enabled';
  static const String _keyAlertThreshold = 'alert_threshold';
  static const String _keyThemeMode = 'theme_mode';

  // Default values
  bool _notificationsEnabled = true;
  bool _fullBinAlerts = true;
  bool _dailySummary = false;
  bool _soundEnabled = true;
  int _alertThreshold = 80;
  ThemeMode _themeMode = ThemeMode.light;

  // Getters
  bool get notificationsEnabled => _notificationsEnabled;
  bool get fullBinAlerts => _fullBinAlerts;
  bool get dailySummary => _dailySummary;
  bool get soundEnabled => _soundEnabled;
  int get alertThreshold => _alertThreshold;
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  /// Initialize settings from SharedPreferences
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadSettings();
  }

  /// Load all settings from storage
  Future<void> _loadSettings() async {
    _notificationsEnabled = _prefs?.getBool(_keyNotificationsEnabled) ?? true;
    _fullBinAlerts = _prefs?.getBool(_keyFullBinAlerts) ?? true;
    _dailySummary = _prefs?.getBool(_keyDailySummary) ?? false;
    _soundEnabled = _prefs?.getBool(_keySoundEnabled) ?? true;
    _alertThreshold = _prefs?.getInt(_keyAlertThreshold) ?? 80;
    
    final themeModeString = _prefs?.getString(_keyThemeMode) ?? 'light';
    _themeMode = themeModeString == 'dark' ? ThemeMode.dark : ThemeMode.light;
    
    notifyListeners();
  }

  /// Toggle notifications on/off
  Future<void> setNotificationsEnabled(bool value) async {
    _notificationsEnabled = value;
    await _prefs?.setBool(_keyNotificationsEnabled, value);
    notifyListeners();
  }

  /// Toggle full bin alerts
  Future<void> setFullBinAlerts(bool value) async {
    _fullBinAlerts = value;
    await _prefs?.setBool(_keyFullBinAlerts, value);
    notifyListeners();
  }

  /// Toggle daily summary
  Future<void> setDailySummary(bool value) async {
    _dailySummary = value;
    await _prefs?.setBool(_keyDailySummary, value);
    notifyListeners();
  }

  /// Toggle sound
  Future<void> setSoundEnabled(bool value) async {
    _soundEnabled = value;
    await _prefs?.setBool(_keySoundEnabled, value);
    notifyListeners();
  }

  /// Set alert threshold (50-95%)
  Future<void> setAlertThreshold(int value) async {
    _alertThreshold = value.clamp(50, 95);
    await _prefs?.setInt(_keyAlertThreshold, _alertThreshold);
    notifyListeners();
  }

  /// Toggle theme between light and dark
  Future<void> toggleTheme() async {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    final themeModeString = _themeMode == ThemeMode.dark ? 'dark' : 'light';
    await _prefs?.setString(_keyThemeMode, themeModeString);
    notifyListeners();
  }

  /// Set specific theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final themeModeString = mode == ThemeMode.dark ? 'dark' : 'light';
    await _prefs?.setString(_keyThemeMode, themeModeString);
    notifyListeners();
  }

  /// Check if a bin fill level should trigger an alert
  bool shouldAlert(int fillLevel) {
    return notificationsEnabled && 
           fullBinAlerts && 
           fillLevel >= alertThreshold;
  }

  /// Reset all settings to defaults
  Future<void> resetToDefaults() async {
    await _prefs?.clear();
    _notificationsEnabled = true;
    _fullBinAlerts = true;
    _dailySummary = false;
    _soundEnabled = true;
    _alertThreshold = 80;
    _themeMode = ThemeMode.light;
    notifyListeners();
  }
}
